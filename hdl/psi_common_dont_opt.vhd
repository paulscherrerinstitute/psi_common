------------------------------------------------------------------------------
--  Copyright (c) 2020 by Enclustra GmbH, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity allows preventing synthesis tools from optimizing away any
-- number of input/output signals. To do so, only four I/O pins are required.
-- This functionality can be used to to synthesis tests runs for design-parts
-- that have more I/Os available than any real chip.

--
--
--       4 Pins       CLK
--          |          |
--          |          |
--          |         _|_
--          |         \./
--          |          V                    +-----------+
--+-------------------------+               |           |
--|                         |               |           |
--| psi_common_dont_opt     |-------------- |           |
--|                         |-------------- |           |
--|                         |-------------- |    DUT    |
--|                         |-------------- |           |
--+-------------------------+               |           |
--                             N-inputs     |           |
--                             N-outputs    +-----------+
--
--
--

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_dont_opt is
  generic(
    FromDutWidth_g : positive := 8;
    ToDutWidth_g   : positive := 16
  );
  port(
    Clk     : in    std_logic;          -- && type=clk; freq=100e6 &&
    IoPins  : inout std_logic_vector(3 downto 0);
    ToDut   : out   std_logic_vector(ToDutWidth_g - 1 downto 0);
    FromDut : in    std_logic_vector(FromDutWidth_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_dont_opt is

  type two_process_t is record
    ToDutShiftReg   : std_logic_vector(ToDut'range);
    ToDutLatchReg   : std_logic_vector(ToDut'range);
    FromDutShiftReg : std_logic_vector(FromDut'range);
  end record;

  signal r, r_next : two_process_t;

begin

  p_comb : process(IoPins, FromDut, r)
    variable v : two_process_t;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Implementation ***
    if IoPins(0) = '1' then
      v.ToDutLatchReg := r.ToDutShiftReg;
    end if;
    v.ToDutShiftReg := r.ToDutShiftReg(r.ToDutShiftReg'high - 1 downto 0) & IoPins(1);

    if IoPins(2) = '1' then
      v.FromDutShiftReg := FromDut;
    else
      v.FromDutShiftReg := r.FromDutShiftReg(r.FromDutShiftReg'high - 1 downto 0) & '0';
    end if;

    -- *** Assign signal ***
    r_next <= v;
  end process;

  IoPins(0) <= 'Z';
  IoPins(1) <= 'Z';
  IoPins(2) <= 'Z';
  IoPins(3) <= r.FromDutShiftReg(r.FromDutShiftReg'high);

  ToDut <= r.ToDutLatchReg;

  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
    end if;
  end process;

end;

