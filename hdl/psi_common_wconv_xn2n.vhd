------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple data-width conversion. The input width
-- must be an integer multiple of the output width (Wi = n*Wo)

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
-- $$ processes=stim,check $$
entity psi_common_wconv_xn2n is
  generic(
    InWidth_g  : natural;               -- $$ constant=16 $$
    OutWidth_g : natural                -- $$ constant=4 $$
  );
  port(
    -- Control Signals
    Clk     : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    Rst     : in  std_logic;            -- $$ type=rst; clk=Clk $$

    -- Input
    InVld   : in  std_logic;
    InRdy   : out std_logic;
    InData  : in  std_logic_vector(InWidth_g - 1 downto 0);
    InLast  : in  std_logic                                             := '0';
    InWe    : in  std_logic_vector(InWidth_g / OutWidth_g - 1 downto 0) := (others => '1');
    -- Output
    OutVld  : out std_logic;
    OutRdy  : in  std_logic                                             := '1';
    OutData : out std_logic_vector(OutWidth_g - 1 downto 0);
    OutLast : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_wconv_xn2n is

  -- *** Constants ***
  constant RatioReal_c : real    := real(InWidth_g) / real(OutWidth_g);
  constant RatioInt_c  : integer := integer(RatioReal_c);

  -- *** Two Process Method ***
  type two_process_r is record
    Data     : std_logic_vector(InWidth_g - 1 downto 0);
    DataVld  : std_logic_vector(RatioInt_c - 1 downto 0);
    DataLast : std_logic_vector(RatioInt_c - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

begin
  --------------------------------------------------------------------------
  -- Assertions
  --------------------------------------------------------------------------
  assert floor(RatioReal_c) = ceil(RatioReal_c) report "psi_common_wconv_xn2n: Ratio Outwidth_g/InWidth_g must be an integer number" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Proccess
  --------------------------------------------------------------------------
  p_comb : process(r, InVld, InData, OutRdy, InWe, InLast)
    variable v         : two_process_r;
    variable IsReady_v : std_logic;
  begin
    -- *** hold variables stable ***
    v := r;

    -- Halt detection
    IsReady_v := '1';
    if unsigned(r.DataVld(r.DataVld'high downto 1)) /= 0 then
      IsReady_v := '0';
    elsif r.DataVld(0) = '1' and OutRdy = '0' then
      IsReady_v := '0';
    end if;

    -- Get new data
    if IsReady_v = '1' and InVld = '1' then
      v.Data                     := InData;
      v.DataVld                  := InWe;
      -- Assert last to the correct data-word
      for i in 0 to RatioInt_c - 2 loop
        v.DataLast(i) := InWe(i) and not InWe(i + 1) and InLast;
      end loop;
      v.DataLast(RatioInt_c - 1) := InWe(RatioInt_c - 1) and InLast;
    elsif (OutRdy = '1') and (unsigned(r.DataVld) /= 0) then
      v.Data     := ZerosVector(OutWidth_g) & r.Data(r.Data'left downto OutWidth_g);
      v.DataVld  := '0' & r.DataVld(r.DataVld'left downto 1);
      v.DataLast := '0' & r.DataLast(r.DataLast'left downto 1);
    end if;

    -- Outputs
    OutData <= r.Data(OutWidth_g - 1 downto 0);
    InRdy   <= IsReady_v;
    OutVld  <= r.DataVld(0);
    OutLast <= r.DataLast(0);

    -- *** assign signal ***
    r_next <= v;
  end process;

  --------------------------------------------------------------------------
  -- Sequential Proccess
  --------------------------------------------------------------------------
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.DataVld <= (others => '0');
      end if;
    end if;
  end process;

end;

