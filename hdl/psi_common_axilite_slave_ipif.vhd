------------------------------------------------------------------------------
--  Copyright (c) 2020 by Enclustra GmbH, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

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
entity psi_common_axilite_slave_ipif is
    generic (
        -- IP Interface Config
        NumReg_g                    : integer   := 32;                              -- $$ export=true $$
        ResetVal_g                  : t_aslv32  := (0 => (others => '0'));          -- $$ constant=(X"0001ABCD", X"00021234") $$
        UseMem_g                    : boolean   := true;                            -- $$ export=true $$
        -- AXI Config
        AxiAddrWidth_g              : integer := 8
    );
    port
    (
        --------------------------------------------------------------------------
        -- AXI Slave Bus Interface
        --------------------------------------------------------------------------
        -- System
        s_axilite_aclk                  : in    std_logic;                                          -- $$ type=clk; freq=100e6 $$
        s_axilite_aresetn               : in    std_logic;                                          -- $$ type=rst; clk=s_axi_aclk; lowactive=true $$
        -- Read address channel         
        s_axilite_araddr                : in    std_logic_vector(AxiAddrWidth_g-1 downto 0);        -- $$ proc=axi $$   
        s_axilite_arvalid               : in    std_logic;                                          -- $$ proc=axi $$
        s_axilite_arready               : out   std_logic;                                          -- $$ proc=axi $$
        -- Read data channel
        s_axilite_rdata                 : out   std_logic_vector(31 downto 0);                      -- $$ proc=axi $$
        s_axilite_rresp                 : out   std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
        s_axilite_rvalid                : out   std_logic;                                          -- $$ proc=axi $$
        s_axilite_rready                : in    std_logic;                                          -- $$ proc=axi $$
        -- Write address channel
        s_axilite_awaddr                : in    std_logic_vector(AxiAddrWidth_g-1 downto 0);        -- $$ proc=axi $$
        s_axilite_awvalid               : in    std_logic;                                          -- $$ proc=axi $$
        s_axilite_awready               : out   std_logic;                                          -- $$ proc=axi $$
        -- Write data channel
        s_axilite_wdata                 : in    std_logic_vector(31     downto 0);                  -- $$ proc=axi $$
        s_axilite_wstrb                 : in    std_logic_vector(3 downto 0);                       -- $$ proc=axi $$
        s_axilite_wvalid                : in    std_logic;                                          -- $$ proc=axi $$
        s_axilite_wready                : out   std_logic;                                          -- $$ proc=axi $$
        -- Write response channel
        s_axilite_bresp                 : out   std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
        s_axilite_bvalid                : out   std_logic;                                          -- $$ proc=axi $$
        s_axilite_bready                : in    std_logic;                                          -- $$ proc=axi $$
        --------------------------------------------------------------------------
        -- Register Interface
        --------------------------------------------------------------------------
        o_reg_rd                        : out   std_logic_vector(NumReg_g-1 downto   0);                                        -- $$ proc=ip $$
        i_reg_rdata                     : in    t_aslv32(0 to NumReg_g-1)                   := (others => (others => '0'));     -- $$ proc=ip $$
        o_reg_wr                        : out   std_logic_vector(NumReg_g-1 downto   0);                                        -- $$ proc=ip $$
        o_reg_wdata                     : out   t_aslv32(0 to NumReg_g-1);                                                      -- $$ proc=ip $$
        --------------------------------------------------------------------------
        -- Memory Interface
        --------------------------------------------------------------------------
        o_mem_addr                      : out   std_logic_vector(AxiAddrWidth_g - 1 downto  0);                                 -- $$ proc=ip $$
        o_mem_wr                        : out   std_logic_vector( 3 downto   0);                                                -- $$ proc=ip $$
        o_mem_wdata                     : out   std_logic_vector(31 downto   0);                                                -- $$ proc=ip $$
        i_mem_rdata                     : in    std_logic_vector(31 downto   0)             := (others => '0')                  -- $$ proc=ip $$
    );
end psi_common_axilite_slave_ipif;

architecture behavioral of psi_common_axilite_slave_ipif is
begin
    i_interface : entity work.psi_common_axi_slave_ipif
        generic map (
            NumReg_g                    => NumReg_g,
            ResetVal_g                  => ResetVal_g,
            UseMem_g                    => UseMem_g,
            AxiIdWidth_g                => 1,
            AxiAddrWidth_g              => AxiAddrWidth_g
        )
        port map
        (
            s_axi_aclk                  => s_axilite_aclk,
            s_axi_aresetn               => s_axilite_aresetn,
            s_axi_arid                  => "0",
            s_axi_araddr                => s_axilite_araddr,
            s_axi_arlen                 => X"00",
            s_axi_arsize                => "010",
            s_axi_arburst               => "01",
            s_axi_arlock                => '0',
            s_axi_arcache               => "0011",
            s_axi_arprot                => "000",
            s_axi_arvalid               => s_axilite_arvalid,
            s_axi_arready               => s_axilite_arready,
            s_axi_rid                   => open,
            s_axi_rdata                 => s_axilite_rdata,
            s_axi_rresp                 => s_axilite_rresp,
            s_axi_rlast                 => open,
            s_axi_rvalid                => s_axilite_rvalid,
            s_axi_rready                => s_axilite_rready,
            s_axi_awid                  => "0",
            s_axi_awaddr                => s_axilite_awaddr,
            s_axi_awlen                 => x"00",
            s_axi_awsize                => "010",
            s_axi_awburst               => "01",
            s_axi_awlock                => '0',
            s_axi_awcache               => "0011",
            s_axi_awprot                => "000",
            s_axi_awvalid               => s_axilite_awvalid,
            s_axi_awready               => s_axilite_awready,
            s_axi_wdata                 => s_axilite_wdata,
            s_axi_wstrb                 => s_axilite_wstrb,
            s_axi_wlast                 => '1',
            s_axi_wvalid                => s_axilite_wvalid,
            s_axi_wready                => s_axilite_wready,
            s_axi_bid                   => open,
            s_axi_bresp                 => s_axilite_bresp,
            s_axi_bvalid                => s_axilite_bvalid,
            s_axi_bready                => s_axilite_bready,
            o_reg_rd                    => o_reg_rd,
            i_reg_rdata                 => i_reg_rdata,
            o_reg_wr                    => o_reg_wr,
            o_reg_wdata                 => o_reg_wdata,
            o_mem_addr                  => o_mem_addr,
            o_mem_wr                    => o_mem_wr,
            o_mem_wdata                 => o_mem_wdata,
            i_mem_rdata                 => i_mem_rdata
        );
end behavioral;
