------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple SPI-master.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim,spi $$
-- $$ tbpkg=work.psi_tb_compare_pkg,work.psi_tb_activity_pkg,work.psi_tb_txt_util $$
entity psi_common_spi_master is
  generic(
    ClockDivider_g : natural range 4 to 1_000_000; -- Must be a multiple of two	$$ constant=8 $$
    TransWidth_g   : positive;          -- SPI Transaction width		$$ constant=8 $$
    CsHighCycles_g : positive;          -- $$ constant=2 $$
    SpiCPOL_g      : natural range 0 to 1; -- $$ export=true $$
    SpiCPHA_g      : natural range 0 to 1; -- $$ export=true $$
    SlaveCnt_g     : positive := 1;     -- $$ constant=2 $$
    LsbFirst_g     : boolean  := false  -- $$ export=true $$
  );
  port(
    -- Control Signals
    Clk     : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    Rst     : in  std_logic;            -- $$ type=rst; clk=Clk $$

    -- Parallel Interface
    Start   : in  std_logic;
    Slave   : in  std_logic_vector(log2ceil(SlaveCnt_g) - 1 downto 0);
    Busy    : out std_logic;
    Done    : out std_logic;
    WrData  : in  std_logic_vector(TransWidth_g - 1 downto 0);
    RdData  : out std_logic_vector(TransWidth_g - 1 downto 0);
    -- SPI 
    SpiSck  : out std_logic;
    SpiMosi : out std_logic;
    SpiMiso : in  std_logic;
    SpiCs_n : out std_logic_vector(SlaveCnt_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_spi_master is

  -- *** Types ***
  type State_t is (Idle_s, SftComp_s, ClkInact_s, ClkAct_s, CsHigh_s);

  -- *** Constants ***
  constant ClkDivThres_c : natural := ClockDivider_g / 2 - 1;

  -- *** Two Process Method ***
  type two_process_r is record
    State     : State_t;
    StateLast : State_t;
    ShiftReg  : std_logic_vector(TransWidth_g - 1 downto 0);
    RdData    : std_logic_vector(TransWidth_g - 1 downto 0);
    SpiCs_n   : std_logic_vector(SlaveCnt_g - 1 downto 0);
    SpiSck    : std_logic;
    SpiMosi   : std_logic;
    ClkDivCnt : integer range 0 to ClkDivThres_c;
    BitCnt    : integer range 0 to TransWidth_g;
    CsHighCnt : integer range 0 to CsHighCycles_g - 1;
    Busy      : std_logic;
    Done      : std_logic;
    MosiNext  : std_logic;
  end record;
  signal r, r_next : two_process_r;

  -- *** Functions and procedures ***
  function GetClockLevel(ClkActive : boolean) return std_logic is
  begin
    if SpiCPOL_g = 0 then
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

  procedure ShiftReg(signal BeforeShift  : in std_logic_vector(TransWidth_g-1 downto 0);
                     variable AfterShift : out std_logic_vector(TransWidth_g-1 downto 0);
                     signal InputBit     : in std_logic;
                     variable OutputBit  : out std_logic) is
  begin
    if LsbFirst_g then
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
  assert floor(real(ClockDivider_g) / 2.0) = ceil(real(ClockDivider_g) / 2.0) report "###ERROR###: psi_common_spi_master - Ratio ClockDivider_g must be a multiple of two" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Proccess
  --------------------------------------------------------------------------
  p_comb : process(r, Start, WrData, SpiMiso, Slave)
    variable v : two_process_r;
  begin
    -- *** hold variables stable ***
    v := r;

    -- *** Default Values ***
    v.Done := '0';

    -- *** State Machine ***
    case r.State is
      when Idle_s =>
        -- Start of Transfer
        if Start = '1' then
          v.ShiftReg                             := WrData;
          v.SpiCs_n(to_integer(unsigned(Slave))) := '0';
          v.State                                := SftComp_s;
          v.Busy                                 := '1';
        end if;
        v.CsHighCnt := 0;
        v.ClkDivCnt := 0;
        v.BitCnt    := 0;

      when SftComp_s =>
        v.State := ClkInact_s;
        -- Compensate shift for CPHA 0
        if SpiCPHA_g = 0 then
          ShiftReg(r.ShiftReg, v.ShiftReg, SpiMiso, v.MosiNext);
        end if;

      when ClkInact_s =>
        v.SpiSck := GetClockLevel(false);
        -- Apply/Latch data if required
        if r.ClkDivCnt = 0 then
          if SpiCPHA_g = 0 then
            v.SpiMosi := r.MosiNext;
          else
            ShiftReg(r.ShiftReg, v.ShiftReg, SpiMiso, v.MosiNext);
          end if;
        end if;
        -- Clock period handling
        if r.ClkDivCnt = ClkDivThres_c then
          -- All bits done
          if r.BitCnt = TransWidth_g then
            v.State := CsHigh_s;
          -- Otherwise contintue
          else
            v.State := ClkAct_s;
          end if;
          v.ClkDivCnt := 0;
        else
          v.ClkDivCnt := r.ClkDivCnt + 1;
        end if;

      when ClkAct_s =>
        v.SpiSck := GetClockLevel(true);
        -- Apply data if required
        if r.ClkDivCnt = 0 then
          if SpiCPHA_g = 1 then
            v.SpiMosi := r.MosiNext;
          else
            ShiftReg(r.ShiftReg, v.ShiftReg, SpiMiso, v.MosiNext);
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
        v.SpiMosi := '0';
        v.SpiCs_n := (others => '1');
        if r.CsHighCnt = CsHighCycles_g - 1 then
          v.State  := Idle_s;
          v.Busy   := '0';
          v.Done   := '1';
          v.RdData := r.ShiftReg;
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
  Busy    <= r.Busy;
  Done    <= r.Done;
  RdData  <= r.RdData;
  SpiSck  <= r.SpiSck;
  SpiCs_n <= r.SpiCs_n;
  SpiMosi <= r.SpiMosi;

  --------------------------------------------------------------------------
  -- Sequential Proccess
  --------------------------------------------------------------------------
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.State   <= Idle_s;
        r.SpiCs_n <= (others => '1');
        r.SpiSck  <= GetClockLevel(false);
        r.Busy    <= '0';
        r.Done    <= '0';
        r.SpiMosi <= '0';
      end if;
    end if;
  end process;

end;

