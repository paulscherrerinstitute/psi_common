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

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_simple_tb_case_split is
	
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
		signal axi_ms : axi_ms_t;
		signal axi_sm : axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t);
		
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_split is
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
		assert false report "Case SPLIT Procedure USER_CMD: No Content added yet!" severity warning;
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
		assert false report "Case SPLIT Procedure USER_DATA: No Content added yet!" severity warning;
	end procedure;
	
	procedure user_resp (
		signal Wr_Done : in std_logic;
		signal Wr_Error : in std_logic;
		signal Rd_Done : in std_logic;
		signal Rd_Error : in std_logic;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		assert false report "Case SPLIT Procedure USER_RESP: No Content added yet!" severity warning;
	end procedure;
	
	procedure axi (
		signal axi_ms : axi_ms_t;
		signal axi_sm : axi_sm_t;
		signal Clk : in std_logic;
		constant Generics_c : Generics_t) is
	begin
		assert false report "Case SPLIT Procedure AXI: No Content added yet!" severity warning;
	end procedure;
	
end;
