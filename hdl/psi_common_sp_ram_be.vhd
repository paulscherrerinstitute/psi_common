------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pure VHDL and vendor indpendent true dual port RAM that has 
-- byte enables.

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
entity psi_common_sp_ram_be is
	generic (
		Depth_g		: positive		:= 1024;
		Width_g		: positive		:= 32;
		Behavior_g	: string		:= "RBW"	-- "RBW" = read-before-write, "WBR" = write-before-read
	);
	port (
		-- Port A
		Clk		: in 	std_logic											:= '0';
		Addr	: in	std_logic_vector(log2ceil(Depth_g)-1 downto 0)		:= (others => '0');
		Be		: in	std_logic_vector(Width_g/8-1 downto 0)				:= (others => '1');
		Wr		: in	std_logic											:= '0';
		Din		: in	std_logic_vector(Width_g-1 downto 0)				:= (others => '0');
		Dout	: out	std_logic_vector(Width_g-1 downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_sp_ram_be is

	-- Constants
	constant BeCount_c		: integer		:= Width_g/8;

	-- memory array
	type mem_t is array(Depth_g-1 downto 0) of std_logic_vector(Width_g-1 downto 0);
	shared variable mem 	: mem_t := (others => (others => '0'));
	
begin

	assert Behavior_g = "RBW" or Behavior_g = "WBR" report "psi_common_sp_ram_be: Behavior_g must be RBW or WBR" severity error;
	assert Width_g mod 8 = 0 report "psi_common_sp_ram_be: Width_g must be a multiple of 8, otherwise byte-enables do not make sense" severity error;

	porta_p : process(Clk)
	begin
		if rising_edge(Clk) then
			if Behavior_g = "RBW" then
				Dout	<= mem(to_integer(unsigned(Addr)));
			end if;
			if Wr = '1' then
				for byte in 0 to BeCount_c-1 loop
					if Be(byte) = '1' then
						mem(to_integer(unsigned(Addr)))(byte*8+7 downto byte*8) := Din(byte*8+7 downto byte*8);
					end if;
				end loop;
			end if;
			if Behavior_g = "WBR" then
				Dout	<= mem(to_integer(unsigned(Addr)));
			end if;			
		end if;
	end process;
	

end;





