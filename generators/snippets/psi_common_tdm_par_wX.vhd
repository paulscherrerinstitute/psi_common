------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- Generated helper package to easily use psi_common_tdm_par

------------------------------------------------------------------------------
-- Package Declaration
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
package psi_common_tdm_par_w<WIDTH>_pkg is

	type psi_common_tdm_par_w<WIDTH>_a is array (natural range <>) of std_logic_vector(<WIDTH>-1 downto 0);

end package;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

	use work.psi_common_tdm_par_w<WIDTH>_pkg.all;

entity psi_common_tdm_par_w<WIDTH> is
	generic (
		ChannelCount_g		: natural	:= 8
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;	
		Rst							: in 	std_logic;	
		
		-- Data Ports
		Tdm							: in 	std_logic_vector(<WIDTH>-1 downto 0);
		TdmVld						: in	std_logic;
		Parallel					: out 	psi_common_tdm_par_w<WIDTH>_a(0 to ChannelCount_g-1);
		ParallelVld					: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par_w<WIDTH> is 
	signal ParallelMerged : std_logic_vector(ChannelCount_g*<WIDTH>-1 downto 0);

begin

	i_inst : entity work.psi_common_tdm_par
		generic map (
			ChannelCount_g		=> ChannelCount_g,
			ChannelWidth_g		=> <WIDTH>
		)
		port map (
			Clk					=> Clk,
			Rst					=> Rst,
			Tdm					=> Tdm,
			TdmVld				=> TdmVld,
			Parallel			=> ParallelMerged,
			ParallelVld			=> ParallelVld
		);
		
	g_merge : for i in 0 to ChannelCount_g-1 generate
		Parallel(i) <= ParallelMerged(<WIDTH>*(i+1)-1 downto <WIDTH>*i);
	end generate;		
 
end rtl;
