------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
--  Modification: Frank Herzog
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple SPI-master
-- Modification: allows modifying transmit vector length dynamically

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=stim,spi $$
-- $$ tbpkg=work.psi_tb_compare_pkg,work.psi_tb_activity_pkg,work.psi_tb_txt_util $$
entity psi_common_spi_master_cfg is
  generic(
    clock_divider_g   : natural range 4 to 1_000_000 := 4; -- Must be a multiple of two	
    max_trans_width_g : positive                     := 16; -- SPI Transaction width		
    cs_high_cycles_g  : positive                     := 2; 
    spi_cpol_g        : natural range 0 to 1         := 1; 
    spi_cpha_g        : natural range 0 to 1         := 1; 
    slave_cnt_g       : positive                     := 1; 
    lsb_first_g       : boolean                      := false; 
    mosi_idle_state_g : std_logic                    := '0';
    rst_pol_g         : std_logic                    := '1');
  port(
    -- Control Signals
    clk_i         : in  std_logic;      
    rst_i         : in  std_logic;      
    -- Parallel Interface
    start_i       : in  std_logic;
    slave_i       : in  std_logic_vector(log2ceil(slave_cnt_g) - 1 downto 0);
    busy_o        : out std_logic;
    done_o        : out std_logic;
    wr_dat_i      : in  std_logic_vector(max_trans_width_g - 1 downto 0);
    rd_dat_o      : out std_logic_vector(max_trans_width_g - 1 downto 0);
    trans_width_i : in  std_logic_vector(log2ceil(max_trans_width_g) downto 0);
    -- SPI
    spi_sck_o     : out std_logic;
    spi_mosi_o    : out std_logic;
    spi_miso_i    : in  std_logic;
    spi_cs_n_o    : out std_logic_vector(slave_cnt_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_spi_master_cfg is

  -- *** Types ***
  type State_t is (Idle_s, SftComp_s, ClkInact_s, ClkAct_s, CsHigh_s);

  -- *** Constants ***
  constant ClkDivThres_c : natural := clock_divider_g / 2 - 1;

  -- *** Two Process Method ***
  type two_process_r is record
    State         : State_t;
    StateLast     : State_t;
    ShiftReg      : std_logic_vector(max_trans_width_g - 1 downto 0);
    rd_dat_o      : std_logic_vector(max_trans_width_g - 1 downto 0);
    spi_cs_n_o    : std_logic_vector(slave_cnt_g - 1 downto 0);
    spi_sck_o     : std_logic;
    spi_mosi_o    : std_logic;
    ClkDivCnt     : integer range 0 to ClkDivThres_c;
    BitCnt        : integer range 0 to max_trans_width_g;
    CsHighCnt     : integer range 0 to cs_high_cycles_g - 1;
    busy_o        : std_logic;
    done_o        : std_logic;
    MosiNext      : std_logic;
    trans_width_i : std_logic_vector(log2ceil(max_trans_width_g) downto 0);
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

  procedure ShiftReg(signal BeforeShift  : in std_logic_vector(max_trans_width_g-1 downto 0);
                     variable AfterShift : out std_logic_vector(max_trans_width_g-1 downto 0);
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
  assert floor(real(clock_divider_g) / 2.0) = ceil(real(clock_divider_g) / 2.0) report "###ERROR###: psi_common_spi_master - Ratio clock_divider_g must be a multiple of two" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Proccess
  --------------------------------------------------------------------------
  p_comb : process(r, start_i, wr_dat_i, spi_miso_i, slave_i, trans_width_i)
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
          v.ShiftReg                                  := wr_dat_i;
          v.spi_cs_n_o(to_integer(unsigned(slave_i))) := '0';
          v.State                                     := SftComp_s;
          v.busy_o                                    := '1';
          v.trans_width_i                             := trans_width_i;
        end if;
        v.CsHighCnt := 0;
        v.ClkDivCnt := 0;
        v.BitCnt    := 0;

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
          if r.BitCnt = to_integer(unsigned(r.trans_width_i)) then
            v.spi_mosi_o := mosi_idle_state_g;
            v.State      := CsHigh_s;
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
        v.spi_cs_n_o := (others => '1');
        if r.CsHighCnt = cs_high_cycles_g - 1 then
          v.State    := Idle_s;
          v.busy_o   := '0';
          v.done_o   := '1';
          v.rd_dat_o := r.ShiftReg;
        else
          v.CsHighCnt := r.CsHighCnt + 1;
        end if;

      when others => null;
    end case;

    -- *** assign signal ***
    r_next <= v;
  end process;

  --------------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------------
  busy_o     <= r.busy_o;
  done_o     <= r.done_o;
  rd_dat_o   <= r.rd_dat_o;
  spi_sck_o  <= r.spi_sck_o;
  spi_cs_n_o <= r.spi_cs_n_o;
  spi_mosi_o <= r.spi_mosi_o;

  --------------------------------------------------------------------------
  -- Sequential Proccess
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.State      <= Idle_s;
        r.spi_cs_n_o <= (others => '1');
        r.spi_sck_o  <= GetClockLevel(false);
        r.busy_o     <= '0';
        r.done_o     <= '0';
        r.spi_mosi_o <= mosi_idle_state_g;
      end if;
    end if;
  end process;

end architecture;
