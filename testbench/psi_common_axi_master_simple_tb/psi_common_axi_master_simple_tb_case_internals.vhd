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
package psi_common_axi_master_simple_tb_case_internals is
	
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
		
	shared variable TestCase_v 		: integer := -1;
	shared variable DataBeats_v		: integer := 0;
	constant DelayBetweenTests 		: time := 0 us;
	constant DebugPrints 			: boolean := false;			
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_internals is

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
		print("*** Tet Group 5: Inernals ***");	
		
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Burst Write - Keep track of already anounced transfers ***		
			-- Are beats already announced (AW-channel command already sent) not taken
			-- into account for the high-latency mode?
			DbgPrint(DebugPrints, "Burst Write - Keep track of already anounced transfers");
			TestCase_v := 0;
			while DataBeats_v < 7 loop
				wait until rising_edge(Clk);
			end loop;
			ApplyCommand(16#00020000#, 4, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);	
			ApplyCommand(16#00021000#, 4, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
			wait for DelayBetweenTests;	
		end if;

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
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Burst Write - Keep track of already anounced transfers ***
			DataBeats_v := 0;
			WaitCase(0, Clk);
			ApplyWrDataMulti(16#1000#, 1, 4, "11", "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);		
			ApplyWrDataMulti(16#2000#, 1, 3, "11", "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);	-- First 3 beats of second transfer
			DataBeats_v := 7;
			wait for 5 us;
			wait until rising_edge(Clk);
			ApplyWrDataMulti(16#2003#, 1, 1, "11", "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);	-- Last beat of second transfer
			DataBeats_v := 8;
		end if;
		
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
		-- Writes
		------------------------------------------------------------------
		if Generics_c.ImplWrite_g then
			-- *** Burst Write - Keep track of already anounced transfers ***
			WaitCase(0, Clk);
			WaitForCompletion(true, 15 us, Wr_Done, Wr_Error, Clk);	
			WaitForCompletion(true, 15 us, Wr_Done, Wr_Error, Clk);	
		end if;

		
	end procedure;
	
	procedure axi (
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------
		if Generics_c.ImplWrite_g then
			-- *** Burst Write - Keep track of already anounced transfers ***
			WaitCase(0, Clk);
			-- First burst is expected immediately
			AxiCheckWrBurst(16#00020000#, 16#1000#, 1, 4, "11", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);	
			-- Check if next transfer is delayed until all data is present
			while DataBeats_v < 8 loop
				StdlCompare(0, axi_ms.awvalid, "Unexpected command");
				wait until rising_edge(Clk);
			end loop;
			-- Check second transfer
			AxiCheckWrBurst(16#00021000#, 16#2000#, 1, 4, "11", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		end if;
			
		
	end procedure;
	
end;
