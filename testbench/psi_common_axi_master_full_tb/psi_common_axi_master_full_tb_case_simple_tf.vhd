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
		print("*** Tet Group 1: Simple Transfer ***");
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			DbgPrint(DebugPrints, ">> Single word write [high latency]");
			TestCase_v := 0;
			ApplyCommand(16#02000001#, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
			wait for DelayBetweenTests;		
			
			-- 32-bit only test with 2 bytes shifted by 1
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
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);	
			ApplyWrDataSingle(16#3EADBEEF#, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
		end if;
	end procedure;
	
	procedure user_resp (
		signal Clk : in std_logic;
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);	
			WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);			
		end if;
	end procedure;
	
	procedure axi (
		signal Clk : in std_logic;
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		constant Generics_c : Generics_t) is
	begin
		axi_slave_init(axi_sm);
		
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);	
			AxiCheckWrSingle(16#02000000#, 16#EF00#, 2#10#, xRESP_OKAY_c, axi_ms, axi_sm, Clk, AxiDataWidth_g);
			
		end if;
	end procedure;
	
end;
