------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements an efficient priority arbiter. The highest index of
-- the input has priority.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ processes=stimuli $$
entity psi_common_arb_priority is
	generic (
		Size_g				: natural	:= 8;		-- $$ constant=5 $$
		OutputRegister_g	: boolean	:= true		-- $$ constant=true &&
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;		-- $$ type=clk; freq=100e6 $$
		Rst							: in 	std_logic;		-- $$ type=rst; clk=Clk $$
		
		-- Data Ports
		Request						: in 	std_logic_vector(Size_g-1 downto 0);
		Grant						: out	std_logic_vector(Size_g-1 downto 0)	
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_arb_priority is 

	signal Grant_I	: std_logic_vector(Grant'range);

begin
	
	-- Only generate code for non-zero sized arbiters to avoid illegal range delcarations
	g_non_zero : if Size_g > 0 generate

		--------------------------------------------------------------------------
		-- Combinatorial Process
		--------------------------------------------------------------------------
		p_comb : process(Request)	
			variable OredRequest_v	: std_logic_vector(Request'range);
		begin			
			-- Or request vector
			OredRequest_v := PpcOr(Request);	
			
			-- Calculate Grant with Edge Detection
			Grant_I <= OredRequest_v and not ('0' & OredRequest_v(OredRequest_v'high downto 1));
		end process;


		--------------------------------------------------------------------------
		-- Output Handling
		--------------------------------------------------------------------------	
		-- Registered
		g_reg : if OutputRegister_g generate
			p_outreg : process(Clk)
			begin
				if rising_edge(Clk) then
					if Rst = '1' then
						Grant <= (others => '0');
					else
						Grant <= Grant_I;
					end if;
				end if;
			end process;
		end generate;
		
		g_nreg : if not OutputRegister_g generate
			Grant <= Grant_I;
		end generate;
	end generate;
 
end rtl;
