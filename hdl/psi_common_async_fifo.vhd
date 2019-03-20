------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic asynchronous FIFO. The clocks can be fully asynchronous
-- (unrelated). It  has optional level- and almost-full/empty ports.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_logic_pkg.all;
	use work.psi_common_math_pkg.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_async_fifo is
	generic (
		Width_g			: positive		:= 16;
		Depth_g			: positive		:= 32;
		AlmFullOn_g		: boolean		:= false;
		AlmFullLevel_g	: natural		:= 28;
		AlmEmptyOn_g	: boolean		:= false;
		AlmEmptyLevel_g	: natural		:= 4;
		RamStyle_g		: string		:= "auto";
		RamBehavior_g	: string		:= "RBW";	-- "RBW" = read-before-write, "WBR" = write-before-read
		RdyRstState_g	: std_logic		:= '1'		-- Use '1' for minimal logic on Rdy path
	);
	port (
		-- Control Ports
		InClk		: in	std_logic;
		InRst		: in	std_logic;
		OutClk		: in 	std_logic;
		OutRst		: in 	std_logic;
		
		-- Input Data
		InData		: in	std_logic_vector(Width_g-1 downto 0);
		InVld		: in	std_logic;
		InRdy		: out	std_logic;	-- not full
		
		-- Output Data
		OutData		: out	std_logic_vector(Width_g-1 downto 0);
		OutVld		: out	std_logic;	-- not empty
		OutRdy		: in	std_logic;	
		
		-- Input Status
		InFull		: out	std_logic;
		InEmpty		: out	std_logic;
		InAlmFull 	: out	std_logic;
		InAlmEmpty	: out	std_logic;
		InLevel		: out	std_logic_vector(log2ceil(Depth_g) downto 0);
		
		-- Output Status
		OutFull		: out	std_logic;
		OutEmpty	: out	std_logic;	
		OutAlmFull	: out	std_logic;
		OutAlmEmpty : out 	std_logic;
		OutLevel	: out	std_logic_vector(log2ceil(Depth_g) downto 0)
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_async_fifo is

	
	type two_process_in_r is record
		WrAddr			: unsigned(log2ceil(Depth_g) downto 0);				-- One additional bit for full/empty detection
		WrAddrGray		: std_logic_vector(log2ceil(Depth_g) downto 0);
		RdAddrGraySync	: std_logic_vector(log2ceil(Depth_g) downto 0);
		RdAddrGray		: std_logic_vector(log2ceil(Depth_g) downto 0);
		RdAddr			: unsigned(log2ceil(Depth_g) downto 0);
	end record;
	
	type two_process_out_r is record
		RdAddr			: unsigned(log2ceil(Depth_g) downto 0);				-- One additional bit for full/empty detection
		RdAddrGray		: std_logic_vector(log2ceil(Depth_g) downto 0);
		WrAddrGraySync	: std_logic_vector(log2ceil(Depth_g) downto 0);
		WrAddrGray		: std_logic_vector(log2ceil(Depth_g) downto 0);
		WrAddr			: unsigned(log2ceil(Depth_g) downto 0);
		OutLevel		: unsigned(log2ceil(Depth_g) downto 0);
	end record;	
	
	signal ri, ri_next	: two_process_in_r	:=(		WrAddr=>(others=>'0'),
													WrAddrGray=>(others=>'0'),
													RdAddrGraySync=>(others=>'0'),
													RdAddrGray=>(others=>'0'),
													RdAddr=>(others=>'0'));
	signal ro, ro_next	: two_process_out_r :=  (	RdAddr=>(others=>'0'),
													RdAddrGray=>(others=>'0'),
													WrAddrGraySync=>(others=>'0'),
													WrAddrGray=>(others=>'0'),
													WrAddr=>(others=>'0'),
													OutLevel=>(others=>'0'));
	
	signal RstInInt				: std_logic;
	signal RstOutInt			: std_logic;
	signal RamWr				: std_logic;
	signal RamRdAddr			: std_logic_vector(log2ceil(Depth_g)-1 downto 0);
	signal RamWrAddr			: std_logic_vector(log2ceil(Depth_g)-1 downto 0);
	
	attribute syn_srlstyle : string;
    attribute syn_srlstyle of ri : signal is "registers";
    attribute syn_srlstyle of ro : signal is "registers";
	
	attribute shreg_extract : string;
    attribute shreg_extract of ri : signal is "no";
    attribute shreg_extract of ro : signal is "no";
	
	attribute ASYNC_REG : string;
    attribute ASYNC_REG of ri : signal is "TRUE";
    attribute ASYNC_REG of ro : signal is "TRUE";	
	
	
begin
	--------------------------------------------------------------------------
	-- Assertions
	--------------------------------------------------------------------------
	assert log2(Depth_g) = log2ceil(Depth_g) report "###ERROR###: psi_common_async_fifo: only power of two Depth_g is allowed" severity error;

	--------------------------------------------------------------------------
	-- Combinatorial Process
	--------------------------------------------------------------------------
	p_comb : process(InVld, OutRdy, ri, ro, RstInInt)
		variable vi				: two_process_in_r;
		variable vo				: two_process_out_r;
		variable InLevel_v		: unsigned(log2ceil(Depth_g) downto 0);
	begin
		-- *** hold variables stable ***
		vi := ri;
		vo := ro;

		-- *** Write Side ***
		-- Defaults
		InRdy		<= '0';
		InFull		<= '0';
		InEmpty		<= '0';
		InAlmFull	<= '0';
		InAlmEmpty	<= '0';
		RamWr		<= '0';
		
		-- Level Detection
		InLevel_v	:= ri.WrAddr - ri.RdAddr;
		InLevel		<= std_logic_vector(InLevel_v);
		
		-- Full
		if InLevel_v = Depth_g then
			InFull	<= '1';
		else	
			InRdy 	<= '1';
			-- Execute Write
			if InVld = '1' then			
				vi.WrAddr	:= ri.WrAddr + 1;
				RamWr 		<= '1';
			end if;
		end if;
		-- Artificially keep InRdy low during reset if required 
		if (RdyRstState_g = '0') and (RstInInt = '1') then
			InRdy <= '0';
		end if;
		
		-- Status Detection
		if InLevel_v = 0 then	
			InEmpty <= '1';
		end if;		
		if InLevel_v >= AlmFullLevel_g and AlmFullOn_g then
			InAlmFull <= '1';
		end if;
		if InLevel_v <= AlmEmptyLevel_g and AlmEmptyOn_g then
			InAlmEmpty <= '1';
		end if;			
		
		-- *** Read Side ***
		-- Defaults
		OutVld		<= '0';
		OutFull		<= '0';
		OutEmpty	<= '0';
		OutAlmFull	<= '0';
		OutAlmEmpty	<= '0';
		
		-- Level Detection
		if ro.WrAddr = ro.RdAddr then
			vo.OutLevel := (others => '0');
		else
			vo.OutLevel	:= ro.WrAddr - ro.RdAddr;
			if (OutRdy = '1') and (ro.OutLevel /= 0) then
				vo.OutLevel := vo.OutLevel - 1;
			end if;
		end if;
		OutLevel	<= std_logic_vector(ro.OutLevel);
		
		-- Empty
		if ro.OutLevel = 0 then
			OutEmpty	<= '1';
		else
			OutVld 		<= '1';
			-- Execute read
			if OutRdy = '1' then
				vo.RdAddr	:= ro.RdAddr + 1;
			end if;
		end if;
		RamRdAddr <= std_logic_vector(vo.RdAddr(log2ceil(Depth_g)-1 downto 0));
		
		-- Status Detection
		if ro.OutLevel = Depth_g then
			OutFull	<= '1';
		end if;
		if ro.OutLevel >= AlmFullLevel_g and AlmFullOn_g then
			OutAlmFull <= '1';
		end if;
		if ro.OutLevel <= AlmEmptyLevel_g and AlmEmptyOn_g then
			OutAlmEmpty <= '1';
		end if;
		
		-- *** Address Clock domain crossings ***
		-- Bin->Gray is simple, can be done without additional FF
		vi.WrAddrGray	:= BinaryToGray(std_logic_vector(vi.WrAddr));
		vo.RdAddrGray	:= BinaryToGray(std_logic_vector(vo.RdAddr));			
		
		-- Two stage synchronizer
		vi.RdAddrGraySync	:= ro.RdAddrGray;
		vi.RdAddrGray		:= ri.RdAddrGraySync;
		vo.WrAddrGraySync	:= ri.WrAddrGray;
		vo.WrAddrGray		:= ro.WrAddrGraySync;

		-- Gray->Bin involves some logic, needs additional FF
		vi.RdAddr		:= unsigned(GrayToBinary(ri.RdAddrGray));
		vo.WrAddr		:= unsigned(GrayToBinary(ro.WrAddrGray));
		
		-- *** Assign signal ***
		ri_next <= vi;
		ro_next <= vo;
		
	end process;
	
	--------------------------------------------------------------------------
	-- Sequential
	--------------------------------------------------------------------------
	p_seq_in : process(InClk)
	begin
		if rising_edge(InClk) then
			ri <= ri_next;
			if RstInInt = '1' then
				ri.WrAddr			<= (others => '0');
				ri.WrAddrGray		<= (others => '0');
				ri.RdAddrGraySync	<= (others => '0');
				ri.RdAddrGray		<= (others => '0');
				ri.RdAddr			<= (others => '0');
			end if;
		end if;
	end process;	
	
	p_seq_out : process(OutClk)
	begin
		if rising_edge(OutClk) then
			ro <= ro_next;
			if RstOutInt = '1' then
				ro.RdAddr			<= (others => '0');
				ro.RdAddrGray		<= (others => '0');
				ro.WrAddrGraySync	<= (others => '0');
				ro.WrAddrGray		<= (others => '0');
				ro.WrAddr			<= (others => '0');
				ro.OutLevel			<= (others => '0');
			end if;
		end if;
	end process;	
	
	--------------------------------------------------------------------------
	-- Component Instantiations
	--------------------------------------------------------------------------
	RamWrAddr <= std_logic_vector(ri.WrAddr(log2ceil(Depth_g)-1 downto 0));
	i_ram : entity work.psi_common_sdp_ram
		generic map (
			Depth_g		=> Depth_g,
			Width_g		=> Width_g,
			RamStyle_g	=> RamStyle_g,
			IsAsync_g	=> true,
			Behavior_g	=> RamBehavior_g
		)
		port map (
			-- Port A
			Clk			=> InClk,
			WrAddr		=> RamWrAddr,
			Wr			=> RamWr,
			WrData		=> InData,
			
			-- Port B
			RdClk		=> OutClk,
			RdAddr		=> RamRdAddr,
			Rd			=> '1',
			RdData		=> OutData
		);
		
	-- only used for reset crossing and oring
	i_rst_cc : entity work.psi_common_pulse_cc
		port map (
			-- Clock Domain A
			ClkA		=> InClk,
			RstInA		=> InRst,
			RstOutA		=> RstInInt,
			PulseA		=> (others => '0'),
			
			-- Clock Domain B
			ClkB		=> OutClk,
			RstInB		=> OutRst,
			RstOutB		=> RstOutInt,
			PulseB		=> open
		);
	

end;





