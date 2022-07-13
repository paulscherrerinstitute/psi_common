----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Description: 
----------------------------------------------------------------------------------
-- A generic pseudo random binary sequence based on a linear-feedback shifter
-- register.
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.psi_common_prbs_pkg.all;

----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------

entity psi_common_prbs is
	generic( width_g : natural range 2 to 32 := 8;				-- I/O data width
			 rst_pol_g: std_logic := '1'						-- Reset polarity
	);

	port( rst_i : in 	std_logic;								-- Input reset
		  clk_i	: in 	std_logic;								-- Input clock
		  str_i : in 	std_logic;								-- Input strobe
		  seed_i: in 	std_logic_vector((width_g-1) downto 0); -- Input seed
		  data_o: out 	std_logic_vector((width_g-1) downto 0)	-- Output data
	);
end psi_common_prbs;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture behav of psi_common_prbs is

	-- Constants
	constant mask_c		:	std_logic_vector((width_g-1) downto 0) := poly_c(width_g)((width_g-1) downto 0);

	-- Signals
	signal d0_s 		:	std_logic := '0';
	signal q_s 			:	std_logic_vector((width_g-1) downto 0) := (others => '0');
	signal q_masked_s 	:	std_logic_vector((width_g-1) downto 0) := (others => '0');
begin

	data_o <= q_s;

	q_masked_s <= mask_c and q_s;
	d0_s <= xor q_masked_s;					-- 2008 syntax

	p_lfsr : process(clk_i)
	begin
		if(rising_edge(clk_i)) then
			if(rst_i = rst_pol_g) then
				q_s <= seed_i;
			elsif(str_i = '1') then		
				q_s <= q_s((width_g-2) downto 0) & d0_s;
			end if;	
		end if;
	end process;

end behav;
