------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple data-width conversion. The output width
-- must be an integer multiple of the input width (Wo = n*Wi)

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim,check $$
entity psi_common_wconv_n2xn is
	generic (
		InWidth_g	: natural;		-- $$ constant=4 $$
		OutWidth_g	: natural		-- $$ constant=16 $$
	);
	port (
		-- Control Signals
		Clk			: in	std_logic;	-- $$ type=clk; freq=100e6 $$
		Rst			: in	std_logic;	-- $$ type=rst; clk=Clk $$
		
		-- Input
		InVld		: in 	std_logic;
		InRdy		: out 	std_logic;
		InData		: in	std_logic_vector(InWidth_g-1 downto 0);
		
		-- Output
		OutVld		: out	std_logic;
		OutRdy		: in	std_logic	:= '1';
		OutData		: out	std_logic_vector(OutWidth_g-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_wconv_n2xn is	

	-- *** Constants ***
	constant RatioReal_c	: real		:= real(OutWidth_g)/real(InWidth_g);
	constant RatioInt_c		: integer	:= integer(RatioReal_c);
	
	-- *** Two Process Method ***
	type two_process_r is record
		DataVld	: std_logic_vector(RatioInt_c-1 downto 0);
		Data	: std_logic_vector(OutWidth_g-1 downto 0);
		OutVld	: std_logic;
		OutData	: std_logic_vector(OutWidth_g-1 downto 0);
	end record;
	signal r, r_next : two_process_r;
	
begin
	--------------------------------------------------------------------------
	-- Assertions
	--------------------------------------------------------------------------
	assert floor(RatioReal_c) = ceil(RatioReal_c) report "psi_common_wconv_n2xn: Ratio Outwidth_g/InWidth_g must be an integer number" severity error;
	

	--------------------------------------------------------------------------
	-- Combinatorial Proccess
	--------------------------------------------------------------------------
	p_comb : process(r, InVld, InData, OutRdy)
		variable v : two_process_r;
		variable IsStuck_v : std_logic;
	begin
		-- *** hold variables stable ***
		v := r;
		
		-- Halt detection
		if (r.DataVld(r.DataVld'high) = '1') and (r.OutVld = '1')  then
			IsStuck_v := '1';
		else 
			IsStuck_v := '0';
		end if;
		
		-- Reset OutVld when transfer occured
		if (r.OutVld = '1') and (OutRdy = '1') then
			v.OutVld := '0';
		end if;
		
		-- Data Deserialization
		if r.DataVld(r.DataVld'high) = '1' and ((r.OutVld = '0') or (OutRdy = '1'))then
			v.OutVld 	:= '1';
			v.OutData 	:= r.Data;
			v.DataVld 	:= (others => '0');
		end if;
		if InVld = '1' and IsStuck_v = '0' then
			v.DataVld 	:= v.DataVld(v.DataVld'high-1 downto 0) & '1';
			v.Data 		:= InData & r.Data(r.Data'high downto InWidth_g);
		end if;	

		-- Outputs
		InRdy 	<= not IsStuck_v;
		OutVld 	<= r.OutVld;
		OutData <= r.OutData;
		
		-- *** assign signal ***
		r_next <= v;
	end process;
	
	--------------------------------------------------------------------------
	-- Sequential Proccess
	--------------------------------------------------------------------------
	p_seq : process(Clk)
	begin
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.DataVld <= (others => '0');
				r.OutVld <= '0';
			end if;			
		end if;
	end process;
	
	
end;





