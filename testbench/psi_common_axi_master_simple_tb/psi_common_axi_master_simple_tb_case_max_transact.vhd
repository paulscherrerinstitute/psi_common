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
package psi_common_axi_master_simple_tb_case_max_transact is
	
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
		
	shared variable TestCase_v : integer := -1;
	constant DelayBetweenTests 	: time := 0 us;
	constant DebugPrints 		: boolean := false;
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_max_transact is

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
		print("*** Tet Group 2: Maximum Open Transactions ***");
		
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			DbgPrint(DebugPrints, ">> Single word write [high latency]");
			TestCase_v := 0;
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyCommand(16#00001000#*i, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
			end loop;
			wait for DelayBetweenTests;
			
			-- *** Burst write [low latency] ***
			DbgPrint(DebugPrints, ">> Burst write [low latency]");
			TestCase_v := 1;
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyCommand(16#00001000#*i, 8, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
			end loop;
			wait for DelayBetweenTests;	
		end if;

		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------
		if Generics_c.ImplRead_g then
			-- *** Single word read [high latency] ***
			DbgPrint(DebugPrints, ">> Single word read [high latency]");
			TestCase_v := 2;
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyCommand(16#00001000#*i, 1, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
			end loop;
			wait for DelayBetweenTests;	

			-- *** Burst read [low latency] ***
			DbgPrint(DebugPrints, ">> Burst read [low latency]");
			TestCase_v := 3;
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyCommand(16#00001000#*i, 8, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
			end loop;
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
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyWrDataSingle(16#0001#*i, "11",  WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
			end loop;
			
			-- *** Burst write [low latency] ***
			WaitCase(1, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				ApplyWrDataMulti(16#0001#*i, 1, 8, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);	
			end loop;
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------
		if Generics_c.ImplRead_g then
			-- *** Single word read [high latency] ***		
			WaitCase(2, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				CheckRdDataSingle(16#0001#*i,  RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);	
			end loop;		
			
			-- *** Burst read [low latency] ***
			WaitCase(3, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				CheckRdDataMulti(16#0001#*i, 1, 8, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);	
			end loop;	
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
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				WaitForCompletion(true, 10 us, Wr_Done, Wr_Error, Clk);
			end loop;
			
			-- *** Burst write [low latency] ***
			WaitCase(1, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				WaitForCompletion(true, 10 us, Wr_Done, Wr_Error, Clk);
			end loop;
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------
		if Generics_c.ImplRead_g then
			-- *** Single word read [high latency] ***	
			WaitCase(2, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				WaitForCompletion(true, 20 us, Rd_Done, Rd_Error, Clk);
			end loop;		
			
			-- *** Burst read [low latency] ***
			WaitCase(3, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				WaitForCompletion(true, 20 us, Rd_Done, Rd_Error, Clk);
			end loop;
		end if;
		
	end procedure;
	
	procedure axi (
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		axi_slave_init(axi_sm);
		
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** Single word wirte [high latency] ***
			WaitCase(0, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				-- check if last transaction is really delayed until response generation is started
				if i = AxiMaxOpenTrasactions_g then
					wait for 1 us;
					wait until rising_edge(Clk);
					assert (axi_ms.awvalid = '0') and (axi_ms.wvalid = '0') report "###ERROR###: Transaction not delayed until responses generated" severity error;
					-- send responses
					for i in 0 to AxiMaxOpenTrasactions_g-1 loop
						axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
					end loop;
				end if;
				-- check transaction
				AxiCheckWrSingle(16#00001000#*i, 16#0001#*i, "11", "XX", axi_ms, axi_sm, Clk, false); --without response
			end loop;
			-- Send last response
			axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			
			-- *** Burst write [low latency] ***
			WaitCase(1, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				-- check if last transaction is really delayed until response generation is started
				if i = AxiMaxOpenTrasactions_g then
					wait for 1 us;
					wait until rising_edge(Clk);
					assert (axi_ms.awvalid = '0') and (axi_ms.wvalid = '0') report "###ERROR###: Transaction not delayed until responses generated" severity error;
					-- send responses
					for i in 0 to AxiMaxOpenTrasactions_g-1 loop
						axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
					end loop;
				end if;
				-- check transaction
				AxiCheckWrBurst(16#00001000#*i, 16#0001#*i, 1, 8, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk, false); --without response
			end loop;
			-- Send last response
			axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);		
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------
		if Generics_c.ImplRead_g then
			-- *** Single word read [high latency] ***			
			WaitCase(2, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				-- check if last transaction is really delayed until response generation is started
				if i = AxiMaxOpenTrasactions_g then
					wait for 1 us;
					wait until rising_edge(Clk);
					assert axi_ms.arvalid = '0' report "###ERROR###: Transaction not delayed until responses generated" severity error;
					-- send responses
					for i in 0 to AxiMaxOpenTrasactions_g-1 loop
						axi_apply_rresp_single(std_logic_vector(to_unsigned(16#0001#*i, AxiDataWidth_g)), xRESP_OKAY_c, axi_ms, axi_sm, Clk);
					end loop;
				end if;
				-- check transaction
				axi_expect_ar(	16#00001000#*i, AxSIZE_2_c, 1-1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
			end loop;
			-- Send last response
			axi_apply_rresp_single(std_logic_vector(to_unsigned(16#0001#*AxiMaxOpenTrasactions_g, AxiDataWidth_g)), xRESP_OKAY_c, axi_ms, axi_sm, Clk);
			
			-- *** Burst read [low latency] ***
			WaitCase(3, Clk);
			for i in 0 to AxiMaxOpenTrasactions_g loop
				-- check if last transaction is really delayed until response generation is started
				if i = AxiMaxOpenTrasactions_g then
					wait for 1 us;
					wait until rising_edge(Clk);
					assert axi_ms.arvalid = '0' report "###ERROR###: Transaction not delayed until responses generated" severity error;
					-- send responses
					for i in 0 to AxiMaxOpenTrasactions_g-1 loop
						axi_apply_rresp_burst(8, 16#0001#*i, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
					end loop;
				end if;
				-- check transaction
				axi_expect_ar(	16#00001000#*i, AxSIZE_2_c, 8-1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
			end loop;
			-- Send last response
			axi_apply_rresp_burst(8, 16#0001#*AxiMaxOpenTrasactions_g, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
		end if;
	
	end procedure;
	
end;
