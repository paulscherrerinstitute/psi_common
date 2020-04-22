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
package psi_common_axi_master_simple_tb_case_split is

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

  shared variable TestCase_v    : integer := -1;
  shared variable RespChecked_v : integer := -1;
  constant DelayBetweenTests    : time    := 0 us;
  constant DebugPrints          : boolean := false;

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_case_split is

  procedure WaitCase(nr         : integer;
                     signal Clk : std_logic) is
  begin
    while TestCase_v /= nr loop
      wait until rising_edge(Clk);
    end loop;
  end procedure;

  procedure WaitRespChecked(nr         : integer;
                            signal Clk : std_logic) is
  begin
    while RespChecked_v /= nr loop
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
    print("*** Tet Group 4: Transfer Splitting ***");

    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.ImplWrite_g then
      -- *** Burst over 4k Boundary ***
      DbgPrint(DebugPrints, ">> Write Burst over 4k Boundary");
      TestCase_v := 0;
      ApplyCommand(16#00020FFC#, 4, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
      WaitRespChecked(0, Clk);
      wait for DelayBetweenTests;

      -- *** Transaction exceed AXI Burst Limit ***
      DbgPrint(DebugPrints, ">> Write Transaction exceed AXI Burst Limit");
      TestCase_v := 1;
      ApplyCommand(16#00020000#, AxiMaxBeats_g + 2, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
      WaitRespChecked(1, Clk);
      wait for DelayBetweenTests;

      -- *** Large Transfer over 2*4K ***
      DbgPrint(DebugPrints, ">> Write Large Transfer over 2*4K");
      TestCase_v := 2;
      ApplyCommand(16#00020F08#, 4096, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
      WaitRespChecked(2, Clk);
      wait for DelayBetweenTests;

      -- *** Error in only one transaction ***
      DbgPrint(DebugPrints, ">> Write Error in only one transaction");
      TestCase_v := 3;
      ApplyCommand(16#00020000#, 2 * AxiMaxBeats_g + 2, true, CmdWr_Addr, CmdWr_Size, CmdWr_LowLat, CmdWr_Vld, CmdWr_Rdy, Clk);
      WaitRespChecked(3, Clk);
      wait for DelayBetweenTests;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.ImplRead_g then
      -- *** Burst over 4k Boundary ***		
      DbgPrint(DebugPrints, ">> Read Burst over 4k Boundary");
      TestCase_v := 4;
      ApplyCommand(16#00020FFC#, 4, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
      WaitRespChecked(4, Clk);
      wait for DelayBetweenTests;

      -- *** Transaction exceed AXI Burst Limit ***
      DbgPrint(DebugPrints, ">> Read Transaction exceed AXI Burst Limit");
      TestCase_v := 5;
      ApplyCommand(16#00020000#, AxiMaxBeats_g + 2, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
      WaitRespChecked(5, Clk);
      wait for DelayBetweenTests;

      -- *** Large Transfer over 2*4K ***	
      DbgPrint(DebugPrints, ">> Read Large Transfer over 2*4K");
      TestCase_v := 6;
      ApplyCommand(16#00020F08#, 4096, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
      WaitRespChecked(6, Clk);
      wait for DelayBetweenTests;

      -- *** Error in only one transaction ***		
      DbgPrint(DebugPrints, ">> Read Error in only one transaction");
      TestCase_v := 7;
      ApplyCommand(16#00020000#, 2 * AxiMaxBeats_g + 2, true, CmdRd_Addr, CmdRd_Size, CmdRd_LowLat, CmdRd_Vld, CmdRd_Rdy, Clk);
      WaitRespChecked(7, Clk);
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
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------	
    if Generics_c.ImplWrite_g then
      -- *** Burst over 4k Boundary ***
      WaitCase(0, Clk);
      ApplyWrDataMulti(16#1000#, 1, 4, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);

      -- *** Transaction exceed AXI Burst Limit ***	
      WaitCase(1, Clk);
      ApplyWrDataMulti(16#1000#, 1, AxiMaxBeats_g + 2, "10", "01", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);

      -- *** Large Transfer over 2*4K ***		
      WaitCase(2, Clk);
      ApplyWrDataMulti(16#0000#, 1, 4096, "11", "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);

      -- *** Error in only one transaction ***	
      WaitCase(3, Clk);
      ApplyWrDataMulti(16#0000#, 1, 2 * AxiMaxBeats_g + 2, "11", "11", WrDat_Data, WrDat_Be, WrDat_Vld, WrDat_Rdy, Clk);
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------	
    if Generics_c.ImplRead_g then
      -- *** Burst over 4k Boundary ***		
      WaitCase(4, Clk);
      CheckRdDataMulti(16#1000#, 1, 4, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);

      -- *** Transaction exceed AXI Burst Limit ***
      WaitCase(5, Clk);
      CheckRdDataMulti(16#1000#, 1, AxiMaxBeats_g + 2, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);

      -- *** Large Transfer over 2*4K ***	
      WaitCase(6, Clk);
      CheckRdDataMulti(16#0000#, 1, 4096, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);

      -- *** Error in only one transaction ***	
      WaitCase(7, Clk);
      CheckRdDataMulti(16#0000#, 1, 2 * AxiMaxBeats_g + 2, RdDat_Data, RdDat_Vld, RdDat_Rdy, Clk);
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
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------
    if Generics_c.ImplWrite_g then
      -- *** Burst over 4k Boundary ***
      WaitCase(0, Clk);
      WaitForCompletion(true, 1 us, Wr_Done, Wr_Error, Clk);
      CheckNoActivity(Wr_Done, 1 us, 0, "Unexpected Done");
      RespChecked_v := 0;

      -- *** Transaction exceed AXI Burst Limit ***	
      WaitCase(1, Clk);
      WaitForCompletion(true, 10 us, Wr_Done, Wr_Error, Clk);
      CheckNoActivity(Wr_Done, 5 us, 0, "Unexpected Done");
      RespChecked_v := 1;

      -- *** Large Transfer over 2*4K ***
      WaitCase(2, Clk);
      WaitForCompletion(true, 100 us, Wr_Done, Wr_Error, Clk);
      CheckNoActivity(Wr_Done, 5 us, 0, "Unexpected Done");
      RespChecked_v := 2;

      -- *** Error in only one transaction ***	
      WaitCase(3, Clk);
      WaitForCompletion(false, 10 us, Wr_Done, Wr_Error, Clk);
      CheckNoActivity(Wr_Error, 5 us, 0, "Unexpected Error");
      RespChecked_v := 3;
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------		
    if Generics_c.ImplRead_g then
      -- *** Burst over 4k Boundary ***		
      WaitCase(4, Clk);
      WaitForCompletion(true, 1 us, Rd_Done, Rd_Error, Clk);
      CheckNoActivity(Rd_Done, 1 us, 0, "Unexpected Done");
      RespChecked_v := 4;

      -- *** Transaction exceed AXI Burst Limit ***
      WaitCase(5, Clk);
      WaitForCompletion(true, 10 us, Rd_Done, Rd_Error, Clk);
      CheckNoActivity(Rd_Done, 5 us, 0, "Unexpected Done");
      RespChecked_v := 5;

      -- *** Large Transfer over 2*4K ***	
      WaitCase(6, Clk);
      WaitForCompletion(true, 100 us, Rd_Done, Rd_Error, Clk);
      CheckNoActivity(Rd_Done, 5 us, 0, "Unexpected Done");
      RespChecked_v := 6;

      -- *** Error in only one transaction ***
      WaitCase(7, Clk);
      WaitForCompletion(false, 10 us, Rd_Done, Rd_Error, Clk);
      CheckNoActivity(Rd_Error, 5 us, 0, "Unexpected Error");
      RespChecked_v := 7;
    end if;
  end procedure;

  procedure axi(
    signal axi_ms       : in axi_ms_t;
    signal axi_sm       : out axi_sm_t;
    signal Clk          : in std_logic;
    constant Generics_c : Generics_t) is
    variable NextAddr_v       : integer;
    variable BeatsChecked_v   : integer;
    variable NextBurstBeats_v : integer;
  begin
    ------------------------------------------------------------------
    -- Writes
    ------------------------------------------------------------------
    if Generics_c.ImplWrite_g then
      -- *** Burst over 4k Boundary ***
      WaitCase(0, Clk);
      AxiCheckWrBurst(16#00020FFC#, 16#1000#, 1, 2, "10", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckWrBurst(16#00021000#, 16#1002#, 1, 2, "11", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Transaction exceed AXI Burst Limit ***
      WaitCase(1, Clk);
      AxiCheckWrBurst(16#00020000#, 16#1000#, 1, AxiMaxBeats_g, "10", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckWrBurst(16#00020000# + AxiMaxBeats_g * 2, 16#1000# + AxiMaxBeats_g, 1, 2, "11", "01", xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Large Transfer over 2*4K ***
      WaitCase(2, Clk);
      NextAddr_v     := 16#00020F08#;
      BeatsChecked_v := 0;
      while BeatsChecked_v < 4096 loop
        -- keep within AXI limit
        NextBurstBeats_v := AxiMaxBeats_g;
        -- Do not write over 4k boundaries
        if ((NextAddr_v + NextBurstBeats_v * 2 - 1) / 4096) /= (NextAddr_v / 4096) then
          NextBurstBeats_v := (4096 - (NextAddr_v mod 4096)) / 2;
        end if;
        -- stop writing at the end
        if (BeatsChecked_v + NextBurstBeats_v > 4096) then
          NextBurstBeats_v := 4096 - BeatsChecked_v;
        end if;
        --debug print usually disabled
        --print("Expect: Addr: " & hstr(std_logic_vector(to_unsigned(NextAddr_v, 32))) & ", Offset: " & hstr(std_logic_vector(to_unsigned(BeatsChecked_v, 32))) & ", Beats:" & str(NextBurstBeats_v));
        AxiCheckWrBurst(NextAddr_v, BeatsChecked_v, 1, NextBurstBeats_v, "11", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        BeatsChecked_v   := BeatsChecked_v + NextBurstBeats_v;
        NextAddr_v       := NextAddr_v + NextBurstBeats_v * 2;
      end loop;

      -- *** Error in only one transaction ***
      WaitCase(3, Clk);
      AxiCheckWrBurst(16#00020000#, 0, 1, AxiMaxBeats_g, "11", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckWrBurst(16#00020000# + AxiMaxBeats_g * 2, AxiMaxBeats_g, 1, AxiMaxBeats_g, "11", "11", xRESP_SLVERR_c, axi_ms, axi_sm, Clk);
      AxiCheckWrBurst(16#00020000# + AxiMaxBeats_g * 2 * 2, AxiMaxBeats_g * 2, 1, 2, "11", "11", xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

    ------------------------------------------------------------------
    -- Reads
    ------------------------------------------------------------------
    if Generics_c.ImplRead_g then
      -- *** Burst over 4k Boundary ***	
      WaitCase(4, Clk);
      AxiCheckRdBurst(16#00020FFC#, 16#1000#, 1, 2, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckRdBurst(16#00021000#, 16#1002#, 1, 2, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Transaction exceed AXI Burst Limit ***
      WaitCase(5, Clk);
      AxiCheckRdBurst(16#00020000#, 16#1000#, 1, AxiMaxBeats_g, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckRdBurst(16#00020000# + AxiMaxBeats_g * 2, 16#1000# + AxiMaxBeats_g, 1, 2, xRESP_OKAY_c, axi_ms, axi_sm, Clk);

      -- *** Large Transfer over 2*4K ***	
      WaitCase(6, Clk);
      NextAddr_v     := 16#00020F08#;
      BeatsChecked_v := 0;
      while BeatsChecked_v < 4096 loop
        -- keep within AXI limit
        NextBurstBeats_v := AxiMaxBeats_g;
        -- Do not write over 4k boundaries
        if ((NextAddr_v + NextBurstBeats_v * 2 - 1) / 4096) /= (NextAddr_v / 4096) then
          NextBurstBeats_v := (4096 - (NextAddr_v mod 4096)) / 2;
        end if;
        -- stop writing at the end
        if (BeatsChecked_v + NextBurstBeats_v > 4096) then
          NextBurstBeats_v := 4096 - BeatsChecked_v;
        end if;
        --debug print usually disabled
        --print("Expect: Addr: " & hstr(std_logic_vector(to_unsigned(NextAddr_v, 32))) & ", Offset: " & hstr(std_logic_vector(to_unsigned(BeatsChecked_v, 32))) & ", Beats:" & str(NextBurstBeats_v));
        AxiCheckRdBurst(NextAddr_v, BeatsChecked_v, 1, NextBurstBeats_v, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
        BeatsChecked_v   := BeatsChecked_v + NextBurstBeats_v;
        NextAddr_v       := NextAddr_v + NextBurstBeats_v * 2;
      end loop;

      -- *** Error in only one transaction ***
      WaitCase(7, Clk);
      AxiCheckRdBurst(16#00020000#, 0, 1, AxiMaxBeats_g, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
      AxiCheckRdBurst(16#00020000# + AxiMaxBeats_g * 2, AxiMaxBeats_g, 1, AxiMaxBeats_g, xRESP_SLVERR_c, axi_ms, axi_sm, Clk);
      AxiCheckRdBurst(16#00020000# + AxiMaxBeats_g * 2 * 2, AxiMaxBeats_g * 2, 1, 2, xRESP_OKAY_c, axi_ms, axi_sm, Clk);
    end if;

  end procedure;

end;
