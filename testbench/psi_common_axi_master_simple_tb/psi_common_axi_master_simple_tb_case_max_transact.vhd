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
	shared variable StartResp_v : boolean := false;
		
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
		wait for 1 us;
		print("*** Tet Group 2: Maximum Open Transactions ***");
		
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------
		-- *** Single word wirte [high latency] ***
		print(">> Single word write [high latency]");
		TestCase_v := 0;
		for i in 0 to AxiMaxOpenTrasactions_g loop
			ApplyCommand(16#00001000#*i, 1, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
		end loop;
		wait for 1 us;
		
		-- *** Burst write [low latency] ***
		print(">> Burst write [low latency]");
		TestCase_v := 1;
		for i in 0 to AxiMaxOpenTrasactions_g loop
			ApplyCommand(16#00001000#*i, 8, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
		end loop;
		wait for 1 us;		
		
		
		wait for 1 us;
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
		-- *** Single word wirte [high latency] ***
		StartResp_v := false;
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
		StartResp_v := false;
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
		
	end procedure;
	
end;
