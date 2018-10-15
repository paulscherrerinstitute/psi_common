------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic strobe divider. Every Nth strobe is sent to the output.
-- Note that the output has a delay of one clock cycle compared to the input.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=ctrl,countout $$
entity psi_common_strobe_divider is
	generic (
		length_g 	: natural 	:= 4;		-- ratio division bit width									$$ constant=4 $$
		rst_pol_g 	: std_logic := '0'		-- reset polarity
	);
	port (
		InClk	: in	std_logic;			-- clk in													$$ type=clk; freq=100e6; $$
		InRst	: in	std_logic;			-- synchornous reset										$$ type=rst; clk=clk_i; lowactive=true $$
		InVld	: in	std_logic;			-- strobe in (if not strobe an edge detection is done)
		InRatio	: in	std_logic_vector(length_g-1 downto 0);-- parameter ratio for division
		OutVld	: out	std_logic);			-- strobe output
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_strobe_divider is
	signal str_dff_s	: std_logic;
	signal str_s		: std_logic;
	signal str_i_s		: std_logic;
	signal counter_s	: integer range 0 to 2**length_g-1 := 0;
begin
	process(InClk)
	begin
		if rising_edge(InClk) then
			if InRst = rst_pol_g then
				counter_s		<= 0;
				str_dff_s	<= '0';
				str_s		<= '0';
				str_i_s		<= '0';
				OutVld		<= '0';
			else
				str_i_s   <= str_s;
				str_dff_s <= InVld;
				if str_dff_s <= '0' and InVld = '1' then
					if counter_s = unsigned(InRatio) - 1 then
						counter_s <= 0;
						str_s <= InVld;
					else
						counter_s <= counter_s + 1;
						str_s <= '0';
					end if;
				end if;
				if str_i_s = '0' and str_s = '1' then
					OutVld <= '1';
				else
					OutVld <= '0';
				end if;
			end if;
		end if;
	end process;
end architecture;