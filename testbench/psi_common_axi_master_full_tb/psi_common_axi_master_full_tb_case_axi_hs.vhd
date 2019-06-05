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
package psi_common_axi_master_full_tb_case_axi_hs is
	
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
package body psi_common_axi_master_full_tb_case_axi_hs is

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
		
		print("*** Tet Group 2: Axi Handshaking ***");
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** No Delay ***
			DbgPrint(DebugPrints, ">> Write No Delay");
			TestCase_v := 0;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
				end loop;
			end loop;
			WaitDone(0, Clk);
			wait for DelayBetweenTests;	

			-- *** AW Delay only ***
			DbgPrint(DebugPrints, ">> Write AW Delay only");
			TestCase_v := 1;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
				end loop;
			end loop;
			WaitDone(1, Clk);
			wait for DelayBetweenTests;		

			-- *** W Delay only ***	
			DbgPrint(DebugPrints, ">> Write W Delay only");
			TestCase_v := 2;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
				end loop;
			end loop;
			WaitDone(2, Clk);
			wait for DelayBetweenTests;		

			-- *** AW and W Delay ***	
			DbgPrint(DebugPrints, ">> Write AW and W Delay");
			TestCase_v := 3;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
				end loop;
			end loop;
			WaitDone(3, Clk);
			wait for DelayBetweenTests;				
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** No Delay ***
			DbgPrint(DebugPrints, ">> Read No Delay");
			TestCase_v := 4;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
				end loop;
			end loop;
			WaitDone(4, Clk);
			wait for DelayBetweenTests;	

			-- *** AR Delay only ***
			DbgPrint(DebugPrints, ">> Read AR Delay only");
			TestCase_v := 5;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);					
				end loop;
			end loop;
			WaitDone(5, Clk);
			wait for DelayBetweenTests;		

			-- *** R Delay only ***	
			DbgPrint(DebugPrints, ">> Read R Delay only");
			TestCase_v := 6;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);				
				end loop;
			end loop;
			WaitDone(6, Clk);
			wait for DelayBetweenTests;		

			-- *** AR and R Delay ***	
			DbgPrint(DebugPrints, ">> Read AR and R Delay");
			TestCase_v := 7;
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyCommand(16#02000000#+offs, size, false, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);					
				end loop;
			end loop;
			WaitDone(7, Clk);
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
			-- *** No Delay  ***
			WaitCase(0, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyWrData(16#10#, size, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
				end loop;
			end loop;	

			-- *** AW Delay only ***
			WaitCase(1, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyWrData(16#10#, size, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
				end loop;
			end loop;	

			-- *** W Delay only ***	
			WaitCase(2, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyWrData(16#10#, size, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
				end loop;
			end loop;	

			-- *** AW and W Delay ***	
			WaitCase(3, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					ApplyWrData(16#10#, size, WrDat_Data, WrDat_Vld, WrDat_Rdy, Clk);
				end loop;
			end loop;				
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** No Delay  ***
			WaitCase(4, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					CheckRdData(16#10#+offs*16, size, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 0 ns, "No Delay s=" & str(size) & ", o=" & str(offs));
				end loop;
			end loop;	

			-- *** AR Delay only ***
			WaitCase(5, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					CheckRdData(16#10#+offs*16, size, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 0 ns, "AR Delay only s=" & str(size) & ", o=" & str(offs));
				end loop;
			end loop;	

			-- *** R Delay only ***	
			WaitCase(6, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					CheckRdData(16#10#+offs*16, size, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 0 ns, "R Delay only s=" & str(size) & ", o=" & str(offs));
				end loop;
			end loop;	

			-- *** AR and R Delay ***	
			WaitCase(7, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					CheckRdData(16#10#+offs*16, size, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 0 ns, "AR and R Delay s=" & str(size) & ", o=" & str(offs));
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
	begin
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** No Delay  ***	
			WaitCase(0, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Wr_Done, Wr_Error, Clk);	
				end loop;
			end loop;
			AllDone_v := 0;
			
			-- *** AW Delay only ***
			WaitCase(1, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Wr_Done, Wr_Error, Clk);	
				end loop;
			end loop;
			AllDone_v := 1;			

			-- *** W Delay only ***	
			WaitCase(2, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Wr_Done, Wr_Error, Clk);	
				end loop;
			end loop;		
			AllDone_v := 2;
			
			-- *** AW and W Delay ***	
			WaitCase(3, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Wr_Done, Wr_Error, Clk);	
				end loop;
			end loop;		
			AllDone_v := 3;			
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** No Delay  ***	
			WaitCase(4, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Rd_Done, Rd_Error, Clk);	
				end loop;
			end loop;
			AllDone_v := 4;
			
			-- *** AR Delay only ***
			WaitCase(5, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Rd_Done, Rd_Error, Clk);	
				end loop;
			end loop;
			AllDone_v := 5;			

			-- *** R Delay only ***	
			WaitCase(6, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Rd_Done, Rd_Error, Clk);	
				end loop;
			end loop;		
			AllDone_v := 6;
			
			-- *** AR and R Delay ***	
			WaitCase(7, Clk);
			for size in 1 to 4 loop
				for offs in 0 to 3 loop
					WaitForCompletion(true, DelayBetweenTests + 50 us, Rd_Done, Rd_Error, Clk);	
				end loop;
			end loop;		
			AllDone_v := 7;			
		end if;		
	end procedure;
	
	procedure axi (
		signal Clk : in std_logic;
		signal axi_ms : in axi_ms_t;
		signal axi_sm : out axi_sm_t;
		constant Generics_c : Generics_t) is
		variable AwDelay, WDelay : time := 0 ns;
		variable ArDelay, RDelay : time := 0 ns;
	begin
		------------------------------------------------------------------
		-- Writes
		------------------------------------------------------------------	
		if Generics_c.ImplWrite_g then
			-- *** No Delay ***
			WaitCase(0, Clk);
			for size in 1 to 4 loop
				AwDelay := 0 ns;
				WDelay := 0 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					CheckAxiWrite(16#02000000#+offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, AwDelay, WDelay);
				end loop;
			end loop;
			
			-- *** AW Delay only ***
			WaitCase(1, Clk);
			for size in 1 to 4 loop
				AwDelay := 1000 ns;
				WDelay := 0 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					CheckAxiWrite(16#02000000#+offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, AwDelay, WDelay);
				end loop;
			end loop;	

			-- *** W Delay only ***	
			WaitCase(2, Clk);
			for size in 1 to 4 loop
				AwDelay := 0 ns;
				WDelay := 1000 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					CheckAxiWrite(16#02000000#+offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, AwDelay, WDelay);
				end loop;
			end loop;	

			-- *** AW and W Delay ***	
			WaitCase(3, Clk);
			for size in 1 to 4 loop
				AwDelay := 0 ns;
				WDelay := 1000 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					CheckAxiWrite(16#02000000#+offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, AwDelay, WDelay);
				end loop;
			end loop;			
		end if;
		
		------------------------------------------------------------------
		-- Reads
		------------------------------------------------------------------	
		if Generics_c.ImplRead_g then
			-- *** No Delay ***
			WaitCase(4, Clk);
			for size in 1 to 4 loop
				ArDelay := 0 ns;
				RDelay := 0 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					DoAxiRead(16#02000000#+offs, 16#10#+offs*16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, ArDelay, RDelay);
				end loop;
			end loop;
			
			-- *** AW Delay only ***
			WaitCase(5, Clk);
			for size in 1 to 4 loop
				ArDelay := 1000 ns;
				RDelay := 0 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					DoAxiRead(16#02000000#+offs, 16#10#+offs*16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, ArDelay, RDelay);
				end loop;
			end loop;	

			-- *** W Delay only ***	
			WaitCase(6, Clk);
			for size in 1 to 4 loop
				ArDelay := 0 ns;
				RDelay := 1000 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					DoAxiRead(16#02000000#+offs, 16#10#+offs*16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, ArDelay, RDelay);
				end loop;
			end loop;	

			-- *** AW and W Delay ***	
			WaitCase(7, Clk);
			for size in 1 to 4 loop
				ArDelay := 0 ns;
				RDelay := 1000 ns;		
				-- Execute transfer
				for offs in 0 to 3 loop	
					DoAxiRead(16#02000000#+offs, 16#10#+offs*16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk, ArDelay, RDelay);
				end loop;
			end loop;			
		end if;		
	end procedure;
	
end;
