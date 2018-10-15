------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic clock crossing that allows passing pulses from one clock
-- domain to another. The pulse frequency must be significantly lower than then
-- slower clock speed.
-- Note that this entity only ensures that all pulses are transferred but not
-- that pulses arriving in the same clock cycle are transmitted in the same
-- clock cycle.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_pulse_cc is
	generic (
		NumPulses_g		: positive		:= 1
	);
	port (
		-- Clock Domain A
		ClkA		: in 	std_logic;
		RstInA		: in 	std_logic;
		RstOutA		: out	std_logic;
		PulseA		: in 	std_logic_vector(NumPulses_g-1 downto 0);
		
		-- Clock Domain B
		ClkB		: in	std_logic;
		RstInB		: in	std_logic;
		RstOutB		: out	std_logic;
		PulseB		: out	std_logic_vector(NumPulses_g-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_pulse_cc is

	type Pulse_t is array (natural range <>) of std_logic_vector(NumPulses_g-1 downto 0);

	-- Domain A signals
	signal RstSyncB2A	: std_logic_vector(3 downto 0);
	signal RstAI		: std_logic;
	-- Domain B signals
	signal RstSyncA2B	: std_logic_vector(3 downto 0);
	signal RstBI		: std_logic;
	-- Data transmit side
	signal ToggleA		: std_logic_vector(NumPulses_g-1 downto 0);
	-- Data receive side
	signal ToggleSyncB	: Pulse_t(2 downto 0);
	
	attribute syn_srlstyle : string;
    attribute syn_srlstyle of RstSyncB2A 	: signal is "registers";
    attribute syn_srlstyle of RstSyncA2B 	: signal is "registers";
	attribute syn_srlstyle of ToggleA 		: signal is "registers";
	attribute syn_srlstyle of ToggleSyncB 	: signal is "registers";
	
	attribute shreg_extract : string;
    attribute shreg_extract of RstSyncB2A 	: signal is "no";
    attribute shreg_extract of RstSyncA2B 	: signal is "no";
	attribute shreg_extract of ToggleA 		: signal is "no";
    attribute shreg_extract of ToggleSyncB 	: signal is "no";
	
	attribute ASYNC_REG : string;
    attribute ASYNC_REG of RstSyncB2A 		: signal is "TRUE";
    attribute ASYNC_REG of RstSyncA2B 		: signal is "TRUE";
	attribute ASYNC_REG of ToggleA 			: signal is "TRUE";
	attribute ASYNC_REG of ToggleSyncB 		: signal is "TRUE";
	
begin
	
	-- Domain A reset sync
	ARstSync_p : process(ClkA, RstInB)
	begin
		if RstInB = '1' then	
			RstSyncB2A <= (others => '1');
		elsif rising_edge(ClkA) then
			RstSyncB2A <= RstSyncB2A(RstSyncB2A'left-1 downto 0) & '0';			
		end if;
	end process;
	ARst_p : process(ClkA)
	begin
		if rising_edge(ClkA) then
			RstAI <= RstSyncB2A(RstSyncB2A'left) or RstInA;
		end if;
	end process;
	RstOutA	<= RstAI;
	
	-- Domain B reset sync
	BRstSync_p : process(ClkB, RstInA)
	begin
		if RstInA = '1' then	
			RstSyncA2B <= (others => '1');
		elsif rising_edge(ClkB) then
			RstSyncA2B <= RstSyncA2B(RstSyncA2B'left-1 downto 0) & '0';
		end if;
	end process;
	BRst_p : process(ClkB)
	begin
		if rising_edge(ClkB) then
			RstBI <= RstSyncA2B(RstSyncA2B'left) or RstInB;
		end if;
	end process;	
	RstOutB	<= RstBI;	
	
	-- Pulse transmit side (A)
	PulseA_p : process(ClkA)
	begin
		if rising_edge(ClkA) then
			if RstAI = '1' then
				ToggleA <= (others => '0');
			else
				ToggleA <= ToggleA xor PulseA;
			end if;
		end if;
	end process;
	
	-- Data receive side (B)
	PulseB_p : process(ClkB)
	begin
		if rising_edge(ClkB) then
			if RstBI = '1' then
				ToggleSyncB <= (others => (others => '0'));
				PulseB <= (others => '0');
			else
				ToggleSyncB <= ToggleSyncB(ToggleSyncB'left-1 downto 0) & ToggleA;
				PulseB <= ToggleSyncB(ToggleSyncB'left) xor ToggleSyncB(ToggleSyncB'left-1);
			end if;	
		end if;
	end process;	
end;





