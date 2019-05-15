------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

entity psi_common_simple_cc_<POSTFIX> is
	port
	(
		-- Clock Domain A
		ClkA			: in 	std_logic;
		RstInA			: in 	std_logic;
		RstOutA			: out	std_logic;
<DATA_IN>
		VldA			: in	std_logic;
		
		-- Clock Domain B
		ClkB			: in	std_logic;
		RstInB			: in	std_logic;
		RstOutB			: out	std_logic;
<DATA_OUT>
		VldB			: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_simple_cc_<POSTFIX> is 
	signal MergedA 	: std_logic_vector(<WIDTH>-1 downto 0);
	signal MergedB 	: std_logic_vector(<WIDTH>-1 downto 0);
begin

<DATA_MERGE>

	i_inst : entity work.psi_common_simple_cc
		generic map (
			DataWidth_g		=> <WIDTH>
		)
		port map (
			ClkA		=> ClkA,
			RstInA		=> RstInA,
			RstOutA		=> RstOutA,
			DataA		=> MergedA,
			VldA		=> VldA,
			ClkB		=> ClkB,
			RstInB		=> RstInB,
			RstOutB		=> RstOutB,
			DataB		=> MergedB,
			VldB		=> VldB
		);
		
<DATA_UNMERGE>

end rtl;
