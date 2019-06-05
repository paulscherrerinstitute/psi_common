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
package psi_common_axi_master_full_tb_case_large is
	
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
	shared variable AllDone_v	: integer := -1;
	constant DebugPrints 		: boolean := false;	
	constant DelayBetweenTests 	: time := 0 us;		
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_case_large is

	procedure WaitCase(	nr 			: integer;
						signal Clk 	: std_logic) is
	begin
		while TestCase_v /= nr loop
			wait until rising_edge(Clk);
		end loop;
	end procedure;
	
	procedure WaitDone(	nr 			: integer;
						signal Clk 	: std_logic) is
	begin
		while AllDone_v /= nr loop
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
		
		print("*** Tet Group 4: Large Transfers ***");
		
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Write 1022 bytes to 0x02000001 ***
			DbgPrint(DebugPrints, ">> Write 1022 bytes to 0x02000001");
			TestCase_v := 0;
			ApplyCommand(16#02000001#, 1022, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
			WaitDone(0, Clk);
			wait for DelayBetweenTests;				
		end if;	
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** Read 1022 bytes from 0x02000001 (high latency) ***
			DbgPrint(DebugPrints, ">> Read 1022 bytes from 0x02000001 (high latency)");
			TestCase_v := 1;
			ApplyCommand(16#02000001#, 1022, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
			WaitDone(1, Clk);
			wait for DelayBetweenTests;			

			-- *** Read 1022 bytes from 0x02000001 (low latency) ***
			DbgPrint(DebugPrints, ">> Read 1022 bytes from 0x02000001 (low latency)");
			TestCase_v := 2;
			ApplyCommand(16#02000001#, 1022, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
			WaitDone(2, Clk);
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
	begin
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Write 1022 bytes to 0x02000001 ***
			WaitCase(0, Clk);
			ApplyWrData(16#10#, 1022, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);				
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** Read 1022 bytes from 0x02000001 (high latency) ***
			WaitCase(1, Clk);
			CheckRdData(16#10#, 1022, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);			

			-- *** Read 1022 bytes from 0x02000001 (low latency) ***
			WaitCase(2, Clk);
			CheckRdData(16#10#, 1022, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);					
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
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Write 1022 bytes to 0x02000001 ***
			WaitCase(0, Clk);
			WaitForCompletion(true, 100 us, Wr_Done, Wr_Error, Clk);	
			AllDone_v := 0;							
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** Read 1022 bytes from 0x02000001 (high latency) ***
			WaitCase(1, Clk);
			WaitForCompletion(true, 100 us, Rd_Done, Rd_Error, Clk);	
			AllDone_v := 1;		

			-- *** Read 1022 bytes from 0x02000001 (low latency) ***
			WaitCase(2, Clk);
			WaitForCompletion(true, 100 us, Rd_Done, Rd_Error, Clk);	
			AllDone_v := 2;				
		end if;		
	end procedure;
	
	procedure axi (
		signal Clk : in std_logic;
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		constant Generics_c : Generics_t) is
	begin
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Write 1022 bytes to 0x02000001 ***			
			WaitCase(0, Clk);
			CheckAxiWrite(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);		
			CheckAxiWrite(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
			CheckAxiWrite(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			CheckAxiWrite(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** Read 1022 bytes from 0x02000001 (high latency) ***
			WaitCase(1, Clk);
			DoAxiRead(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);		
			DoAxiRead(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
			DoAxiRead(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
			
			-- *** Read 1022 bytes from 0x02000001 (low latency) ***
			WaitCase(2, Clk);
			DoAxiRead(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);		
			DoAxiRead(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
			DoAxiRead(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			DoAxiRead(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);				
		end if;		
	end procedure;
	
end;
