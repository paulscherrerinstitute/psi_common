------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
------------------------------------------------------------

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;

library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

library work;
	use work.psi_common_axi_master_full_tb_pkg.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_tb_activity_pkg.all;
	use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_full_tb_case_simple_tf is
	
	procedure user_cmd (
		signal Clk : in std_logic;
		signal CmdWr_Addr : inout std_logic_vector;
		signal CmdWr_Size : inout std_logic_vector;
		signal CmdWr_LowLat : inout std_logic;
		signal CmdWr_Vld : inout std_logic;
		signal CmdWr_Rdy : in std_logic;
		signal CmdRd_Addr : inout std_logic_vector;
		signal CmdRd_Size : inout std_logic_vector;
		signal CmdRd_LowLat : inout std_logic;
		signal CmdRd_Vld : inout std_logic;
		signal CmdRd_Rdy : in std_logic;
		constant Generics_c : Generics_t);
		
	procedure user_data (
		signal Clk : in std_logic;
		signal WrDat_Data : inout std_logic_vector;
		signal WrDat_Vld : inout std_logic;
		signal WrDat_Rdy : in std_logic;
		signal RdDat_Data : in std_logic_vector;
		signal RdDat_Vld : in std_logic;
		signal RdDat_Rdy : inout std_logic;
		constant Generics_c : Generics_t);
		
	procedure user_resp (
		signal Clk : in std_logic;
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		constant Generics_c : Generics_t);
		
	procedure axi (
		signal Clk : in std_logic;
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		constant Generics_c : Generics_t);
		
	shared variable TestCase_v 	: integer := -1;
	shared variable ExpectCmd_v : boolean;
	constant DelayBetweenTests 	: time := 0.2 us;	-- Minimum is 0.2 us (because of test implementation...)
	constant DebugPrints 		: boolean := false;		
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_case_simple_tf is

	procedure WaitCase(	nr 			: integer;
						signal Clk 	: std_logic) is
	begin
		while TestCase_v /= nr loop
			wait until rising_edge(Clk);
		end loop;
	end procedure;

	procedure user_cmd (
		signal Clk : in std_logic;
		signal CmdWr_Addr : inout std_logic_vector;
		signal CmdWr_Size : inout std_logic_vector;
		signal CmdWr_LowLat : inout std_logic;
		signal CmdWr_Vld : inout std_logic;
		signal CmdWr_Rdy : in std_logic;
		signal CmdRd_Addr : inout std_logic_vector;
		signal CmdRd_Size : inout std_logic_vector;
		signal CmdRd_LowLat : inout std_logic;
		signal CmdRd_Vld : inout std_logic;
		signal CmdRd_Rdy : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		wait for DelayBetweenTests;
		wait until rising_edge(Clk);
		
		print("*** Tet Group 1: Simple Transfer ***");
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** 1-8 bytes, shifted by 0-3 ***
			DbgPrint(DebugPrints, ">> 1-8 bytes, shifted by 0-3");
			for size in 1 to 8 loop
				for offs in 0 to 3 loop
					TestCase_v := TestCase_v + 1;
					-- Debug helper string
					-- print("Addr=" & hstr(to_unsigned(16#02000000#+offs, 32)) & ", size=" & str(size));
					ApplyCommand(16#02000000#+offs, size, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
					wait for DelayBetweenTests;
				end loop;
			end loop;
			wait for DelayBetweenTests;					
		end if;

		
	end procedure;
	
	procedure user_data (
		signal Clk : in std_logic;
		signal WrDat_Data : inout std_logic_vector;
		signal WrDat_Vld : inout std_logic;
		signal WrDat_Rdy : in std_logic;
		signal RdDat_Data : in std_logic_vector;
		signal RdDat_Vld : in std_logic;
		signal RdDat_Rdy : inout std_logic;
		constant Generics_c : Generics_t) is
		variable LastCase_v : integer := -1;
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** 1-8 bytes, shifted by 0-3  ***
			for size in 1 to 8 loop
				for offs in 0 to 3 loop
					WaitCase(LastCase_v+1, Clk);
					LastCase_v := TestCase_v;
					ApplyWrData(16#10#, size, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
				end loop;
			end loop;			
		end if;
	end procedure;
	
	procedure user_resp (
		signal Clk : in std_logic;
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		constant Generics_c : Generics_t) is
		variable LastCase_v : integer := -1;
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** 1-8 bytes, shifted by 0-3  ***	
			for size in 1 to 8 loop
				for offs in 0 to 3 loop
					WaitCase(LastCase_v+1, Clk);
					LastCase_v := TestCase_v;
					WaitForCompletion(true, DelayBetweenTests + 1 us, Wr_Done, Wr_Error, Clk);	
				end loop;
			end loop;
		end if;
	end procedure;
	
	procedure axi (
		signal Clk : in std_logic;
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		constant Generics_c : Generics_t) is
		variable LastCase_v : integer := -1;
	begin
		axi_slave_init(axi_sm);
		
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** 1-8 bytes, shifted by 0-3 ***
			for size in 1 to 8 loop
				for offs in 0 to 3 loop	
					WaitCase(LastCase_v+1, Clk);
					LastCase_v := TestCase_v;
					CheckAxiWrite(16#02000000#+offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
				end loop;
			end loop;
		end if;
	end procedure;
	
end;
