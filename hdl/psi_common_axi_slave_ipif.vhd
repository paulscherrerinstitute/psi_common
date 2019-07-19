------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Goran Marinkovic, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a full AXI-4 slave for simple IP-Core interfaces. It 
-- supports the implementation of registers as well as access to memories. 
-- Its only main limitations are, that data for memory accesses must be available for 
-- reading after one clock cycle. So except using a synchronous RAM, no additional
-- pipelining is possible and that it only supports 32-bit wide AXI bus.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ processes=axi,ip $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_slave_ipif is
	generic (
		-- IP Interface Config
		NumReg_g					: integer 	:= 32; 								-- $$ export=true $$
		ResetVal_g					: t_aslv32	:= (0 => (others => '0'));			-- $$ constant=(X"0001ABCD", X"00021234") $$
		UseMem_g					: boolean	:= true;							-- $$ export=true $$
		-- AXI Config
		AxiIdWidth_g				: integer := 1;	
		AxiAddrWidth_g				: integer := 8
	);
	port
	(
		--------------------------------------------------------------------------
		-- AXI Slave Bus Interface
		--------------------------------------------------------------------------
		-- System
		s_axi_aclk						: in	std_logic;											-- $$ type=clk; freq=100e6 $$
		s_axi_aresetn					: in	std_logic;											-- $$ type=rst; clk=s_axi_aclk; lowactive=true $$
		-- Read address channel				
		s_axi_arid						: in	std_logic_vector(AxiIdWidth_g-1	  downto 0);		-- $$ proc=axi $$
		s_axi_araddr					: in	std_logic_vector(AxiAddrWidth_g-1 downto 0);		-- $$ proc=axi $$	
		s_axi_arlen						: in	std_logic_vector(7 downto 0);		                -- $$ proc=axi $$
		s_axi_arsize					: in	std_logic_vector(2 downto 0);		                -- $$ proc=axi $$
		s_axi_arburst					: in	std_logic_vector(1 downto 0);		                -- $$ proc=axi $$
		s_axi_arlock					: in	std_logic;		                                    -- $$ proc=axi $$
		s_axi_arcache					: in	std_logic_vector(3 downto 0);		                -- $$ proc=axi $$
		s_axi_arprot					: in	std_logic_vector(2 downto 0);		                -- $$ proc=axi $$
		s_axi_arvalid					: in	std_logic;		                                    -- $$ proc=axi $$
		s_axi_arready					: out	std_logic;		                                    -- $$ proc=axi $$
		-- Read data channel
		s_axi_rid						: out	std_logic_vector(AxiIdWidth_g-1 downto 0);          -- $$ proc=axi $$
		s_axi_rdata						: out	std_logic_vector(31 downto 0);                      -- $$ proc=axi $$
		s_axi_rresp						: out	std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
		s_axi_rlast						: out	std_logic;                                          -- $$ proc=axi $$
		s_axi_rvalid					: out	std_logic;                                          -- $$ proc=axi $$
		s_axi_rready					: in	std_logic;                                          -- $$ proc=axi $$
		-- Write address channel
		s_axi_awid						: in	std_logic_vector(AxiIdWidth_g-1	  downto 0);        -- $$ proc=axi $$
		s_axi_awaddr					: in	std_logic_vector(AxiAddrWidth_g-1 downto 0);        -- $$ proc=axi $$
		s_axi_awlen						: in	std_logic_vector(7 downto 0);                       -- $$ proc=axi $$
		s_axi_awsize					: in	std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
		s_axi_awburst					: in	std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
		s_axi_awlock					: in	std_logic;                                          -- $$ proc=axi $$
		s_axi_awcache					: in	std_logic_vector(3 downto 0);                       -- $$ proc=axi $$
		s_axi_awprot					: in	std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
		s_axi_awvalid					: in	std_logic;                                          -- $$ proc=axi $$
		s_axi_awready					: out	std_logic;                                          -- $$ proc=axi $$
		-- Write data channel
		s_axi_wdata						: in	std_logic_vector(31		downto 0);                  -- $$ proc=axi $$
		s_axi_wstrb						: in	std_logic_vector(3 downto 0);                       -- $$ proc=axi $$
		s_axi_wlast						: in	std_logic;                                          -- $$ proc=axi $$
		s_axi_wvalid					: in	std_logic;                                          -- $$ proc=axi $$
		s_axi_wready					: out	std_logic;                                          -- $$ proc=axi $$
		-- Write response channel
		s_axi_bid						: out	std_logic_vector(AxiIdWidth_g-1 downto 0);          -- $$ proc=axi $$
		s_axi_bresp						: out	std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
		s_axi_bvalid					: out	std_logic;                                          -- $$ proc=axi $$
		s_axi_bready					: in	std_logic;                                          -- $$ proc=axi $$
		--------------------------------------------------------------------------
		-- Register Interface
		--------------------------------------------------------------------------
		o_reg_rd						: out	std_logic_vector(NumReg_g-1 downto	 0);										-- $$ proc=ip $$
		i_reg_rdata						: in	t_aslv32(0 to NumReg_g-1)					:= (others => (others => '0'));		-- $$ proc=ip $$
		o_reg_wr						: out	std_logic_vector(NumReg_g-1 downto	 0);										-- $$ proc=ip $$
		o_reg_wdata						: out	t_aslv32(0 to NumReg_g-1);														-- $$ proc=ip $$
		--------------------------------------------------------------------------
		-- Memory Interface
		--------------------------------------------------------------------------
		o_mem_addr						: out	std_logic_vector(AxiAddrWidth_g - 1 downto	0);									-- $$ proc=ip $$
		o_mem_wr						: out	std_logic_vector( 3 downto	 0);												-- $$ proc=ip $$
		o_mem_wdata						: out	std_logic_vector(31 downto	 0);												-- $$ proc=ip $$
		i_mem_rdata						: in	std_logic_vector(31 downto	 0)				:= (others => '0')					-- $$ proc=ip $$
	);
end psi_common_axi_slave_ipif;

architecture behavioral of psi_common_axi_slave_ipif is

	-----------------------------------------------------------------------------
	-- AXI slave bus interface
	-----------------------------------------------------------------------------
	type axi_fsm_type is
	(
		axi_fsm_idle,
		axi_fsm_rd_data,
		axi_fsm_wr_data,
		axi_fsm_wr_done
	);
	signal rst						: std_logic;
	signal	axi_fsm_comb			: axi_fsm_type;
	signal	axi_fsm					: axi_fsm_type;
	-- ADDR_INDEX_LOW is used for addressing 32/64 bit registers/memories
	-- ADDR_INDEX_LOW = 2 for 32 bits (n downto 2)
	-- ADDR_INDEX_LOW = 3 for 64 bits (n downto 3)
	constant REG_ADDR_INDEX_LOW		: integer := 2;
	constant REG_ADDR_WIDTH			: integer := integer(log2ceil(NumReg_g)) + REG_ADDR_INDEX_LOW;
	constant REG_ADDR_INDEX_HIGH	: integer := REG_ADDR_WIDTH - 1;
	constant MEM_ADDR_START			: unsigned(AxiAddrWidth_g - 1 downto	 0) := to_unsigned(2**(REG_ADDR_WIDTH), AxiAddrWidth_g);
	-- Read address channel
	signal	axi_arid				: std_logic_vector(AxiIdWidth_g - 1 downto 0) := (others => '0');
	signal	axi_araddr				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	signal	axi_araddr_last			: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	signal	axi_arlen				: unsigned( 7 downto  0) := (others => '0');
	signal	axi_arsize				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	signal	axi_arburst				: std_logic_vector(1 downto 0) := (others => '0');
	signal	axi_arready				: std_logic := '0';
	signal	axi_arwrap_en			: std_logic := '0';
	signal	axi_arwrap				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	-- Read data channel
	constant axi_rresp				: std_logic_vector( 1 downto	 0) := "00"; -- 'OKAY' response
	signal	axi_rlast				: std_logic := '0';
	signal	axi_rready				: std_logic := '0';
	signal	axi_rvalid				: std_logic := '0';
	-- Write address channel
	signal	axi_awid				: std_logic_vector(AxiIdWidth_g - 1 downto 0) := (others => '0');
	signal	axi_awaddr				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	signal	axi_awlen				: unsigned( 7 downto  0) := (others => '0');
	signal	axi_awsize				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	signal	axi_awburst				: std_logic_vector(1 downto 0) := (others => '0');
	signal	axi_awready				: std_logic := '0';
	signal	axi_awwrap_en			: std_logic := '0';
	signal	axi_awwrap				: unsigned(AxiAddrWidth_g - 1 downto	 0) := (others => '0');
	-- Write data channel
	signal	axi_wlast				: std_logic := '0';
	signal	axi_wready				: std_logic := '0';
	-- Write response channel
	constant axi_bresp				: std_logic_vector( 1 downto	 0) := "00"; -- 'OKAY' response
	-- Derived signals
	signal	axi_raddr_sel			: std_logic := '0';
	signal	axi_waddr_sel			: std_logic := '0';
	signal	reg_rd					: std_logic_vector(NumReg_g-1 downto	 0) := (others => '0');
	signal	reg_wr					: std_logic_vector(NumReg_g-1 downto	 0) := (others => '0');
	signal	reg_rlast				: std_logic := '0';
	signal	reg_rdata				: std_logic_vector(31 downto	0) := (others => '0');
	signal	reg_rvalid				: std_logic := '0';
	signal	reg_byte_index			: integer := 0;
	signal	mem_rlast				: std_logic := '0';
	signal	mem_rvalid				: std_logic := '0';
	-- R-channel pipeline stage
	signal rpl_rready				: std_logic;
	signal rpl_rvalid				: std_logic;
	signal rpl_rid					: std_logic_vector(AxiIdWidth_g-1 downto 0);
	signal rpl_rdata				: std_logic_vector(31 downto 0);
	signal rpl_rresp				: std_logic_vector(1 downto 0);
	signal rpl_rlast				: std_logic;

begin
	rst <= not s_axi_aresetn;

	-----------------------------------------------------------------------------
	-- Assertions
	-----------------------------------------------------------------------------
	assert isLog2(NumReg_g) report "###ERROR###: psi_common_axi_slave_ipif: NumReg_g must be a power of two!" severity error;

	-----------------------------------------------------------------------------
	-- AXI fsm
	-----------------------------------------------------------------------------
	axi_fsm_comb_proc: process (axi_fsm, axi_rlast, axi_wlast, s_axi_aresetn,
										 s_axi_arvalid, s_axi_awvalid, s_axi_bready, rpl_rready,
										 s_axi_wvalid)
	begin
		if (s_axi_aresetn = '0') then
			axi_fsm_comb				 <= axi_fsm_idle;
		else
			axi_fsm_comb				 <= axi_fsm;
			case axi_fsm is
			when axi_fsm_idle =>
				if		(s_axi_arvalid = '1') then
					axi_fsm_comb		 <= axi_fsm_rd_data;
				elsif (s_axi_awvalid = '1') then
					axi_fsm_comb		 <= axi_fsm_wr_data;
				end if;
			when axi_fsm_rd_data =>
				if		((axi_rlast = '1') and (rpl_rready = '1')) then
					axi_fsm_comb		 <= axi_fsm_idle;
				end if;
			when axi_fsm_wr_data =>
				if		((axi_wlast = '1') and (s_axi_wvalid = '1')) then
					axi_fsm_comb		 <= axi_fsm_wr_done;
				end if;
			when axi_fsm_wr_done =>
				if (s_axi_bready = '1') then
					axi_fsm_comb		 <= axi_fsm_idle;
				end if;
			when others =>
				axi_fsm_comb			 <= axi_fsm_idle;
			end case;
		end if;
	end process;

	axi_fsm_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			axi_fsm						 <= axi_fsm_comb;
		end if;
	end process axi_fsm_proc;

	-----------------------------------------------------------------------------
	-- AXI ARADDR
	-----------------------------------------------------------------------------
	axi_arwrap_en						 <= '1' when ((axi_araddr and axi_arwrap) = axi_arwrap) else '0';

	axi_araddr_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			case axi_fsm is
			when axi_fsm_idle =>
				if (axi_fsm_comb = axi_fsm_rd_data) then
					axi_araddr			 <= unsigned(s_axi_araddr);
					axi_araddr_last	 <= unsigned(s_axi_araddr);
					case (s_axi_arsize) is
					when "000" =>
						axi_arsize		 <= to_unsigned( 1, AxiAddrWidth_g);
					when "001" =>
						axi_arsize		 <= to_unsigned( 2, AxiAddrWidth_g);
					when "010" =>
						axi_arsize		 <= to_unsigned( 4, AxiAddrWidth_g);
					when others =>
						axi_arsize		 <= to_unsigned( 1, AxiAddrWidth_g);
					end case;
					axi_arburst			 <= s_axi_arburst;
					axi_arlen			 <= unsigned(s_axi_arlen);
					if (s_axi_arburst = "10") then -- If wrapping burst
						case (s_axi_arlen) is
						when X"01" =>
							case (s_axi_arsize) is
							when "000" =>
								axi_arwrap <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_arwrap <= to_unsigned( 2 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_arwrap <= to_unsigned( 2 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_arwrap <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"03" =>
							case (s_axi_arsize) is
							when "000" =>
								axi_arwrap <= to_unsigned( 4 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_arwrap <= to_unsigned( 4 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_arwrap <= to_unsigned( 4 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_arwrap <= to_unsigned( 4 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"07" =>
							case (s_axi_arsize) is
							when "000" =>
								axi_arwrap <= to_unsigned( 8 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_arwrap <= to_unsigned( 8 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_arwrap <= to_unsigned( 8 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_arwrap <= to_unsigned( 8 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"0F" =>
							case (s_axi_arsize) is
							when "000" =>
								axi_arwrap <= to_unsigned(16 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_arwrap <= to_unsigned(16 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_arwrap <= to_unsigned(16 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_arwrap <= to_unsigned(16 * 1 - 1, AxiAddrWidth_g);
							end case;
						when others =>
							axi_arwrap	  <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
						end case;
					end if;
				end if;
			when axi_fsm_rd_data =>
				if (rpl_rready = '1') then
					case (axi_arburst) is
					when "00" => -- Fixed burst
						null;
					when "01" => -- Incremental burst
						axi_araddr		 <= axi_araddr + axi_arsize;
					when "10" => -- Wrapping burst
						if (axi_arwrap_en = '1') then
							axi_araddr	 <= axi_araddr - axi_arwrap;
						else
							axi_araddr	 <= axi_araddr + axi_arsize;
						end if;
					when others => -- Reserved
						null;
					end case;
					axi_araddr_last	 <= axi_araddr;
				else
					axi_araddr			 <= axi_araddr_last;
				end if;
				if (axi_rvalid = '1') then
					axi_arlen			 <= axi_arlen - 1;
				end if;
			when others =>
				null;
			end case;
		end if;
	end process axi_araddr_proc;

	-----------------------------------------------------------------------------
	-- AXI RADDR denotes register or memory
	-----------------------------------------------------------------------------
	axi_raddr_sel						 <= '1' when ((axi_fsm = axi_fsm_rd_data) and (to_integer(unsigned(axi_araddr_last(AxiAddrWidth_g - 1 downto REG_ADDR_WIDTH))) /= 0)) else '0';

	-----------------------------------------------------------------------------
	-- AXI ARREADY
	-----------------------------------------------------------------------------
	s_axi_arready						 <= '1' when ((axi_fsm = axi_fsm_idle) and (axi_fsm_comb = axi_fsm_rd_data)) else '0';

	-----------------------------------------------------------------------------
	-- AXI RID
	-----------------------------------------------------------------------------
	axi_rid_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			if (axi_fsm = axi_fsm_idle) then
				if (axi_fsm_comb = axi_fsm_rd_data) then
					axi_arid				 <= s_axi_arid;
				else
					axi_arid				 <= (others => '0');
				end if;
			end if;
		end if;
	end process axi_rid_proc;

	rpl_rid							 <= axi_arid;

	-----------------------------------------------------------------------------
	-- AXI RREADY
	-----------------------------------------------------------------------------
	axi_rready_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			if (axi_fsm = axi_fsm_rd_data) then
				axi_rready				 <= rpl_rready;
			else
				axi_rready				 <= '0';
			end if;
		end if;
	end process axi_rready_proc;

	-----------------------------------------------------------------------------
	-- AXI RVALID
	-----------------------------------------------------------------------------
	axi_rvalid							 <= reg_rvalid or mem_rvalid	when UseMem_g else
											reg_rvalid;
	rpl_rvalid						 <= axi_rvalid;

	-----------------------------------------------------------------------------
	-- AXI RLAST
	-----------------------------------------------------------------------------
	axi_rlast							 <= reg_rlast or mem_rlast		when UseMem_g else			
											reg_rlast;
	rpl_rlast							 <= axi_rlast;

	-----------------------------------------------------------------------------
	-- AXI RRESP
	-----------------------------------------------------------------------------
	rpl_rresp							 <= axi_rresp;

	-----------------------------------------------------------------------------
	-- AXI AWADDR
	-----------------------------------------------------------------------------
	axi_awwrap_en						 <= '1' when ((axi_awaddr and axi_awwrap) = axi_awwrap) else '0';

	axi_awaddr_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			case axi_fsm is
			when axi_fsm_idle =>
				if (axi_fsm_comb = axi_fsm_wr_data) then
					axi_awaddr			 <= unsigned(s_axi_awaddr);

					case (s_axi_awsize) is
					when "000" =>
						axi_awsize		 <= to_unsigned( 1, AxiAddrWidth_g);
					when "001" =>
						axi_awsize		 <= to_unsigned( 2, AxiAddrWidth_g);
					when "010" =>
						axi_awsize		 <= to_unsigned( 4, AxiAddrWidth_g);
					when others =>
						axi_awsize		 <= to_unsigned( 1, AxiAddrWidth_g);
					end case;
					axi_awburst			 <= s_axi_awburst;
					axi_awlen			 <= unsigned(s_axi_awlen);
					if (s_axi_awburst = "10") then -- If wrapping burst
						case (s_axi_awlen) is
						when X"01" =>
							case (s_axi_awsize) is
							when "000" =>
								axi_awwrap <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_awwrap <= to_unsigned( 2 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_awwrap <= to_unsigned( 2 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_awwrap <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"03" =>
							case (s_axi_awsize) is
							when "000" =>
								axi_awwrap <= to_unsigned( 4 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_awwrap <= to_unsigned( 4 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_awwrap <= to_unsigned( 4 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_awwrap <= to_unsigned( 4 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"07" =>
							case (s_axi_awsize) is
							when "000" =>
								axi_awwrap <= to_unsigned( 8 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_awwrap <= to_unsigned( 8 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_awwrap <= to_unsigned( 8 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_awwrap <= to_unsigned( 8 * 1 - 1, AxiAddrWidth_g);
							end case;
						when X"0F" =>
							case (s_axi_awsize) is
							when "000" =>
								axi_awwrap <= to_unsigned(16 * 1 - 1, AxiAddrWidth_g);
							when "001" =>
								axi_awwrap <= to_unsigned(16 * 2 - 1, AxiAddrWidth_g);
							when "010" =>
								axi_awwrap <= to_unsigned(16 * 4 - 1, AxiAddrWidth_g);
							when others =>
								axi_awwrap <= to_unsigned(16 * 1 - 1, AxiAddrWidth_g);
							end case;
						when others =>
							axi_awwrap	  <= to_unsigned( 2 * 1 - 1, AxiAddrWidth_g);
						end case;
					end if;
				end if;
			when axi_fsm_wr_data =>
				if (s_axi_wvalid = '1') then
					case (axi_awburst) is
					when "00" => -- Fixed burst
						null;
					when "01" => -- Incremental burst
						axi_awaddr		 <= axi_awaddr + axi_awsize;
					when "10" => -- Wrapping burst
						if (axi_awwrap_en = '1') then
							axi_awaddr	 <= axi_awaddr - axi_awwrap;
						else
							axi_awaddr	 <= axi_awaddr + axi_awsize;
						end if;
					when others => -- Reserved
						null;
					end case;
				end if;
				if (axi_wready = '1') then
					axi_awlen			 <= axi_awlen - 1;
				end if;
			when others =>
				null;
			end case;
		end if;
	end process axi_awaddr_proc;

	-----------------------------------------------------------------------------
	-- AXI WADDR denotes register or memory
	-----------------------------------------------------------------------------
	axi_waddr_sel						 <= '1' when ((axi_fsm = axi_fsm_wr_data) and (to_integer(unsigned(axi_awaddr(AxiAddrWidth_g - 1 downto REG_ADDR_WIDTH))) /= 0)) else '0';

	-----------------------------------------------------------------------------
	-- AXI AWREADY
	-----------------------------------------------------------------------------
	s_axi_awready						 <= '1' when ((axi_fsm = axi_fsm_idle) and (axi_fsm_comb = axi_fsm_wr_data)) else '0';

	-----------------------------------------------------------------------------
	-- AXI WID
	-----------------------------------------------------------------------------
	axi_wid_proc: process (s_axi_aclk)
	begin
		if rising_edge(s_axi_aclk) then
			if (axi_fsm = axi_fsm_idle) then
				if (axi_fsm_comb = axi_fsm_wr_data) then
					axi_awid				 <= s_axi_awid;
				else
					axi_awid				 <= (others => '0');
				end if;
			end if;
		end if;
	end process axi_wid_proc;

	s_axi_bid							 <= axi_awid;

	-----------------------------------------------------------------------------
	-- AXI WREADY
	-----------------------------------------------------------------------------
	axi_wready							 <= '1' when ((axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1')) else '0';
	s_axi_wready						 <= axi_wready;

	-----------------------------------------------------------------------------
	-- AXI WLAST
	-----------------------------------------------------------------------------
	axi_wlast							 <= '1' when ((axi_wready = '1') and (axi_awlen = X"00")) else '0';

	-----------------------------------------------------------------------------
	-- AXI BRESP
	-----------------------------------------------------------------------------
	s_axi_bresp							 <= axi_bresp;

	-----------------------------------------------------------------------------
	-- AXI BVALID
	-----------------------------------------------------------------------------
	s_axi_bvalid						 <= '1' when (axi_fsm = axi_fsm_wr_done) else '0';

	---------------------------------------------------------------------------
	-- IP to Bus data
	---------------------------------------------------------------------------
	rpl_rdata							 <= reg_rdata	 when (reg_rvalid = '1') else
											i_mem_rdata when (mem_rvalid = '1' and UseMem_g) else
											(others => '0');

	---------------------------------------------------------------------------
	-- Register read
	---------------------------------------------------------------------------
	reg_rvalid							 <= '1' when ((axi_raddr_sel = '0') and (axi_fsm = axi_fsm_rd_data) and (axi_rready = '1') and (rpl_rready = '1')) else '0';

	reg_rlast							 <= '1' when ((reg_rvalid = '1') and (axi_arlen = X"00")) else '0';

	b_rdreg : block
		signal rd_data_ext : t_aslv32(0 to NumReg_g+1) := (others => (others => '0'));
	begin
		rd_data_ext(0 to i_reg_rdata'high) <= i_reg_rdata; -- extend number of registers to prevent indexing errors
		reg_rdata_proc: process(s_axi_aclk) is
		begin
			if rising_edge(s_axi_aclk) then
				 reg_rdata(31 downto	 0)  <= rd_data_ext(to_integer(unsigned(axi_araddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW))));
			end if;
		end process reg_rdata_proc;
	end block;

	reg_rd_proc: process(s_axi_aclk) is
	begin
		if rising_edge(s_axi_aclk) then
			if (s_axi_aresetn = '0') then
				reg_rd					 <= (others => '0');
			else
				reg_rd					 <= (others => '0');
				if (reg_rvalid = '1') then
					reg_rd(to_integer(unsigned(axi_araddr_last(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW)))) <= '1';
				end if;
			end if;
		end if;
	end process reg_rd_proc;

	o_reg_rd								 <= reg_rd;

	---------------------------------------------------------------------------
	-- Register write
	---------------------------------------------------------------------------
	reg_wr_proc: process(s_axi_aclk) is
	begin
		if rising_edge(s_axi_aclk) then
			if (s_axi_aresetn = '0') then
				reg_wr					 <= (others => '0');
			else
				reg_wr					 <= (others => '0');
				if ((axi_waddr_sel = '0') and (axi_wready = '1')) then
					reg_wr(to_integer(unsigned(axi_awaddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW)))) <= '1';
				end if;
			end if;
		end if;
	end process reg_wr_proc;

	o_reg_wr								 <= reg_wr;

	slv_reg_wr_proc: process(s_axi_aclk) is
	begin
		if rising_edge(s_axi_aclk) then
			if (s_axi_aresetn = '0') then
				o_reg_wdata						<= (others => (others => '0'));
				o_reg_wdata(ResetVal_g'range)	<= ResetVal_g;
			else
				for reg_byte_index in 0 to 3 loop
					if ((axi_waddr_sel = '0') and (axi_wready = '1') and (s_axi_wstrb(reg_byte_index) = '1')) then
						o_reg_wdata(to_integer(unsigned(axi_awaddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW))))(reg_byte_index * 8 + 7 downto reg_byte_index * 8) <= s_axi_wdata(reg_byte_index * 8 + 7 downto reg_byte_index * 8);
					end if;
				end loop;
			end if;
		end if;
	end process slv_reg_wr_proc;

	-----------------------------------------------------------------------------
	-- Memory read/write
	-----------------------------------------------------------------------------
	g_mem : if UseMem_g generate
		mem_rvalid							 <= '1' when ((axi_raddr_sel = '1') and (axi_fsm = axi_fsm_rd_data) and (axi_rready = '1') and (rpl_rready = '1')) else '0';

		mem_rlast							 <= '1' when ((mem_rvalid = '1') and (axi_arlen = X"00")) else '0';

		o_mem_addr							 <= std_logic_vector(axi_awaddr - MEM_ADDR_START) when (axi_waddr_sel = '1') else
													 std_logic_vector(axi_araddr - MEM_ADDR_START);
		o_mem_wr(0)							 <= '1' when ((axi_waddr_sel = '1') and (axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1') and (s_axi_wstrb(0) = '1')) else '0';
		o_mem_wr(1)							 <= '1' when ((axi_waddr_sel = '1') and (axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1') and (s_axi_wstrb(1) = '1')) else '0';
		o_mem_wr(2)							 <= '1' when ((axi_waddr_sel = '1') and (axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1') and (s_axi_wstrb(2) = '1')) else '0';
		o_mem_wr(3)							 <= '1' when ((axi_waddr_sel = '1') and (axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1') and (s_axi_wstrb(3) = '1')) else '0';
		o_mem_wdata							 <= s_axi_wdata;
	end generate;
	g_nmem : if not UseMem_g generate
		o_mem_wr	<= (others => '0');
		o_mem_wdata	<= (others => '0');
		o_mem_addr	<= (others => '0');
	end generate;

	-----------------------------------------------------------------------------
	-- R-Channel Pipeline Stage
	-----------------------------------------------------------------------------
	-- The logic (ported legacy code) does only assert RVALID after RREADY is present. This violates the AXI specification.
	-- By using a pipeline stage to decouple the logic from the bus, this problem can be solved (the PL stage always asserts READY).
	b_rplstage : block
		signal pl_in_data 	: std_logic_vector(34+AxiIdWidth_g downto 0);
		signal pl_out_data	: std_logic_vector(pl_in_data'range);
	begin
		pl_in_data(31 downto 0)					<= rpl_rdata;
		pl_in_data(33 downto 32)				<= rpl_rresp;
		pl_in_data(34)							<= rpl_rlast;
		pl_in_data(AxiIdWidth_g+34 downto 35)	<= rpl_rid;
	
		i_rplstage : entity work.psi_common_pl_stage
			generic map (
				Width_g		=> 35+AxiIdWidth_g,
				UseRdy_g	=> true
			)
			port map (	
				Clk			=> s_axi_aclk,
				Rst			=> rst,
				InVld		=> rpl_rvalid,
				InRdy		=> rpl_rready,
				InData		=> pl_in_data,
				
				-- Output
				OutVld		=> s_axi_rvalid,
				OutRdy		=> s_axi_rready,
				OutData		=> pl_out_data
			);
		
		s_axi_rdata	<= pl_out_data(31 downto 0);
		s_axi_rresp	<= pl_out_data(33 downto 32);
		s_axi_rlast	<= pl_out_data(34);
		s_axi_rid	<= pl_out_data(AxiIdWidth_g+34 downto 35);
	end block;

end behavioral;
