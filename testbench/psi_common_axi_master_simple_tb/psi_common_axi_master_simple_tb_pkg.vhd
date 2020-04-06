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
use work.psi_tb_axi_pkg.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_activity_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_simple_tb_pkg is

  -- *** Generics Record ***
  type Generics_t is record
    ImplRead_g  : boolean;
    ImplWrite_g : boolean;
  end record;

  ------------------------------------------------------------
  -- Not exported Generics
  ------------------------------------------------------------
  constant DataFifoDepth_g           : natural := 14;
  constant AxiDataWidth_g            : natural := 16;
  constant UserTransactionSizeBits_g : natural := 16;
  constant AxiAddrWidth_g            : natural := 32;
  constant AxiMaxBeats_g             : natural := 16;
  constant RamBehavior_g             : string  := "RBW";
  constant AxiMaxOpenTrasactions_g   : natural := 3;

  ------------------------------------------------------------
  -- Axi
  ------------------------------------------------------------
  constant ID_WIDTH   : integer := 1;
  constant ADDR_WIDTH : integer := 32;
  constant USER_WIDTH : integer := 1;
  constant DATA_WIDTH : integer := 16;
  constant BYTE_WIDTH : integer := DATA_WIDTH / 8;

  subtype ID_RANGE is natural range ID_WIDTH - 1 downto 0;
  subtype ADDR_RANGE is natural range ADDR_WIDTH - 1 downto 0;
  subtype USER_RANGE is natural range USER_WIDTH - 1 downto 0;
  subtype DATA_RANGE is natural range DATA_WIDTH - 1 downto 0;
  subtype BYTE_RANGE is natural range BYTE_WIDTH - 1 downto 0;

  subtype axi_ms_t is axi_ms_r(arid(ID_RANGE), awid(ID_RANGE),
                               araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
                               aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
                               wdata(DATA_RANGE),
                               wstrb(BYTE_RANGE));

  subtype axi_sm_t is axi_sm_r(rid(ID_RANGE), bid(ID_RANGE),
                               ruser(USER_RANGE), buser(USER_RANGE),
                               rdata(DATA_RANGE));

  ------------------------------------------------------------
  -- Procedures
  ------------------------------------------------------------
  procedure ApplyCommand(Addr               : in integer;
                         Size               : in integer;
                         LowLat             : in boolean;
                         signal CmdX_Addr   : out std_logic_vector(AxiAddrWidth_g-1 downto 0);
                         signal CmdX_Size   : out std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
                         signal CmdX_LowLat : out std_logic;
                         signal CmdX_Vld    : out std_logic;
                         signal CmdX_Rdy    : in std_logic;
                         signal Clk         : in std_logic);

  procedure ApplyWrDataSingle(Data              : in integer;
                              Be                : in std_logic_vector;
                              signal WrDat_Data : out std_logic_vector(AxiDataWidth_g-1 downto 0);
                              signal WrDat_Be   : out std_logic_vector;
                              signal WrDat_Vld  : out std_logic;
                              signal WrDat_Rdy  : in std_logic;
                              signal Clk        : in std_logic);

  procedure ApplyWrDataMulti(Start             : in integer;
                             Incr              : in integer;
                             Size              : in integer;
                             FirstBe           : in std_logic_vector;
                             LastBe            : in std_logic_vector;
                             signal WrDat_Data : out std_logic_vector(AxiDataWidth_g-1 downto 0);
                             signal WrDat_Be   : out std_logic_vector;
                             signal WrDat_Vld  : out std_logic;
                             signal WrDat_Rdy  : in std_logic;
                             signal Clk        : in std_logic;
                             VldLowCyc         : in integer := 0);

  procedure CheckRdDataSingle(Data              : in integer;
                              signal RdDat_Data : in std_logic_vector(AxiDataWidth_g-1 downto 0);
                              signal RdDat_Vld  : in std_logic;
                              signal RdDat_Rdy  : out std_logic;
                              signal Clk        : in std_logic);

  procedure CheckRdDataMulti(Start             : in integer;
                             Incr              : in integer;
                             Size              : in integer;
                             signal RdDat_Data : in std_logic_vector(AxiDataWidth_g-1 downto 0);
                             signal RdDat_Vld  : in std_logic;
                             signal RdDat_Rdy  : out std_logic;
                             signal Clk        : in std_logic;
                             RdyLowCyc         : in integer := 0);

  procedure WaitForCompletion(Success        : in boolean;
                              WaitTime       : in time;
                              signal X_Done  : in std_logic;
                              signal X_Error : in std_logic;
                              signal Clk     : in std_logic);

  procedure AxiCheckWrSingle(Addr          : in integer;
                             Data          : in integer;
                             Be            : in std_logic_vector;
                             Resp          : in std_logic_vector;
                             signal axi_ms : in axi_ms_t;
                             signal axi_sm : out axi_sm_t;
                             signal Clk    : in std_logic;
                             SendResp      : in boolean := true);

  procedure AxiCheckWrBurst(Addr          : in integer;
                            Start         : in integer;
                            Incr          : in integer;
                            Size          : in integer;
                            FirstBe       : in std_logic_vector;
                            LastBe        : in std_logic_vector;
                            Resp          : in std_logic_vector;
                            signal axi_ms : in axi_ms_t;
                            signal axi_sm : out axi_sm_t;
                            signal Clk    : in std_logic;
                            SendResp      : in boolean := true;
                            AwRdyDelay    : in time    := 0 ns;
                            WRdyLowCyc    : in integer := 0);

  procedure AxiCheckRdSingle(Addr          : in integer;
                             Data          : in integer;
                             Resp          : in std_logic_vector;
                             signal axi_ms : in axi_ms_t;
                             signal axi_sm : out axi_sm_t;
                             signal Clk    : in std_logic);

  procedure AxiCheckRdBurst(Addr          : in integer;
                            Start         : in integer;
                            Incr          : in integer;
                            Size          : in integer;
                            Resp          : in std_logic_vector;
                            signal axi_ms : in axi_ms_t;
                            signal axi_sm : out axi_sm_t;
                            signal Clk    : in std_logic;
                            ArRdyDelay    : in time    := 0 ns;
                            RVldLowCyc    : in integer := 0);

  procedure DbgPrint(Enable : in boolean;
                     Str    : in string);

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_simple_tb_pkg is

  procedure ApplyCommand(Addr               : in integer;
                         Size               : in integer;
                         LowLat             : in boolean;
                         signal CmdX_Addr   : out std_logic_vector(AxiAddrWidth_g-1 downto 0);
                         signal CmdX_Size   : out std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
                         signal CmdX_LowLat : out std_logic;
                         signal CmdX_Vld    : out std_logic;
                         signal CmdX_Rdy    : in std_logic;
                         signal Clk         : in std_logic) is
  begin
    wait until rising_edge(Clk);
    CmdX_Addr <= std_logic_vector(to_unsigned(Addr, CmdX_Addr'length));
    CmdX_Size <= std_logic_vector(to_unsigned(Size, CmdX_Size'length));
    if LowLat then
      CmdX_LowLat <= '1';
    else
      CmdX_LowLat <= '0';
    end if;
    CmdX_Vld  <= '1';
    wait until rising_edge(Clk) and CmdX_Rdy = '1';
    CmdX_Vld  <= '0';
  end procedure;

  procedure ApplyWrDataSingle(Data              : in integer;
                              Be                : in std_logic_vector;
                              signal WrDat_Data : out std_logic_vector(AxiDataWidth_g-1 downto 0);
                              signal WrDat_Be   : out std_logic_vector;
                              signal WrDat_Vld  : out std_logic;
                              signal WrDat_Rdy  : in std_logic;
                              signal Clk        : in std_logic) is
  begin
    WrDat_Be   <= Be;
    WrDat_Data <= std_logic_vector(to_unsigned(Data, WrDat_Data'length));
    WrDat_Vld  <= '1';
    wait until rising_edge(Clk) and WrDat_Rdy = '1';
    WrDat_Vld  <= '0';
  end procedure;

  procedure ApplyWrDataMulti(Start             : in integer;
                             Incr              : in integer;
                             Size              : in integer;
                             FirstBe           : in std_logic_vector;
                             LastBe            : in std_logic_vector;
                             signal WrDat_Data : out std_logic_vector(AxiDataWidth_g-1 downto 0);
                             signal WrDat_Be   : out std_logic_vector;
                             signal WrDat_Vld  : out std_logic;
                             signal WrDat_Rdy  : in std_logic;
                             signal Clk        : in std_logic;
                             VldLowCyc         : in integer := 0) is
    variable DataCnt_v : integer                          := Start;
    constant LastIdx_c : integer                          := Size - 1;
    constant BeOnes_c  : std_logic_vector(WrDat_Be'range) := (others => '1');
  begin
    for i in 0 to Size - 1 loop
      if i = 0 then
        WrDat_Be <= FirstBe;
      elsif i = LastIdx_c then
        WrDat_Be <= LastBe;
      else
        WrDat_Be <= BeOnes_c;
      end if;
      WrDat_Data <= std_logic_vector(to_unsigned(DataCnt_v, WrDat_Data'length));
      WrDat_Vld  <= '1';
      wait until rising_edge(Clk) and WrDat_Rdy = '1';
      DataCnt_v  := (DataCnt_v + Incr) mod 2**AxiDataWidth_g;
      if VldLowCyc > 0 then
        WrDat_Vld <= '0';
        for i in 0 to VldLowCyc - 1 loop
          wait until rising_edge(Clk);
        end loop;
      end if;
    end loop;
    WrDat_Vld <= '0';
  end procedure;

  procedure CheckRdDataSingle(Data              : in integer;
                              signal RdDat_Data : in std_logic_vector(AxiDataWidth_g-1 downto 0);
                              signal RdDat_Vld  : in std_logic;
                              signal RdDat_Rdy  : out std_logic;
                              signal Clk        : in std_logic) is
  begin
    RdDat_Rdy <= '1';
    wait until rising_edge(Clk) and RdDat_Vld = '1';
    StdlvCompareInt(Data, RdDat_Data, "Received wrong Read Data", false);
    RdDat_Rdy <= '0';
  end procedure;

  procedure CheckRdDataMulti(Start             : in integer;
                             Incr              : in integer;
                             Size              : in integer;
                             signal RdDat_Data : in std_logic_vector(AxiDataWidth_g-1 downto 0);
                             signal RdDat_Vld  : in std_logic;
                             signal RdDat_Rdy  : out std_logic;
                             signal Clk        : in std_logic;
                             RdyLowCyc         : in integer := 0) is
    variable DataCnt_v : integer := Start;
    constant LastIdx_c : integer := Size - 1;
  begin
    for i in 0 to Size - 1 loop
      RdDat_Rdy <= '1';
      wait until rising_edge(Clk) and RdDat_Vld = '1';
      StdlvCompareInt(DataCnt_v, RdDat_Data, "Received wrong Read Data in Burst", false);
      DataCnt_v := (DataCnt_v + Incr) mod 2**AxiDataWidth_g;
      if RdyLowCyc > 0 then
        RdDat_Rdy <= '0';
        for i in 0 to RdyLowCyc - 1 loop
          wait until rising_edge(Clk);
        end loop;
      end if;
    end loop;
    RdDat_Rdy <= '0';
  end procedure;

  procedure WaitForCompletion(Success        : in boolean;
                              WaitTime       : in time;
                              signal X_Done  : in std_logic;
                              signal X_Error : in std_logic;
                              signal Clk     : in std_logic) is
  begin
    if Success then
      wait until rising_edge(Clk) and X_Done = '1' for WaitTime;
      StdlCompare(1, X_Done, "No Done");
    else
      wait until rising_edge(Clk) and X_Error = '1' for WaitTime;
      StdlCompare(1, X_Error, "No Error");
    end if;
  end procedure;

  procedure AxiCheckWrSingle(Addr          : in integer;
                             Data          : in integer;
                             Be            : in std_logic_vector;
                             Resp          : in std_logic_vector;
                             signal axi_ms : in axi_ms_t;
                             signal axi_sm : out axi_sm_t;
                             signal Clk    : in std_logic;
                             SendResp      : in boolean := true) is
  begin
    axi_expect_aw(Addr, AxSIZE_2_c, 1 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    axi_expect_wd_single(std_logic_vector(to_unsigned(Data, AxiDataWidth_g)), Be, axi_ms, axi_sm, Clk);
    if SendResp then
      axi_apply_bresp(Resp, axi_ms, axi_sm, Clk);
    end if;
  end procedure;

  procedure AxiCheckWrBurst(Addr          : in integer;
                            Start         : in integer;
                            Incr          : in integer;
                            Size          : in integer;
                            FirstBe       : in std_logic_vector;
                            LastBe        : in std_logic_vector;
                            Resp          : in std_logic_vector;
                            signal axi_ms : in axi_ms_t;
                            signal axi_sm : out axi_sm_t;
                            signal Clk    : in std_logic;
                            SendResp      : in boolean := true;
                            AwRdyDelay    : in time    := 0 ns;
                            WRdyLowCyc    : in integer := 0) is
  begin
    if AwRdyDelay > 0 ns then
      wait for AwRdyDelay;
      wait until rising_edge(Clk);
    end if;
    axi_expect_aw(Addr, AxSIZE_2_c, Size - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    axi_expect_wd_burst(Size, Start, Incr, FirstBe, LastBe, axi_ms, axi_sm, Clk, WRdyLowCyc);
    if SendResp then
      axi_apply_bresp(Resp, axi_ms, axi_sm, Clk);
    end if;
  end procedure;

  procedure AxiCheckRdSingle(Addr          : in integer;
                             Data          : in integer;
                             Resp          : in std_logic_vector;
                             signal axi_ms : in axi_ms_t;
                             signal axi_sm : out axi_sm_t;
                             signal Clk    : in std_logic) is
  begin
    axi_expect_ar(Addr, AxSIZE_2_c, 1 - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    axi_apply_rresp_single(std_logic_vector(to_unsigned(Data, AxiDataWidth_g)), Resp, axi_ms, axi_sm, Clk);
  end procedure;

  procedure AxiCheckRdBurst(Addr          : in integer;
                            Start         : in integer;
                            Incr          : in integer;
                            Size          : in integer;
                            Resp          : in std_logic_vector;
                            signal axi_ms : in axi_ms_t;
                            signal axi_sm : out axi_sm_t;
                            signal Clk    : in std_logic;
                            ArRdyDelay    : in time    := 0 ns;
                            RVldLowCyc    : in integer := 0) is
  begin
    if ArRdyDelay > 0 ns then
      wait for ArRdyDelay;
      wait until rising_edge(Clk);
    end if;
    axi_expect_ar(Addr, AxSIZE_2_c, Size - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    axi_apply_rresp_burst(Size, Start, Incr, Resp, axi_ms, axi_sm, Clk, RVldLowCyc);
  end procedure;

  procedure DbgPrint(Enable : in boolean;
                     Str    : in string) is
  begin
    if Enable then
      Print(Str);
    end if;
  end procedure;

end;
