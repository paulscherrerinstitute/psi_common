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
use work.psi_common_axi_master_full_tb_pkg.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_full_tb_case_user_hs is

  procedure user_cmd(
    signal Clk          : in std_logic;
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
    constant Generics_c : Generics_t);

  procedure user_data(
    signal Clk          : in std_logic;
    signal wr_dat_i   : inout std_logic_vector;
    signal wr_vld_i    : inout std_logic;
    signal wr_rdy_o    : in std_logic;
    signal rd_dat_o   : in std_logic_vector;
    signal rd_vld_o    : in std_logic;
    signal rd_rdy_i    : inout std_logic;
    constant Generics_c : Generics_t);

  procedure user_resp(
    signal Clk          : in std_logic;
    signal wr_done_o      : in std_logic;
    signal wr_error_o     : in std_logic;
    signal rd_done_o      : in std_logic;
    signal rd_error_o     : in std_logic;
    constant Generics_c : Generics_t);

  procedure axi(
    signal Clk          : in std_logic;
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    constant Generics_c : Generics_t);

  shared variable TestCase_v : integer := -1;
  shared variable AllDone_v  : integer := -1;
  constant DebugPrints       : boolean := false;
  constant DelayBetweenTests : time    := 0 us;

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_case_user_hs is

  procedure WaitCase(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while TestCase_v /= nr loop
      wait until rising_edge(Clk);
    end loop;
  end procedure;

  procedure WaitDone(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while AllDone_v /= nr loop
      wait until rising_edge(Clk);
    end loop;
  end procedure;

  procedure user_cmd(
    signal Clk          : in std_logic;
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
    constant Generics_c : Generics_t) is
  begin
    wait for DelayBetweenTests;
    wait until rising_edge(Clk);

    print("*** Tet Group 3: User Data Handshaking ***");

    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Lo Latency write with delay ***
      DbgPrint(DebugPrints, ">> Lo Latency write with delay ");
      TestCase_v := 0;
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          ApplyCommand(16#02000000# + offs, size, true, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
        end loop;
      end loop;
      WaitDone(0, Clk);
      wait for DelayBetweenTests;

      -- *** Hi Latency write with delay ***
      DbgPrint(DebugPrints, ">> Hi Latency write with delay ");
      TestCase_v := 1;
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          ApplyCommand(16#02000000# + offs, size, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
        end loop;
      end loop;
      WaitDone(1, Clk);
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Lo Latency read with delay ***
      DbgPrint(DebugPrints, ">> Lo Latency read with delay ");
      TestCase_v := 2;
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          ApplyCommand(16#02000000# + offs, size, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
        end loop;
      end loop;
      WaitDone(2, Clk);
      wait for DelayBetweenTests;

      -- *** Hi Latency read with delay ***
      DbgPrint(DebugPrints, ">> Hi Latency read with delay ");
      TestCase_v := 3;
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          ApplyCommand(16#02000000# + offs, size, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
        end loop;
      end loop;
      WaitDone(3, Clk);
      wait for DelayBetweenTests;
    end if;
  end procedure;

  procedure user_data(
    signal Clk          : in std_logic;
    signal wr_dat_i   : inout std_logic_vector;
    signal wr_vld_i    : inout std_logic;
    signal wr_rdy_o    : in std_logic;
    signal rd_dat_o   : in std_logic_vector;
    signal rd_vld_o    : in std_logic;
    signal rd_rdy_i    : inout std_logic;
    constant Generics_c : Generics_t) is
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Lo Latency write with delay ***
      WaitCase(0, Clk);
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          ApplyWrData(16#10# + offs * 16, size, wr_dat_i, wr_vld_i, wr_rdy_o, Clk, 100 ns);
        end loop;
      end loop;

      -- *** Hi Latency write with delay ***
      WaitCase(1, Clk);
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          ApplyWrData(16#10# + offs * 16, size, wr_dat_i, wr_vld_i, wr_rdy_o, Clk, 100 ns);
        end loop;
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Lo Latency read with delay ***
      WaitCase(2, Clk);
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          CheckRdData(16#10# + offs * 16, size, rd_dat_o, rd_vld_o, rd_rdy_i, Clk, 100 ns);
        end loop;
      end loop;

      -- *** Hi Latency read with delay ***
      WaitCase(3, Clk);
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          CheckRdData(16#10# + offs * 16, size, rd_dat_o, rd_vld_o, rd_rdy_i, Clk, 100 ns);
        end loop;
      end loop;
    end if;
  end procedure;

  procedure user_resp(
    signal Clk          : in std_logic;
    signal wr_done_o      : in std_logic;
    signal wr_error_o     : in std_logic;
    signal rd_done_o      : in std_logic;
    signal rd_error_o     : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Lo Latency write with delay ***
      WaitCase(0, Clk);
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          WaitForCompletion(true, DelayBetweenTests + 50 us, wr_done_o, wr_error_o, Clk);
        end loop;
      end loop;
      AllDone_v := 0;

      -- *** Hi Latency write with delay ***
      WaitCase(1, Clk);
      for size in 20 to 24 loop
        for offs in 0 to 3 loop
          WaitForCompletion(true, DelayBetweenTests + 50 us, wr_done_o, wr_error_o, Clk);
        end loop;
      end loop;
      AllDone_v := 1;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Lo Latency read with delay ***
      WaitCase(2, Clk);
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          WaitForCompletion(true, DelayBetweenTests + 50 us, rd_done_o, rd_error_o, Clk);
        end loop;
      end loop;
      AllDone_v := 2;

      -- *** Hi Latency read with delay ***
      WaitCase(3, Clk);
      for size in 40 to 44 loop
        for offs in 0 to 3 loop
          WaitForCompletion(true, DelayBetweenTests + 50 us, rd_done_o, rd_error_o, Clk);
        end loop;
      end loop;
      AllDone_v := 3;
    end if;
  end procedure;

  procedure axi(
    signal Clk          : in std_logic;
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    constant Generics_c : Generics_t) is
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Lo Latency write with delay ***
      WaitCase(0, Clk);
      for size in 20 to 24 loop
        -- Execute transfer
        for offs in 0 to 3 loop
          CheckAxiWrite(16#02000000# + offs, 16#10# + offs * 16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;

      -- *** Hi Latency write with delay ***
      WaitCase(1, Clk);
      for size in 20 to 24 loop
        -- Execute transfer
        for offs in 0 to 3 loop
          CheckAxiWrite(16#02000000# + offs, 16#10# + offs * 16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Lo Latency read with delay ***
      WaitCase(2, Clk);
      for size in 40 to 44 loop
        -- Execute transfer
        for offs in 0 to 3 loop
          DoAxiRead(16#02000000# + offs, 16#10# + offs * 16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;

      -- *** Hi Latency read with delay ***
      WaitCase(3, Clk);
      for size in 40 to 44 loop
        -- Execute transfer
        for offs in 0 to 3 loop
          DoAxiRead(16#02000000# + offs, 16#10# + offs * 16, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;
    end if;
  end procedure;

end;
