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
package psi_common_axi_master_full_tb_case_large is

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
package body psi_common_axi_master_full_tb_case_large is

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

    print("*** Tet Group 4: Large Transfers ***");

    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Write 1022 bytes to 0x02000001 ***
      DbgPrint(DebugPrints, ">> Write 1022 bytes to 0x02000001");
      TestCase_v := 0;
      ApplyCommand(16#02000001#, 1022, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
      WaitDone(0, Clk);
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1022 bytes from 0x02000001 (high latency) ***
      DbgPrint(DebugPrints, ">> Read 1022 bytes from 0x02000001 (high latency)");
      TestCase_v := 1;
      ApplyCommand(16#02000001#, 1022, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      WaitDone(1, Clk);
      wait for DelayBetweenTests;

      -- *** Read 1022 bytes from 0x02000001 (low latency) ***
      DbgPrint(DebugPrints, ">> Read 1022 bytes from 0x02000001 (low latency)");
      TestCase_v := 2;
      ApplyCommand(16#02000001#, 1022, true, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
      WaitDone(2, Clk);
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
      -- *** Write 1022 bytes to 0x02000001 ***
      WaitCase(0, Clk);
      ApplyWrData(16#10#, 1022, wr_dat_i, wr_vld_i, wr_rdy_o, Clk);
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1022 bytes from 0x02000001 (high latency) ***
      WaitCase(1, Clk);
      CheckRdData(16#10#, 1022, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);

      -- *** Read 1022 bytes from 0x02000001 (low latency) ***
      WaitCase(2, Clk);
      CheckRdData(16#10#, 1022, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
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
      -- *** Write 1022 bytes to 0x02000001 ***
      WaitCase(0, Clk);
      WaitForCompletion(true, 100 us, wr_done_o, wr_error_o, Clk);
      AllDone_v := 0;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1022 bytes from 0x02000001 (high latency) ***
      WaitCase(1, Clk);
      WaitForCompletion(true, 100 us, rd_done_o, rd_error_o, Clk);
      AllDone_v := 1;

      -- *** Read 1022 bytes from 0x02000001 (low latency) ***
      WaitCase(2, Clk);
      WaitForCompletion(true, 100 us, rd_done_o, rd_error_o, Clk);
      AllDone_v := 2;
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
      -- *** Write 1022 bytes to 0x02000001 ***			
      WaitCase(0, Clk);
      CheckAxiWrite(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      CheckAxiWrite(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1022 bytes from 0x02000001 (high latency) ***
      WaitCase(1, Clk);
      DoAxiRead(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Read 1022 bytes from 0x02000001 (low latency) ***
      WaitCase(2, Clk);
      DoAxiRead(16#02000001#, 16#10#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000040#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000080#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020000C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000100#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000140#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000180#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020001C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000200#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000240#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000280#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020002C0#, 16#CF#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000300#, 16#0F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000340#, 16#4F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#02000380#, 16#8F#, 64, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      DoAxiRead(16#020003C0#, 16#CF#, 63, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;
  end procedure;

end;
