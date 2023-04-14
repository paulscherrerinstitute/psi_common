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
use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_simple_tb_case_simple_tf is

  procedure user_cmd(
    signal cmd_wr_addr_i   : inout std_logic_vector;
    signal cmd_wr_size_i   : inout std_logic_vector;
    signal cmd_wr_low_lat_i : inout std_logic;
    signal cmd_wr_vld_i    : inout std_logic;
    signal cmd_wr_rdy_o    : in std_logic;
    signal cmd_rd_addr_i   : inout std_logic_vector;
    signal cmd_rd_size_o   : inout std_logic_vector;
    signal cmd_rd_low_lat_i : inout std_logic;
    signal cmd_rd_vld_i    : inout std_logic;
    signal cmd_rd_rdy_o    : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  procedure user_data(
    signal wr_dat_i   : inout std_logic_vector;
    signal wr_data_be     : inout std_logic_vector;
    signal wr_vld_i    : inout std_logic;
    signal wr_rdy_o    : in std_logic;
    signal rd_dat_o   : in std_logic_vector;
    signal rd_vld_o    : in std_logic;
    signal rd_rdy_i    : inout std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  procedure user_resp(
    signal wr_done_o      : in std_logic;
    signal wr_error_o     : in std_logic;
    signal rd_done_o      : in std_logic;
    signal rd_error_o     : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  procedure axi(
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  shared variable TestCase_v  : integer := -1;
  shared variable ExpectCmd_v : boolean;
  constant DelayBetweenTests  : time    := 0.2 us; -- Minimum is 0.2 us (because of test implementation...)
  constant DebugPrints        : boolean := false;

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_simple_tf is
  procedure WaitCase(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while TestCase_v /= nr loop
      wait until rising_edge(Clk);
    end loop;
  end procedure;

  procedure user_cmd(
    signal cmd_wr_addr_i   : inout std_logic_vector;
    signal cmd_wr_size_i   : inout std_logic_vector;
    signal cmd_wr_low_lat_i : inout std_logic;
    signal cmd_wr_vld_i    : inout std_logic;
    signal cmd_wr_rdy_o    : in std_logic;
    signal cmd_rd_addr_i   : inout std_logic_vector;
    signal cmd_rd_size_o   : inout std_logic_vector;
    signal cmd_rd_low_lat_i : inout std_logic;
    signal cmd_rd_vld_i    : inout std_logic;
    signal cmd_rd_rdy_o    : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    wait for DelayBetweenTests;
    print("*** Tet Group 1: Simple Transfer ***");

    ------------------------------------------------------------------
    -- High Latency Writes
    ------------------------------------------------------------------		
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency, command+data together] ***
      DbgPrint(DebugPrints, ">> Single word write [high latency, command+data together]");
      TestCase_v := 0;
      ApplyCommand(16#12345678#, 1, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word wirte [high latency, command before data] ***
      DbgPrint(DebugPrints, ">> Single word wirte [high latency, command before data]");
      TestCase_v := 1;
      ApplyCommand(16#00010020#, 1, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word wirte [high latency, command after data + error] ***
      DbgPrint(DebugPrints, ">> Single word wirte [high latency, command after data + error]");
      TestCase_v := 2;
      wait for 200 ns;
      ApplyCommand(16#00010030#, 1, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst wirte[high latency] ***		
      DbgPrint(DebugPrints, ">> Burst write [high latency]");
      TestCase_v := 3;
      ApplyCommand(16#00020000#, 12, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Low Latency Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [low latency, command+data together] ***
      DbgPrint(DebugPrints, ">> Single word write [low latency, command+data together]");
      TestCase_v := 4;
      ApplyCommand(16#12345678#, 1, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word wirte [low latency, command before data] ***
      DbgPrint(DebugPrints, ">> Single word wirte [low latency, command before data]");
      TestCase_v := 5;
      ApplyCommand(16#00010020#, 1, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word wirte [low latency, command after data + error] ***
      DbgPrint(DebugPrints, ">> Single word wirte [low latency, command after data + error]");
      TestCase_v := 6;
      wait for 200 ns;
      ApplyCommand(16#00010030#, 1, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst wirte[low latency] ***
      DbgPrint(DebugPrints, ">> Burst write [low latency]");
      TestCase_v := 7;
      ApplyCommand(16#00020000#, 12, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      wait for DelayBetweenTests;
    end if;
    ------------------------------------------------------------------
    -- High Latency Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency, space available] ***
      DbgPrint(DebugPrints, ">> Single word read [high latency, space available]");
      TestCase_v := 8;
      ApplyCommand(16#12345678#, 1, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst read [high latency, space available] ***
      DbgPrint(DebugPrints, ">> Burst read [high latency, space available]");
      TestCase_v := 9;
      ApplyCommand(16#00020000#, 12, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word read [high latency, wait for space] ***
      DbgPrint(DebugPrints, ">> Single word read [high latency, wait for space]");
      TestCase_v := 10;
      -- Do a read to fill the FIFO
      ApplyCommand(16#00020000#, data_fifo_depth_g, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      -- Do the test read
      ApplyCommand(16#12345678#, 1, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst read [high latency, wait for space] ***
      DbgPrint(DebugPrints, ">> Burst read [high latency, wait for space");
      TestCase_v := 11;
      -- Do a read to fill the FIFO
      ApplyCommand(16#00020000#, data_fifo_depth_g - 4, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      -- Do the test read
      ApplyCommand(16#00021000#, data_fifo_depth_g - 4, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Low Latency Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Single word read [low latency, space available] ***
      DbgPrint(DebugPrints, ">> Single word read [low latency, space available]");
      TestCase_v := 12;
      ApplyCommand(16#12345678#, 1, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst read [low latency, space available] ***
      DbgPrint(DebugPrints, ">> Burst read [low latency, space available]");
      TestCase_v := 13;
      ApplyCommand(16#00020000#, 12, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Single word read [low latency, no space] ***
      DbgPrint(DebugPrints, ">> Single word read [low latency, no space]");
      TestCase_v := 14;
      -- Do a read to fill the FIFO
      ApplyCommand(16#00020000#, data_fifo_depth_g, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      -- Do the test read
      ApplyCommand(16#12345678#, 1, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;

      -- *** Burst read [low latency, no space] ***
      DbgPrint(DebugPrints, ">> Burst read [low latency, no space");
      TestCase_v := 15;
      -- Do a read to fill the FIFO
      ApplyCommand(16#00020000#, data_fifo_depth_g - 4, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      -- Do the test read
      ApplyCommand(16#00021000#, data_fifo_depth_g - 4, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      wait for DelayBetweenTests;
    end if;

    wait for DelayBetweenTests;

  end procedure;

  procedure user_data(
    signal wr_dat_i   : inout std_logic_vector;
    signal wr_data_be     : inout std_logic_vector;
    signal wr_vld_i    : inout std_logic;
    signal wr_rdy_o    : in std_logic;
    signal rd_dat_o   : in std_logic_vector;
    signal rd_vld_o    : in std_logic;
    signal rd_rdy_i    : inout std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    ------------------------------------------------------------------
    -- High Latency Writes
    ------------------------------------------------------------------
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency, command+data together] ***
      WaitCase(0, Clk);
      ApplyWrDataSingle(16#BEEF#, "10", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);

      -- *** Single word wirte [high latency, command before data] ***
      ExpectCmd_v := false;
      WaitCase(1, Clk);
      wait for 200 ns;
      wait until rising_edge(Clk);
      ApplyWrDataSingle(16#BABE#, "11", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);
      ExpectCmd_v := true;

      -- *** Single word wirte [high latency, command after data + error] ***
      WaitCase(2, Clk);
      wait until rising_edge(Clk);
      ApplyWrDataSingle(16#0001#, "11", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);

      -- *** Burst wirte[high latency] ***
      ExpectCmd_v := false;
      WaitCase(3, Clk);
      wait for 200 ns;
      wait until rising_edge(Clk);
      ApplyWrDataMulti(16#1000#, 1, 12, "10", "01", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);
      ExpectCmd_v := true;
    end if;

    ------------------------------------------------------------------
    -- Low Latency Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [low latency, command+data together] ***
      WaitCase(4, Clk);
      ApplyWrDataSingle(16#BEEF#, "10", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);

      -- *** Single word wirte [low latency, command before data] ***
      WaitCase(5, Clk);
      wait for 200 ns;
      wait until rising_edge(Clk);
      ApplyWrDataSingle(16#BABE#, "11", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);

      -- *** Single word wirte [low latency, command after data + error] ***
      WaitCase(6, Clk);
      wait until rising_edge(Clk);
      ApplyWrDataSingle(16#0001#, "11", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);

      -- *** Burst wirte[low latency] ***
      WaitCase(7, Clk);
      wait until rising_edge(Clk);
      ApplyWrDataMulti(16#1000#, 1, 12, "10", "01", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);
    end if;

    ------------------------------------------------------------------
    -- High Latency Reads
    ------------------------------------------------------------------		
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency, space available] ***
      WaitCase(8, Clk);
      CheckRdDataSingle(16#BEEF#, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Burst read [high latency, space available] ***
      WaitCase(9, Clk);
      CheckRdDataMulti(16#1000#, 1, 12, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Single word read [high latency, wait for space] ***
      WaitCase(10, Clk);
      -- Read to fill the FIFO
      CheckRdDataMulti(16#1000#, 1, data_fifo_depth_g, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      -- Test Read
      CheckRdDataSingle(16#BEEF#, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Burst read [high latency, wait for space] ***
      WaitCase(11, Clk);
      -- Read to fill the FIFO
      CheckRdDataMulti(16#1000#, 1, data_fifo_depth_g - 4, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      -- Test Read	
      CheckRdDataMulti(16#2000#, 1, data_fifo_depth_g - 4, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
    end if;

    ------------------------------------------------------------------
    -- Low Latency Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Single word read [low latency, space available] ***
      WaitCase(12, Clk);
      CheckRdDataSingle(16#BEEF#, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Burst read [low latency, space available] ***
      WaitCase(13, Clk);
      CheckRdDataMulti(16#1000#, 1, 12, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Single word read [low latency, no space] ***
      WaitCase(14, Clk);
      -- Read to fill the FIFO
      CheckRdDataMulti(16#1000#, 1, data_fifo_depth_g, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      -- Test Read
      CheckRdDataSingle(16#BEEF#, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Burst read [low latency, no space] ***		
      WaitCase(15, Clk);
      -- Read to fill the FIFO
      CheckRdDataMulti(16#1000#, 1, data_fifo_depth_g - 4, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      -- Test Read	
      CheckRdDataMulti(16#2000#, 1, data_fifo_depth_g - 4, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
    end if;

  end procedure;

  procedure user_resp(
    signal wr_done_o      : in std_logic;
    signal wr_error_o     : in std_logic;
    signal rd_done_o      : in std_logic;
    signal rd_error_o     : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    ------------------------------------------------------------------
    -- High Latency Writes
    ------------------------------------------------------------------		
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency, command+data together] ***
      WaitCase(0, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Single word wirte [high latency, command before data] ***
      WaitCase(1, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Single word wirte [high latency, command after data + error] ***
      WaitCase(2, Clk);
      WaitForCompletion(false, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Burst wirte[high latency] ***
      WaitCase(3, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);
    end if;

    ------------------------------------------------------------------
    -- Low Latency Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [low latency, command+data together] ***
      WaitCase(4, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Single word wirte [low latency, command before data] ***
      WaitCase(5, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Single word wirte [low latency, command after data + error] ***
      WaitCase(6, Clk);
      WaitForCompletion(false, 1 us, wr_done_o, wr_error_o, Clk);

      -- *** Burst wirte[low latency] ***
      WaitCase(7, Clk);
      WaitForCompletion(true, 1 us, wr_done_o, wr_error_o, Clk);
    end if;

    ------------------------------------------------------------------
    -- High Latency Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency, space available] ***		
      WaitCase(8, Clk);
      WaitForCompletion(true, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Burst read [high latency, space available] ***
      WaitCase(9, Clk);
      WaitForCompletion(false, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Single word read [high latency, wait for space] ***
      WaitCase(10, Clk);
      -- Read to fill the FIFO
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
      -- Test Read
      WaitForCompletion(true, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Burst read [high latency, wait for space] ***;
      WaitCase(11, Clk);
      -- Read to fill the FIFO
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
      -- Test Read
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
    end if;

    ------------------------------------------------------------------
    -- Low Latency Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [low latency, space available] ***		
      WaitCase(12, Clk);
      WaitForCompletion(true, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Burst read [low latency, space available] ***
      WaitCase(13, Clk);
      WaitForCompletion(false, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Single word read [low latency, no space] ***
      WaitCase(14, Clk);
      -- Read to fill the FIFO
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
      -- Test Read
      WaitForCompletion(true, 1 us, rd_done_o, rd_error_o, Clk);

      -- *** Burst read [low latency, no space] ***	
      WaitCase(15, Clk);
      -- Read to fill the FIFO
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
      -- Test Read
      WaitForCompletion(true, 10 us, rd_done_o, rd_error_o, Clk);
    end if;

  end procedure;

  procedure axi(
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    axi_slave_init(axi_sm);

    ------------------------------------------------------------------
    -- High Latency Writes
    ------------------------------------------------------------------		
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency, command+data together] ***
      WaitCase(0, Clk);
      AxiCheckWrSingle(16#12345678#, 16#BEEF#, "10", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Single word wirte [high latency, command before data] ***
      WaitCase(1, Clk);
      while not ExpectCmd_v loop
        wait until rising_edge(Clk);
        assert axi_ms.awvalid = '0' report "###ERROR###: High Latency did not wait for data in fifo" severity error;
      end loop;
      AxiCheckWrSingle(16#00010020#, 16#BABE#, "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Single word wirte [high latency, command before data] ***
      WaitCase(2, Clk);
      AxiCheckWrSingle(16#00010030#, 16#0001#, "11", xRESP_DECERR_c, axi_ms, axi_sm, Clk);

      -- *** Burst wirte[high latency] ***
      WaitCase(3, Clk);
      while not ExpectCmd_v loop
        wait until rising_edge(Clk);
        assert axi_ms.awvalid = '0' report "###ERROR###: High Latency did not wait for data in fifo" severity error;
      end loop;
      AxiCheckWrBurst(16#00020000#, 16#1000#, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- Low Latency Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [low latency, command+data together] ***
      WaitCase(4, Clk);
      AxiCheckWrSingle(16#12345678#, 16#BEEF#, "10", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Single word wirte [low latency, command before data] ***
      WaitCase(5, Clk);
      AxiCheckWrSingle(16#00010020#, 16#BABE#, "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Single word wirte [low latency, command before data] ***
      WaitCase(6, Clk);
      AxiCheckWrSingle(16#00010030#, 16#0001#, "11", xRESP_DECERR_c, axi_ms, axi_sm, Clk);

      -- *** Burst wirte[low latency] ***
      WaitCase(7, Clk);
      AxiCheckWrBurst(16#00020000#, 16#1000#, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- High Latency Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency, space available] ***	
      WaitCase(8, Clk);
      AxiCheckRdSingle(16#12345678#, 16#BEEF#, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst read [high latency, space available] ***
      WaitCase(9, Clk);
      AxiCheckRdBurst(16#00020000#, 16#1000#, 1, 12, xRESP_DECERR_c, axi_ms, axi_sm, Clk);

      -- *** Single word read [high latency, wait for space] ***
      WaitCase(10, Clk);
      -- Read to fill the FIFO
      axi_expect_ar(16#00020000#, AxSIZE_2_c, data_fifo_depth_g - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      -- Delay the response and check if the read command is delayed
      CheckNoActivity(axi_ms.arvalid, 0.2 us, 0, "Unexpected read command received");
      wait until rising_edge(Clk);
      -- send response
      axi_apply_rresp_burst(data_fifo_depth_g, 16#1000#, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      -- Test Read (can happen now)
      AxiCheckRdSingle(16#12345678#, 16#BEEF#, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst read [high latency, wait for space] ***
      WaitCase(11, Clk);
      -- Read to fill the FIFO
      axi_expect_ar(16#00020000#, AxSIZE_2_c, data_fifo_depth_g - 4 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      -- Delay the response and check if the read command is delayed
      CheckNoActivity(axi_ms.arvalid, 0.2 us, 0, "Unexpected read command received");
      wait until rising_edge(Clk);
      -- send response
      axi_apply_rresp_burst(data_fifo_depth_g - 4, 16#1000#, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      -- Test Read (can happen now)
      AxiCheckRdBurst(16#00021000#, 16#2000#, 1, data_fifo_depth_g - 4, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- Low Latency Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [low latency, space available] ***	
      WaitCase(12, Clk);
      AxiCheckRdSingle(16#12345678#, 16#BEEF#, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst read [low latency, space available] ***
      WaitCase(13, Clk);
      AxiCheckRdBurst(16#00020000#, 16#1000#, 1, 12, xRESP_DECERR_c, axi_ms, axi_sm, Clk);

      -- *** Single word read [low latency, no space] ***
      WaitCase(14, Clk);
      -- Expect commands
      axi_expect_ar(16#00020000#, AxSIZE_2_c, data_fifo_depth_g - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      axi_expect_ar(16#12345678#, AxSIZE_2_c, 1 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      -- Send responses
      axi_apply_rresp_burst(data_fifo_depth_g, 16#1000#, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      axi_apply_rresp_single(X"BEEF", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst read [low latency, no space] ***	
      WaitCase(15, Clk);
      -- Expect commands
      axi_expect_ar(16#00020000#, AxSIZE_2_c, data_fifo_depth_g - 4 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      axi_expect_ar(16#00021000#, AxSIZE_2_c, data_fifo_depth_g - 4 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      -- Send responses
      axi_apply_rresp_burst(data_fifo_depth_g - 4, 16#1000#, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      axi_apply_rresp_burst(data_fifo_depth_g - 4, 16#2000#, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

  end procedure;

end;
