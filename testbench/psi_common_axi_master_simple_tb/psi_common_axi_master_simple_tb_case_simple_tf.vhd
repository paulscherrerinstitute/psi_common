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
	use work.psi_common_axi_master_simple_tb_pkg.all;

library work;
	use work.psi_tb_txt_util.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_tb_activity_pkg.all;
	use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_simple_tb_case_simple_tf is
	
	procedure user_cmd (
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
		signal Clk : in std_logic;
		constant Generics_c : Generics_t);
		
	procedure user_data (
		signal WrDat_Data : inout std_logic_vector;
		signal WrDat_Be : inout std_logic_vector;
		signal WrDat_Vld : inout std_logic;
		signal WrDat_Rdy : in std_logic;
		signal RdDat_Data : in std_logic_vector;
		signal RdDat_Vld : in std_logic;
		signal RdDat_Rdy : inout std_logic;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t);
		
	procedure user_resp (
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t);
		
	procedure axi (
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t);
		
	shared variable TestCase_v 	: integer := -1;
	shared variable ExpectCmd_v : boolean;
	constant DelayBetweenTests 	: time := 1 us;
	constant DebugPrints 		: boolean := true;
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_simple_tf is
	procedure WaitCase(	nr 			: integer;
						signal Clk 	: std_logic) is
	begin
		while TestCase_v /= nr loop
			wait until rising_edge(Clk);
		end loop;
	end procedure;

	procedure user_cmd (
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
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		wait for DelayBetweenTests;
		print("*** Tet Group 1: Simple Transfer ***");
		
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------		
		-- *** Single word wirte [high latency, command+data together] ***
		DbgPrint(DebugPrints, ">> Single word write [high latency, command+data together]");
		TestCase_v := 0;
		ApplyCommand(16#12345678#, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
		wait for DelayBetweenTests;
		
		-- *** Single word wirte [high latency, command before data] ***
		DbgPrint(DebugPrints, ">> Single word wirte [high latency, command before data]");
		TestCase_v := 1;
		ApplyCommand(16#00010020#, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);		
		wait for DelayBetweenTests;
		
		-- *** Single word wirte [high latency, command after data + error] ***
		DbgPrint(DebugPrints, ">> Single word wirte [high latency, command after data + error]");
		TestCase_v := 2;
		wait for 200 ns;
		ApplyCommand(16#00010030#, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);		
		wait for DelayBetweenTests;		
		
		-- *** Burst wirte[high latency] ***		
		DbgPrint(DebugPrints, ">> Burst write [high latency]");
		TestCase_v := 3;
		ApplyCommand(16#00020000#, 12, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);	
		wait for DelayBetweenTests;	
		
		------------------------------------------------------------------
		-- Low Latency Writes
		------------------------------------------------------------------	
		-- *** Single word wirte [low latency, command+data together] ***
		DbgPrint(DebugPrints, ">> Single word write [low latency, command+data together]");
		TestCase_v := 4;
		ApplyCommand(16#12345678#, 1, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
		wait for DelayBetweenTests;
		
		-- *** Single word wirte [low latency, command before data] ***
		DbgPrint(DebugPrints, ">> Single word wirte [low latency, command before data]");
		TestCase_v := 5;
		ApplyCommand(16#00010020#, 1, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);		
		wait for DelayBetweenTests;
		
		-- *** Single word wirte [low latency, command after data + error] ***
		DbgPrint(DebugPrints, ">> Single word wirte [low latency, command after data + error]");
		TestCase_v := 6;
		wait for 200 ns;
		ApplyCommand(16#00010030#, 1, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);		
		wait for DelayBetweenTests;		
		
		-- *** Burst wirte[low latency] ***
		DbgPrint(DebugPrints, ">> Burst write [low latency]");
		TestCase_v := 7;
		ApplyCommand(16#00020000#, 12, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);	
		wait for DelayBetweenTests;		

		------------------------------------------------------------------
		-- High Latency Reads
		------------------------------------------------------------------		
		-- *** Single word read [high latency, space available] ***
		DbgPrint(DebugPrints, ">> Single word read [high latency, space available]");
		TestCase_v := 8;
		ApplyCommand(16#12345678#, 1, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
		wait for DelayBetweenTests;
		
		-- *** Burst read [high latency, space available] ***
		DbgPrint(DebugPrints, ">> Burst read [high latency, space available]");
		TestCase_v := 9;
		ApplyCommand(16#00020000#, 12, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
		wait for DelayBetweenTests;		
		
		-- *** Single word read [high latency, wait for space] ***
		
		-- *** Burst read [high latency, wait for space] ***
		

		wait for DelayBetweenTests;			
		
	end procedure;
	
	procedure user_data (
		signal WrDat_Data : inout std_logic_vector;
		signal WrDat_Be : inout std_logic_vector;
		signal WrDat_Vld : inout std_logic;
		signal WrDat_Rdy : in std_logic;
		signal RdDat_Data : in std_logic_vector;
		signal RdDat_Vld : in std_logic;
		signal RdDat_Rdy : inout std_logic;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------		
		-- *** Single word wirte [high latency, command+data together] ***
		WaitCase(0, Clk);
		ApplyWrDataSingle(16#BEEF#, "10",  WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		
		-- *** Single word wirte [high latency, command before data] ***
		ExpectCmd_v := false;
		WaitCase(1, Clk);
		wait for 200 ns;
		wait until rising_edge(Clk);
		ApplyWrDataSingle(16#BABE#, "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		ExpectCmd_v := true;
		
		-- *** Single word wirte [high latency, command after data + error] ***
		WaitCase(2, Clk);
		wait until rising_edge(Clk);
		ApplyWrDataSingle(16#0001#, "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		
		-- *** Burst wirte[high latency] ***
		ExpectCmd_v := false;
		WaitCase(3, Clk);
		wait for 200 ns;
		wait until rising_edge(Clk);
		ApplyWrDataMulti(16#1000#, 1, 12, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		ExpectCmd_v := true;
		
		------------------------------------------------------------------
		-- Low Latency Writes
		------------------------------------------------------------------	
		-- *** Single word wirte [low latency, command+data together] ***
		WaitCase(4, Clk);
		ApplyWrDataSingle(16#BEEF#, "10",  WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		
		-- *** Single word wirte [low latency, command before data] ***
		WaitCase(5, Clk);
		wait for 200 ns;
		wait until rising_edge(Clk);
		ApplyWrDataSingle(16#BABE#, "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		
		-- *** Single word wirte [low latency, command after data + error] ***
		WaitCase(6, Clk);
		wait until rising_edge(Clk);
		ApplyWrDataSingle(16#0001#, "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
		
		-- *** Burst wirte[low latency] ***
		WaitCase(7, Clk);
		wait until rising_edge(Clk);
		ApplyWrDataMulti(16#1000#, 1, 12, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);	
		
		------------------------------------------------------------------
		-- High Latency Reads
		------------------------------------------------------------------		
		-- *** Single word read [high latency, space available] ***
		WaitCase(8, Clk);
		CheckRdDataSingle(16#BEEF#,  RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);	
		
		-- *** Burst read [high latency, space available] ***
		WaitCase(9, Clk);
		CheckRdDataMulti(16#1000#,  1, 12, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);
		
	end procedure;
	
	procedure user_resp (
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------		
		-- *** Single word wirte [high latency, command+data together] ***
		WaitCase(0, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Single word wirte [high latency, command before data] ***
		WaitCase(1, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Single word wirte [high latency, command after data + error] ***
		WaitCase(2, Clk);
		WaitForCompletion(false, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Burst wirte[high latency] ***
		WaitCase(3, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);	

		------------------------------------------------------------------
		-- Low Latency Writes
		------------------------------------------------------------------	
		-- *** Single word wirte [low latency, command+data together] ***
		WaitCase(4, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Single word wirte [low latency, command before data] ***
		WaitCase(5, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Single word wirte [low latency, command after data + error] ***
		WaitCase(6, Clk);
		WaitForCompletion(false, 1 us, Wr_Done, Wr_Error, Clk);
		
		-- *** Burst wirte[low latency] ***
		WaitCase(7, Clk);
		WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);	

		------------------------------------------------------------------
		-- High Latency Reads
		------------------------------------------------------------------
		-- *** Single word read [high latency, space available] ***		
		WaitCase(8, Clk);
		WaitForCompletion(true, 1 us, Rd_Done, Rd_Error, Clk);
		
		-- *** Burst read [high latency, space available] ***
		WaitCase(9, Clk);
		WaitForCompletion(false, 1 us, Rd_Done, Rd_Error, Clk);		
		
	end procedure;
	
	procedure axi (
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		axi_slave_init(axi_sm);
		
		------------------------------------------------------------------
		-- High Latency Writes
		------------------------------------------------------------------		
		-- *** Single word wirte [high latency, command+data together] ***
		WaitCase(0, Clk);
		AxiCheckWrSingle(16#12345678#, 16#BEEF#, "10", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		-- *** Single word wirte [high latency, command before data] ***
		WaitCase(1, Clk);
		while not ExpectCmd_v loop
			wait until rising_edge(Clk);
			assert axi_ms.awvalid = '0' report "###ERROR###: High Latency did not wait for data in fifo" severity error;
		end loop;
		AxiCheckWrSingle(16#00010020#, 16#BABE#, "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		-- *** Single word wirte [high latency, command before data] ***
		WaitCase(2, Clk);
		AxiCheckWrSingle(16#00010030#, 16#0001#, "11", xRESP_DECERR_c, axi_ms, axi_sm, Clk);	

		-- *** Burst wirte[high latency] ***
		WaitCase(3, Clk);
		while not ExpectCmd_v loop
			wait until rising_edge(Clk);
			assert axi_ms.awvalid = '0' report "###ERROR###: High Latency did not wait for data in fifo" severity error;
		end loop;
		AxiCheckWrBurst(16#00020000#, 16#1000#, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		------------------------------------------------------------------
		-- Low Latency Writes
		------------------------------------------------------------------		
		-- *** Single word wirte [low latency, command+data together] ***
		WaitCase(4, Clk);
		AxiCheckWrSingle(16#12345678#, 16#BEEF#, "10", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		-- *** Single word wirte [low latency, command before data] ***
		WaitCase(5, Clk);
		AxiCheckWrSingle(16#00010020#, 16#BABE#, "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		-- *** Single word wirte [low latency, command before data] ***
		WaitCase(6, Clk);
		AxiCheckWrSingle(16#00010030#, 16#0001#, "11", xRESP_DECERR_c, axi_ms, axi_sm, Clk);	

		-- *** Burst wirte[low latency] ***
		WaitCase(7, Clk);
		AxiCheckWrBurst(16#00020000#, 16#1000#, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		------------------------------------------------------------------
		-- High Latency Reads
		------------------------------------------------------------------
		-- *** Single word read [high latency, space available] ***	
		WaitCase(8, Clk);
		AxiCheckRdSingle(16#12345678#, 16#BEEF#, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		
		-- *** Burst read [high latency, space available] ***
		WaitCase(9, Clk);
		AxiCheckRdBurst(16#00020000#, 16#1000#, 1, 12, xRESP_DECERR_c, axi_ms, axi_sm, Clk);

	end procedure;
	
end;
