------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a conversion from length-variable time-division-multiplexed input
-- (multiple values transferred over the same signal one after the other) to
-- parallel (multiple values distributed over multiple parallel signals).
-- The enabled channels order is (ChannelCount_g downto ChannelCount_g - EnabledChannels -1) 
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
entity psi_common_tdm_par_cfg is
	generic (
		ChannelCount_g		: natural	:= 8;		-- $$ constant=3 $$
		ChannelWidth_g		: natural	:= 16		-- $$ constant=8 $$
	);
	port
	(
		-- Control Signals
		Clk							: in 	std_logic;		-- $$ type=clk; freq=100e6 $$
		Rst							: in 	std_logic;		-- $$ type=rst; clk=Clk $$
		EnabledChannels : in  integer range 0 to ChannelCount_g := ChannelCount_g; -- Number of enable output channels
		-- Data Ports
    Tdm         : in  std_logic_vector(ChannelWidth_g - 1 downto 0);
    TdmVld      : in  std_logic;
    TdmLast     : in  std_logic;    -- If the Tdm has a last bit it can be used to ensure the synchronization, it is usefull once the user changes the number of enabled channels
    Parallel    : out std_logic_vector(ChannelCount_g * ChannelWidth_g - 1 downto 0);
    ParallelVld : out std_logic		
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par_cfg is 

	-- Two Process Method
	type two_process_r is record
		ParallelReg 	: std_logic_vector(Parallel'range);
		ChCounter			: integer range 0 to ChannelCount_g + 1;
		Odata			: std_logic_vector(Parallel'range);
		Ovld			: std_logic;
		TdmLast_d   : std_logic;
	end record;	
	signal r, r_next : two_process_r;
begin

	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(	r, Tdm, TdmVld, EnabledChannels, TdmLast)	
		variable v : two_process_r;		
	begin	
		-- hold variables stable
		v := r;
		
		-- *** Implementation ***
		v.TdmLast_d := '0';
		if TdmVld = '1' then
			if (v.ChCounter < EnabledChannels) then 
			  v.ParallelReg ((ChannelWidth_g*v.ChCounter)+(ChannelWidth_g - 1) downto ChannelWidth_g*v.ChCounter)	:= Tdm ;
			else
			  v.ParallelReg ((ChannelWidth_g - 1) downto 0)  := Tdm ;
		  end if;
			v.ChCounter := v.ChCounter + 1;
			v.TdmLast_d := TdmLast;
		end if;
		
		-- *** Latch ***
		v.Ovld := '0';
		if r.ChCounter =  EnabledChannels or r.TdmLast_d = '1' then
			v.Ovld := '1';
			v.Odata := r.ParallelReg;
			v.ChCounter				:= to_integer(unsigned'('0' & TdmVld));
		end if;
		
		-- *** Outputs ***
		Parallel <= r.Odata;
		ParallelVld <= r.Ovld;
		
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
				r.ChCounter	<= 0;
				r.Ovld <= '0';
				r.TdmLast_d <= '0';
			end if;
		end if;
	end process;
 
end rtl;
