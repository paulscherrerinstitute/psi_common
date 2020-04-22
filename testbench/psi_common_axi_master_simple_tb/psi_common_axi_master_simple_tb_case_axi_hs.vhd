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
package psi_common_axi_master_simple_tb_case_axi_hs is

  procedure user_cmd(
    signal CmdWr_Addr   : inout std_logic_vector;
    signal CmdWr_Size   : inout std_logic_vector;
    signal CmdWr_LowLat : inout std_logic;
    signal CmdWr_Vld    : inout std_logic;
    signal CmdWr_Rdy    : in std_logic;
    signal CmdRd_Addr   : inout std_logic_vector;
    signal CmdRd_Size   : inout std_logic_vector;
    signal CmdRd_LowLat : inout std_logic;
    signal CmdRd_Vld    : inout std_logic;
    signal CmdRd_Rdy    : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  procedure user_data(
    signal WrDat_Data   : inout std_logic_vector;
    signal WrDat_Be     : inout std_logic_vector;
    signal WrDat_Vld    : inout std_logic;
    signal WrDat_Rdy    : in std_logic;
    signal RdDat_Data   : in std_logic_vector;
    signal RdDat_Vld    : in std_logic;
    signal RdDat_Rdy    : inout std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t);

  procedure user_resp(
    signal Wr_Done      : in std_logic;
    signal Wr_Error     : in std_logic;
    signal Rd_Done      : in std_logic;
    signal Rd_Error     : in std_logic;
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
package body psi_common_axi_master_simple_tb_case_axi_hs is

  procedure WaitCase(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while TestCase_v /= nr loop
      wait until rising_edge(Clk);
    end loop;
  end procedure;

  procedure user_cmd(
    signal CmdWr_Addr   : inout std_logic_vector;
    signal CmdWr_Size   : inout std_logic_vector;
    signal CmdWr_LowLat : inout std_logic;
    signal CmdWr_Vld    : inout std_logic;
    signal CmdWr_Rdy    : in std_logic;
    signal CmdRd_Addr   : inout std_logic_vector;
    signal CmdRd_Size   : inout std_logic_vector;
    signal CmdRd_LowLat : inout std_logic;
    signal CmdRd_Vld    : inout std_logic;
    signal CmdRd_Rdy    : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    wait for DelayBetweenTests;
    print("*** Tet Group 3: Axi Handshake ***");

    -- *** Burst wirte - single transaction ***
    if Generics_c.ImplWrite_g then
      DbgPrint(DebugPrints, ">> Burst write - single transaction");
      TestCase_v := 0;
      for i in 0 to AxiMaxOpenTrasactions_g + 2 loop
        ApplyCommand(16#00020000# * i, 12, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
      end loop;
      wait for DelayBetweenTests;
    end if;

    -- *** Burst read - single transaction ***
    if Generics_c.ImplRead_g then
      DbgPrint(DebugPrints, ">> Burst read - single transaction");
      TestCase_v := 1;
      for i in 0 to AxiMaxOpenTrasactions_g + 2 loop
        ApplyCommand(16#00020000# * i, 12, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
      end loop;
      wait for DelayBetweenTests;
    end if;

    wait for DelayBetweenTests;
  end procedure;

  procedure user_data(
    signal WrDat_Data   : inout std_logic_vector;
    signal WrDat_Be     : inout std_logic_vector;
    signal WrDat_Vld    : inout std_logic;
    signal WrDat_Rdy    : in std_logic;
    signal RdDat_Data   : in std_logic_vector;
    signal RdDat_Vld    : in std_logic;
    signal RdDat_Rdy    : inout std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    -- *** Burst wirte - single transaction ***
    if Generics_c.ImplWrite_g then
      WaitCase(0, Clk);
      wait until rising_edge(Clk);
      -- First transfers at full speed
      for i in 0 to AxiMaxOpenTrasactions_g loop
        ApplyWrDataMulti(16#1000# * i, 1, 12, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
      end loop;
      -- Last two transfers breaked by data stream (wait to ensure the Vld pattern is visible on AXI and not hidden by buffered data)
      wait for 1 us;
      wait until rising_edge(Clk);
      ApplyWrDataMulti(16#1000# * (AxiMaxOpenTrasactions_g + 1), 1, 12, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk, 3);
      ApplyWrDataMulti(16#1000# * (AxiMaxOpenTrasactions_g + 2), 1, 12, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk, 3);
    end if;

    -- *** Burst read - single transaction ***
    if Generics_c.ImplRead_g then
      WaitCase(1, Clk);
      wait until rising_edge(Clk);
      -- First transfers at full speed
      for i in 0 to AxiMaxOpenTrasactions_g loop
        CheckRdDataMulti(16#1000# * i, 1, 12, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);
      end loop;
      -- Last two transfers breaked by data stream (wait to ensure the Vld pattern is visible on AXI and not hidden by buffered data)
      wait for 1 us;
      wait until rising_edge(Clk);
      CheckRdDataMulti(16#1000# * (AxiMaxOpenTrasactions_g + 1), 1, 12, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 3);
      CheckRdDataMulti(16#1000# * (AxiMaxOpenTrasactions_g + 2), 1, 12, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk, 3);
    end if;

  end procedure;

  procedure user_resp(
    signal Wr_Done      : in std_logic;
    signal Wr_Error     : in std_logic;
    signal Rd_Done      : in std_logic;
    signal Rd_Error     : in std_logic;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    -- *** Burst wirte - single transaction ***
    if Generics_c.ImplWrite_g then
      WaitCase(0, Clk);
      for i in 0 to AxiMaxOpenTrasactions_g + 2 loop
        WaitForCompletion(true, 10 us, Wr_Done, Wr_Error, Clk);
      end loop;
    end if;

    -- *** Burst read - single transaction ***
    if Generics_c.ImplRead_g then
      WaitCase(1, Clk);
      for i in 0 to AxiMaxOpenTrasactions_g + 2 loop
        WaitForCompletion(true, 10 us, Rd_Done, Rd_Error, Clk);
      end loop;
    end if;

  end procedure;

  procedure axi(
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
  begin
    -- *** Burst wirte - single transaction ***
    if Generics_c.ImplWrite_g then
      WaitCase(0, Clk);
      -- First transaction breaked by awready
      AxiCheckWrBurst(16#00020000# * 0, 16#1000# * 0, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk, true, 800 ns);
      -- Other transactions breaked by wready		
      for i in 1 to AxiMaxOpenTrasactions_g + 1 loop
        AxiCheckWrBurst(16#00020000# * i, 16#1000# * i, 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk, true, 0 ns, 3);
      end loop;
      -- last transaction fullspeed
      AxiCheckWrBurst(16#00020000# * (AxiMaxOpenTrasactions_g + 2), 16#1000# * (AxiMaxOpenTrasactions_g + 2), 1, 12, "10", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    -- *** Burst read - single transaction ***
    if Generics_c.ImplRead_g then
      WaitCase(1, Clk);
      -- First transaction breaked by arready
      AxiCheckRdBurst(16#00020000# * 0, 16#1000# * 0, 1, 12, xRESP_OKAY_c, axi_ms, axi_sm, Clk, 800 ns);
      -- Other transactions breaked by wready	
      for i in 1 to AxiMaxOpenTrasactions_g + 1 loop
        AxiCheckRdBurst(16#00020000# * i, 16#1000# * i, 1, 12, xRESP_OKAY_c, axi_ms, axi_sm, Clk, 0 ns, 3);
      end loop;
      -- last transaction fullspeed
      AxiCheckRdBurst(16#00020000# * (AxiMaxOpenTrasactions_g + 2), 16#1000# * (AxiMaxOpenTrasactions_g + 2), 1, 12, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

  end procedure;

end;
