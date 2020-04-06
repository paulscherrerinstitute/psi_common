------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a delay element. It is either emplemented in BRAM or SRL. The output
-- is always a fabric register for improved timing.
-- 
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_delay is
  generic(
    Width_g         : positive := 16;
    Delay_g         : positive := 10;
    Resource_g      : string   := "AUTO"; -- AUTO, SRL or BRAM
    BramThreshold_g : positive := 128;  -- Number of delay taps to start using BRAM from (if Resource_g = AUTO)
    RstState_g      : boolean  := True; -- True = '0' is outputted after reset, '1' after reset the existing state is outputted
    RamBehavior_g   : string   := "RBW" -- "RBW" = read-before-write, "WBR" = write-before-read
  );
  port(
    -- Control Ports
    Clk     : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    Rst     : in  std_logic;
    -- Data
    InData  : in  std_logic_vector(Width_g - 1 downto 0);
    InVld   : in  std_logic;
    OutData : out std_logic_vector((Width_g - 1) downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_delay is

  signal MemOut      : std_logic_vector(Width_g - 1 downto 0);
  constant MemTaps_c : natural := Delay_g - 1;

  signal RstStateCnt : integer range 0 to Delay_g - 1;

begin

  -- *** Assertions ***
  assert Resource_g = "AUTO" or Resource_g = "SRL" or Resource_g = "BRAM" report "###ERROR###: psi_common_delay: Unknown Resource_g - " & Resource_g severity error;
  assert Resource_g /= "BRAM" or Delay_g >= 3 report "###ERROR###: psi_common_delay: Delay_g >= 3 required for Resource_g=BRAM" severity error;
  assert BramThreshold_g > 3 report "###ERROR###: psi_common_delay: BramThreshold_g must be > 3" severity error;

  -- *** SRL ***
  g_srl : if (Delay_g > 1) and ((Resource_g = "SRL") or ((Resource_g = "AUTO") and (Delay_g < BramThreshold_g))) generate
    type Srl_t is array (0 to MemTaps_c - 1) of std_logic_vector(Width_g - 1 downto 0);
    signal SrlSig : Srl_t := (others => (others => '0'));
  begin
    p_srl : process(Clk)
    begin
      if rising_edge(Clk) then
        if InVld = '1' then
          SrlSig(0)                <= InData;
          SrlSig(1 to SrlSig'high) <= SrlSig(0 to SrlSig'high - 1);
        end if;
      end if;
    end process;
    MemOut <= SrlSig(SrlSig'high);
  end generate;

  -- *** BRAM ***
  g_bram : if (Delay_g > 1) and ((Resource_g = "BRAM") or ((Resource_g = "AUTO") and (Delay_g >= BramThreshold_g))) generate
    signal RdAddr, WrAddr : std_logic_vector(log2ceil(MemTaps_c) - 1 downto 0) := (others => '0');
  begin
    -- address control process
    p_bram : process(Clk)
    begin
      if rising_edge(Clk) then
        if Rst = '1' then
          WrAddr <= std_logic_vector(to_unsigned(MemTaps_c - 1, WrAddr'length));
          RdAddr <= (others => '0');
        elsif InVld = '1' then
          -- write address
          if unsigned(WrAddr) = MemTaps_c - 1 then
            WrAddr <= (others => '0');
          else
            WrAddr <= std_logic_vector(unsigned(WrAddr) + 1);
          end if;
          -- read address
          if unsigned(RdAddr) = MemTaps_c - 1 then
            RdAddr <= (others => '0');
          else
            RdAddr <= std_logic_vector(unsigned(RdAddr) + 1);
          end if;
        end if;
      end if;
    end process;

    -- memory instantiation
    i_bram : entity work.psi_common_sdp_ram
      generic map(
        Depth_g    => MemTaps_c,
        Width_g    => Width_g,
        Behavior_g => RamBehavior_g
      )
      port map(
        Clk    => Clk,
        WrAddr => WrAddr,
        Wr     => InVld,
        WrData => InData,
        RdAddr => RdAddr,
        Rd     => InVld,
        RdData => MemOut
      );
  end generate;

  -- *** Single Stage ***
  g_single : if Delay_g = 1 generate
    MemOut <= InData;
  end generate;

  -- *** Output register ***
  p_outreg : process(Clk)
  begin
    if rising_edge(Clk) then
      if Rst = '1' then
        OutData     <= (others => '0');
        RstStateCnt <= 0;
      elsif InVld = '1' then
        if RstState_g = false or RstStateCnt = Delay_g - 1 then
          OutData <= MemOut;
        else
          OutData     <= (others => '0');
          RstStateCnt <= RstStateCnt + 1;
        end if;
      end if;
    end if;
  end process;

end;

