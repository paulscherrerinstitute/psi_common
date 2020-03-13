------------------------------------------------------------------------------
--  Copyright (c) 2019 by Enclustra GmbH, Switzerland
--  All rights reserved.
--  Authors: Eduardo del Castillo
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements multiple pipeline stages for an axi mm slave interface.
-- It is based on 
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;
	
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=master,slave $$
entity psi_common_axi_multi_pl_stage is
	generic (
		AddrWidth_g 	: positive := 32;
		DataWidth_g		: positive := 32;
		Stages_g		: positive := 1
	);
	port (	
		-- global signals
		Clk					   		: in 	std_logic;				-- $$ type=clk; freq=100.0e6 $$
		Rst					   		: in 	std_logic;				-- $$ type=rst; clk=Clk $$			
		
		-------------------------------------------------------------------------------------------
		-- input interface
		-------------------------------------------------------------------------------------------
		
		-- write address channel
		InAwAddr                 : in  	std_logic_vector(AddrWidth_g-1 downto 0);
		InAwValid                : in  	std_logic;
		InAwReady                : out 	std_logic;
		InAwLen                  : in  	std_logic_vector(7 downto 0);
		InAwSize                 : in  	std_logic_vector(2 downto 0);
		InAwBurst                : in  	std_logic_vector(1 downto 0);
		InAwLock                 : in  	std_logic;
		InAwCache                : in  	std_logic_vector(3 downto 0);
		InAwProt                 : in  	std_logic_vector(2 downto 0);
		
		-- write data channel
		InWData                  : in  	std_logic_vector(DataWidth_g-1 downto 0);
		InWStrb                  : in  	std_logic_vector(DataWidth_g/8-1 downto 0);
		InWValid                 : in  	std_logic;
		InWReady                 : out 	std_logic;
		InWLast                  : in  	std_logic;
		
		-- write response channel
		InBResp                  : out 	std_logic_vector(1 downto 0);
		InBValid                 : out 	std_logic;
		InBReady                 : in  	std_logic;
		
		-- read address channel
		InArAddr                 : in  	std_logic_vector(AddrWidth_g-1 downto 0);
		InArValid                : in  	std_logic;
		InArReady                : out 	std_logic;
		InArLen                  : in  	std_logic_vector(7 downto 0);
		InArSize                 : in  	std_logic_vector(2 downto 0);
		InArBurst                : in  	std_logic_vector(1 downto 0);
		InArLock                 : in  	std_logic;
		InArCache                : in  	std_logic_vector(3 downto 0);
		InArProt                 : in  	std_logic_vector(2 downto 0);

		-- read data channel
		InRData                  : out 	std_logic_vector(DataWidth_g-1 downto 0);
		InRValid                 : out 	std_logic;
		InRReady                 : in  	std_logic;
		InRResp                  : out 	std_logic_vector(1 downto 0);
		InRLast                  : out 	std_logic;
		
		-------------------------------------------------------------------------------------------
		-- output interface
		-------------------------------------------------------------------------------------------
		
		-- write address channel
		OutAwAddr                : out 	std_logic_vector(AddrWidth_g-1 downto 0);
		OutAwValid               : out 	std_logic;
		OutAwReady               : in 	std_logic;
		OutAwLen                 : out 	std_logic_vector(7 downto 0);
		OutAwSize                : out 	std_logic_vector(2 downto 0);
		OutAwBurst               : out 	std_logic_vector(1 downto 0);
		OutAwLock                : out 	std_logic;
		OutAwCache               : out 	std_logic_vector(3 downto 0);
		OutAwProt                : out 	std_logic_vector(2 downto 0);
		
		-- write data channel
		OutWData                 : out 	std_logic_vector(DataWidth_g-1 downto 0);
		OutWStrb                 : out 	std_logic_vector(DataWidth_g/8-1 downto 0);
		OutWValid                : out 	std_logic;
		OutWReady                : in 	std_logic;
		OutWLast                 : out 	std_logic;
		
		-- write response channel
		OutBResp                 : in 	std_logic_vector(1 downto 0);
		OutBValid                : in 	std_logic;
		OutBReady                : out 	std_logic;
		
		-- read address channel
		OutArAddr                : out 	std_logic_vector(AddrWidth_g-1 downto 0);
		OutArValid               : out 	std_logic;
		OutArReady               : in 	std_logic;
		OutArLen                 : out 	std_logic_vector(7 downto 0);
		OutArSize                : out 	std_logic_vector(2 downto 0);
		OutArBurst               : out 	std_logic_vector(1 downto 0);
		OutArLock                : out 	std_logic;
		OutArCache               : out 	std_logic_vector(3 downto 0);
		OutArProt                : out 	std_logic_vector(2 downto 0);

		-- read data channel
		OutRData                 : in 	std_logic_vector(DataWidth_g-1 downto 0);
		OutRValid                : in 	std_logic;
		OutRReady                : out 	std_logic;
		OutRResp                 : in 	std_logic_vector(1 downto 0);
		OutRLast                 : in 	std_logic	
	);
end entity;
		
------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_axi_multi_pl_stage is

	constant LenWidth_c		: positive := 8;
	constant SizeWidth_c	: positive := 3;
	constant BurstWidth_c	: positive := 2;
	constant CacheWidth_c	: positive := 4;
	constant ProtWidth_c	: positive := 3;
	constant RespWidth_c	: positive := 2;

	signal AwData 	: std_logic_vector(AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+1+CacheWidth_c+ProtWidth_c-1 downto 0);
	signal WData 	: std_logic_vector(DataWidth_g+DataWidth_g/8+1-1 downto 0);
	signal ArData 	: std_logic_vector(AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+1+CacheWidth_c+ProtWidth_c-1 downto 0);
	signal RData 	: std_logic_vector(DataWidth_g+RespWidth_c+1-1 downto 0);

begin
	
	-- write address channel
	
	awch_multi_stage: entity work.psi_common_multi_pl_stage
	generic map(
		Width_g		=> AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+1+CacheWidth_c+ProtWidth_c,
		Stages_g	=> Stages_g
	)
	port map(	
		-- Control Signals
		Clk			=> Clk,
		Rst			=> Rst,
	
		-- Input
		InData		=> InAwAddr & InAwLen & InAwSize & InAwBurst & InAwLock & InAwCache & InAwProt,
		InVld		=> InAwValid,
		InRdy		=> InAwReady,
		
		-- Output
		OutData		=> AwData,
		OutVld		=> OutAwValid,									
		OutRdy		=> OutAwReady
	);
	
	OutAwProt 	<= AwData(ProtWidth_c-1 downto 0);
	OutAwCache 	<= AwData(CacheWidth_c-1+ProtWidth_c downto ProtWidth_c);																															
	OutAwLock 	<= AwData(CacheWidth_c+ProtWidth_c);																																			
	OutAwBurst 	<= AwData(BurstWidth_c-1+CacheWidth_c+ProtWidth_c+1 downto CacheWidth_c+ProtWidth_c+1);																								
	OutAwSize 	<= AwData(SizeWidth_c-1+BurstWidth_c+CacheWidth_c+ProtWidth_c+1 downto BurstWidth_c+CacheWidth_c+ProtWidth_c+1);																
	OutAwLen 	<= AwData(LenWidth_c-1+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c+1 downto SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c+1);												
	OutAwAddr 	<= AwData(AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c downto AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c-AddrWidth_g+1);
	
	-- write data channel
		
	wch_multi_stage: entity work.psi_common_multi_pl_stage
	generic map(
		Width_g		=> DataWidth_g+DataWidth_g/8+1,
		Stages_g	=> Stages_g
	)
	port map(	
		-- Control Signals
		Clk			=> Clk,
		Rst			=> Rst,
	
		-- Input
		InData		=> InWData & InWStrb & InWLast,
		InVld		=> InWValid,
		InRdy		=> InWReady,
		
		-- Output
		OutData		=> WData,
		OutVld		=> OutWValid,									
		OutRdy		=> OutWReady
	);
	
	OutWLast <= WData(0);																				
	OutWStrb <= WData(DataWidth_g/8-1+1 downto 1);														
	OutWData <= WData(DataWidth_g+DataWidth_g/8 downto DataWidth_g+DataWidth_g/8-DataWidth_g+1);		
		
	-- write response channel
	bch_multi_stage: entity work.psi_common_multi_pl_stage
	generic map(
		Width_g		=> RespWidth_c,
		Stages_g	=> Stages_g
	)
	port map(	
		-- Control Signals
		Clk			=> Clk,
		Rst			=> Rst,
	
		-- Input
		InData		=> OutBResp,
		InVld		=> OutBValid,
		InRdy		=> OutBReady,
		
		-- Output
		OutData		=> InBResp,
		OutVld		=> InBValid,									
		OutRdy		=> InBReady
	);
	
	-- read address channel
	arch_multi_stage: entity work.psi_common_multi_pl_stage
	generic map(
		Width_g		=> AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+1+CacheWidth_c+ProtWidth_c,
		Stages_g	=> Stages_g
	)
	port map(	
		-- Control Signals
		Clk			=> Clk,
		Rst			=> Rst,
	
		-- Input
		InData		=> InArAddr & InArLen & InArSize & InArBurst & InArLock & InArCache & InArProt,
		InVld		=> InArValid,
		InRdy		=> InArReady,
		
		-- Output
		OutData		=> ArData,
		OutVld		=> OutArValid,									
		OutRdy		=> OutArReady
	);
	
	OutArProt 	<= ArData(ProtWidth_c-1 downto 0);																																				
	OutArCache 	<= ArData(CacheWidth_c-1+ProtWidth_c downto ProtWidth_c);																														
	OutArLock	<= ArData(CacheWidth_c+ProtWidth_c);																																					
	OutArBurst	<= ArData(BurstWidth_c-1+CacheWidth_c+ProtWidth_c+1 downto CacheWidth_c+ProtWidth_c+1);																							
	OutArSize	<= ArData(SizeWidth_c-1+BurstWidth_c+CacheWidth_c+ProtWidth_c+1 downto BurstWidth_c+CacheWidth_c+ProtWidth_c+1);																		
	OutArLen	<= ArData(LenWidth_c-1+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c+1 downto SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c+1);												
	OutArAddr	<= ArData(AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c downto AddrWidth_g+LenWidth_c+SizeWidth_c+BurstWidth_c+CacheWidth_c+ProtWidth_c-AddrWidth_g+1);	
	
	-- read data channel
	rch_multi_stage: entity work.psi_common_multi_pl_stage
	generic map(
		Width_g		=> DataWidth_g+RespWidth_c+1,
		Stages_g	=> Stages_g
	)
	port map(	
		-- Control Signals
		Clk			=> Clk,
		Rst			=> Rst,
	
		-- Input
		InData		=> OutRData & OutRResp & OutRLast,
		InVld		=> OutRValid,
		InRdy		=> OutRReady,
		
		-- Output
		OutData		=> RData,
		OutVld		=> InRValid,									
		OutRdy		=> InRReady
	);
	
	InRLast <= RData(0);															
	InRResp <= RData(RespWidth_c-1+1 downto 1);
	InRData <= RData(DataWidth_g+RespWidth_c downto DataWidth_g+RespWidth_c-DataWidth_g+1);
	
end;





