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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psi_common_dont_opt is
  generic(
    from_dut_width_g : positive := 8;
    to_dut_width_g   : positive := 16
  );
  port(
    clk_i  : in    std_logic;           -- && type=clk; freq=100e6 &&
    pin_io : inout std_logic_vector(3 downto 0);
    dat_o  : out   std_logic_vector(to_dut_width_g - 1 downto 0);
    dat_i  : in    std_logic_vector(from_dut_width_g - 1 downto 0)
  );
end entity;

architecture rtl of psi_common_dont_opt is

  type two_process_t is record
    ToDutShiftReg   : std_logic_vector(dat_o'range);
    ToDutLatchReg   : std_logic_vector(dat_o'range);
    FromDutShiftReg : std_logic_vector(dat_i'range);
  end record;

  signal r, r_next : two_process_t;

begin

  p_comb : process(pin_io, dat_i, r)
    variable v : two_process_t;
  begin
    -- *** Hold variables stable ***
    v := r;

    -- *** Implementation ***
    if pin_io(0) = '1' then
      v.ToDutLatchReg := r.ToDutShiftReg;
    end if;
    v.ToDutShiftReg := r.ToDutShiftReg(r.ToDutShiftReg'high - 1 downto 0) & pin_io(1);

    if pin_io(2) = '1' then
      v.FromDutShiftReg := dat_i;
    else
      v.FromDutShiftReg := r.FromDutShiftReg(r.FromDutShiftReg'high - 1 downto 0) & '0';
    end if;

    -- *** Assign signal ***
    r_next <= v;
  end process;

  pin_io(0) <= 'Z';
  pin_io(1) <= 'Z';
  pin_io(2) <= 'Z';
  pin_io(3) <= r.FromDutShiftReg(r.FromDutShiftReg'high);

  dat_o <= r.ToDutLatchReg;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
    end if;
  end process;

end architecture;