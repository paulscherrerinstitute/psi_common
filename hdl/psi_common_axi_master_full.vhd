------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a full AXI master. In contrast to psi_common_axi_master_full,
-- this entity can do unaligned transfers and it supports different width for the 
-- AXI interface than for the data interface. The AXI interface can be wider than
-- the data interface but not vice versa.
-- The flexibility of doing unaligned transfers is paid by lower performance for
-- very small transfers. There is an overhead of some clock cycles per command.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ testcases=simple_tf,axi_hs,user_hs,all_shifts$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_master_full is
	generic 
	(
		AxiAddrWidth_g				: natural range 12 to 64	:= 32;			-- $$ constant=32 $$
		AxiDataWidth_g				: natural range 8 to 1024	:= 32;			-- $$ export=true $$
		AxiMaxBeats_g				: natural range 1 to 256	:= 256;			-- $$ constant=16 $$
		AxiMaxOpenTrasactions_g		: natural range 1 to 8		:= 8;			-- $$ constant=3 $$
		UserTransactionSizeBits_g	: natural					:= 32;			-- $$ constant=10 $$
		DataFifoDepth_g				: natural					:= 1024;		-- $$ constant=10 $$
		DataWidth_g					: natural					:= 32;			-- $$ constant=16 $$
		ImplRead_g					: boolean					:= true;		-- $$ export=true $$
		ImplWrite_g					: boolean					:= true;		-- $$ export=true $$
		RamBehavior_g				: string					:= "RBW"		-- $$ constant="RBW" $$
	);
	port
	(
		-- Control Signals
		M_Axi_Aclk		: in 	std_logic;													-- $$ type=clk; freq=100e6; proc=user_cmd,user_data,user_resp,axi $$
		M_Axi_Aresetn	: in 	std_logic;													-- $$ type=rst; clk=M_Axi_Aclk; lowactive=true $$
		
		-- User Command Interface
		CmdWr_Addr		: in	std_logic_vector(AxiAddrWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_cmd $$
		CmdWr_Size		: in	std_logic_vector(UserTransactionSizeBits_g-1 downto 0)	:= (others => '0');  	-- $$ proc=user_cmd $$
		CmdWr_LowLat	: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdWr_Vld		: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdWr_Rdy		: out	std_logic;																		-- $$ proc=user_cmd $$
		
		-- User Command Interface
		CmdRd_Addr		: in	std_logic_vector(AxiAddrWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_cmd $$
		CmdRd_Size		: in	std_logic_vector(UserTransactionSizeBits_g-1 downto 0)	:= (others => '0');  	-- $$ proc=user_cmd $$
		CmdRd_LowLat	: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdRd_Vld		: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdRd_Rdy		: out	std_logic;																		-- $$ proc=user_cmd $$		
		
		-- Write Data
		WrDat_Data		: in	std_logic_vector(DataWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_data $$
		WrDat_Vld		: in	std_logic												:= '0';					-- $$ proc=user_data $$
		WrDat_Rdy		: out	std_logic;																		-- $$ proc=user_data $$		
    
		-- Read Data
		RdDat_Data		: out	std_logic_vector(DataWidth_g-1 downto 0);										-- $$ proc=user_data $$
		RdDat_Vld		: out	std_logic;																		-- $$ proc=user_data $$
		RdDat_Rdy		: in	std_logic												:= '0';					-- $$ proc=user_data $$			
		
		-- Response
		Wr_Done			: out	std_logic;																		-- $$ proc=user_resp $$
		Wr_Error		: out	std_logic;																		-- $$ proc=user_resp $$
		Rd_Done			: out	std_logic;																		-- $$ proc=user_resp $$
		Rd_Error		: out	std_logic;																		-- $$ proc=user_resp $$
		
		-- AXI Address Write Channel
		M_Axi_AwAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);									-- $$ proc=axi $$
		M_Axi_AwLen		: out	std_logic_vector(7 downto 0);													-- $$ proc=axi $$
		M_Axi_AwSize	: out	std_logic_vector(2 downto 0);													-- $$ proc=axi $$
		M_Axi_AwBurst	: out	std_logic_vector(1 downto 0);													-- $$ proc=axi $$
		M_Axi_AwLock	: out	std_logic;																		-- $$ proc=axi $$
		M_Axi_AwCache	: out	std_logic_vector(3 downto 0);													-- $$ proc=axi $$
		M_Axi_AwProt	: out	std_logic_vector(2 downto 0);													-- $$ proc=axi $$
		M_Axi_AwValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_AwReady	: in	std_logic                                             	:= '0';			     	-- $$ proc=axi $$
    
		-- AXI Write Data Channel                                                           					-- $$ proc=axi $$
		M_Axi_WData		: out	std_logic_vector(AxiDataWidth_g-1 downto 0);                					-- $$ proc=axi $$
		M_Axi_WStrb		: out	std_logic_vector(AxiDataWidth_g/8-1 downto 0);              					-- $$ proc=axi $$
		M_Axi_WLast		: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_WValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_WReady	: in	std_logic                                              := '0';				    -- $$ proc=axi $$
    
		-- AXI Write Response Channel                                                      
		M_Axi_BResp		: in	std_logic_vector(1 downto 0)                           := (others => '0');	    -- $$ proc=axi $$
		M_Axi_BValid	: in	std_logic                                              := '0';				    -- $$ proc=axi $$
		M_Axi_BReady	: out	std_logic;                                                  					-- $$ proc=axi $$
    
		-- AXI Read Address Channel                                               
		M_Axi_ArAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);                					-- $$ proc=axi $$
		M_Axi_ArLen		: out	std_logic_vector(7 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArSize	: out	std_logic_vector(2 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArBurst	: out	std_logic_vector(1 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArLock	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_ArCache	: out	std_logic_vector(3 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArProt	: out	std_logic_vector(2 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_ArReady	: in	std_logic                                           	:= '0';					-- $$ proc=axi $$
    
		-- AXI Read Data Channel                                                      
		M_Axi_RData		: in	std_logic_vector(AxiDataWidth_g-1 downto 0)             := (others => '0');    	-- $$ proc=axi $$
		M_Axi_RResp		: in	std_logic_vector(1 downto 0)                            := (others => '0');	    -- $$ proc=axi $$
		M_Axi_RLast		: in	std_logic                                               := '0';				    -- $$ proc=axi $$
		M_Axi_RValid	: in	std_logic                                               := '0';				    -- $$ proc=axi $$
		M_Axi_RReady	: out	std_logic		                                         						-- $$ proc=axi $$
	);	
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_axi_master_full is 

	------------------------------------------------------------------------------
	-- Constants
	------------------------------------------------------------------------------	
	constant AxiBytes_c		: natural 	:= AxiDataWidth_g/8;
	constant DataBytes_c	: natural	:= DataWidth_g/8;
	
	
	------------------------------------------------------------------------------
	-- Type
	------------------------------------------------------------------------------	
	type WriteCmdFsm_t is (Idle_s, Apply_s);
	type WriteWconvFsm_t is (Idle_s, Transfer_s);
	type WriteAlignFsm_t is (Idle_s, Transfer_s, Last_s);
	
	------------------------------------------------------------------------------
	-- Functions
	------------------------------------------------------------------------------	
	function AlignedAddr_f(	Addr 	: in unsigned(AxiAddrWidth_g-1 downto 0)) 
							return unsigned is
		variable Addr_v : unsigned(Addr'range) := (others => '0');
	begin
		Addr_v(Addr'left downto log2(AxiBytes_c)) := Addr(Addr'left downto log2(AxiBytes_c));
		return Addr_v;		
	end function;
	
	------------------------------------------------------------------------------
	-- Two Process Record
	------------------------------------------------------------------------------		
	type two_process_r is record
	
		-- *** Write Related Registers ***
		WrCmdFsm		: WriteCmdFsm_t;
		WrLastAddr		: unsigned(AxiAddrWidth_g-1 downto 0);
		CmdWr_Rdy		: std_logic;
		AxiWrCmd_Addr	: std_logic_vector(AxiAddrWidth_g-1 downto 0);
		AxiWrCmd_Size	: std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
		AxiWrCmd_LowLat	: std_logic;
		AxiWrCmd_Vld	: std_logic;
		WrWconvFsm		: WriteWconvFsm_t;
		WrStartTf		: std_logic;
		WrWordsDone		: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrDataWordsCmd	: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrDataWordsWc	: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrAlignFsm		: WriteAlignFsm_t;
		WrAlignReg		: std_logic_vector(AxiDataWidth_g*2-1 downto 0);
		WrAlignBe		: std_logic_vector(AxiBytes_c*2-1 downto 0);		
		WrShift			: unsigned(log2(AxiBytes_c)-1 downto 0);	
		WrAlignVld		: std_logic;
		AxiWordCnt		: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrLastBe		: std_logic_vector(AxiBytes_c-1 downto 0);

		
		-- *** Read Related Registers *** 

		
	end record;
	signal r, r_next : two_process_r;
		
	
	------------------------------------------------------------------------------
	-- Instantiation Signals
	------------------------------------------------------------------------------
	signal Rst				: std_logic;
	signal WrFifo_Data		: std_logic_vector(WrDat_Data'range);
	signal WrFifo_Vld		: std_logic;
	signal AxiWrCmd_Rdy		: std_logic;
	signal AxiWrDat_Rdy		: std_logic;
	signal AxiWrDat_Data	: std_logic_vector(AxiDataWidth_g-1 downto 0);
	signal WrFifo_Rdy		: std_logic;
	signal AxiWrDat_Be		: std_logic_vector(AxiBytes_c-1 downto 0);
	
	signal WrWconvEna		: std_logic;
	signal WrWconv_Vld		: std_logic;
	signal WrWconv_Rdy		: std_logic;
	signal WrWconv_Last		: std_logic;
	signal WrData_Vld		: std_logic;
	signal WrData_Data		: std_logic_vector(AxiDataWidth_g-1 downto 0);
	signal WrData_Last		: std_logic;
	signal WrData_We		: std_logic_vector(AxiBytes_c/DataBytes_c-1 downto 0);
	signal WrData_Rdy		: std_logic;
	signal WrDataEna		: std_logic;
	
begin
	
	------------------------------------------------------------------------------
	-- Assertions
	------------------------------------------------------------------------------
	assert AxiDataWidth_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full AxiDataWidth_g must be a multiple of 8" severity failure;
	assert DataWidth_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full DataWidth_g must be a multiple of 8" severity failure;
	assert AxiDataWidth_g mod DataWidth_g = 0 report "###ERROR###: psi_common_axi_master_full AxiDataWidth_g must be a multiple of DataWidth_g" severity failure;
	
	
	------------------------------------------------------------------------------
	-- Combinatorial Process
	------------------------------------------------------------------------------	
	p_comb : process(	r,
						CmdWr_Addr, CmdWr_Size, CmdWr_Vld, CmdWr_LowLat,
						AxiWrCmd_Rdy, AxiWrDat_Rdy,
						WrWconv_Rdy, WrFifo_Vld,
						WrData_Vld, WrData_Data, WrData_Last, WrData_We)
		variable v 					: two_process_r;
		variable WriteBe_v			: std_logic_vector(AxiBytes_c-1 downto 0);
	begin
		-- *** Keep two process variables stable ***
		v := r;
		
		--------------------------------------------------------------------------
		-- Write Related Code
		--------------------------------------------------------------------------	
		if ImplWrite_g then
		
			-- *** Command FSM ***
			v.WrStartTf	:= '0';
			v.AxiWrCmd_Vld	:= '0';
			case r.WrCmdFsm is
			
				when Idle_s =>
					v.CmdWr_Rdy			:= '1';
					v.WrLastAddr		:= unsigned(CmdWr_Addr) + unsigned(CmdWr_Size) - 1;
					if unsigned(CmdWr_Size(log2(DataBytes_c)-1 downto 0)) = 0 then
						v.WrDataWordsCmd	:= resize(unsigned(CmdWr_Size(CmdWr_Size'high downto log2(DataBytes_c))), UserTransactionSizeBits_g);
					else
						v.WrDataWordsCmd	:= resize(unsigned(CmdWr_Size(CmdWr_Size'high downto log2(DataBytes_c)))+1, UserTransactionSizeBits_g);
					end if;
					v.AxiWrCmd_Addr		:= std_logic_vector(AlignedAddr_f(unsigned(CmdWr_Addr)));
					v.WrShift			:= unsigned(CmdWr_Addr(v.WrShift'range));
					v.AxiWrCmd_LowLat	:= CmdWr_LowLat;
					if CmdWr_Vld = '1' then
						v.CmdWr_Rdy		:= '0';
						v.WrCmdFsm		:= Apply_s;						
					end if;
					
				when Apply_s =>
					v.WrStartTf	:= '1';
					v.AxiWrCmd_Vld	:= '1';
					if AxiWrCmd_Rdy = '1' and r.WrWconvFsm = Idle_s and r.WrAlignFsm = Idle_s then
						v.WrCmdFsm		:= Idle_s;
						v.CmdWr_Rdy		:= '1';
						v.AxiWrCmd_Size	:= std_logic_vector(resize(shift_right(AlignedAddr_f(r.WrLastAddr) - unsigned(r.AxiWrCmd_Addr), log2(AxiBytes_c))+1, UserTransactionSizeBits_g));
						-- Calculate byte enables for last word
						for byte in 0 to AxiBytes_c-1 loop
							if r.WrLastAddr(log2(AxiBytes_c)-1 downto 0) >= byte then
								v.WrLastBe(byte)	:= '1';
							else	
								v.WrLastBe(byte)	:= '0';
							end if;
						end loop;
					end if;					
				
				when others => null;
			
			end case;
			
			-- *** With Conversion FSM ***
			WrWconvEna	<= '0';
			WrWconv_Last <= '0';
			case r.WrWconvFsm is 
			
				when Idle_s =>
					v.WrWordsDone		:= to_unsigned(1, v.WrWordsDone'length);
					v.WrDataWordsWc	:= r.WrDataWordsCmd;
					if r.WrStartTf = '1' then
						v.WrWconvFsm 	:= Transfer_s;	
					end if;
									
				when Transfer_s =>
					WrWconvEna <= '1';
					if r.WrWordsDone = r.WrDataWordsWc then
						WrWconv_Last	<= '1';
					end if;		
					if (WrWconv_Rdy = '1') and (WrFifo_Vld = '1') then
						v.WrWordsDone := r.WrWordsDone + 1;
						if r.WrWordsDone = r.WrDataWordsWc then
							v.WrWconvFsm 	:= Idle_s;	
						end if;
					end if;
				
				when others => null;				
			end case;
			
			-- *** Alignment FSM ***
			-- Initial values
			WrDataEna <= '0';
			v.WrAlignVld := '0';
			-- Word- to Byte-Enable conversion
			for i in 0 to AxiBytes_c-1 loop
				WriteBe_v(i)	:= WrData_We(i/(AxiDataWidth_g/DataWidth_g));
			end loop;
			-- FSM
			case r.WrAlignFsm is
				when Idle_s =>				
					v.WrAlignReg 	:= (others => '0');
					v.WrAlignBe		:= (others => '0');
					v.AxiWordCnt	:= to_unsigned(1, v.AxiWordCnt'length);
					if r.WrStartTf = '1' then
						v.WrAlignFsm := Transfer_s;
					end if;
					
				when Transfer_s =>
					WrDataEna <= '1';
					if (AxiWrDat_Rdy = '1') and (WrData_Vld = '1') then
						-- Shift
						v.WrAlignReg(AxiDataWidth_g-1 downto 0)	:= r.WrAlignReg(r.WrAlignReg'left downto AxiDataWidth_g);
						v.WrAlignBe(AxiBytes_c-1 downto 0)		:= r.WrAlignBe(r.WrAlignBe'left downto AxiBytes_c);
						-- New Data
						v.WrAlignReg((to_integer(r.WrShift)+AxiBytes_c)*8-1 downto to_integer(r.WrShift)*8) := WrData_Data;
						v.WrAlignBe(to_integer(r.WrShift)+AxiBytes_c-1 downto to_integer(r.WrShift)) := WriteBe_v;
						-- Flow control
						v.WrAlignVld	:= '1';
						if r.AxiWordCnt = unsigned(r.AxiWrCmd_Size) then
							v.WrAlignFsm := Last_s;
							v.WrAlignBe(AxiBytes_c-1 downto 0) := v.WrAlignBe(AxiBytes_c-1 downto 0) and r.WrLastBe;
						end if;						
					end if;
					
				when Last_s =>
					v.WrAlignVld	:= '1';
					if AxiWrDat_Rdy = '1' then
						v.WrAlignVld	:= '0';
						v.WrAlignFsm := Idle_s;
					end if;				
					
				when others => null;	
			end case;
					
		end if;
		
		--------------------------------------------------------------------------
		-- Read Related Code
		--------------------------------------------------------------------------	
		if ImplRead_g then
		end if;
		
		
		-- *** Update Signal ***
		r_next <= v;
	end process;
	
	------------------------------------------------------------------------------
	-- Registered Process
	------------------------------------------------------------------------------
	p_reg : process(M_Axi_Aclk)
	begin
		if rising_edge(M_Axi_Aclk) then
			r <= r_next;
			if M_Axi_Aresetn = '0' then
				-- *** Write Related Registers ***
				if ImplWrite_g then
					r.WrCmdFsm 		<= Idle_s;
					r.CmdWr_Rdy		<= '0';
					r.AxiWrCmd_Vld	<= '0';
					r.WrWconvFsm	<= Idle_s;
					r.WrStartTf		<= '0';
					r.WrAlignFsm	<= Idle_s;
					r.WrAlignVld	<= '0';
				end if;
				-- *** Read Related Registers ***
				if ImplRead_g then

				end if;
			end if;
		end if;
	end process;
	
	------------------------------------------------------------------------------
	-- Outputs
	------------------------------------------------------------------------------		
	CmdWr_Rdy	<= r.CmdWr_Rdy;

	
	------------------------------------------------------------------------------
	-- Constant Outputs
	------------------------------------------------------------------------------	
	
	------------------------------------------------------------------------------
	-- Instantiations
	------------------------------------------------------------------------------
	Rst <= not M_Axi_Aresetn;
	
	-- AXI Master Interface
	AxiWrDat_Data 	<= r.WrAlignReg(AxiWrDat_Data'range);
	AxiWrDat_Be		<= r.WrAlignBe(AxiWrDat_Be'range);
	i_axi : entity work.psi_common_axi_master_simple
		generic  map
		(
			AxiAddrWidth_g				=> AxiAddrWidth_g,
			AxiDataWidth_g				=> AxiDataWidth_g,
			AxiMaxBeats_g				=> AxiMaxBeats_g,
			AxiMaxOpenTrasactions_g		=> AxiMaxOpenTrasactions_g,
			UserTransactionSizeBits_g	=> UserTransactionSizeBits_g,
			DataFifoDepth_g				=> AxiMaxBeats_g*2,
			ImplRead_g					=> ImplRead_g,
			ImplWrite_g					=> ImplWrite_g,
			RamBehavior_g				=> RamBehavior_g
		)
		port map
		(
			-- Control Signals
			M_Axi_Aclk		=> M_Axi_Aclk,
			M_Axi_Aresetn	=> M_Axi_Aresetn,
			-- User Command Interface
			CmdWr_Addr		=> r.AxiWrCmd_Addr,
			CmdWr_Size		=> r.AxiWrCmd_Size,
			CmdWr_LowLat	=> r.AxiWrCmd_LowLat,
			CmdWr_Vld		=> r.AxiWrCmd_Vld,
			CmdWr_Rdy		=> AxiWrCmd_Rdy,			
			-- User Command Interface
			CmdRd_Addr		=> (others => '0'), 	-- TODO
			CmdRd_Size		=> (others => '0'), 	-- TODO
			CmdRd_LowLat	=> '0',					-- TODO
			CmdRd_Vld		=> '0',					-- TODO
			CmdRd_Rdy		=> open,				-- TODO		
			-- Write Data
			WrDat_Data		=> AxiWrDat_Data,
			WrDat_Be		=> AxiWrDat_Be,
			WrDat_Vld		=> r.WrAlignVld,
			WrDat_Rdy		=> AxiWrDat_Rdy,
			-- Read Data
			RdDat_Data		=> open,				-- TODO
			RdDat_Vld		=> open,				-- TODO
			RdDat_Rdy		=> '0',					-- TODO
			-- Response
			Wr_Done			=> Wr_Done,
			Wr_Error		=> Wr_Error,
			Rd_Done			=> Rd_Done,
			Rd_Error		=> Rd_Error,			
			-- AXI Address Write Channel
			M_Axi_AwAddr	=> M_Axi_AwAddr,
			M_Axi_AwLen		=> M_Axi_AwLen,
			M_Axi_AwSize	=> M_Axi_AwSize,
			M_Axi_AwBurst	=> M_Axi_AwBurst,
			M_Axi_AwLock	=> M_Axi_AwLock,
			M_Axi_AwCache	=> M_Axi_AwCache,
			M_Axi_AwProt	=> M_Axi_AwProt,
			M_Axi_AwValid	=> M_Axi_AwValid,
			M_Axi_AwReady	=> M_Axi_AwReady,
			-- AXI Write Data Channel
			M_Axi_WData		=> M_Axi_WData,	
			M_Axi_WStrb		=> M_Axi_WStrb,	
			M_Axi_WLast		=> M_Axi_WLast,
			M_Axi_WValid	=> M_Axi_WValid,
			M_Axi_WReady	=> M_Axi_WReady,
			-- AXI Write Response Channel                                                      
			M_Axi_BResp		=> M_Axi_BResp,	
			M_Axi_BValid	=> M_Axi_BValid,
			M_Axi_BReady	=> M_Axi_BReady,
			-- AXI Read Address Channel                                               
			M_Axi_ArAddr	=> M_Axi_ArAddr,
			M_Axi_ArLen		=> M_Axi_ArLen,	
			M_Axi_ArSize	=> M_Axi_ArSize,
			M_Axi_ArBurst	=> M_Axi_ArBurst,
			M_Axi_ArLock	=> M_Axi_ArLock,
			M_Axi_ArCache	=> M_Axi_ArCache,
			M_Axi_ArProt	=> M_Axi_ArProt,
			M_Axi_ArValid	=> M_Axi_ArValid,
			M_Axi_ArReady	=> M_Axi_ArReady,
			-- AXI Read Data Channel                                                      
			M_Axi_RData		=> M_Axi_RData,	
			M_Axi_RResp		=> M_Axi_RResp,	
			M_Axi_RLast		=> M_Axi_RLast,	
			M_Axi_RValid	=> M_Axi_RValid,
			M_Axi_RReady	=> M_Axi_RReady
		);	
		
	-- Write Data FIFO	
	WrFifo_Rdy	<= WrWconv_Rdy and WrWconvEna;
	fifo_wr_data : entity work.psi_common_sync_fifo
		generic map (
			Width_g			=> DataWidth_g,
			Depth_g			=> DataFifoDepth_g,
			AlmFullOn_g		=> false,
			AlmEmptyOn_g	=> false,
			RamStyle_g		=> "auto",
			RamBehavior_g	=> RamBehavior_g
		)
		port map (
			Clk		=> M_Axi_Aclk,
			Rst		=> Rst,
			InData	=> WrDat_Data,
			InVld	=> WrDat_Vld,
			InRdy	=> WrDat_Rdy,
			OutData	=> WrFifo_Data,
			OutVld	=> WrFifo_Vld,
			OutRdy	=> WrFifo_Rdy
		);	
		
	-- Write Data With Conversion
	WrWconv_Vld <= WrWconvEna and WrFifo_Vld;
	WrData_Rdy <= AxiWrDat_Rdy and WrDataEna;
	wc_wr : entity work.psi_common_wconv_n2xn
		generic map (
			InWidth_g	=> DataWidth_g,
			OutWidth_g	=> AxiDataWidth_g
		)
		port map (
			Clk			=> M_Axi_Aclk,
			Rst			=> Rst,
			InVld		=> WrWconv_Vld,
			InRdy		=> WrWconv_Rdy,
			InData		=> WrFifo_Data,
			InLast		=> WrWconv_Last,
			OutVld		=> WrData_Vld,
			OutRdy		=> WrData_Rdy,
			OutData		=> WrData_Data,
			OutLast		=> WrData_Last,
			OutWe		=> WrData_We
		);

	
	-- Read Data FIFO
	fifo_rd_data : entity work.psi_common_sync_fifo
	generic map (
		Width_g			=> DataWidth_g,
		Depth_g			=> DataFifoDepth_g,
		AlmFullOn_g		=> false,
		AlmEmptyOn_g	=> false,
		RamStyle_g		=> "auto",
		RamBehavior_g	=> RamBehavior_g
	)
	port map (
		Clk		=> M_Axi_Aclk,
		Rst		=> Rst,
		InData	=> (others => '0'),		-- TODO
		InVld	=> '0',					-- TODO
		InRdy	=> open,				-- TODO
		OutData	=> RdDat_Data,
		OutVld	=> RdDat_Vld,
		OutRdy	=> RdDat_Rdy
	);
 
end rtl;
