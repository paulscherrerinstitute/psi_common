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
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Package Header
------------------------------------------------------------
package psi_common_axi_master_full_tb_pkg is

  -- *** Generics Record ***
  type Generics_t is record
    DataWidth_g : natural;
    ImplRead_g  : boolean;
    ImplWrite_g : boolean;
  end record;

  ------------------------------------------------------------
  -- Not exported Generics
  ------------------------------------------------------------
  constant AxiAddrWidth_g            : natural := 32;
  constant DataFifoDepth_g           : natural := 10;
  constant AxiFifoDepth_g            : natural := 32;
  constant UserTransactionSizeBits_g : natural := 10;
  constant RamBehavior_g             : string  := "RBW";
  constant AxiMaxOpenTrasactions_g   : natural := 3;
  constant AxiMaxBeats_g             : natural := 16;
  constant AxiDataWidth_g            : natural := 32;

  ------------------------------------------------------------
  -- Axi
  ------------------------------------------------------------
  constant ID_WIDTH   : integer := 1;
  constant ADDR_WIDTH : integer := 32;
  constant USER_WIDTH : integer := 1;
  constant DATA_WIDTH : integer := 32;
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

  procedure WaitForCompletion(Success        : in boolean;
                              WaitTime       : in time;
                              signal X_Done  : in std_logic;
                              signal X_Error : in std_logic;
                              signal Clk     : in std_logic);

  procedure DbgPrint(Enable : in boolean;
                     Str    : in string);

  procedure ApplyWrData(DataStart         : in integer;
                        NrBytes           : in integer;
                        signal WrDat_Data : out std_logic_vector;
                        signal WrDat_Vld  : out std_logic;
                        signal WrDat_Rdy  : in std_logic;
                        signal Clk        : in std_logic;
                        VldDelay          : in time := 0 ns);

  procedure CheckRdData(DataStart         : in integer;
                        NrBytes           : in integer;
                        signal RdDat_Data : in std_logic_vector;
                        signal RdDat_Vld  : in std_logic;
                        signal RdDat_Rdy  : out std_logic;
                        signal Clk        : in std_logic;
                        RdyDelay          : in time   := 0 ns;
                        msg               : in string := "");

  procedure CheckAxiWrite(Addr          : in integer;
                          DataStart     : in integer;
                          NrBytes       : in integer;
                          Resp          : in std_logic_vector;
                          signal axi_ms : in axi_ms_t;
                          signal axi_sm : out axi_sm_t;
                          signal Clk    : in std_logic;
                          AwRdyDelay    : in time := 0 ns;
                          WRdyDelay     : in time := 0 ns);

  procedure DoAxiRead(Addr          : in integer;
                      DataStart     : in integer;
                      NrBytes       : in integer;
                      Resp          : in std_logic_vector;
                      signal axi_ms : in axi_ms_t;
                      signal axi_sm : out axi_sm_t;
                      signal Clk    : in std_logic;
                      ArRdyDelay    : in time := 0 ns;
                      RVldDelay     : in time := 0 ns);

end package;

------------------------------------------------------------
-- Package Body
------------------------------------------------------------
package body psi_common_axi_master_full_tb_pkg is

  function AxSize(AxiDataWidth : integer) return std_logic_vector is
  begin
    if AxiDataWidth = 16 then
      return AxSIZE_2_c;
    elsif AxiDataWidth = 32 then
      return AxSIZE_4_c;
    else
      assert false report "###ERROR###: AxSize - Illegal AxiDataWidth" severity error;
      return "0";
    end if;
  end function;

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

  procedure DbgPrint(Enable : in boolean;
                     Str    : in string) is
  begin
    if Enable then
      Print(Str);
    end if;
  end procedure;

  procedure ApplyWrData(DataStart         : in integer;
                        NrBytes           : in integer;
                        signal WrDat_Data : out std_logic_vector;
                        signal WrDat_Vld  : out std_logic;
                        signal WrDat_Rdy  : in std_logic;
                        signal Clk        : in std_logic;
                        VldDelay          : in time := 0 ns) is
    constant DataWidth_c : integer := WrDat_Data'length;
    variable BitsDone_v  : integer := 0;
    variable Data_v      : integer := DataStart;
  begin
    assert DataWidth_c = 16 or DataWidth_c = 32 report "###ERROR###: ApplyWrData() only works for 16 or 32 bits data width" severity error;
    WrDat_Vld <= '0';
    while BitsDone_v < NrBytes * 8 loop
      if VldDelay > 0 ns then
        WrDat_Vld <= '0';
        wait for VldDelay;
        wait until rising_edge(Clk);
        WrDat_Vld <= '1';
      else
        WrDat_Vld <= '1';
      end if;
      for byte in 0 to DataWidth_c / 8 - 1 loop
        if BitsDone_v < NrBytes * 8 then
          WrDat_Data((byte + 1) * 8 - 1 downto byte * 8) <= std_logic_vector(to_unsigned(Data_v, 8));
          Data_v                                         := Data_v + 1;
          BitsDone_v                                     := BitsDone_v + 8;
        end if;
      end loop;
      wait until rising_edge(Clk) and WrDat_Rdy = '1';
    end loop;
    WrDat_Vld <= '0';
  end procedure;

  procedure CheckRdData(DataStart         : in integer;
                        NrBytes           : in integer;
                        signal RdDat_Data : in std_logic_vector;
                        signal RdDat_Vld  : in std_logic;
                        signal RdDat_Rdy  : out std_logic;
                        signal Clk        : in std_logic;
                        RdyDelay          : in time   := 0 ns;
                        msg               : in string := "") is
    constant DataWidth_c : integer := RdDat_Data'length;
    variable BitsDone_v  : integer := 0;
    variable Data_v      : integer := DataStart;
  begin
    assert DataWidth_c = 16 or DataWidth_c = 32 report "###ERROR###: CheckRdData() only works for 16 or 32 bits data width {" & msg & "}" severity error;
    RdDat_Rdy <= '0';
    while BitsDone_v < NrBytes * 8 loop
      if RdyDelay > 0 ns then
        RdDat_Rdy <= '0';
        wait for RdyDelay;
        wait until rising_edge(Clk);
        RdDat_Rdy <= '1';
      else
        RdDat_Rdy <= '1';
      end if;
      wait until rising_edge(Clk) and RdDat_Vld = '1';
      for byte in 0 to DataWidth_c / 8 - 1 loop
        if BitsDone_v < NrBytes * 8 then
          StdlvCompareInt(Data_v, RdDat_Data((byte + 1) * 8 - 1 downto byte * 8), "Wrong read data byte " & str(BitsDone_v / 8) & " {" & msg & "}", false);
          Data_v     := (Data_v + 1) mod 256;
          BitsDone_v := BitsDone_v + 8;
        end if;
      end loop;
    end loop;
    RdDat_Rdy <= '0';
  end procedure;

  procedure CheckAxiWrite(Addr          : in integer;
                          DataStart     : in integer;
                          NrBytes       : in integer;
                          Resp          : in std_logic_vector;
                          signal axi_ms : in axi_ms_t;
                          signal axi_sm : out axi_sm_t;
                          signal Clk    : in std_logic;
                          AwRdyDelay    : in time := 0 ns;
                          WRdyDelay     : in time := 0 ns) is
    constant AxiBytes_c     : integer := axi_ms.wdata'length / 8;
    constant LastAddr_c     : integer := Addr + NrBytes - 1;
    constant WordAddr_c     : integer := Addr / 4 * 4;
    constant Beats_c        : integer := (LastAddr_c - WordAddr_c) / AxiBytes_c + 1;
    variable Data_v         : integer := DataStart;
    variable BytesChecked_v : integer := 0;
    constant AddrOffs       : integer := Addr mod 4;

  begin
    -- Check AW
    if AwRdyDelay > 0 ns then
      wait for AwRdyDelay;
      wait until rising_edge(Clk);
    end if;
    axi_expect_aw(WordAddr_c, AxSize(AxiBytes_c * 8), Beats_c - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    -- Check W		
    for beat in 1 to Beats_c loop
      if WRdyDelay > 0 ns then
        axi_sm.wready <= '0';
        wait for WRdyDelay;
        wait until rising_edge(Clk);
        axi_sm.wready <= '1';
      else
        axi_sm.wready <= '1';
      end if;
      wait until rising_edge(Clk) and axi_ms.wvalid = '1';
      if WRdyDelay > 0 ns then
        axi_sm.wready <= '0';
      end if;
      -- last transfer
      if beat = Beats_c then
        StdlCompare(1, axi_ms.wlast, "WLAST not asserted at end of burst transfer");
      elsif beat = 1 then
        StdlCompare(0, axi_ms.wlast, "WLAST asserted at beginning of burst transfer");
      else
        StdlCompare(0, axi_ms.wlast, "WLAST asserted in the middle of burst transfer");
      end if;
      -- Check First Beats
      if beat = 1 then
        -- unused bytes
        for byte in 0 to AddrOffs - 1 loop
          StdlCompare(0, axi_ms.wstrb(byte), "STRB high in beat 1 byte " & str(byte));
        end loop;
        -- used bytes
        for byte in AddrOffs to 3 loop
          if BytesChecked_v < NrBytes then
            StdlCompare(1, axi_ms.wstrb(byte), "STRB low in beat 1 byte " & str(byte));
            StdlvCompareInt(Data_v, axi_ms.wdata((byte + 1) * 8 - 1 downto byte * 8), "wrong WDATA, beat 1, byte " & str(byte), false);
            Data_v         := (Data_v + 1) mod 256;
            BytesChecked_v := BytesChecked_v + 1;
          else
            StdlCompare(0, axi_ms.wstrb(byte), "STRB high in beat 1, byte " & str(byte));
          end if;
        end loop;
      -- Check other beats
      else
        for byte in 0 to 3 loop
          if BytesChecked_v < NrBytes then
            StdlCompare(1, axi_ms.wstrb(byte), "STRB low in beat " & str(beat) & " byte " & str(byte));
            StdlvCompareInt(Data_v, axi_ms.wdata((byte + 1) * 8 - 1 downto byte * 8), "wrong WDATA, beat " & str(beat) & " byte " & str(byte), false);
            Data_v         := (Data_v + 1) mod 256;
            BytesChecked_v := BytesChecked_v + 1;
          else
            StdlCompare(0, axi_ms.wstrb(byte), "STRB high in beat " & str(beat) & " byte " & str(byte));
          end if;
        end loop;
      end if;
    end loop;
    axi_sm.wready <= '0';
    -- Apply BRESP
    axi_apply_bresp(Resp, axi_ms, axi_sm, Clk);
  end procedure;

  procedure DoAxiRead(Addr          : in integer;
                      DataStart     : in integer;
                      NrBytes       : in integer;
                      Resp          : in std_logic_vector;
                      signal axi_ms : in axi_ms_t;
                      signal axi_sm : out axi_sm_t;
                      signal Clk    : in std_logic;
                      ArRdyDelay    : in time := 0 ns;
                      RVldDelay     : in time := 0 ns) is
    constant AxiBytes_c  : integer := axi_ms.wdata'length / 8;
    constant LastAddr_c  : integer := Addr + NrBytes - 1;
    constant WordAddr_c  : integer := Addr / 4 * 4;
    constant Beats_c     : integer := (LastAddr_c - WordAddr_c) / AxiBytes_c + 1;
    variable Data_v      : integer := DataStart;
    variable BytesDone_v : integer := 0;
    constant AddrOffs    : integer := Addr mod 4;

  begin
    -- Check AW
    if ArRdyDelay > 0 ns then
      wait for ArRdyDelay;
      wait until rising_edge(Clk);
    end if;
    axi_expect_ar(WordAddr_c, AxSize(AxiBytes_c * 8), Beats_c - 1, xBURST_INCR_c, axi_ms, axi_sm, Clk);
    -- Apply R
    for beat in 1 to Beats_c loop
      -- Wait until valid is asserted
      if RVldDelay > 0 ns then
        axi_sm.rvalid <= '0';
        wait for RVldDelay;
        wait until rising_edge(Clk);
        axi_sm.rvalid <= '1';
      else
        axi_sm.rvalid <= '1';
      end if;
      -- last transfer
      if beat = Beats_c then
        axi_sm.rlast <= '1';
        axi_sm.rresp <= Resp;
      else
        axi_sm.rlast <= '0';
        axi_sm.rresp <= "00";
      end if;
      -- Apply First Beat
      if beat = 1 then
        axi_sm.rdata <= (others => '0');
        -- used bytes
        for byte in AddrOffs to 3 loop
          if BytesDone_v < NrBytes then
            axi_sm.rdata((byte + 1) * 8 - 1 downto byte * 8) <= std_logic_vector(to_unsigned(Data_v, 8));
            Data_v                                           := (Data_v + 1) mod 256;
            BytesDone_v                                      := BytesDone_v + 1;
          end if;
        end loop;
      -- Apply other beats
      else
        axi_sm.rdata <= (others => '0');
        for byte in 0 to 3 loop
          if BytesDone_v < NrBytes then
            axi_sm.rdata((byte + 1) * 8 - 1 downto byte * 8) <= std_logic_vector(to_unsigned(Data_v, 8));
            Data_v                                           := (Data_v + 1) mod 256;
            BytesDone_v                                      := BytesDone_v + 1;
          end if;
        end loop;
      end if;
      -- de-assert valid
      wait until rising_edge(Clk) and axi_ms.rready = '1';
    end loop;
    axi_sm.rvalid <= '0';
  end procedure;
end;
