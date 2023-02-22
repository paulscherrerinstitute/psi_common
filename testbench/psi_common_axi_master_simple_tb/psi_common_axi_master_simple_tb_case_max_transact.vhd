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
package psi_common_axi_master_simple_tb_case_max_transact is

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

  shared variable TestCase_v : integer := -1;
  constant DelayBetweenTests : time    := 0 us;
  constant DebugPrints       : boolean := false;

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_max_transact is

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
    print("*** Tet Group 2: Maximum Open Transactions ***");

    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency] ***
      DbgPrint(DebugPrints, ">> Single word write [high latency]");
      TestCase_v := 0;
      for i in 0 to axi_max_open_transactions_g loop
        ApplyCommand(16#00001000# * i, 1, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      end loop;
      wait for DelayBetweenTests;

      -- *** Burst write [low latency] ***
      DbgPrint(DebugPrints, ">> Burst write [low latency]");
      TestCase_v := 1;
      for i in 0 to axi_max_open_transactions_g loop
        ApplyCommand(16#00001000# * i, 8, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      end loop;
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency] ***
      DbgPrint(DebugPrints, ">> Single word read [high latency]");
      TestCase_v := 2;
      for i in 0 to axi_max_open_transactions_g loop
        ApplyCommand(16#00001000# * i, 1, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      end loop;
      wait for DelayBetweenTests;

      -- *** Burst read [low latency] ***
      DbgPrint(DebugPrints, ">> Burst read [low latency]");
      TestCase_v := 3;
      for i in 0 to axi_max_open_transactions_g loop
        ApplyCommand(16#00001000# * i, 8, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      end loop;
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
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency] ***
      WaitCase(0, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        ApplyWrDataSingle(16#0001# * i, "11", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);
      end loop;

      -- *** Burst write [low latency] ***
      WaitCase(1, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        ApplyWrDataMulti(16#0001# * i, 1, 8, "10", "01", wr_dat_i, wr_data_be, wr_vld_i, wr_rdy_o, Clk);
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency] ***		
      WaitCase(2, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        CheckRdDataSingle(16#0001# * i, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      end loop;

      -- *** Burst read [low latency] ***
      WaitCase(3, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        CheckRdDataMulti(16#0001# * i, 1, 8, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
      end loop;
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
    -- Writes
    ------------------------------------------------------------------
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency] ***
      WaitCase(0, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        WaitForCompletion(true, 10 us, wr_done_o, wr_error_o, Clk);
      end loop;

      -- *** Burst write [low latency] ***
      WaitCase(1, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        WaitForCompletion(true, 10 us, wr_done_o, wr_error_o, Clk);
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency] ***	
      WaitCase(2, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        WaitForCompletion(true, 20 us, rd_done_o, rd_error_o, Clk);
      end loop;

      -- *** Burst read [low latency] ***
      WaitCase(3, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        WaitForCompletion(true, 20 us, rd_done_o, rd_error_o, Clk);
      end loop;
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
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Single word wirte [high latency] ***
      WaitCase(0, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        -- check if last transaction is really delayed until response generation is started
        if i = axi_max_open_transactions_g then
          wait for 1 us;
          wait until rising_edge(Clk);
          assert (axi_ms.awvalid = '0') and (axi_ms.wvalid = '0') report "###ERROR###: Transaction not delayed until responses generated" severity error;
          -- send responses
          for i in 0 to axi_max_open_transactions_g - 1 loop
            axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
          end loop;
        end if;
        -- check transaction
        AxiCheckWrSingle(16#00001000# * i, 16#0001# * i, "11", "XX", axi_ms, axi_sm, Clk, false); --without response
      end loop;
      -- Send last response
      axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst write [low latency] ***
      WaitCase(1, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        -- check if last transaction is really delayed until response generation is started
        if i = axi_max_open_transactions_g then
          wait for 1 us;
          wait until rising_edge(Clk);
          assert (axi_ms.awvalid = '0') and (axi_ms.wvalid = '0') report "###ERROR###: Transaction not delayed until responses generated" severity error;
          -- send responses
          for i in 0 to axi_max_open_transactions_g - 1 loop
            axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
          end loop;
        end if;
        -- check transaction
        AxiCheckWrBurst(16#00001000# * i, 16#0001# * i, 1, 8, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk, false); --without response
      end loop;
      -- Send last response
      axi_apply_bresp(xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------
    if Generics_c.impl_read_g then
      -- *** Single word read [high latency] ***			
      WaitCase(2, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        -- check if last transaction is really delayed until response generation is started
        if i = axi_max_open_transactions_g then
          wait for 1 us;
          wait until rising_edge(Clk);
          assert axi_ms.arvalid = '0' report "###ERROR###: Transaction not delayed until responses generated" severity error;
          -- send responses
          for i in 0 to axi_max_open_transactions_g - 1 loop
            axi_apply_rresp_single(std_logic_vector(to_unsigned(16#0001# * i, axi_data_width_g)), xRESP_OKAY_c, axi_ms, axi_sm, Clk);
          end loop;
        end if;
        -- check transaction
        axi_expect_ar(16#00001000# * i, AxSIZE_2_c, 1 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      end loop;
      -- Send last response
      axi_apply_rresp_single(std_logic_vector(to_unsigned(16#0001# * axi_max_open_transactions_g, axi_data_width_g)), xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Burst read [low latency] ***
      WaitCase(3, Clk);
      for i in 0 to axi_max_open_transactions_g loop
        -- check if last transaction is really delayed until response generation is started
        if i = axi_max_open_transactions_g then
          wait for 1 us;
          wait until rising_edge(Clk);
          assert axi_ms.arvalid = '0' report "###ERROR###: Transaction not delayed until responses generated" severity error;
          -- send responses
          for i in 0 to axi_max_open_transactions_g - 1 loop
            axi_apply_rresp_burst(8, 16#0001# * i, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
          end loop;
        end if;
        -- check transaction
        axi_expect_ar(16#00001000# * i, AxSIZE_2_c, 8 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
      end loop;
      -- Send last response
      axi_apply_rresp_burst(8, 16#0001# * axi_max_open_transactions_g, 1, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

  end procedure;

end;
