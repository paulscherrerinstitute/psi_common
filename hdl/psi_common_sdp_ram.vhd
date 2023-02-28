------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent simple dual port RAM.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

entity psi_common_sdp_ram is
  generic(depth_g        : positive := 1024;                                                         -- memory depthg, samples
          width_g        : positive := 16;                                                           -- data length
          is_async_g     : boolean  := false;                                                        -- True = Separate Rd clock is used (clk is WrClk in this case)
          ram_style_g    : string   := "auto";                                                       -- "auto", "distributed" or "block"
          ram_behavior_g : string   := "RBW");                                                       -- "RBW" = read-before-write, "WBR" = write-before-read
  port(   wr_clk_i       : in  std_logic                                        := '0';              -- write clock
          wr_addr_i      : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');  -- write address
          wr_i           : in  std_logic                                        := '0';              -- write enable
          wr_dat_i       : in  std_logic_vector(width_g - 1 downto 0)           := (others => '0');  -- write data input
          rd_clk_i       : in  std_logic                                        := '0';              -- read clock
          rd_addr_i      : in  std_logic_vector(log2ceil(depth_g) - 1 downto 0) := (others => '0');  -- read address
          rd_i           : in  std_logic                                        := '1';              -- read enable
          rd_dat_o       : out std_logic_vector(width_g - 1 downto 0));                              -- read data output
end entity;

architecture rtl of psi_common_sdp_ram is

  -- memory array
  type mem_t is array (depth_g - 1 downto 0) of std_logic_vector(width_g - 1 downto 0);
  shared variable mem : mem_t := (others => (others => '0'));
  attribute ram_style : string;
  attribute ram_style of mem : variable is ram_style_g;

begin
  -- Synchronous Implementation
  g_sync : if not is_async_g generate
    ram_p : process(wr_clk_i)
    begin
      if rising_edge(wr_clk_i) then
        if ram_behavior_g = "RBW" then
          if rd_i = '1' then
            rd_dat_o <= mem(to_integer(unsigned(rd_addr_i)));
          end if;
        end if;
        if wr_i = '1' then
          mem(to_integer(unsigned(wr_addr_i))) := wr_dat_i;
        end if;
        if ram_behavior_g = "WBR" then
          if rd_i = '1' then
            rd_dat_o <= mem(to_integer(unsigned(rd_addr_i)));
          end if;
        end if;
      end if;
    end process;
  end generate;

  -- Asynchronous implementation
  g_async : if is_async_g generate

    write_p : process(wr_clk_i)
    begin
      if rising_edge(wr_clk_i) then
        if wr_i = '1' then
          mem(to_integer(unsigned(wr_addr_i))) := wr_dat_i;
        end if;
      end if;
    end process;

    read_p : process(rd_clk_i)
    begin
      if rising_edge(rd_clk_i) then
        if rd_i = '1' then
          rd_dat_o <= mem(to_integer(unsigned(rd_addr_i)));
        end if;
      end if;
    end process;

  end generate;

end architecture;

