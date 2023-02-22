------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM with byte enables.

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
entity psi_common_tdp_ram_be is
  generic(
    depth_g    : positive := 1024;
    width_g    : positive := 32;
    behavior_g : string   := "RBW"      -- "RBW" = read-before-write, "WBR" = write-before-read
  );
  port(
    -- Port A
    a_clk_i  : in  std_logic                                        := '0'; -- $$ type=clk; freq=180e6 $$
    a_addr_i : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');
    a_be_i   : in  std_logic_vector(width_g / 8 - 1 downto 0)       := (others => '1');
    a_wr_i   : in  std_logic                                        := '0';
    a_dat_i  : in  std_logic_vector(width_g - 1 downto 0)           := (others => '0');
    a_dat_o : out std_logic_vector(width_g - 1 downto 0);
    -- Port B
    b_clk_i  : in  std_logic                                        := '0'; -- $$ type=clk; freq=25e6 $$
    b_addr_i : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');
    b_be_i   : in  std_logic_vector(width_g / 8 - 1 downto 0)       := (others => '1');
    b_wr_i   : in  std_logic                                        := '0';
    b_dat_i  : in  std_logic_vector(width_g - 1 downto 0)           := (others => '0');
    b_dat_o : out std_logic_vector(width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_tdp_ram_be is

  -- Constants
  constant BeCount_c : integer := width_g / 8;

  -- memory array
  type mem_t is array (depth_g - 1 downto 0) of std_logic_vector(width_g - 1 downto 0);
  shared variable mem : mem_t := (others => (others => '0'));

begin

  assert behavior_g = "RBW" or behavior_g = "WBR" report "psi_common_tdp_ram_be: behavior_g must be RBW or WBR" severity error;
  assert width_g mod 8 = 0 report "psi_common_tdp_ram_be: width_g must be a multiple of 8, otherwise byte-enables do not make sense" severity error;

  -- Port A
  porta_p : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if behavior_g = "RBW" then
        a_dat_o <= mem(to_integer(unsigned(a_addr_i)));
      end if;
      if a_wr_i = '1' then
        for byte in 0 to BeCount_c - 1 loop
          if a_be_i(byte) = '1' then
            mem(to_integer(unsigned(a_addr_i)))(byte * 8 + 7 downto byte * 8) := a_dat_i(byte * 8 + 7 downto byte * 8);
          end if;
        end loop;
      end if;
      if behavior_g = "WBR" then
        a_dat_o <= mem(to_integer(unsigned(a_addr_i)));
      end if;
    end if;
  end process;

  -- Port B
  portb_p : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if behavior_g = "RBW" then
        b_dat_o <= mem(to_integer(unsigned(b_addr_i)));
      end if;
      if b_wr_i = '1' then
        for byte in 0 to BeCount_c - 1 loop
          if b_be_i(byte) = '1' then
            mem(to_integer(unsigned(b_addr_i)))(byte * 8 + 7 downto byte * 8) := b_dat_i(byte * 8 + 7 downto byte * 8);
          end if;
        end loop;
      end if;
      if behavior_g = "WBR" then
        b_dat_o <= mem(to_integer(unsigned(b_addr_i)));
      end if;
    end if;
  end process;
end;

