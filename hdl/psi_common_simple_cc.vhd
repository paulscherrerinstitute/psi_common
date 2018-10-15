------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic clock crossing that allows passing single samples of data
-- from one clock domain to another. It only works if sample rates are significantly
-- lower than the clock speed of both domains.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_simple_cc is
	generic (
		DataWidth_g		: positive		:= 16
	);
	port (
		-- Clock Domain A
		ClkA		: in 	std_logic;
		RstInA		: in 	std_logic;
		RstOutA		: out	std_logic;
		DataA		: in 	std_logic_vector(DataWidth_g-1 downto 0);
		VldA		: in	std_logic;
		
		-- Clock Domain B
		ClkB		: in	std_logic;
		RstInB		: in	std_logic;
		RstOutB		: out	std_logic;
		DataB		: out	std_logic_vector(DataWidth_g-1 downto 0);
		VldB		: out	std_logic
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_simple_cc is
	-- Domain A signals
	signal RstAI		: std_logic;
	signal DataLatchA	: std_logic_vector(DataWidth_g-1 downto 0);
	-- Domain B signals
	signal RstBI		: std_logic;
	signal VldBI		: std_logic;
	
begin

	i_pulse_cc : entity work.psi_common_pulse_cc
		generic map(
			NumPulses_g	=> 1
		)
		port map (
			ClkA		=> ClkA,
			RstInA		=> RstInA,
			RstOutA		=> RstAI,
			PulseA(0)	=> VldA,
			ClkB		=> ClkB,
			RstInB		=> RstInB,
			RstOutB		=> RstBI,
			PulseB(0)	=> VldBI
		);
	RstOutA	<= RstAI;
	RstOutB <= RstBI;
	

		
	-- Data transmit side (A)
	DataA_p : process(ClkA)
	begin
		if rising_edge(ClkA) then
			if RstAI = '1' then
				DataLatchA <= (others => '0');
			else
				if VldA = '1' then
					DataLatchA	<= DataA;
				end if;
			end if;
		end if;
	end process;
	
	-- Data receive side (B)
	DataB_p : process(ClkB)
	begin
		if rising_edge(ClkB) then
			if RstBI = '1' then
				DataB 	<= (others => '0');
				VldB 	<= '0';
			else
				VldB <= VldBI;
				if VldBI = '1' then
					DataB 	<= DataLatchA;
				end if;
			end if;	
		end if;
	end process;	
end;





