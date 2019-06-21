------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
library work;
	use work.psi_tb_txt_util.all;
	

entity psi_common_status_cc_tb is
	generic (
		ClockRatioN_g		: integer := 3;
		ClockRatioD_g		: integer := 2
	);
end entity psi_common_status_cc_tb;

architecture sim of psi_common_status_cc_tb is

	-------------------------------------------------------------------------
	-- Constants
	-------------------------------------------------------------------------	
	constant ClockRatio_c		: real			:= real(ClockRatioN_g)/real(ClockRatioD_g);
	constant DataWidth_c		: integer		:= 8;

	-------------------------------------------------------------------------
	-- TB Defnitions
	-------------------------------------------------------------------------
	constant 	ClockAFrequency_c	: real 		:= 100.0e6;
	constant	ClockAPeriod_c		: time		:= (1 sec)/ClockAFrequency_c;
	constant 	ClockBFrequency_c	: real 		:= ClockAFrequency_c*ClockRatio_c;
	constant	ClockBPeriod_c		: time		:= (1 sec)/ClockBFrequency_c;	
	signal 		TbRunning			: boolean 	:= True;
	constant 	SlowerClockPeriod_c	: time		:= (1 sec)/realmin(ClockAFrequency_c, ClockBFrequency_c);

	

	-------------------------------------------------------------------------
	-- Interface Signals
	-------------------------------------------------------------------------
	signal ClkA			: std_logic		:= '0';
	signal RstInA		: std_logic		:= '1';
	signal RstOutA		: std_logic;
	signal DataA		: std_logic_vector(DataWidth_c-1 downto 0)		:= X"00";
	signal ClkB			: std_logic		:= '0';
	signal RstInB		: std_logic		:= '1';
	signal RstOutB		: std_logic;
	signal DataB		: std_logic_vector(DataWidth_c-1 downto 0);
					

begin

	-------------------------------------------------------------------------
	-- DUT
	-------------------------------------------------------------------------
	i_dut : entity work.psi_common_status_cc
		generic map (
			DataWidth_g		=> DataWidth_c
		)
		port map (
			-- Clock Domain A
			ClkA		=> ClkA,
			RstInA		=> RstInA,
			RstOutA		=> RstOutA,
			DataA		=> DataA,
			
			-- Clock Domain B
			ClkB		=> ClkB,
			RstInB		=> RstInB,
			RstOutB		=> RstOutB,
			DataB		=> DataB
		);
	
	-------------------------------------------------------------------------
	-- Clock
	-------------------------------------------------------------------------
	p_aclk : process
	begin
		ClkA <= '0';
		while TbRunning loop
			wait for 0.5*ClockAPeriod_c;
			ClkA <= '1';
			wait for 0.5*ClockAPeriod_c;
			ClkA <= '0';
		end loop;
		wait;
	end process;
	
	p_bclk : process
	begin
		ClkB <= '0';
		while TbRunning loop
			wait for 0.5*ClockBPeriod_c;
			ClkB <= '1';
			wait for 0.5*ClockBPeriod_c;
			ClkB <= '0';
		end loop;
		wait;
	end process;	
	
	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
	begin
		-- *** Reset Tests ***
		print("Reset Tests");
		
		-- Reset
		RstInA <= '1';
		RstInB <= '1';
		wait for 1 us;
		
		-- Check if both sides are in reset
		assert RstOutA = '1' report "###ERROR###: ResetOutA not asserted" severity error;
		assert RstOutB = '1' report "###ERROR###: ResetOutB not asserted" severity error;
	
		-- Remove reset
		wait until rising_edge(ClkA);
		RstInA <= '0';
		wait until rising_edge(ClkB);
		RstInB <= '0';
		wait for 1 us;
		
		-- Check if both sides exited reset
		assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted" severity error;
		assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted" severity error;
		
		
		-- Check if RstA is propagated to both sides
		wait until rising_edge(ClkA);
		RstInA <= '1';
		wait until rising_edge(ClkA);
		RstInA <= '0';
		wait for 1 us;
		assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted after reset A" severity error;
		assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted after reset A" severity error;
		assert RstOutA'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset A" severity error;
		assert RstOutB'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset A" severity error;		
		
		-- Check if RstB is propagated to both sides
		wait until rising_edge(ClkB);
		RstInB <= '1';
		wait until rising_edge(ClkB);
		RstInB <= '0';
		wait for 1 us;
		assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted after reset B" severity error;
		assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted after reset B" severity error;
		assert RstOutA'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset B" severity error;
		assert RstOutB'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset B" severity error;		

		-- *** Data Tests ***
		print("Data Transfer Tests");
		-- data transfer after resetting both
		RstInA <= '1';
		RstInB <= '1';
		wait for 2 * SlowerClockPeriod_c;
		RstInA <= '0';
		RstInB <= '0';		
		wait for 10 * SlowerClockPeriod_c;
		DataA <= X"AB";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"AB" report "###ERROR###: Data not transferred 1" severity error;
		DataA <= X"CD";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"CD" report "###ERROR###: Data not transferred 2" severity error;
		
		-- data transfer with A longer in reset
		RstInA <= '1';
		RstInB <= '1';
		wait for 2 * SlowerClockPeriod_c;
		RstInB <= '0';
		wait for 100 * SlowerClockPeriod_c;
		RstInA <= '0';		
		wait for 10 * SlowerClockPeriod_c;
		DataA <= X"12";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"12" report "###ERROR###: Data not transferred 3" severity error;
		DataA <= X"34";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"34" report "###ERROR###: Data not transferred 4" severity error;
		
		-- data transfer with B longer in reset
		RstInA <= '1';
		RstInB <= '1';
		wait for 2 * SlowerClockPeriod_c;
		RstInA <= '0';
		wait for 100 * SlowerClockPeriod_c;
		RstInB <= '0';		
		wait for 10 * SlowerClockPeriod_c;
		DataA <= X"56";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"56" report "###ERROR###: Data not transferred 5" severity error;
		DataA <= X"78";
		wait for 12 * SlowerClockPeriod_c;
		assert DataB = X"78" report "###ERROR###: Data not transferred 6" severity error;				
		
		-- TB done
		TbRunning <= false;
		wait;
	end process;


end sim;
