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
package psi_common_axi_master_full_tb_case_simple_tf is

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

  shared variable TestCase_v  : integer := -1;
  shared variable ExpectCmd_v : boolean;
  constant DelayBetweenTests  : time    := 0.2 us; -- Minimum is 0.2 us (because of test implementation...)
  constant DebugPrints        : boolean := false;

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_case_simple_tf is

  procedure WaitCase(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while TestCase_v /= nr loop
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

    print("*** Tet Group 1: Simple Transfer ***");
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Write 1-8 bytes, shifted by 0-7 ***
      DbgPrint(DebugPrints, ">> Write 1-8 bytes, shifted by 0-7");
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          TestCase_v := TestCase_v + 1;
          -- Debug helper string
          -- print("Addr=" & hstr(to_unsigned(16#02000000#+offs, 32)) & ", size=" & str(size));
          ApplyCommand(16#02000000# + offs, size, false, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, cmd_wr_rdy_o, Clk);
          wait for DelayBetweenTests;
        end loop;
      end loop;
      wait for DelayBetweenTests;
    end if;
    wait for 10 us;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------		
    if Generics_c.impl_read_g then
      -- *** Read 1-8 bytes, shifted by 0-7 ***
      DbgPrint(DebugPrints, ">> Read 1-8 bytes, shifted by 0-7");
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          TestCase_v := TestCase_v + 1;
          -- Debug helper string
          -- print("Addr=" & hstr(to_unsigned(16#02000000#+offs, 32)) & ", size=" & str(size));
          ApplyCommand(16#02000000# + offs, size, false, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, cmd_rd_rdy_o, Clk);
          wait for DelayBetweenTests;
        end loop;
      end loop;
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
    variable LastCase_v : integer := -1;
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Write 1-8 bytes, shifted by 0-7  ***
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          ApplyWrData(16#10#, size, wr_dat_i, wr_vld_i, wr_rdy_o, Clk);
        end loop;
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1-8 bytes, shifted by 0-7  ***
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          CheckRdData(16#10#, size, rd_dat_o, rd_vld_o, rd_rdy_i, Clk);
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
    variable LastCase_v : integer := -1;
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Write 1-8 bytes, shifted by 0-7  ***	
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          WaitForCompletion(true, DelayBetweenTests + 1 us, wr_done_o, wr_error_o, Clk);
        end loop;
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1-8 bytes, shifted by 0-7  ***	
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          WaitForCompletion(true, DelayBetweenTests + 1 us, rd_done_o, rd_error_o, Clk);
        end loop;
      end loop;
    end if;

  end procedure;

  procedure axi(
    signal Clk          : in std_logic;
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    constant Generics_c : Generics_t) is
    variable LastCase_v : integer := -1;
  begin
    axi_slave_init(axi_sm);

    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.impl_write_g then
      -- *** Write 1-8 bytes, shifted by 0-7 ***
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          CheckAxiWrite(16#02000000# + offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.impl_read_g then
      -- *** Read 1-8 bytes, shifted by 0-7 ***
      for size in 1 to 8 loop
        for offs in 0 to 7 loop
          WaitCase(LastCase_v + 1, Clk);
          LastCase_v := TestCase_v;
          DoAxiRead(16#02000000# + offs, 16#10#, size, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        end loop;
      end loop;
    end if;
  end procedure;

end;
