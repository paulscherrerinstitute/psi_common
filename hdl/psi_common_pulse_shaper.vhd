------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pulse shaping block allowing to generate pulses of a fixed length
-- from pulses with an unknown length. Additionally input pulses occuring 
-- during a configurable hold-off time can be ignored after one pulse was detected.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stimuli $$
entity psi_common_pulse_shaper is
	generic (
		Duration_g	: positive	:= 3;		-- Output pulse duration in clock cycles															$$ constant=3 $$
		HoldOff_g	: natural	:= 0		-- Minimum number of clock cycles between input pulses, if pulses arrive faster, they are ignored	$$ constant=20 $$
	);
	port (
		Clk			: in	std_logic;			-- $$ type=clk; freq=100e6 $$
		Rst			: in	std_logic;			-- $$ type=rst; clk=Clk $$
		InPulse		: in	std_logic;		
		OutPulse	: out	std_logic	
	);		
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_pulse_shaper is
	-- Two Process Method
	type two_process_r is record
		PulseLast	: std_logic;
		OutPulse	: std_logic;
		DurCnt		: integer range 0 to Duration_g-1;
		HoCnt		: integer range 0 to HoldOff_g;
	end record;	
	signal r, r_next : two_process_r;
begin

	
	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, InPulse)	
		variable v : two_process_r;
	begin	
		-- hold variables stable
		v := r;
		
		-- *** Implementation ***
		v.PulseLast	:= InPulse;
		if r.DurCnt = 0 then
			v.OutPulse	:= '0';
		else
			v.DurCnt := r.DurCnt - 1;
		end if;		
		if r.HoCnt /= 0 then
			v.HoCnt := r.HoCnt - 1 ;
		end if;		
		if (InPulse = '1') and (r.PulseLast = '0') and (r.HoCnt = 0) then
			v.OutPulse	:= '1';
			v.HoCnt 	:= HoldOff_g;
			v.DurCnt 	:= Duration_g-1;
		end if;

		
		-- Apply to record
		r_next <= v;
		
	end process;
	
	-- *** Output ***
	OutPulse <= r.OutPulse;
	
	--------------------------------------------------------------------------
	-- Sequential Process
	--------------------------------------------------------------------------	
	p_seq : process(Clk)
	begin	
		if rising_edge(Clk) then
			r <= r_next;
			if Rst = '1' then
				r.OutPulse	<= '0';
				r.HoCnt		<= 0;
			end if;
		end if;
	end process;
end architecture;