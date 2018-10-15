------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic mux for Time Division Multiplxed data input
-- Latency is two clock cycles after the falling edge strobe input

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- @formatter:off
entity psi_common_tdm_mux is
	generic(rst_pol_g     : std_logic := '1'; 								-- reset polarity select
	        num_channel_g : natural   := 8; 								-- number of channel
	        data_length_g : natural   := 16); 								-- data vector width
	port(InClk     	: in  std_logic;     									-- clk in
	     InRst     	: in  std_logic;     									-- sync reset
	     InChSel  	: in  std_logic_vector(log2ceil(num_channel_g) - 1 downto 0); -- mux select
	     InTdmVld 	: in  std_logic;     									-- tdm strobe
	     InTdmDat 	: in  std_logic_vector(data_length_g - 1 downto 0); 	-- tdm data
	     OutTdmVld 	: out std_logic;     									-- strobe output
	     OutTdmDat 	: out std_logic_vector(data_length_g - 1 downto 0)); 	-- selected data out
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture RTL of psi_common_tdm_mux is
	signal tdm_dat_s     : std_logic_vector(data_length_g - 1 downto 0);
	signal tdm_str_s     : std_logic;
	signal count_s       : integer range 0 to num_channel_g - 1 := 0;
begin

	------------------------------------------------------------------------------
	-- TAG <=> info: decoder output process
	------------------------------------------------------------------------------
	proc_decod : process(InClk)
	begin
		if rising_edge(InClk) then
			if InRst = rst_pol_g then
				count_s       <= 0;
				OutTdmVld     <= '0';
				tdm_str_s	  <= '0';
			else

				--variable counter increment
				if InTdmVld = '1' then
					if count_s = num_channel_g - 1 then
						count_s <= 0;
					else
						count_s <= count_s + 1;
					end if;
				end if;

				-- output data after last channel was latched (i.e. if counter = 0)
				if count_s = 0 and tdm_str_s = '1' then
					OutTdmDat <= tdm_dat_s;
					OutTdmVld <= tdm_str_s;
					tdm_str_s <= '0';
				else
					OutTdmVld <= '0';
				end if;

				--decode tdm (override reset of tdm_str_s if required)
				if unsigned(InChSel) = count_s then
					if InTdmVld = '1' then
						tdm_dat_s <= InTdmDat;
						tdm_str_s <= InTdmVld;
					end if;
				end if;

				--output map
				--tdm_str_o <= tdm_str_s;
				--tdm_dat_o <= tdm_dat_s;
			end if;
		end if;
	end process;

end architecture;
