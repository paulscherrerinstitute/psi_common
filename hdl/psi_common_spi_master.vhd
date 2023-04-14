------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple SPI-master.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- @formatter:off
entity psi_common_spi_master is
  generic(clk_div_g         : natural range 4 to 1_000_000;                      -- Must be a multiple of two
          trans_width_g     : positive;                                          -- SPI Transaction width
          cs_high_cycles_g  : positive;                                          -- Minimal number of CS high cycle between 2 trans
          spi_cpol_g        : natural range 0 to 1;                              -- SPI clock polarity
          spi_cpha_g        : natural range 0 to 1;                              -- SPI sampling edge config
          slave_cnt_g       : positive  := 1;                                    -- Number if slaves to support
          lsb_first_g       : boolean   := false;                                -- False = MSB first trasnmission and True LSB
          mosi_idle_state_g : std_logic := '0';                                  -- Idle state of the MOSI line
          rst_pol_g         : std_logic:= '1');                                  -- reset polarity
  port(    -- Control Signals                                                    
          clk_i      : in  std_logic;                                            -- system clock
          rst_i      : in  std_logic;                                            -- system reset (sync)
          -- Parallel Interface                                                  
          start_i    : in  std_logic;                                            -- a high pulse on this line starts the trasnfer, Note that starting a transaction is  only possible when *Busy* is low.
          slave_i    : in  std_logic_vector(log2ceil(slave_cnt_g) - 1 downto 0); --  Slave number to access
          busy_o     : out std_logic;                                            -- High during a transaction
          done_o     : out std_logic;                                            -- Pulse that goes high for exactly one clock cycle after a transaction is done and *RdData* is valid
          dat_i      : in  std_logic_vector(trans_width_g - 1 downto 0);         --  Data to send to  slave. Sampled  during *Start = '1'*
          dat_o      : out std_logic_vector(trans_width_g - 1 downto 0);         -- Data received from slave. Must be sampled during *Done = '1'* or *Busy = '0'*.
          -- SPI
          spi_sck_o  : out std_logic;                                            -- SPI clock
          spi_mosi_o : out std_logic;                                            -- SPI master to slave data signal
          spi_miso_i : in  std_logic;                                            -- SPI slave to master data signal
          spi_cs_n_o : out std_logic_vector(slave_cnt_g - 1 downto 0);           -- SPI slave select signal (low active)
          spi_le_o   : out std_logic_vector(slave_cnt_g - 1 downto 0));          -- SPI slave latch enable (high active)
end entity;
-- @formatter:on

architecture rtl of psi_common_spi_master is

  -- *** Types ***
  type State_t is (Idle_s, SftComp_s, ClkInact_s, ClkAct_s, CsHigh_s);

  -- *** Constants ***
  constant ClkDivThres_c : natural := clk_div_g / 2 - 1;

  -- *** Two Process Method ***
  type two_process_r is record
    State      : State_t;
    StateLast  : State_t;
    ShiftReg   : std_logic_vector(trans_width_g - 1 downto 0);
    dat_o      : std_logic_vector(trans_width_g - 1 downto 0);
    spi_cs_n_o : std_logic_vector(slave_cnt_g - 1 downto 0);
    spi_le_o   : std_logic_vector(slave_cnt_g - 1 downto 0);
    spi_sck_o  : std_logic;
    spi_mosi_o : std_logic;
    ClkDivCnt  : integer range 0 to ClkDivThres_c;
    BitCnt     : integer range 0 to trans_width_g;
    CsHighCnt  : integer range 0 to cs_high_cycles_g - 1;
    busy_o     : std_logic;
    done_o     : std_logic;
    MosiNext   : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- *** Functions and procedures ***
  function GetClockLevel(ClkActive : boolean) return std_logic is
  begin
    if spi_cpol_g = 0 then
      if ClkActive then
        return '1';
      else
        return '0';
      end if;
    else
      if ClkActive then
        return '0';
      else
        return '1';
      end if;
    end if;
  end function;

  procedure ShiftReg(signal BeforeShift  : in std_logic_vector(trans_width_g-1 downto 0);
                     variable AfterShift : out std_logic_vector(trans_width_g-1 downto 0);
                     signal InputBit     : in std_logic;
                     variable OutputBit  : out std_logic) is
  begin
    if lsb_first_g then
      OutputBit  := BeforeShift(0);
      AfterShift := InputBit & BeforeShift(BeforeShift'high downto 1);
    else
      OutputBit  := BeforeShift(BeforeShift'high);
      AfterShift := BeforeShift(BeforeShift'high - 1 downto 0) & InputBit;
    end if;
  end procedure;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  assert floor(real(clk_div_g) / 2.0) = ceil(real(clk_div_g) / 2.0) report "###ERROR###: psi_common_spi_master - Ratio clk_div_g must be a multiple of two" severity error;

  p_comb : process(r, start_i, dat_i, spi_miso_i, slave_i)
    variable v : two_process_r;
  begin
    -- *** hold variables stable ***
    v := r;

    -- *** Default Values ***
    v.done_o := '0';

    -- *** State Machine ***
    case r.State is
      when Idle_s =>
        -- Start of Transfer
        if start_i = '1' then
          v.ShiftReg                                  := dat_i;
          v.spi_cs_n_o(to_integer(unsigned(slave_i))) := '0';
          v.State                                     := SftComp_s;
          v.busy_o                                    := '1';
        end if;
        v.CsHighCnt := 0;
        v.ClkDivCnt := 0;
        v.BitCnt    := 0;
        v.spi_le_o  := (others => '0');
      when SftComp_s =>
        v.State := ClkInact_s;
        -- Compensate shift for CPHA 0
        if spi_cpha_g = 0 then
          ShiftReg(r.ShiftReg, v.ShiftReg, spi_miso_i, v.MosiNext);
        end if;

      when ClkInact_s =>
        v.spi_sck_o := GetClockLevel(false);
        -- Apply/Latch data if required
        if r.ClkDivCnt = 0 then
          if spi_cpha_g = 0 then
            v.spi_mosi_o := r.MosiNext;
          else
            ShiftReg(r.ShiftReg, v.ShiftReg, spi_miso_i, v.MosiNext);
          end if;
        end if;
        -- Clock period handling
        if r.ClkDivCnt = ClkDivThres_c then
          -- All bits done
          if r.BitCnt = trans_width_g then
            v.spi_mosi_o := mosi_idle_state_g;
            v.State      := CsHigh_s;
            v.spi_le_o   := not r.spi_cs_n_o;
          -- Otherwise contintue
          else
            v.State := ClkAct_s;
          end if;
          v.ClkDivCnt := 0;
        else
          v.ClkDivCnt := r.ClkDivCnt + 1;
        end if;

      when ClkAct_s =>
        v.spi_sck_o := GetClockLevel(true);
        -- Apply data if required
        if r.ClkDivCnt = 0 then
          if spi_cpha_g = 1 then
            v.spi_mosi_o := r.MosiNext;
          else
            ShiftReg(r.ShiftReg, v.ShiftReg, spi_miso_i, v.MosiNext);
          end if;
        end if;
        -- Clock period handling
        if r.ClkDivCnt = ClkDivThres_c then
          v.State     := ClkInact_s;
          v.ClkDivCnt := 0;
          v.BitCnt    := r.BitCnt + 1;
        else
          v.ClkDivCnt := r.ClkDivCnt + 1;
        end if;

      when CsHigh_s =>
        v.spi_mosi_o := '0';
        v.spi_cs_n_o := (others => '1');
        if r.CsHighCnt = cs_high_cycles_g - 1 then
          v.State  := Idle_s;
          v.busy_o := '0';
          v.done_o := '1';
          v.dat_o  := r.ShiftReg;
        else
          v.CsHighCnt := r.CsHighCnt + 1;
        end if;

      when others => null;
    end case;

    -- *** assign signal ***
    r_next <= v;
  end process;

  -- Outputs
  busy_o     <= r.busy_o;
  done_o     <= r.done_o;
  dat_o      <= r.dat_o;
  spi_sck_o  <= r.spi_sck_o;
  spi_cs_n_o <= r.spi_cs_n_o;
  spi_mosi_o <= r.spi_mosi_o;
  spi_le_o   <= r.spi_le_o;
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.State      <= Idle_s;
        r.spi_cs_n_o <= (others => '1');
        r.spi_le_o   <= (others => '0');
        r.spi_sck_o  <= GetClockLevel(false);
        r.busy_o     <= '0';
        r.done_o     <= '0';
        r.spi_mosi_o <= mosi_idle_state_g;
      end if;
    end if;
  end process;

end architecture;

