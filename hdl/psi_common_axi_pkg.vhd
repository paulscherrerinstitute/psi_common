------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- AXI helper package to simplify port connections using records.
-- Designed for ISE projects with IFC1210.
--
-- Usage example:
--
--    port (
--        ------- AXI Slave interfaces:
--        axi_slv2_o   : out axi_slv_oup   := C_AXI_SLV_OUP_DEF;
--        axi_slv2_i   : in axi_slv_inp    := C_AXI_SLV_INP_DEF;
--        ------- AXI Master interfaces:
--        axi_mst0_o   : out axi_slv_inp   := C_AXI_SLV_INP_DEF;
--        axi_mst0_i   : in axi_slv_oup    := C_AXI_SLV_OUP_DEF;
--    );
--

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_common_axi_pkg is

    -- AXI BUS parameters:
    ---------------------------------------------- 
    constant  C_S_AXI_ID_WIDTH            : integer := 4;
    constant  C_S_AXI_DATA_WIDTH          : integer := 32;
    constant  C_S_AXI_ADDR_WIDTH          : integer := 32;
    constant  C_S_AXI_ARUSER_WIDTH        : integer := 1;
    constant  C_S_AXI_RUSER_WIDTH         : integer := 1;
    constant  C_S_AXI_AWUSER_WIDTH        : integer := 1;
    constant  C_S_AXI_WUSER_WIDTH         : integer := 1;
    constant  C_S_AXI_BUSER_WIDTH         : integer := 1;
    
    -- AXI Read Address Channel:
    ---------------------------------------------- 
    type axi_slv_rd_addr_inp is record
      id        : std_logic_vector(C_S_AXI_ID_WIDTH-1   downto 0);
      addr      : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      len       : std_logic_vector(7 downto 0);
      size      : std_logic_vector(2 downto 0);
      burst     : std_logic_vector(1 downto 0);
      lock      : std_logic;
      cache     : std_logic_vector(3 downto 0);
      prot      : std_logic_vector(2 downto 0);
      qos       : std_logic_vector(3 downto 0);
      region    : std_logic_vector(3 downto 0);
      user      : std_logic_vector(C_S_AXI_ARUSER_WIDTH-1 downto 0);
      valid     : std_logic;
    end record;
    
    type axi_slv_rd_addr_oup is record
      ready     : std_logic;
    end record;
    
    -- AXI Read Data Channel:
    ----------------------------------------------
    type axi_slv_rd_data_inp is record
      ready      :  std_logic;
    end record;
    
    type axi_slv_rd_data_oup is record
      id         : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      data       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      resp       : std_logic_vector(1 downto 0);
      last       : std_logic;
      user       : std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
      valid      : std_logic;
    end record;
    
    -- AXI Write Address Channel:
    ----------------------------------------------
    type axi_slv_wr_addr_inp is record
      id      :  std_logic_vector(C_S_AXI_ID_WIDTH-1   downto 0);
      addr    :  std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      len     :  std_logic_vector(7 downto 0);
      size    :  std_logic_vector(2 downto 0);
      burst   :  std_logic_vector(1 downto 0);
      lock    :  std_logic;
      cache   :  std_logic_vector(3 downto 0);
      prot    :  std_logic_vector(2 downto 0);
      qos     :  std_logic_vector(3 downto 0);
      region  :  std_logic_vector(3 downto 0);
      user    :  std_logic_vector(C_S_AXI_AWUSER_WIDTH-1 downto 0);
      valid   :  std_logic;
    end record;
    
    type axi_slv_wr_addr_oup is record
      ready      :  std_logic;
    end record;
    
    -- AXI Write Data Channel:
    ----------------------------------------------
    type axi_slv_wr_data_inp is record
      data      : std_logic_vector( C_S_AXI_DATA_WIDTH-1    downto 0);
      strb      : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      last      : std_logic;
      user      : std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
      valid     : std_logic;
    end record;
    
    type axi_slv_wr_data_oup is record
      ready     : std_logic;
    end record;
    
    -- AXI Write Response Channel:
    ----------------------------------------------
    type axi_slv_wr_resp_inp is record
      ready         : std_logic;
    end record;
    
    type axi_slv_wr_resp_oup is record
      id            : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      resp          : std_logic_vector(1 downto 0);
      user          : std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
      valid         : std_logic;
    end record;
    
    -- AXI Bus:
    ----------------------------------------------
    type axi_slv_inp is record
      ar : axi_slv_rd_addr_inp;
      dr : axi_slv_rd_data_inp;
      aw : axi_slv_wr_addr_inp;
      dw : axi_slv_wr_data_inp;
      b : axi_slv_wr_resp_inp;
    end record;
    
    type axi_slv_oup is record
      ar : axi_slv_rd_addr_oup;
      dr : axi_slv_rd_data_oup;
      aw : axi_slv_wr_addr_oup;
      dw : axi_slv_wr_data_oup;
      b : axi_slv_wr_resp_oup;
    end record;
    
    -- AXI Stream Channel
    ----------------------------------------------
    type axi_strm_src_oup is record
        data        : std_logic_vector(31 downto 0);
        valid       : std_logic;
        last        : std_logic;
    end record;
    
    type axi_strm_src_inp is record
        ready       : std_logic;
    end record;
    
    -- Initialization:
    ----------------------------------------------
    constant C_AXI_SLV_INP_DEF : axi_slv_inp := (
                ar  => ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0',(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0'),
                dr  => (others=>'0'),
                aw  => ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0',(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0'),
                dw  => ((others=>'0'),(others=>'0'),'0',(others=>'0'),'0'),
                b   => (others=>'0')
                );
                
    constant C_AXI_SLV_OUP_DEF : axi_slv_oup := (
                ar  => (others=>'0'),
                dr  => ((others=>'0'),(others=>'0'),(others=>'0'),'0',(others=>'0'),'0'),
                aw  => (others=>'0'),
                dw  => (others=>'0'),
                b   => ((others=>'0'),(others=>'0'),(others=>'0'),'0')
                );
 
    constant C_AXI_STRM_SRC_OUP_DEF : axi_strm_src_oup := (
                data => (others=>'0'),
                valid => '0',
                last => '0'
                );
 
    constant C_AXI_STRM_SRC_INP_DEF : axi_strm_src_inp := (
                ready => '0'
                );
 
end psi_common_axi_pkg;
