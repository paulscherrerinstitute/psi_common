------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  Copyright (c) 2020 by Enclustra GmbH, Switherland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity takes multiple inputs in parallel and converts them to time-
-- division-multiplexed (i.e. the values are transferred one after the other
-- over a single signal)
-- The number of channels to be serialized can be configured at runtime.

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
-- $$ processes=inp,outp $$
entity psi_common_par_tdm_cfg is
	generic (
		ChannelCount_g		: natural	:= 8;		-- $$ constant=3 $$
		ChannelWidth_g		: natural	:= 16		-- $$ constant=8 $$
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;	-- $$ type=clk; freq=100e6 $$
		Rst							: in 	std_logic;	-- $$ type=rst; clk=Clk $$
		EnabledChannels				: in 	integer range 0 to ChannelCount_g := ChannelCount_g; -- Number of enabled output channels (starting from index 0)
		
		-- Data Ports
		Parallel					: in 	std_logic_vector(ChannelCount_g*ChannelWidth_g-1 downto 0);
		ParallelVld					: in	std_logic;
		Tdm							: out 	std_logic_vector(ChannelWidth_g-1 downto 0);
		TdmLast						: out	std_logic;
		TdmVld						: out	std_logic
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_par_tdm_cfg is 

	-- Two Process Method
	type two_process_r is record
		ShiftReg		: std_logic_vector(Parallel'range);
		ChCnt			: integer range 0 to ChannelCount_g;
	end record;	
	signal r, r_next : two_process_r;
	signal ChCnt_I : integer range 0 to ChannelCount_g;
begin

	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, Parallel, ParallelVld, EnabledChannels)	
		variable v : two_process_r;
	begin	
		-- hold variables stable
		v := r;
		
		-- *** Implementation ***
		if ParallelVld = '1' then
			v.ShiftReg	:= Parallel;
			v.ChCnt		:= EnabledChannels;
		else
			v.ShiftReg 	:= shiftRight(r.ShiftReg, ChannelWidth_g);
			if r.ChCnt /= 0 then
				v.ChCnt		:= r.ChCnt - 1;
			end if;
		end if;

		-- *** Outputs ***
		Tdm		<= r.ShiftReg(ChannelWidth_g-1 downto 0);
		TdmVld	<= '1' when r.ChCnt /= 0 else '0';
		TdmLast	<= '1' when r.ChCnt = 1 else '0';
		
		-- Apply to record
		r_next <= v;
		
	end process;
	ChCnt_I <= r.ChCnt;
	
	--------------------------------------------------------------------------
	-- Sequential Process
	--------------------------------------------------------------------------	
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.ChCnt <= 0;
			end if;
		end if;
	end process;
 
end rtl;
