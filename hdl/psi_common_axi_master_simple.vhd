------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple AXI master. Simple means: It does not 
-- support any unaligned reads/writes and it does not do any width conversions.
-- It just executes the transfers requested and splits them into multiple AXI
-- transactions in order to not burst over 4k boundaries and respect the maximum
-- transaction size.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;
	
		-- TODO: EnableRead
		-- TODO: EnableWrite

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ testcases=simple_tf,max_transact,axi_hs,split,internals,highlat$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_master_simple is
	generic 
	(
		AxiAddrWidth_g				: natural range 12 to 64	:= 32;			-- $$ constant=32 $$
		AxiDataWidth_g				: natural range 8 to 1024	:= 32;			-- $$ constant=16 $$
		AxiMaxBeats_g				: natural range 1 to 256	:= 256;			-- $$ constant=16 $$
		AxiMaxOpenTrasactions_g		: natural range 1 to 8		:= 8;			-- $$ constant=3 $$
		UserTransactionSizeBits_g	: natural					:= 32;			-- $$ constant=10 $$
		DataFifoDepth_g				: natural					:= 1024;		-- $$ constant=10 $$
		RamBehavior_g				: string					:= "RBW"		-- $$ constant="RBW" $$
	);
	port
	(
		-- Control Signals
		M_Axi_Aclk		: in 	std_logic;													-- $$ type=clk; freq=100e6 $$
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
		WrDat_Data		: in	std_logic_vector(AxiDataWidth_g-1 downto 0);				-- $$ proc=user_data $$
		WrDat_Be		: in	std_logic_vector(AxiDataWidth_g/8-1 downto 0);				-- $$ proc=user_data $$
		WrDat_Vld		: in	std_logic;													-- $$ proc=user_data $$
		WrDat_Rdy		: out	std_logic;													-- $$ proc=user_data $$		
    
		-- Read Data
		RdDat_Data		: out	std_logic_vector(AxiDataWidth_g-1 downto 0);				-- $$ proc=user_data $$
		RdDat_Vld		: out	std_logic;													-- $$ proc=user_data $$
		RdDat_Rdy		: in	std_logic;													-- $$ proc=user_data $$			
		
		-- Response
		Wr_Done			: out	std_logic;													-- $$ proc=user_resp $$
		Wr_Error		: out	std_logic;													-- $$ proc=user_resp $$
		Rd_Done			: out	std_logic;													-- $$ proc=user_resp $$
		Rd_Error		: out	std_logic;													-- $$ proc=user_resp $$
		
		-- AXI Address Write Channel
		M_Axi_AwAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);				-- $$ proc=axi $$
		M_Axi_AwLen		: out	std_logic_vector(7 downto 0);								-- $$ proc=axi $$
		M_Axi_AwSize	: out	std_logic_vector(2 downto 0);								-- $$ proc=axi $$
		M_Axi_AwBurst	: out	std_logic_vector(1 downto 0);								-- $$ proc=axi $$
		M_Axi_AwLock	: out	std_logic;													-- $$ proc=axi $$
		M_Axi_AwCache	: out	std_logic_vector(3 downto 0);								-- $$ proc=axi $$
		M_Axi_AwProt	: out	std_logic_vector(2 downto 0);								-- $$ proc=axi $$
		M_Axi_AwValid	: out	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_AwReady	: in	std_logic;                                                  -- $$ proc=axi $$
    
		-- AXI Write Data Channel                                                           -- $$ proc=axi $$
		M_Axi_WData		: out	std_logic_vector(AxiDataWidth_g-1 downto 0);                -- $$ proc=axi $$
		M_Axi_WStrb		: out	std_logic_vector(AxiDataWidth_g/8-1 downto 0);              -- $$ proc=axi $$
		M_Axi_WLast		: out	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_WValid	: out	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_WReady	: in	std_logic;                                                  -- $$ proc=axi $$
    
		-- AXI Write Response Channel                                                       -- $$ proc=axi $$
		M_Axi_BResp		: in	std_logic_vector(1 downto 0);                               -- $$ proc=axi $$
		M_Axi_BValid	: in	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_BReady	: out	std_logic;                                                  -- $$ proc=axi $$
    
		-- AXI Read Address Channel                                                         -- $$ proc=axi $$
		M_Axi_ArAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);                -- $$ proc=axi $$
		M_Axi_ArLen		: out	std_logic_vector(7 downto 0);                               -- $$ proc=axi $$
		M_Axi_ArSize	: out	std_logic_vector(2 downto 0);                               -- $$ proc=axi $$
		M_Axi_ArBurst	: out	std_logic_vector(1 downto 0);                               -- $$ proc=axi $$
		M_Axi_ArLock	: out	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_ArCache	: out	std_logic_vector(3 downto 0);                               -- $$ proc=axi $$
		M_Axi_ArProt	: out	std_logic_vector(2 downto 0);                               -- $$ proc=axi $$
		M_Axi_ArValid	: out	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_ArReady	: in	std_logic;                                                  -- $$ proc=axi $$
    
		-- AXI Read Data Channel                                                            -- $$ proc=axi $$
		M_Axi_RData		: in	std_logic_vector(AxiDataWidth_g-1 downto 0);                -- $$ proc=axi $$
		M_Axi_RResp		: in	std_logic_vector(1 downto 0);                               -- $$ proc=axi $$
		M_Axi_RLast		: in	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_RValid	: in	std_logic;                                                  -- $$ proc=axi $$
		M_Axi_RReady	: out	std_logic		                                            -- $$ proc=axi $$
	);
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_axi_master_simple is 

	------------------------------------------------------------------------------
	-- Constants
	------------------------------------------------------------------------------	
	constant Axi_BurstType_Incr_c	: std_logic_vector(1 downto 0)	:= "01";
	constant Axi_Resp_Okay_c 		: std_logic_vector(1 downto 0) 	:= "00";
	constant UnusedAddrBits_c		: natural	:= log2(AxiDataWidth_g/8);
	
	subtype Trans_AddrRange_c 	is natural range CmdWr_Addr'high downto 0;
	subtype Trans_BurstRange_c	is natural range 9+Trans_AddrRange_c'high downto Trans_AddrRange_c'high+1;
	constant Trans_LowLatIdx_c	: natural	:= Trans_BurstRange_c'high+1;
	constant Trans_Size_c		: natural	:= Trans_LowLatIdx_c+1;
	
	------------------------------------------------------------------------------
	-- Type
	------------------------------------------------------------------------------	
	type WriteTfGen_s is (Idle_s, MaxCalc_s, GenTf_s, WriteTf_s);
	type AwFsm_s is (Idle_s, Wait_s);
	
	------------------------------------------------------------------------------
	-- Functions
	------------------------------------------------------------------------------	
	function AddrMasked_f (	Addr : in std_logic_vector) return std_logic_vector is
		variable Masked_v : std_logic_vector(Addr'range);
	begin
		Masked_v := Addr;
		Masked_v(UnusedAddrBits_c-1 downto 0) := (others => '0');
		return Masked_v;
	end function;
	
	------------------------------------------------------------------------------
	-- Two Process Record
	------------------------------------------------------------------------------		
	type two_process_r is record
		-- Generate Write Transactions
		CmdWr_Rdy		: std_logic;
		WriteTfGenState	: WriteTfGen_s;
		WrAddr			: unsigned(CmdWr_Addr'range);
		WrBeats			: unsigned(CmdWr_Size'range);
		WrLowLat		: std_logic;
		WrMaxBeats		: unsigned(8 downto 0);
		WrTfBeats		: unsigned(8 downto 0);
		WrTfVld			: std_logic;
		WrTfIsLast		: std_logic;
		-- Execute Aw Commands
		AwFsm 			: AwFsm_s;
		AwFsmRdy		: std_logic;
		-- Execute W Data
		WDataFifoRd		: std_logic;
		WDataEna		: std_logic;
		WDataBeats		: unsigned(8 downto 0);
		-- Write Response
		WrRespError		: std_logic;
		-- Write General
		WrOpenTrans		: integer range 0 to AxiMaxOpenTrasactions_g;
		-- AXI Signals
		M_Axi_AwAddr	: std_logic_vector(M_Axi_AwAddr'range);
		M_Axi_AwLen		: std_logic_vector(M_Axi_AwLen'range);
		M_Axi_AwValid	: std_logic;
		M_Axi_WLast		: std_logic;
		Wr_Error		: std_logic;
		Wr_Done			: std_logic;
	end record;
	signal r, r_next : two_process_r;
		
	
	------------------------------------------------------------------------------
	-- Instantiation Signals
	------------------------------------------------------------------------------
	signal Rst				: std_logic;
	signal WrDataFifoLevel	: std_logic_vector(log2ceil(DataFifoDepth_g) downto 0);
	signal WrDataFifoORdy	: std_logic;
	signal WrDataFifoOVld	: std_logic;
	signal WrTransFifoInVld	: std_logic;
	signal WrTransFifoBeats	: std_logic_vector(8 downto 0);
	signal WrTransFifoOutVld: std_logic;
	signal WrRespIsLast		: std_logic;
	signal WrRespFifoVld	: std_logic;
	
begin
	CmdRd_Rdy <= '0';
	RdDat_Data <= (others => '0');
	RdDat_Vld <= '0';
	Rd_Done <= '0';
	Rd_Error <= '0';
	M_Axi_ArAddr <= (others => '0');
	M_Axi_ArLen <= (others => '0');
	M_Axi_ArValid <= '0';
	M_Axi_RReady <= '0';
	
	
	------------------------------------------------------------------------------
	-- Assertions
	------------------------------------------------------------------------------
	assert AxiDataWidth_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_simple AxiDataWidth_g must be a multiple of 8" severity failure;
	
	------------------------------------------------------------------------------
	-- Combinatorial Process
	------------------------------------------------------------------------------	
	p_comb : process(	r, M_Axi_AwReady, M_Axi_BValid, M_Axi_BResp,
						WrDataFifoLevel, WrDataFifoORdy, WrDataFifoOVld, WrTransFifoOutVld, WrTransFifoBeats, WrRespIsLast, WrRespFifoVld,
						CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld)
		variable v 				: two_process_r;
		variable Max4kBeats_v	: unsigned(13-UnusedAddrBits_c downto 0);
		variable Stdlv9Bit_v	: std_logic_vector(8 downto 0);
	begin
		-- *** Keep two process variables stable ***
		v := r;
		
		-- *** Write Transfer Generation ***
		Max4kBeats_v	:= (others => '0');
		case r.WriteTfGenState is
			when Idle_s =>
				v.CmdWr_Rdy	:= '1';
				if (r.CmdWr_Rdy = '1') and (CmdWr_Vld = '1') then
					v.CmdWr_Rdy			:= '0';
					v.WrAddr			:= unsigned(AddrMasked_f(CmdWr_Addr));
					v.WrBeats			:= unsigned(CmdWr_Size);
					v.WrLowLat			:= CmdWr_LowLat;
					v.WriteTfGenState 	:= MaxCalc_s;
				end if;
				
			when MaxCalc_s =>
				Max4kBeats_v	:= resize(unsigned('0' & not r.WrAddr(11 downto UnusedAddrBits_c)) + 1, Max4kBeats_v'length);
				if Max4kBeats_v > AxiMaxBeats_g-1 then
					v.WrMaxBeats := to_unsigned(AxiMaxBeats_g, 9);
				else
					v.WrMaxBeats := Max4kBeats_v(8 downto 0);
				end if;
				v.WriteTfGenState 	:= GenTf_s;
				
			when GenTf_s =>
				if (r.WrMaxBeats < r.WrBeats) then
					v.WrTfBeats		:= r.WrMaxBeats;
					v.WrTfIsLast	:= '0';
				else
					v.WrTfBeats 	:= r.WrBeats(8 downto 0);
					v.WrTfIsLast	:= '1';
				end if;
				v.WrTfVld	:= '1';
				v.WriteTfGenState 	:= WriteTf_s;
			
			when WriteTf_s => 
				if (r.WrTfVld = '1') and (r.AwFsmRdy = '1') then
					v.WrTfVld 	:= '0';
					v.WrBeats	:= r.WrBeats - r.WrTfBeats;
					v.WrAddr	:= r.WrAddr + 2**UnusedAddrBits_c*r.WrTfBeats;
					if r.WrTfIsLast = '1' then
						v.WriteTfGenState 	:= Idle_s;
					else
						v.WriteTfGenState 	:= MaxCalc_s;
					end if;
				end if;			
			
			when others => null;
		end case;
		
		-- *** AW Command Generation ***
		case r.AwFsm is
			when Idle_s =>
				if ((r.WrLowLat = '1') or (unsigned(WrDataFifoLevel) >= r.WrTfBeats)) and (r.WrOpenTrans < AxiMaxOpenTrasactions_g) and (r.WrTfVld = '1') then
					v.AwFsmRdy := '1';
				end if;
				if (r.AwFsmRdy = '1') and (r.WrTfVld = '1') then
					v.AwFsmRdy 		:= '0';
					v.M_Axi_AwAddr	:= std_logic_vector(r.WrAddr);
					Stdlv9Bit_v		:= std_logic_vector(r.WrTfBeats-1);
					v.M_Axi_AwLen	:= Stdlv9Bit_v(7 downto 0);
					v.M_Axi_AwValid	:= '1';
					v.AwFsm			:= Wait_s;
				end if;
				
			when Wait_s =>
				if M_Axi_AwReady = '1' then
					v.WrOpenTrans	:= r.WrOpenTrans + 1;
					v.M_Axi_AwValid	:= '0';
					v.AwFsm			:= Idle_s;
				end if;
				
			when others => null;
		end case;	

		-- *** W Data Generation ***
		v.WDataFifoRd := '0';
		if (r.WDataEna = '0') and (WrTransFifoOutVld = '1') then
			v.WDataFifoRd 	:= '1';
			v.WDataEna 		:= '1';
			v.WDataBeats	:= unsigned(WrTransFifoBeats);			
			-- If it is a single beat transfer, last has to be asserted on the first beat
			if unsigned(WrTransFifoBeats) = 1 then
				v.M_Axi_WLast	:= '1';
			else
				v.M_Axi_WLast	:= '0';
			end if;
		end if;
		if (r.WDataEna = '1') and (WrDataFifoOVld = '1') and (WrDataFifoORdy = '1') then
			if r.WDataBeats = 2 then
				v.M_Axi_WLast := '1';
			elsif r.WDataBeats = 1 then
				v.WDataEna := '0';
			end if;
			v.WDataBeats := r.WDataBeats - 1;
		end if;		
		
		-- *** W Response Generation ***
		v.Wr_Done := '0';
		v.Wr_Error := '0';
		if M_Axi_BValid = '1' then
			assert WrRespFifoVld = '1' report "###ERROR###: psi_common_axi_master_simple internal error --> WrRespFifo Empty" severity error;
			v.WrOpenTrans	:= v.WrOpenTrans - 1; -- Use v. because it may have been modified above and this modification has not to be overriden
			if WrRespIsLast = '1' then
				if (M_Axi_BResp /= Axi_Resp_Okay_c) then
					v.Wr_Error := '1';
				else
					v.Wr_Error := r.WrRespError;
					v.Wr_Done  := not r.WrRespError;
					v.WrRespError := '0';
				end if;
			elsif M_Axi_BResp /= Axi_Resp_Okay_c then
				v.WrRespError := '1';
			end if;
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
				r.CmdWr_Rdy 		<= '0';
				r.WriteTfGenState	<= Idle_s;
				r.WrTfVld			<= '0';
				r.AwFsm				<= Idle_s;
				r.AwFsmRdy			<= '0';
				r.M_Axi_AwValid		<= '0';
				r.WDataFifoRd		<= '0';
				r.WDataEna			<= '0';
				r.WrOpenTrans		<= 0;
				r.WrRespError		<= '0';
				r.Wr_Done			<= '0';
				r.Wr_Error			<= '0';
			end if;
		end if;
	end process;
	
	------------------------------------------------------------------------------
	-- Outputs
	------------------------------------------------------------------------------		
	CmdWr_Rdy 		<= r.CmdWr_Rdy;
	M_Axi_AwAddr	<= r.M_Axi_AwAddr;
	M_Axi_AwLen		<= r.M_Axi_AwLen;
	M_Axi_AwValid	<= r.M_Axi_AwValid;
	M_Axi_WLast		<= r.M_Axi_WLast;
	Wr_Done			<= r.Wr_Done;
	Wr_Error		<= r.Wr_Error;
	
	------------------------------------------------------------------------------
	-- Constant Outputs
	------------------------------------------------------------------------------	
	M_Axi_AwSize <= std_logic_vector(to_unsigned(log2(AxiDataWidth_g/8), 3));
	M_Axi_ArSize <= std_logic_vector(to_unsigned(log2(AxiDataWidth_g/8), 3));
	M_Axi_AwBurst <= Axi_BurstType_Incr_c;
	M_Axi_ArBurst <= Axi_BurstType_Incr_c;
	M_Axi_AwCache	<= "0011";	-- According AXI reference guide
	M_Axi_ArCache	<= "0011";	-- According AXI reference guide
	M_Axi_AwProt	<= "000";	-- According AXI reference guide
	M_Axi_ArProt	<= "000";	-- According AXI reference guide
	M_Axi_AwLock	<= '0'; 	-- Exclusive access support not implemented 
	M_Axi_ArLock	<= '0'; 	-- Exclusive access support not implemented 	
	M_Axi_BReady	<= '1';
	
	------------------------------------------------------------------------------
	-- Instantiations
	------------------------------------------------------------------------------
	Rst <= not M_Axi_Aresetn;
	
	-- *** Write FIFOs ***
	
	-- FIFO for data transfer FSM
	WrTransFifoInVld <= r.AwFsmRdy and r.WrTfVld;	
	fifo_wr_trans : entity work.psi_common_sync_fifo
		generic map (
			Width_g			=> 9,
			Depth_g			=> AxiMaxOpenTrasactions_g,
			AlmFullOn_g		=> false,
			AlmEmptyOn_g	=> false,
			RamStyle_g		=> "auto",
			RamBehavior_g	=> RamBehavior_g
		)
		port map (
			Clk					=> M_Axi_Aclk,
			Rst					=> Rst,
			InData(8 downto 0)	=> std_logic_vector(r.WrTfBeats),
			InVld				=> WrTransFifoInVld,
			InRdy				=> open,	-- Not required since maximum of open transactions is limitted
			OutData				=> WrTransFifoBeats,
			OutVld				=> WrTransFifoOutVld,
			OutRdy				=> r.WDataFifoRd
		);
	
	-- Write Data FIFO
	b_fifo_wr_data : block
		signal InData 	: std_logic_vector(WrDat_Data'length+WrDat_Be'length-1 downto 0);
		signal OutData	: std_logic_vector(InData'range);
	begin
		InData(WrDat_Data'high downto WrDat_Data'low)					<= WrDat_Data;
		InData(WrDat_Data'high+WrDat_Be'length downto WrDat_Data'high+1)	<= WrDat_Be;
		fifo_wr_data : entity work.psi_common_sync_fifo
			generic map (
				Width_g			=> WrDat_Data'length+WrDat_Be'length,
				Depth_g			=> DataFifoDepth_g,
				AlmFullOn_g		=> false,
				AlmEmptyOn_g	=> false,
				RamStyle_g		=> "auto",
				RamBehavior_g	=> RamBehavior_g
			)
			port map (
				Clk		=> M_Axi_Aclk,
				Rst		=> Rst,
				InData	=> InData,
				InVld	=> WrDat_Vld,
				InRdy	=> WrDat_Rdy,
				OutData	=> OutData,
				OutVld	=> WrDataFifoOVld,
				OutRdy	=> WrDataFifoORdy,
				InLevel	=> WrDataFifoLevel
			);
		M_Axi_WData	<= OutData(WrDat_Data'high downto WrDat_Data'low);
		M_Axi_WStrb	<= OutData(WrDat_Data'high+WrDat_Be'length downto WrDat_Data'high+1);
			
		M_Axi_WValid 	<= WrDataFifoOVld and r.WDataEna;
		WrDataFifoORdy 	<= M_Axi_WReady and r.WDataEna;
	end block;
	
	-- FIFO for write response FSM
		fifo_wr_data : entity work.psi_common_sync_fifo
			generic map (
				Width_g			=> 1,
				Depth_g			=> AxiMaxOpenTrasactions_g,
				AlmFullOn_g		=> false,
				AlmEmptyOn_g	=> false,
				RamStyle_g		=> "auto",
				RamBehavior_g	=> RamBehavior_g
			)
			port map (
				Clk			=> M_Axi_Aclk,
				Rst			=> Rst,
				InData(0)	=> r.WrTfIsLast,
				InVld		=> WrTransFifoInVld,
				InRdy		=> open,	-- Not required since maximum of open transactions is limitted
				OutData(0)	=> WrRespIsLast,
				OutVld		=> WrRespFifoVld,
				OutRdy		=> M_Axi_BValid
			);	
 
end rtl;
