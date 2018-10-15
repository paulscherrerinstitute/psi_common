------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements an efficient round-robin arbiter.

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
entity psi_common_arb_round_robin is
	generic (
		Size_g				: natural	:= 8		-- $$ constant=5 $$
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;		-- $$ type=clk; freq=100e6 $$
		Rst							: in 	std_logic;		-- $$ type=rst; clk=Clk $$
		
		-- Data Ports
		Request						: in 	std_logic_vector(Size_g-1 downto 0);
		Grant						: out	std_logic_vector(Size_g-1 downto 0);
		Grant_Rdy					: in 	std_logic;
		Grant_Vld					: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_arb_round_robin is 

	-- Two Process Method
	type two_process_r is record
		Mask	: std_logic_vector(Request'range);
	end record;	
	signal r, r_next : two_process_r;
	
	signal RequestMasked	: std_logic_vector(Request'range);
	signal GrantMasked   	: std_logic_vector(Grant'range);
	signal GrantUnmasked	: std_logic_vector(Grant'range);
begin
	-- Only generate code for non-zero sized arbiters to avoid illegal range delcarations
	g_non_zero : if Size_g > 0 generate
	
		--------------------------------------------------------------------------
		-- Combinatorial Process
		--------------------------------------------------------------------------
		p_comb : process(	r, Request, Grant_Rdy, GrantMasked, GrantUnmasked)	
			variable v : two_process_r;
			variable Grant_v	: std_logic_vector(Grant'range);
		begin	
			-- hold variables stable
			v := r;
			
			-- Round Robing Logic
			RequestMasked <= Request and r.Mask;
			
			-- Generate Grant
			if unsigned(GrantMasked) = 0 then
				Grant_v := GrantUnmasked;
			else
				Grant_v := GrantMasked;
			end if;		

			
			-- Update mask
			if (unsigned(Grant_v) /= 0) and (Grant_Rdy = '1') then
				v.Mask := '0' & PpcOr(Grant_v(Grant_v'high downto 1));
			end if;

			-- *** Outputs ***
			if unsigned(Grant_v) /= 0 then
				Grant_Vld <= '1';
			else
				Grant_Vld <= '0';
			end if;		
			Grant <= Grant_v;
			
			-- Apply to record
			r_next <= v;
			
		end process;
		
		--------------------------------------------------------------------------
		-- Sequential Process
		--------------------------------------------------------------------------	
		p_seq : process(Clk)
		begin	
			if rising_edge(Clk) then
				r <= r_next;
				if Rst = '1' then
					r.Mask	<= (others => '0');
				end if;
			end if;
		end process;
		
		--------------------------------------------------------------------------
		-- Component Instantiations
		--------------------------------------------------------------------------		
		i_prio_masked : entity work.psi_common_arb_priority
			generic map (
				Size_g				=> Size_g,
				OutputRegister_g	=> false
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				Request		=> RequestMasked,
				Grant		=> GrantMasked
			);
			
		i_prio_unmasked : entity work.psi_common_arb_priority
			generic map (
				Size_g				=> Size_g,
				OutputRegister_g	=> false
			)
			port map (
				Clk			=> Clk,
				Rst			=> Rst,
				Request		=> Request,
				Grant		=> GrantUnmasked
			);		
	end generate;
 
end rtl;
