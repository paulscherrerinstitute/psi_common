------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
------------------------------------------------------------

------------------------------------------------------------
-- Testbench generated by TbGen.py
------------------------------------------------------------
-- see Library/Python/TbGenerator

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_common_i2c_master_pkg.all;

library work;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_tb_i2c_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_i2c_master_tb is
  generic(
    internal_tri_state_g : boolean := true
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_i2c_master_tb is
  -- *** Fixed Generics ***
  constant clock_frequency_g : real := 125.0e6;
  constant i2c_frequency_g   : real := 1.0e6;
  constant bus_busy_timeout_g : real := 50.0e-6;
  constant cmd_timeout_g     : real := 10.0e-6;

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_i2c_c     : integer                  := 1;
  signal StimCase             : integer                  := -1;
  signal I2cCase              : integer                  := -1;

  -- *** DUT Signals ***
  signal clk_i        : std_logic                    := '1';
  signal rst_i        : std_logic                    := '1';
  signal cmd_rdy_o     : std_logic                    := '0';
  signal cmd_vld_i     : std_logic                    := '0';
  signal cmd_type_i    : std_logic_vector(2 downto 0) := (others => '0');
  signal cmd_dat_i    : std_logic_vector(7 downto 0) := (others => '0');
  signal cmd_ack_i     : std_logic                    := '0';
  signal rsp_vld_o     : std_logic                    := '0';
  signal rsp_dat_o    : std_logic_vector(7 downto 0) := (others => '0');
  signal rsp_type_o    : std_logic_vector(2 downto 0) := (others => '0');
  signal rsp_arb_lost_o : std_logic                    := '0';
  signal rsp_ack_o     : std_logic                    := '0';
  signal rsp_seq_o     : std_logic                    := '0';
  signal bus_busy_o    : std_logic                    := '0';
  signal timeout_cmd_o : std_logic                    := '0';
  signal i2c_scl_io     : std_logic                    := '0';
  signal i2c_sda_io     : std_logic                    := '0';
  signal i2c_scl_i   : std_logic                    := '0';
  signal i2c_scl_o   : std_logic                    := '0';
  signal i2c_scl_t   : std_logic                    := '0';
  signal i2c_sda_i   : std_logic                    := '0';
  signal i2c_sda_o   : std_logic                    := '0';
  signal i2c_sda_t   : std_logic                    := '0';

  -- *** Helper Functions ***
  procedure WaitForCase(signal TestCase : in integer;
                        Value           : in integer) is
  begin
    if TestCase /= Value then
      wait until TestCase = Value;
    end if;
  end procedure;

  procedure ApplyCmd(Command        : in std_logic_vector(2 downto 0);
                     Data           : in std_logic_vector(7 downto 0);
                     Ack            : in std_logic;
                     signal cmd_vld_i  : out std_logic;
                     signal cmd_rdy_o  : in std_logic;
                     signal cmd_type_i : out std_logic_vector(2 downto 0);
                     signal cmd_dat_i : out std_logic_vector(7 downto 0);
                     signal cmd_ack_i  : out std_logic) is
  begin
    wait until rising_edge(clk_i);
    cmd_vld_i  <= '1';
    cmd_type_i <= Command;
    cmd_dat_i <= Data;
    cmd_ack_i  <= Ack;
    wait until rising_edge(clk_i) and cmd_rdy_o = '1';
    cmd_vld_i  <= '0';
    cmd_type_i <= (others => '0');
    cmd_dat_i <= (others => '0');
    cmd_ack_i  <= '0';
  end procedure;

  procedure CheckRsp(Command           : in std_logic_vector(2 downto 0);
                     Data              : in std_logic_vector;
                     Ack               : in std_logic;
                     ArbLost           : in std_logic;
                     signal rsp_vld_o     : in std_logic;
                     signal rsp_dat_o    : in std_logic_vector(7 downto 0);
                     signal rsp_type_o    : in std_logic_vector(2 downto 0);
                     signal rsp_arb_lost_o : in std_logic;
                     signal rsp_ack_o     : in std_logic;
                     signal rsp_seq_o     : in std_logic;
                     Msg               : in string    := "No Msg";
                     Err               : in std_logic := '0') is
  begin
    wait until rising_edge(clk_i) and rsp_vld_o = '1';
    StdlvCompareStdlv(Command, rsp_type_o, "Response: Wrong Type - " & Msg);
    if Data /= "X" then
      StdlvCompareStdlv(Data, rsp_dat_o, "Response: Wrong Data - " & Msg);
    end if;
    if Ack /= 'X' then
      StdlCompare(choose(Ack = '1', 1, 0), rsp_ack_o, "Response: Wrong Ack - " & Msg);
    end if;
    if ArbLost /= 'X' then
      StdlCompare(choose(ArbLost = '1', 1, 0), rsp_arb_lost_o, "Response: Wrong ArbLost - " & Msg);
    end if;
    StdlCompare(choose(Err = '1', 1, 0), rsp_seq_o, "Response: Wrong Err - " & Msg);
  end procedure;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_i2c_master
    generic map(
      clock_frequency_g   => clock_frequency_g,
      i2c_frequency_g     => i2c_frequency_g,
      bus_busy_timeout_g   => bus_busy_timeout_g,
      cmd_timeout_g       => cmd_timeout_g,
      internal_tri_state_g => internal_tri_state_g,
      disable_asserts_g   => true
    )
    port map(
      clk_i        => clk_i,
      rst_i        => rst_i,
      cmd_rdy_o     => cmd_rdy_o,
      cmd_vld_i     => cmd_vld_i,
      cmd_type_i    => cmd_type_i,
      cmd_dat_i    => cmd_dat_i,
      cmd_ack_i     => cmd_ack_i,
      rsp_vld_o     => rsp_vld_o,
      rsp_type_o    => rsp_type_o,
      rsp_arb_lost_o => rsp_arb_lost_o,
      rsp_dat_o    => rsp_dat_o,
      rsp_ack_o     => rsp_ack_o,
      rsp_seq_o     => rsp_seq_o,
      bus_busy_o    => bus_busy_o,
      timeout_cmd_o => timeout_cmd_o,
      i2c_scl_io     => i2c_scl_io,
      i2c_sda_io     => i2c_sda_io,
      i2c_scl_i   => i2c_scl_i,
      i2c_scl_o   => i2c_scl_o,
      i2c_scl_t   => i2c_scl_t,
      i2c_sda_i   => i2c_sda_i,
      i2c_sda_o   => i2c_sda_o,
      i2c_sda_t   => i2c_sda_t
    );

  ------------------------------------------------------------
  -- I2C Emulation
  ------------------------------------------------------------		
  I2cPullup(i2c_scl_io, i2c_sda_io);
  g_triState : if not internal_tri_state_g generate
    i2c_scl_io   <= 'Z' when i2c_scl_t = '1' else i2c_scl_o;
    i2c_scl_i <= to_01X(i2c_scl_io);
    i2c_sda_io   <= 'Z' when i2c_sda_t = '1' else i2c_sda_o;
    i2c_sda_i <= to_01X(i2c_sda_io);
  end generate;

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until rst_i = '0';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_Clk : process
    constant Frequency_c : real := real(125e6);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
      clk_i <= not clk_i;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_Rst : process
  begin
    wait for 1 us;
    -- Wait for two clk edges to ensure reset is active for at least one edge
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    rst_i <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** stim ***
  p_stim : process
  begin
    I2cSetFrequency(i2c_frequency_g);
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';
    wait until rising_edge(clk_i);

    -- *** Test Bus Busy ***
    print(">> Test Bus Busy");
    StimCase <= 0;
    wait until rising_edge(clk_i);
    WaitForCase(I2cCase, 0);
    wait for 10 us;

    -- *** Test Start / Repeated-Start / Stop ***
    print(">> Test Start / Repeated-Start / Stop");
    StimCase <= 1;
    wait until rising_edge(clk_i);
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start");
    ApplyCmd(CMD_REPSTART, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REPSTART, "X", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop");
    WaitForCase(I2cCase, 1);
    wait for 10 us;

    -- *** Test Write ***
    print(">> Test Write");
    StimCase <= 2;
    wait until rising_edge(clk_i);

    -- 1Byte ACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 1b ACK");

    -- 2Byte ACK, then NACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK");
    ApplyCmd(CMD_SEND, X"12", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK 1");
    ApplyCmd(CMD_SEND, X"34", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '0', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK 2");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 2b ACK -> NACK");

    WaitForCase(I2cCase, 2);
    wait for 10 us;

    -- *** Test Read ***
    print(">> Test Read");
    StimCase <= 3;
    wait until rising_edge(clk_i);

    -- 1Byte ACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"67", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 1b ACK");

    -- 2Byte ACK, then NACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK");
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"34", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK 1");
    ApplyCmd(CMD_REC, X"00", '0', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"56", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b ACK -> NACK 2");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 2b ACK -> NACK");

    WaitForCase(I2cCase, 3);
    wait for 10 us;

    -- *** Test Clock Stretching ***
    print(">> Test Clock Stretching");
    StimCase <= 4;
    wait until rising_edge(clk_i);

    -- 1Byte Read ACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK");
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"67", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop Read 1b ACK");

    -- 2Byte ACK, then NACK
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b Write ACK -> NACK");
    ApplyCmd(CMD_SEND, X"12", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b Write ACK -> NACK 1");
    ApplyCmd(CMD_SEND, X"34", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '0', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b Write ACK -> NACK 2");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 2b Write ACK -> NACK");

    -- Write / Read
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 2b W->R");
    ApplyCmd(CMD_SEND, X"12", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Write 2b W->R");
    ApplyCmd(CMD_REPSTART, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REPSTART, "X", 'X', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "RepStart 2b W->R");
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"67", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Read 2b W->R");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 2b W->R");

    WaitForCase(I2cCase, 4);
    wait for 10 us;

    -- *** Test Delayed Command *** (clock is held low until command available)
    print(">> Test Delayed Command");
    StimCase <= 5;
    wait until rising_edge(clk_i);

    -- 1Byte Read ACK, delay shorter than timeout
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK");
    wait for cmd_timeout_g / 2.0 * (1 sec);
    wait until rising_edge(clk_i);
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, X"67", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK");
    wait for cmd_timeout_g / 2.0 * (1 sec);
    wait until rising_edge(clk_i);
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop Read 1b ACK");

    -- Command Timeout (Timeout after start, other commands ignored)
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK");
    wait for cmd_timeout_g * 2.0 * (1 sec);
    wait until rising_edge(clk_i);
    ApplyCmd(CMD_REC, X"00", '1', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REC, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Read 1b ACK", Err => '1');
    wait for cmd_timeout_g * 2.0 * (1 sec);
    wait until rising_edge(clk_i);
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop Read 1b ACK", Err => '1');

    WaitForCase(I2cCase, 5);
    wait for 10 us;

    -- *** Test Arbitration *** 
    print(">> Test Arbitration");
    StimCase <= 6;
    wait until rising_edge(clk_i);

    -- Multi Master, Same Write 
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start 1b ACK");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop 1b ACK");

    -- Arbitration Lost during Write
    wait for 10 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost Write");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '0', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost Write");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Lost Write", Err => '1');

    -- Arbitration Lost during STOP (other master continues writing)
    wait for 10 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost Stop");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost Stop");
    ApplyCmd(CMD_STOP, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_STOP, "X", 'X', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Stop Lost Stop");

    -- Arbitration Lost during repeated start (other master continues writing)
    wait for 20 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost RepStartA");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost RepStartA");
    ApplyCmd(CMD_REPSTART, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REPSTART, "X", 'X', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Repstart Lost RepStartA");

    -- Arbitration Lost during repeated start (other master stops)
    wait for 20 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost RepStartB");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost RepStartB");
    ApplyCmd(CMD_REPSTART, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_REPSTART, "X", 'X', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Repstart Lost RepStartB");

    -- Arbitration lost due to stop (during first bit of data)
    wait for 10 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueStop");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueStop 1");
    ApplyCmd(CMD_SEND, X"F0", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '0', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueStop 2");

    -- Arbitration lost due to rep-start (during first bit of data)
    wait for 10 us;
    ApplyCmd(CMD_START, X"00", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_START, "X", 'X', 'X', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueRepStart");
    ApplyCmd(CMD_SEND, X"A3", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '1', '0', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueRepStart 1");
    ApplyCmd(CMD_SEND, X"F0", 'X', cmd_vld_i, cmd_rdy_o, cmd_type_i, cmd_dat_i, cmd_ack_i);
    CheckRsp(CMD_SEND, "X", '0', '1', rsp_vld_o, rsp_dat_o, rsp_type_o, rsp_arb_lost_o, rsp_ack_o, rsp_seq_o, "Start Lost DueRepStart 2");

    WaitForCase(I2cCase, 6);
    wait for 10 us;

    -- end of process !DO NOT EDIT!
    wait for 1 us;
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** i2c slave ***
  p_i2c_slave : process
  begin
    I2cBusFree(i2c_scl_io, i2c_sda_io);

    -- start of process !DO NOT EDIT
    wait until rst_i = '0';
    wait until rising_edge(clk_i);

    -- *** Test Bus Busy ***
    WaitForCase(StimCase, 0);
    -- Not busy
    wait for 1 us;
    StdlCompare(0, bus_busy_o, "Busy 0");
    -- A transfer is goiong on
    i2c_scl_io  <= '0';
    wait for 1 us;
    StdlCompare(1, bus_busy_o, "Busy 1");
    -- busy is kept
    i2c_scl_io  <= 'Z';
    wait for 10 us;
    StdlCompare(1, bus_busy_o, "Busy 2");
    -- released after timeout
    wait for bus_busy_timeout_g * (1 sec);
    StdlCompare(0, bus_busy_o, "Busy 3");
    -- Asserted on start
    I2cMasterSendStart(i2c_scl_io, i2c_sda_io, "Assert Start");
    wait for 1 us;
    StdlCompare(1, bus_busy_o, "Busy 4");
    -- Released on stop
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "Assert Start");
    wait for 1 us;
    StdlCompare(0, bus_busy_o, "Busy 4");
    I2cCase <= 0;

    -- *** Test Start / Stop ***
    WaitForCase(StimCase, 1);
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start");
    I2cSlaveWaitRepeatedStart(i2c_scl_io, i2c_sda_io, "RepStart");
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");
    I2cCase <= 1;

    -- *** Test Write ***
    WaitForCase(StimCase, 2);

    -- 1 Byte Ack
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 1b Ack");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "Data 1b Ack", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    -- 2 Byte Ack, then NACK
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 2b ACK -> NACK");
    I2cSlaveExpectByte(16#12#, i2c_scl_io, i2c_sda_io, "Data 2b ACK -> NACK 1", '0');
    I2cSlaveExpectByte(16#34#, i2c_scl_io, i2c_sda_io, "Data 2b ACK -> NACK 2", '1');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    I2cCase <= 2;

    -- *** Test Read ***
    WaitForCase(StimCase, 3);

    -- 1 Byte Ack
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 1b Ack");
    I2cSlaveSendByte(16#67#, i2c_scl_io, i2c_sda_io, "Data 1b Ack", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    -- 2 Byte Ack, then NACK
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 2b ACK -> NACK");
    I2cSlaveSendByte(16#34#, i2c_scl_io, i2c_sda_io, "Data 2b ACK -> NACK 1", '0');
    I2cSlaveSendByte(16#56#, i2c_scl_io, i2c_sda_io, "Data 2b ACK -> NACK 2", '1');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    I2cCase <= 3;

    -- *** Test Clock Stretching ***
    WaitForCase(StimCase, 4);

    -- 1 Byte Read Ack
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start Read 1b Ack");
    I2cSlaveSendByte(16#67#, i2c_scl_io, i2c_sda_io, "Data Write 1b Ack", '0', ClkStretch => 1 us);
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop", ClkStretch => 1 us);

    -- 2 Byte Write Ack, then NACK
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 2b Write ACK -> NACK");
    I2cSlaveExpectByte(16#12#, i2c_scl_io, i2c_sda_io, "Data 2b Write ACK -> NACK 1", '0', ClkStretch => 1 us);
    I2cSlaveExpectByte(16#34#, i2c_scl_io, i2c_sda_io, "Data 2b Write ACK -> NACK 2", '1', ClkStretch => 1 us);
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop", ClkStretch => 1 us);

    -- Write / Read
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 2b W->R");
    I2cSlaveExpectByte(16#12#, i2c_scl_io, i2c_sda_io, "Write 2b W->R", '0', ClkStretch => 1 us);
    I2cSlaveWaitRepeatedStart(i2c_scl_io, i2c_sda_io, "RepStart 2b W->R", ClkStretch => 1 us);
    I2cSlaveSendByte(16#67#, i2c_scl_io, i2c_sda_io, "Read 2b W->R", '0', ClkStretch => 1 us);
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop 2b W->R", ClkStretch => 1 us);

    I2cCase <= 4;

    -- *** Test Delayed Command *** 
    WaitForCase(StimCase, 5);

    -- 1 Byte Ack, delay shorter than timeout
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 1b Ack");
    I2cSlaveSendByte(16#67#, i2c_scl_io, i2c_sda_io, "Data 1b Ack", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    -- Command Timeout (Timeout after start, stop generated internally)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "Start 1b Ack");
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "Stop");

    I2cCase <= 5;

    -- *** Test Arbitration ***
    WaitForCase(StimCase, 6);

    -- Multi Master, Same Write 
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start 1b Ack");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Data 1b Ack", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop");

    -- Arbitration Lost during Write
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost Write");
    I2cSlaveExpectByte(16#87#, i2c_scl_io, i2c_sda_io, "S: Stop Lost Write", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Lost Write Stop");

    -- Arbitration Lost STOP (other master continues writing)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost Stop");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Data Lost Stop 1", '0');
    I2cSlaveExpectByte(16#12#, i2c_scl_io, i2c_sda_io, "S: Data Lost Stop 2", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop Lost Stop");

    -- Arbitration Lost during repeated start (other master continues writing)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost RepStartA");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Data Lost RepStartA 1", '0');
    I2cSlaveExpectByte(16#12#, i2c_scl_io, i2c_sda_io, "S: Data Lost RepStartA 2", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop Lost RepStartA");

    -- Arbitration Lost during repeated start (other master stops)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost RepStartB");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Data Lost RepStartB 1", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop Lost RepStartB");

    -- Arbitration lost due to stop (during first bit of data)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost DueStop");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Data Lost DueStop 1", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop Lost DueStop");

    -- Arbitration lost due to rep-start (during first bit of data)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "S: Start Lost RepStart");
    I2cSlaveExpectByte(16#A3#, i2c_scl_io, i2c_sda_io, "S: Write Lost RepStart 1", '0');
    I2cSlaveWaitRepeatedStart(i2c_scl_io, i2c_sda_io, "S: Lost RepStart RepStart");
    I2cSlaveSendByte(16#34#, i2c_scl_io, i2c_sda_io, "S: Read Lost RepStart RepStart", '0');
    I2cSlaveWaitStop(i2c_scl_io, i2c_sda_io, "S: Stop Lost RepStart");

    I2cCase <= 6;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_i2c_c) <= '1';
    wait;
  end process;

  -- *** i2c master ***
  p_i2c_master : process
  begin
    I2cBusFree(i2c_scl_io, i2c_sda_io);

    -- *** Test Arbitration ***
    WaitForCase(StimCase, 6);

    -- Multi Master, Same Write 
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start 1b Ack");
    -- small delay
    i2c_scl_io <= '0';
    wait for 100 ns;
    -- continue
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: Data 1b Ack");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop");

    -- Arbitration Lost during Write
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost Write");
    I2cMasterSendByte(16#87#, i2c_scl_io, i2c_sda_io, "M: Data Lost Write");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Loast Read");

    -- Arbitration Lost STOP (other master continues writing)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost Stop");
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: Data Lost Stop 1");
    I2cMasterSendByte(16#12#, i2c_scl_io, i2c_sda_io, "M: Data Lost Stop 2");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Lost Stop");

    -- Arbitration Lost during repeated start (other master continues writing)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost RepStartA");
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: Data Lost RepStartA 1");
    I2cMasterSendByte(16#12#, i2c_scl_io, i2c_sda_io, "M: Data Lost RepStartA 2");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Lost RepStartA");

    -- Arbitration Lost during repeated start (other master stops)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost RepStartB");
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: Data Lost RepStartB 1");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Lost RepStartB");

    -- Arbitration lost due to stop (during first bit of data)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost DueStop");
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: Data Lost DueStop 1");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Lost DueStop");

    -- Arbitration lost due to rep-start (during first bit of data)
    I2cSlaveWaitStart(i2c_scl_io, i2c_sda_io, "M: Start Lost DueRepstart");
    I2cMasterSendByte(16#A3#, i2c_scl_io, i2c_sda_io, "M: write Lost DueRepstart 1");
    I2cMasterSendRepeatedStart(i2c_scl_io, i2c_sda_io, "M: Stop Lost DueRepstart");
    I2cMasterExpectByte(16#34#, i2c_scl_io, i2c_sda_io, "M: read Lost DueRepstart 1");
    I2cMasterSendStop(i2c_scl_io, i2c_sda_io, "M: Stop Lost DueRepstart");

    wait;

  end process;

end;
