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
-- The following Abreviations in signal names are used to identify the direction.
-- sm/SM = Slave  -> Master
-- ms/MS = Master -> Slave
--
-- Usage example:
--
--    port (
--        ------- AXI Slave interfaces:
--        axi_slv2_o   : out rec_axi_sm   := C_AXI_SM_DEF;
--        axi_slv2_i   : in  rec_axi_ms   := C_AXI_MS_DEF;
--        ------- AXI Master interfaces:
--        axi_mst0_o   : out rec_axi_ms   := C_AXI_MS_DEF;
--        axi_mst0_i   : in  rec_axi_sm   := C_AXI_SM_DEF;
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
    constant  C_S_AXI_ID_WIDTH            : integer := 1;
    constant  C_S_AXI_DATA_WIDTH          : integer := 32;
    constant  C_S_AXI_ADDR_WIDTH          : integer := 32;
    constant  C_S_AXI_ARUSER_WIDTH        : integer := 1;
    constant  C_S_AXI_RUSER_WIDTH         : integer := 1;
    constant  C_S_AXI_AWUSER_WIDTH        : integer := 1;
    constant  C_S_AXI_WUSER_WIDTH         : integer := 1;
    constant  C_S_AXI_BUSER_WIDTH         : integer := 1;
    
    -- AXI Read Address Channel:
    ---------------------------------------------- 
    type axi_ms_rd_addr is record
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
    
    type axi_sm_rd_addr is record
      ready     : std_logic;
    end record;
    
    -- AXI Read Data Channel:
    ----------------------------------------------
    type axi_ms_rd_data is record
      ready      :  std_logic;
    end record;
    
    type axi_sm_rd_data is record
      id         : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      data       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      resp       : std_logic_vector(1 downto 0);
      last       : std_logic;
      user       : std_logic_vector(C_S_AXI_RUSER_WIDTH-1 downto 0);
      valid      : std_logic;
    end record;
    
    -- AXI Write Address Channel:
    ----------------------------------------------
    type axi_ms_wr_addr is record
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
    
    type axi_sm_wr_addr is record
      ready      :  std_logic;
    end record;
    
    -- AXI Write Data Channel:
    ----------------------------------------------
    type axi_ms_wr_data is record
      data      : std_logic_vector( C_S_AXI_DATA_WIDTH-1    downto 0);
      strb      : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      last      : std_logic;
      user      : std_logic_vector(C_S_AXI_WUSER_WIDTH-1 downto 0);
      valid     : std_logic;
    end record;
    
    type axi_sm_wr_data is record
      ready     : std_logic;
    end record;
    
    -- AXI Write Response Channel:
    ----------------------------------------------
    type axi_ms_wr_resp is record
      ready         : std_logic;
    end record;
    
    type axi_sm_wr_resp is record
      id            : std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      resp          : std_logic_vector(1 downto 0);
      user          : std_logic_vector(C_S_AXI_BUSER_WIDTH-1 downto 0);
      valid         : std_logic;
    end record;
    
    -- AXI Bus:
    ----------------------------------------------
    type rec_axi_ms is record
      ar : axi_ms_rd_addr;
      dr : axi_ms_rd_data;
      aw : axi_ms_wr_addr;
      dw : axi_ms_wr_data;
      b  : axi_ms_wr_resp;
    end record;
    
    type rec_axi_sm is record
      ar : axi_sm_rd_addr;
      dr : axi_sm_rd_data;
      aw : axi_sm_wr_addr;
      dw : axi_sm_wr_data;
      b  : axi_sm_wr_resp;
    end record;
    
    -- AXI Bus Array:
    ----------------------------------------------
    type typ_arr_axi_sm  is array (natural range <>) of rec_axi_sm;
    type typ_arr_axi_ms  is array (natural range <>) of rec_axi_ms;
    
    
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
    constant C_AXI_MS_DEF : rec_axi_ms := (
                ar  => ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0',(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0'),
                dr  => (others=>'0'),
                aw  => ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0',(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),'0'),
                dw  => ((others=>'0'),(others=>'0'),'0',(others=>'0'),'0'),
                b   => (others=>'0')
                );
                
    constant C_AXI_SM_DEF : rec_axi_sm := (
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
