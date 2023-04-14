------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM that has
-- byte enables.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
-- @formatter:off
entity psi_common_sp_ram_be is
  generic(depth_g        : positive := 1024;                                                        -- memory depth in sample
          width_g        : positive := 32;                                                          -- data width in bit
          ram_behavior_g : string   := "RBW");                                                      -- "RBW" = read-before-write, "WBR" = write-before-read
  port(   clk_i          : in  std_logic                                        := '0';             -- system clock
          addr_i         : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0'); -- address 
          be_i           : in  std_logic_vector(width_g / 8 - 1 downto 0)       := (others => '1'); -- byte enable
          wr_i           : in  std_logic                                        := '0';             -- write enable
          dat_i          : in  std_logic_vector(width_g - 1 downto 0)           := (others => '0'); -- data input
          dat_o          : out std_logic_vector(width_g - 1 downto 0));                             -- data output
end entity;
-- @formatter:on

architecture rtl of psi_common_sp_ram_be is

  -- Constants
  constant BeCount_c : integer := width_g / 8;

  -- memory array
  type mem_t is array (depth_g - 1 downto 0) of std_logic_vector(width_g - 1 downto 0);
  shared variable mem : mem_t := (others => (others => '0'));

begin

  assert ram_behavior_g = "RBW" or ram_behavior_g = "WBR" report "psi_common_sp_ram_be: ram_behavior_g must be_i RBW or WBR" severity error;
  assert width_g mod 8 = 0 report "psi_common_sp_ram_be: width_g must be_i a multiple of 8, otherwise byte-enables do not make sense" severity error;

  porta_p : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if ram_behavior_g = "RBW" then
        dat_o <= mem(to_integer(unsigned(addr_i)));
      end if;
      if wr_i = '1' then
        for byte in 0 to BeCount_c - 1 loop
          if be_i(byte) = '1' then
            mem(to_integer(unsigned(addr_i)))(byte * 8 + 7 downto byte * 8) := dat_i(byte * 8 + 7 downto byte * 8);
          end if;
        end loop;
      end if;
      if ram_behavior_g = "WBR" then
        dat_o <= mem(to_integer(unsigned(addr_i)));
      end if;
    end if;
  end process;

end architecture;

