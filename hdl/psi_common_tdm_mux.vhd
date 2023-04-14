------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic mux for Time Division Multiplxed data input
-- Latency is two clock cycles after the falling edge strobe input

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

-- @formatter:off
entity psi_common_tdm_mux is
	generic(rst_pol_g   : std_logic := '1';                                      -- reset polarity select
	        ch_nb_g     : natural   := 8;                                        -- number of channel
	        width_g     : natural   := 16);                                      -- data vector width
	port(   clk_i     	: in  std_logic;                                         -- clk in
	        rst_i     	: in  std_logic;                                         -- sync reset
	        ch_sel_i  	: in  std_logic_vector(log2ceil(ch_nb_g) - 1 downto 0);  -- mux select
	        tdm_vld_i 	: in  std_logic;                                         -- tdm strobe
	        tdm_dat_i 	: in  std_logic_vector(width_g - 1 downto 0);            -- tdm data
	        tdm_vld_o 	: out std_logic;                                         -- strobe output
	        tdm_dat_o 	: out std_logic_vector(width_g - 1 downto 0));           -- selected data out
end entity;
-- @formatter:on

architecture RTL of psi_common_tdm_mux is
  signal tdm_dat_s : std_logic_vector(width_g - 1 downto 0);
  signal tdm_str_s : std_logic;
  signal count_s   : integer range 0 to ch_nb_g - 1 := 0;
begin

  -- TAG <=> info: decoder output process

  proc_decod : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        count_s   <= 0;
        tdm_vld_o <= '0';
        tdm_str_s <= '0';
      else

        --variable counter increment
        if tdm_vld_i = '1' then
          if count_s = ch_nb_g - 1 then
            count_s <= 0;
          else
            count_s <= count_s + 1;
          end if;
        end if;

        -- output data after last channel was latched (i.e. if counter = 0)
        if count_s = 0 and tdm_str_s = '1' then
          tdm_dat_o <= tdm_dat_s;
          tdm_vld_o <= tdm_str_s;
          tdm_str_s <= '0';
        else
          tdm_vld_o <= '0';
        end if;

        --decode tdm (override reset of tdm_str_s if required)
        if unsigned(ch_sel_i) = count_s then
          if tdm_vld_i = '1' then
            tdm_dat_s <= tdm_dat_i;
            tdm_str_s <= tdm_vld_i;
          end if;
        end if;

      end if;
    end if;
  end process;

end architecture;
