------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee ;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_tdp_ram is
	generic (
		Depth_g		: positive		:= 1024;
		Width_g		: positive		:= 32;
		Behavior_g	: string		:= "RBW"	-- "RBW" = read-before-write, "WBR" = write-before-read
	);
	port (
		-- Port A
		ClkA		: in 	std_logic											:= '0';
		AddrA		: in	std_logic_vector(log2ceil(Depth_g)-1 downto 0)		:= (others => '0');
		WrA			: in	std_logic											:= '0';
		DinA		: in	std_logic_vector(Width_g-1 downto 0)				:= (others => '0');
		DoutA		: out	std_logic_vector(Width_g-1 downto 0);
		
		-- Port B
		ClkB		: in 	std_logic											:= '0';
		AddrB		: in	std_logic_vector(log2ceil(Depth_g)-1 downto 0)		:= (others => '0');
		WrB			: in	std_logic											:= '0';
		DinB		: in	std_logic_vector(Width_g-1 downto 0)				:= (others => '0');
		DoutB		: out	std_logic_vector(Width_g-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_tdp_ram is

	-- memory array
	type mem_t is array(Depth_g-1 downto 0) of std_logic_vector(Width_g-1 downto 0);
	shared variable mem 	: mem_t := (others => (others => '0'));
	
begin

	assert Behavior_g = "RBW" or Behavior_g = "WBR" report "psi_common_tdp_ram: Behavior_g must be RBW or WBR" severity error;

	-- Port A
	porta_p : process(ClkA)
	begin
		if rising_edge(ClkA) then
			if Behavior_g = "RBW" then
				DoutA	<= mem(to_integer(unsigned(AddrA)));
			end if;
			if WrA = '1' then
				mem(to_integer(unsigned(AddrA))) := DinA;
			end if;
			if Behavior_g = "WBR" then
				DoutA	<= mem(to_integer(unsigned(AddrA)));
			end if;
		end if;
	end process;
	
	-- Port B
	portb_p : process(ClkB)
	begin
		if rising_edge(ClkB) then
			if Behavior_g = "RBW" then
				DoutB	<= mem(to_integer(unsigned(AddrB)));
			end if;
			if WrB = '1' then
				mem(to_integer(unsigned(AddrB))) := DinB;
			end if;
			if Behavior_g = "WBR" then
				DoutB	<= mem(to_integer(unsigned(AddrB)));
			end if;
		end if;
	end process;
end;





