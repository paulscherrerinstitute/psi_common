----------------------------------------------------------------------------------
-- Original VHDL source code Copyright 1995-2021 DOULOS
----------------------------------------------------------------------------------
-- Copyright (c) 2023 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso, Radoslaw Rybaniec

-- Added seed input
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity maximal_length_lfsr is
  port(
    clock    : in  std_logic;
    reset    : in  std_logic;
    seed     : in  std_logic_vector(9 downto 0);
    str      : in  std_logic;
    data_out : out std_logic_vector(9 downto 0)
  );
end maximal_length_lfsr;

architecture modular of maximal_length_lfsr is

  signal lfsr_reg : std_logic_vector(9 downto 0);

begin

  process(clock)
    variable lfsr_tap : std_logic;
  begin
    if RISING_EDGE(clock) then
      if reset = '1' then
        lfsr_reg <= seed;
      else
        if str = '1' then
          lfsr_tap := lfsr_reg(6) xor lfsr_reg(9);
          lfsr_reg <= lfsr_reg(8 downto 0) & lfsr_tap;
        end if;
      end if;
    end if;
  end process;

  data_out <= lfsr_reg;

end modular;
