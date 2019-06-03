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
	use work.psi_tb_txt_util.all;
	use work.psi_tb_compare_pkg.all;
	use work.psi_tb_activity_pkg.all;
	use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_full_tb_pkg is
	
	-- *** Generics Record ***
	type Generics_t is record
		DataWidth_g : natural;
		ImplRead_g : boolean;
		ImplWrite_g : boolean;
	end record;
	
	------------------------------------------------------------
	-- Not exported Generics
	------------------------------------------------------------
	constant AxiAddrWidth_g : natural := 32;
	constant DataFifoDepth_g : natural := 10;
	constant UserTransactionSizeBits_g : natural := 10;
	constant RamBehavior_g : string := "RBW";
	constant AxiMaxOpenTrasactions_g : natural := 3;
	constant AxiMaxBeats_g : natural := 16;
	constant AxiDataWidth_g : natural := 32;
	
	------------------------------------------------------------
	-- Axi
	------------------------------------------------------------
	constant ID_WIDTH 		: integer 	:= 1;
	constant ADDR_WIDTH 	: integer	:= 32;
	constant USER_WIDTH		: integer	:= 1;
	constant DATA_WIDTH		: integer	:= 32;
	constant BYTE_WIDTH		: integer	:= DATA_WIDTH/8;
	
	subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
	subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
	subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
	subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
	subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
	
	subtype axi_ms_t is axi_ms_r (	arid(ID_RANGE), awid(ID_RANGE),
								araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
								aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
								wdata(DATA_RANGE),
								wstrb(BYTE_RANGE));
	
	subtype axi_sm_t is axi_sm_r (	rid(ID_RANGE), bid(ID_RANGE),
								ruser(USER_RANGE), buser(USER_RANGE),
								rdata(DATA_RANGE));	
								
	------------------------------------------------------------
	-- Procedures
	------------------------------------------------------------

	procedure ApplyCommand(			Addr		: in	integer;
									Size		: in	integer;
									LowLat		: in	boolean;
							signal	CmdX_Addr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);
							signal 	CmdX_Size	: out	std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
							signal	CmdX_LowLat	: out	std_logic;
							signal	CmdX_Vld	: out 	std_logic;
							signal	CmdX_Rdy	: in	std_logic;
							signal	Clk			: in	std_logic);			

	procedure ApplyWrDataSingle(	Data		: in	integer;
							signal	WrDat_Data	: out	std_logic_vector;
							signal	WrDat_Vld	: out	std_logic;
							signal	WrDat_Rdy	: in	std_logic;
							signal	Clk			: in	std_logic);		

	procedure WaitForCompletion(	Success		: in	boolean;
									WaitTime	: in	time;
							signal	X_Done		: in	std_logic;
							signal	X_Error		: in	std_logic;
							signal	Clk			: in	std_logic);		

	procedure AxiCheckWrSingle(		Addr		: in	integer;
									Data		: in	integer;
									Be			: in	integer;
									Resp		: in	std_logic_vector;
							signal 	axi_ms 		: in axi_ms_t;
							signal 	axi_sm 		: out axi_sm_t;
							signal 	Clk 		: in std_logic;
									AxiDataWidth: in	integer;
									SendResp	: in	boolean := true);	

	procedure DbgPrint(	Enable 	: in boolean;
						Str		: in string);									
	
	
end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_pkg is

	function AxSize(	AxiDataWidth : integer) return std_logic_vector is
	begin
		if AxiDataWidth = 16 then
			return AxSIZE_2_c;
		elsif AxiDataWidth = 32 then
			return AxSIZE_4_c;
		else
			assert false report "###ERROR###: AxSize - Illegal AxiDataWidth" severity error;
			return "0";
		end if;
	end function;
	

	procedure ApplyCommand(			Addr		: in	integer;
									Size		: in	integer;
									LowLat		: in	boolean;
							signal	CmdX_Addr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);
							signal 	CmdX_Size	: out	std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
							signal	CmdX_LowLat	: out	std_logic;
							signal	CmdX_Vld	: out 	std_logic;
							signal	CmdX_Rdy	: in	std_logic;
							signal	Clk			: in	std_logic) is
	begin
		wait until rising_edge(Clk);
		CmdX_Addr <= std_logic_vector(to_unsigned(Addr, CmdX_Addr'length));
		CmdX_Size <= std_logic_vector(to_unsigned(Size, CmdX_Size'length));
		if LowLat then
			CmdX_LowLat <= '1';
		else
			CmdX_LowLat <= '0';
		end if;
		CmdX_Vld <= '1';
		wait until rising_edge(Clk) and CmdX_Rdy = '1';
		CmdX_Vld <= '0';
	end procedure;	
	
	procedure ApplyWrDataSingle(	Data		: in	integer;
							signal	WrDat_Data	: out	std_logic_vector;
							signal	WrDat_Vld	: out	std_logic;
							signal	WrDat_Rdy	: in	std_logic;
							signal	Clk			: in	std_logic) is
	begin
		WrDat_Data <= std_logic_vector(to_unsigned(Data, WrDat_Data'length));
		WrDat_Vld <= '1';
		wait until rising_edge(Clk) and WrDat_Rdy = '1';
		WrDat_Vld <= '0';	
	end procedure;	
	
	procedure WaitForCompletion(	Success		: in	boolean;
									WaitTime	: in	time;
							signal	X_Done		: in	std_logic;
							signal	X_Error		: in	std_logic;
							signal	Clk			: in	std_logic) is
	begin	
		if Success then
			wait until rising_edge(Clk) and X_Done = '1' for WaitTime;
			StdlCompare(1, X_Done, "No Done");
		else
			wait until rising_edge(Clk) and X_Error = '1' for WaitTime;
			StdlCompare(1, X_Error, "No Error");
		end if;
	end procedure;	
	
	procedure AxiCheckWrSingle(		Addr		: in	integer;
									Data		: in	integer;
									Be			: in	integer;
									Resp		: in	std_logic_vector;
							signal 	axi_ms 		: in 	axi_ms_t;
							signal 	axi_sm 		: out 	axi_sm_t;
							signal 	Clk 		: in 	std_logic;
									AxiDataWidth: in	integer;
									SendResp	: in	boolean := true) is
	begin	
		axi_expect_aw(	Addr, AxSize(AxiDataWidth), 1-1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
		axi_expect_wd_single(std_logic_vector(to_unsigned(Data, AxiDataWidth_g)), std_logic_vector(to_unsigned(Be, AxiDataWidth/8)), axi_ms, axi_sm, Clk);
		if SendResp then
			axi_apply_bresp(Resp, axi_ms, axi_sm, Clk);
		end if;
	end procedure;	
	
	procedure DbgPrint(	Enable 	: in boolean;
						Str		: in string) is
	begin
		if Enable then
			Print(Str);
		end if;
	end procedure;	
end;
