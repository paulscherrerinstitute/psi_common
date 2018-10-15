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
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;
	use work.psi_common_array_pkg.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_tb_txt_util.all;
	

entity psi_common_logic_pkg_tb is
end entity psi_common_logic_pkg_tb;

architecture sim of psi_common_logic_pkg_tb is

begin

	-------------------------------------------------------------------------
	-- TB Control
	-------------------------------------------------------------------------
	p_control : process
		constant BinaryToGray_BinArray_c 	: t_aslv3(0 to 7)	:= ("000", "001", "010", "011", "100", "101", "110", "111");
		constant BinaryToGray_GrayArray_c 	: t_aslv3(0 to 7)	:= ("000", "001", "011", "010", "110", "111", "101", "100");
	begin
	
		-- *** ZerosVector ***
		print("*** ZerosVector ***");	
		StdlvCompareStdlv("00000", ZerosVector(5), "Wrong Result");
		
		-- *** OnesVector ***
		print("*** OnesVector ***");	
		StdlvCompareStdlv("11111", OnesVector(5), "Wrong Result");
		
		-- *** ShiftLeft ***
		print("*** ShiftLeft ***");	
		StdlvCompareStdlv("10100", ShiftLeft("11101", 2, '0'), "Wrong Result");		
		StdlvCompareStdlv("10111", ShiftLeft("11101", 2, '1'), "Wrong Result");	
		StdlvCompareStdlv("01011", ShiftLeft("10101", 1, '1'), "Wrong Result");	
		
		-- *** ShiftRight ***
		print("*** ShiftRight ***");	
		StdlvCompareStdlv("00101", ShiftRight("10111", 2, '0'), "Wrong Result");		
		StdlvCompareStdlv("11101", ShiftRight("10111", 2, '1'), "Wrong Result");	
		StdlvCompareStdlv("11010", ShiftRight("10101", 1, '1'), "Wrong Result");			
		
		-- *** BinaryToGray ***
		print("*** BinaryToGray ***");	
		for i in 0 to 7 loop
			StdlvCompareStdlv(BinaryToGray_GrayArray_c(i), BinaryToGray(BinaryToGray_BinArray_c(i)), "Index=" & integer'image(i));
		end loop;
		
		-- *** GrayToBinary ***
		print("*** GrayToBinary ***");	
		for i in 0 to 7 loop
			StdlvCompareStdlv(BinaryToGray_BinArray_c(i), GrayToBinary(BinaryToGray_GrayArray_c(i)), "Index=" & integer'image(i));
		end loop;		
		
		-- PpcOr
		print("*** PpcOr ***");	
		for length in 1 to 6 loop
			for value in 0 to 2**length-1 loop
				if value = 0 then
					StdlvCompareInt (	0, PpcOr(std_logic_vector(to_unsigned(value, length))), "Wrong PpcOr: Length " & to_string(length) & " Value " & to_string(value), false);	
				else
					StdlvCompareInt (	2**(log2(value)+1)-1, PpcOr(std_logic_vector(to_unsigned(value, length))), "Wrong PpcOr: Length " & to_string(length) & " Value " & to_string(value), false);	
				end if;
				-- print for debugging purposes
				--print("l " & to_string(length) & " v " & to_string(std_logic_vector(to_unsigned(value, length))) & " r " & to_string(PpcOr(std_logic_vector(to_unsigned(value, length)))));
			end loop;
		end loop;
		wait;
	end process;


end sim;
