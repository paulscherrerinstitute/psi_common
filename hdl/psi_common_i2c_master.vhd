------------------------------------------------------------------------------
--	Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple I2C-master (multi master capable)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Package for Interface Simplification
------------------------------------------------------------------------------
package psi_common_i2c_master_pkg is
  constant CMD_START    : std_logic_vector(2 downto 0) := "000";
  constant CMD_STOP     : std_logic_vector(2 downto 0) := "001";
  constant CMD_REPSTART : std_logic_vector(2 downto 0) := "010";
  constant CMD_SEND     : std_logic_vector(2 downto 0) := "011";
  constant CMD_REC      : std_logic_vector(2 downto 0) := "100";
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_common_i2c_master_pkg.all;

-- $$ processes=stim,i2c $$
-- $$ tbpkg=work.psi_tb_compare_pkg,work.psi_tb_activity_pkg,work.psi_tb_txt_util,work.psi_tb_i2c_pkg $$
entity psi_common_i2c_master is
  generic(
    clock_frequency_g    : real    := 125.0e6;  -- in Hz		$$ constant=125.0e6 $$
    i2c_frequency_g      : real    := 100.0e3;  -- in Hz		$$ constant=1.0e6 $$
    bus_busy_timeout_g   : real    := 1.0e-3;   -- in sec		$$ constant=100.0e-6 $$
    cmd_timeout_g        : real    := 100.0e-6; -- in sec		$$ constant=10.0e-6 $$
    internal_tri_state_g : boolean := true;     -- 				$$ constant=true $$
    disable_asserts_g    : boolean := false;
    rst_pol_g            : std_logic:= '1'
  );
  port(
    -- Control Signals
    clk_i          : in    std_logic;   -- $$ type=clk; freq=125e6 $$
    rst_i          : in    std_logic;   -- $$ type=rst; clk=Clk $$
    -- Command Interface
    cmd_rdy_o      : out   std_logic;
    cmd_vld_i      : in    std_logic;
    cmd_type_i     : in    std_logic_vector(2 downto 0);
    cmd_dat_i      : in    std_logic_vector(7 downto 0);
    cmd_ack_i      : in    std_logic;
    -- Response Interface
    rsp_vld_o      : out   std_logic;
    rsp_type_o     : out   std_logic_vector(2 downto 0);
    rsp_dat_o      : out   std_logic_vector(7 downto 0);
    rsp_ack_o      : out   std_logic;
    rsp_arb_lost_o : out   std_logic;
    rsp_seq_o      : out   std_logic;
    -- Status Interface
    bus_busy_o     : out   std_logic;
    timeout_cmd_o  : out   std_logic;
    -- I2c Interface with internal Tri-State (InternalTriState_g = true)
    i2c_scl_io     : inout std_logic := 'Z';
    i2c_sda_io     : inout std_logic := 'Z';
    -- I2c Interface with external Tri-State (InternalTriState_g = false)
    i2c_scl_i      : in    std_logic := '0';
    i2c_scl_o      : out   std_logic;
    i2c_scl_t      : out   std_logic;
    i2c_sda_i      : in    std_logic := '0';
    i2c_sda_o      : out   std_logic;
    i2c_sda_t      : out   std_logic
  );
end entity;

architecture rtl of psi_common_i2c_master is

  -- *** Constants ***
  constant BusyTimoutLimit_c    : integer := integer(clock_frequency_g * bus_busy_timeout_g) - 1;
  constant QuarterPeriodLimit_c : integer := integer(ceil(clock_frequency_g / i2c_frequency_g / 4.0)) - 1;
  constant CmdTimeoutLimit_c    : integer := integer(clock_frequency_g * cmd_timeout_g) - 1;

  -- *** Types ***
  type Fsm_t is (BusIdle_s, BusBusy_s, MinIdle_s, Start1_s, Start2_s, WaitCmd_s, WaitLowCenter_s, Stop1_s, Stop2_s, Stop3_s, RepStart1_s,
                 DataBit1_s, DataBit2_s, DataBit3_s, DataBit4_s, ArbitLost_s);

  -- *** Two Process Method ***
  type two_process_r is record
    bus_busy_o     : std_logic;
    cmd_rdy_o      : std_logic;
    SclLast        : std_logic;
    SdaLast        : std_logic;
    BusBusyToCnt   : unsigned(log2ceil(BusyTimoutLimit_c + 1) - 1 downto 0);
    TimeoutCmdCnt  : unsigned(log2ceil(CmdTimeoutLimit_c + 1) - 1 downto 0);
    QuartPeriodCnt : unsigned(log2ceil(QuarterPeriodLimit_c + 1) - 1 downto 0);
    QPeriodTick    : std_logic;
    CmdTypeLatch   : std_logic_vector(cmd_type_i'range);
    CmdAckLatch    : std_logic;
    Fsm            : Fsm_t;
    SclOut         : std_logic;
    SdaOut         : std_logic;
    rsp_vld_o      : std_logic;
    rsp_ack_o      : std_logic;
    rsp_seq_o      : std_logic;
    rsp_dat_o      : std_logic_vector(7 downto 0);
    rsp_arb_lost_o : std_logic;
    BitCnt         : unsigned(3 downto 0); -- 8 Data + 1 Ack = 9 = 4 bits
    ShReg          : std_logic_vector(8 downto 0);
    CmdTimeout     : std_logic;
    timeout_cmd_o  : std_logic;
  end record;
  signal r, r_next     : two_process_r;
  attribute dont_touch : string;
  attribute dont_touch of r : signal is "true"; -- Required to Fix Vivado 2018.2 Synthesis Bug! Is fixed in Vivado 2019.1 according to Xilinx.

  -- Tri-state buffer muxing
  signal I2cScl_Input : std_logic;
  signal I2cSda_Input : std_logic;
  signal I2cScl_Sync  : std_logic;
  signal I2cSda_Sync  : std_logic;

begin

  --------------------------------------------------------------------------
  -- Combinatorial Proccess
  --------------------------------------------------------------------------
  p_comb : process(r, I2cScl_Sync, I2cSda_Sync, cmd_vld_i, cmd_type_i, cmd_dat_i, cmd_ack_i)
    variable v                                  : two_process_r;
    variable   SdaRe_v, SdaFe_v : std_logic;
    variable I2cStart_v, I2cStop_v              : std_logic;
  begin
    -- *** hold variables stable ***
    v := r;

    -- *** Edge Detection ***
    --SclRe_v   := not r.SclLast and I2cScl_Sync;
    --SclFe_v   := r.SclLast and not I2cScl_Sync;
    SdaRe_v   := not r.SdaLast and I2cSda_Sync;
    SdaFe_v   := r.SdaLast and not I2cSda_Sync;
    v.SclLast := I2cScl_Sync;
    v.SdaLast := I2cSda_Sync;

    -- *** Start/Stop Detection ***
    I2cStart_v := r.SclLast and I2cScl_Sync and SdaFe_v;
    I2cStop_v  := r.SclLast and I2cScl_Sync and SdaRe_v;

    -- *** Quarter Period Counter ***
    -- The FSM may overwrite the counter in some cases!
    v.QPeriodTick := '0';
    if (r.Fsm = BusIdle_s) or (r.Fsm = BusBusy_s) then
      v.QuartPeriodCnt := (others => '0');
    elsif r.QuartPeriodCnt = QuarterPeriodLimit_c then
      v.QuartPeriodCnt := (others => '0');
      v.QPeriodTick    := '1';
    else
      v.QuartPeriodCnt := r.QuartPeriodCnt + 1;
    end if;

    -- *** Command Timeout Detection ***
    if r.Fsm = WaitCmd_s then
      -- Timeout
      if r.TimeoutCmdCnt = CmdTimeoutLimit_c then
        v.CmdTimeout := '1';
      -- Count
      else
        v.TimeoutCmdCnt := r.TimeoutCmdCnt + 1;
      end if;
    -- In all states except waiting for command, reset the timer
    else
      v.TimeoutCmdCnt := (others => '0');
    end if;

    -- *** Latch Command ***
    if (r.cmd_rdy_o = '1') and (cmd_vld_i = '1') then
      v.CmdTypeLatch := cmd_type_i;
      v.CmdAckLatch  := cmd_ack_i;
    end if;

    -- *** Default Values ***
    v.rsp_vld_o      := '0';
    v.rsp_ack_o      := not r.ShReg(0);
    v.rsp_dat_o      := r.ShReg(8 downto 1);
    v.rsp_seq_o      := '0';
    v.rsp_arb_lost_o := '0';
    v.timeout_cmd_o  := '0';
    v.cmd_rdy_o      := '0';

    -- *** FSM ***
    case r.Fsm is

      -- **********************************************************************************************
      -- Bus Idle
      -- **********************************************************************************************
      when BusIdle_s =>
        -- Default Outputs
        v.cmd_rdy_o    := '1';
        v.BusBusyToCnt := (others => '0');
        v.SclOut       := '1';
        v.SdaOut       := '1';
        v.CmdTimeout   := '0';

        -- Detect Bus Busy by Start Command
        if (r.cmd_rdy_o = '1') and (cmd_vld_i = '1') then
          -- Everyting else than START commands is ignored and an error is printed in this case
          assert (cmd_type_i = CMD_START) or disable_asserts_g
          report "###ERROR###: psi_common_i2c_master: In idle state, only CMD_START commands are allowed!"
          severity error;
          if cmd_type_i = CMD_START then
            v.Fsm          := Start1_s;
            v.cmd_rdy_o    := '0';
            v.CmdTypeLatch := cmd_type_i;
          else
            v.rsp_vld_o := '1';
            v.rsp_seq_o := '1';
          end if;
        -- Detect Busy from other master
        elsif (I2cScl_Sync = '0') or (I2cStart_v = '1') then
          v.Fsm       := BusBusy_s;
          v.cmd_rdy_o := '0';
        end if;

      -- **********************************************************************************************
      -- Bus Busy by other master
      -- **********************************************************************************************
      when BusBusy_s =>
        -- Bus released
        if I2cStop_v = '1' then
          v.Fsm := MinIdle_s;
        end if;
        -- Timeout Handling
        if I2cScl_Sync = '0' then
          v.BusBusyToCnt := (others => '0');
        elsif r.BusBusyToCnt = BusyTimoutLimit_c then
          v.Fsm := BusIdle_s;
        else
          v.BusBusyToCnt := r.BusBusyToCnt + 1;
        end if;

        v.SclOut := '1';
        v.SdaOut := '1';

      -- Ensure that SDA stays low for at least half a clock period
      when MinIdle_s =>
        if r.QPeriodTick = '1' then
          v.Fsm := BusIdle_s;
        end if;

        v.SclOut := '1';
        v.SdaOut := '1';

      -- **********************************************************************************************
      -- Start Condition
      -- **********************************************************************************************
      -- State	BusBusy_s   Start1_s   Start2_s   WaitCmd_s
      --        __________________________________
      -- Scl ...                                  |___________ ...
      --        _______________________
      -- SDA ...                       |______________________ ...
      -- **********************************************************************************************

      when Start1_s =>
        if r.QPeriodTick = '1' then
          v.Fsm := Start2_s;
        end if;

        -- Handle Clock Stretching in case of a repeated start (slave keeps SCL low)
        if I2cScl_Sync = '0' and r.CmdTypeLatch = CMD_REPSTART then
          v.QuartPeriodCnt := (others => '0');
        end if;

        -- Handle Arbitration (other master transmits start condition first)
        if I2cSda_Sync = '0' then
          v.Fsm := ArbitLost_s;
        end if;

        v.SclOut := '1';
        v.SdaOut := '1';

      when Start2_s =>
        if r.QPeriodTick = '1' then
          v.Fsm       := WaitCmd_s;
          v.rsp_vld_o := '1';
        end if;
        v.SclOut := '1';
        v.SdaOut := '0';

      -- **********************************************************************************************
      -- Wait for user command (in first half of SCL low phase)
      -- **********************************************************************************************
      when WaitCmd_s =>
        -- Default Outputs
        v.cmd_rdy_o := '1';
        v.SclOut    := '0';

        -- All commands except START are allowed, START commands are ignored
        if (r.cmd_rdy_o = '1') and (cmd_vld_i = '1') then
          assert (cmd_type_i = CMD_STOP) or (cmd_type_i = CMD_REPSTART) or (cmd_type_i = CMD_SEND) or (cmd_type_i = CMD_REC) or disable_asserts_g
          report "###ERROR###: psi_common_i2c_master: In WaitCmd_s state, CMD_START commands are not allowed!"
          severity error;
          if (cmd_type_i = CMD_STOP) or (cmd_type_i = CMD_REPSTART) or (cmd_type_i = CMD_SEND) or (cmd_type_i = CMD_REC) then
            v.Fsm       := WaitLowCenter_s;
            v.cmd_rdy_o := '0';
          else
            v.rsp_vld_o := '1';
            v.rsp_seq_o := '1';
          end if;
          -- Latch data (used for SEND)
          v.ShReg := cmd_dat_i & '0';
        -- Command timeout - In this case send a STOP to free the bus
        elsif r.CmdTimeout = '1' then
          v.Fsm           := WaitLowCenter_s;
          v.cmd_rdy_o     := '0';
          v.timeout_cmd_o := '1';
        end if;

      -- **********************************************************************************************
      -- Wait for center of SCL low phase (after user command arrived)
      -- **********************************************************************************************
      when WaitLowCenter_s =>
        -- State Handling
        v.SclOut := '0';
        v.BitCnt := (others => '0');

        -- Switch to commands
        if r.QPeriodTick = '1' then
          -- In timeout case, send a STOP to free the bus
          if r.CmdTimeout = '1' then
            v.Fsm := Stop1_s;
          -- Else, go to requested command
          else
            case r.CmdTypeLatch is
              when CMD_STOP     => v.Fsm := Stop1_s;
              when CMD_REPSTART => v.Fsm := RepStart1_s;
              when CMD_SEND     => v.Fsm := DataBit1_s;
              when CMD_REC      => v.Fsm := DataBit1_s;
              when others       => null;
            end case;
          end if;
        end if;

      -- **********************************************************************************************
      -- Start Condition
      -- **********************************************************************************************
      -- State	   RepStart1_s   Start1_s   Start2_s   WaitCmd_s
      --                          _____________________
      -- Scl ..._________________|                     |___________ ...
      --           __________________________
      -- SDA ...XXX                          |_____________________ ...
      -- **********************************************************************************************
      -- States after RepStart1_s are shared with normal start condition

      when RepStart1_s =>
        if r.QPeriodTick = '1' then
          -- The rest of the sequence is same as for START
          v.Fsm := Start1_s;

          -- Handle Arbitration other master prvents repeating start by transmitting 0
          if I2cSda_Sync = '0' then
            v.Fsm := ArbitLost_s;
          end if;
        end if;
        v.SclOut := '0';
        v.SdaOut := '1';

      -- **********************************************************************************************
      -- Start Condition
      -- **********************************************************************************************
      -- State  DataBit1_s   DataBit2_s   DataBit3_s   WaitCmd_s / DataBit4_s
      --                    _________________________
      -- Scl ...___________|                         |___________ ...
      --
      -- SDA ...XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
      -- **********************************************************************************************
      -- The DataBit1_s is the second half of the SCL low period. So the
      -- SDA Line is set at the beginning of DataBit1_s. After the SCL high period
      -- of the last bit, the state is changed to WaitCmd_s. Otherwise the first half of the SCL low
      -- period is executed (DataBit4_s) before the next bit starts (DataBit1_s)

      when DataBit1_s =>
        if r.QPeriodTick = '1' then
          v.Fsm := DataBit2_s;
        end if;
        v.SclOut := '0';

        -- Send Operation
        if r.CmdTypeLatch = CMD_SEND then
          -- For Ack, receive data
          if r.BitCnt = 8 then
            v.SdaOut := '1';
          -- .. else send data
          else
            v.SdaOut := r.ShReg(8);
          end if;
        -- Receive Operatiom
        else
          -- Ack Handling
          if r.BitCnt = 8 then
            if r.CmdAckLatch = '1' then
              v.SdaOut := '0';
            else
              v.SdaOut := '1';
            end if;
          -- .. else tri-state for receiving
          else
            v.SdaOut := '1';
          end if;
        end if;

      when DataBit2_s =>
        if r.QPeriodTick = '1' then
          v.Fsm   := DataBit3_s;
          -- Shift register in the middle of the CLK pulse
          v.ShReg := r.ShReg(7 downto 0) & I2cSda_Sync;
        end if;
        v.SclOut := '1';

        -- Handle Clock Stretching (slave keeps SCL low)
        if I2cScl_Sync = '0' then
          v.QuartPeriodCnt := (others => '0');
        end if;

        -- Handle Arbitration for Sending (only databits, not ack)
        if (r.CmdTypeLatch = CMD_SEND) and (r.BitCnt /= 8) then
          if I2cSda_Sync /= r.SdaOut then
            v.Fsm := ArbitLost_s;
          end if;
          -- Receiving does not need arbitration since slave addresses are unique
        end if;

      when DataBit3_s =>
        if r.QPeriodTick = '1' then
          -- Command Done after 9 bits (8 Data + 1 Ack)
          if r.BitCnt = 8 then
            v.Fsm       := WaitCmd_s;
            v.rsp_vld_o := '1';
          -- Else goto next bit
          else
            v.Fsm := DataBit4_s;
          end if;
        end if;
        v.SclOut := '1';

        -- Handle Arbitration for Sending (only databits, not ack)
        if (r.CmdTypeLatch = CMD_SEND) and (r.BitCnt /= 8) then
          if I2cSda_Sync /= r.SdaOut then
            v.Fsm := ArbitLost_s;
          end if;
          -- Receiving does not need arbitration since slave addresses are unique
        end if;

      when DataBit4_s =>
        if r.QPeriodTick = '1' then
          v.Fsm    := DataBit1_s;
          v.BitCnt := r.BitCnt + 1;
        end if;
        v.SclOut := '0';

      -- **********************************************************************************************
      -- Stop Condition
      -- **********************************************************************************************
      -- State   WaitCmd_s   Stop1_s   Stop2_s   Stop3_s   BusIdle_s
      --                              _____________________
      -- Scl ..._____________________|                     |__________ ...
      --                                         _____________________
      -- SDA ...XXXXXXXXXXXX____________________|                      ...
      -- **********************************************************************************************

      when Stop1_s =>
        if r.QPeriodTick = '1' then
          v.Fsm := Stop2_s;
        end if;
        v.SclOut := '0';
        v.SdaOut := '0';

      when Stop2_s =>
        if r.QPeriodTick = '1' then
          v.Fsm := Stop3_s;
        end if;
        v.SclOut := '1';
        v.SdaOut := '0';

        -- Handle Clock Stretching (slave keeps SCL low)
        if I2cScl_Sync = '0' then
          v.QuartPeriodCnt := (others => '0');
        end if;

      when Stop3_s =>
        if r.QPeriodTick = '1' then
          -- Handle Arbitration
          if I2cSda_Sync = '0' then
            v.Fsm := ArbitLost_s;
          -- Else the STOP was successful
          else
            v.Fsm       := BusIdle_s;
            v.rsp_vld_o := '1';
          end if;
        end if;
        v.SclOut := '1';
        v.SdaOut := '1';

      -- **********************************************************************************************
      --  Send Response in case the arbitration was lost
      -- **********************************************************************************************

      when ArbitLost_s =>
        v.Fsm            := BusBusy_s;
        v.rsp_vld_o      := '1';
        v.rsp_ack_o      := '0';
        v.rsp_arb_lost_o := '1';
        v.SclOut         := '1';
        v.SdaOut         := '1';

      when others => null;
    end case;

    -- TODO: FSM Stuck detection timeout!

    -- *** Bus Busy ***
    if r.Fsm = BusIdle_s then
      v.bus_busy_o := '0';
    else
      v.bus_busy_o := '1';
    end if;

    -- *** assign signal ***
    r_next <= v;
  end process;

  --------------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------------
  bus_busy_o     <= r.bus_busy_o;
  cmd_rdy_o      <= r.cmd_rdy_o;
  rsp_vld_o      <= r.rsp_vld_o;
  rsp_type_o     <= r.CmdTypeLatch;
  rsp_arb_lost_o <= r.rsp_arb_lost_o;
  rsp_ack_o      <= r.rsp_ack_o;
  rsp_dat_o      <= r.rsp_dat_o;
  rsp_seq_o      <= r.rsp_seq_o;
  timeout_cmd_o  <= r.timeout_cmd_o;
  g_intTristate : if internal_tri_state_g generate
    i2c_scl_io <= 'Z' when r.SclOut = '1' else '0';
    i2c_sda_io <= 'Z' when r.SdaOut = '1' else '0';
    i2c_scl_o  <= '0';
    i2c_sda_o  <= '0';
    i2c_scl_t  <= '1';
    i2c_sda_t  <= '1';
  end generate;
  g_extTristatte : if not internal_tri_state_g generate
    i2c_scl_o  <= r.SclOut;
    i2c_sda_o  <= r.SdaOut;
    i2c_scl_t  <= r.SclOut;
    i2c_sda_t  <= r.SdaOut;
    i2c_scl_io <= 'Z';
    i2c_sda_io <= 'Z';
  end generate;

  --------------------------------------------------------------------------
  -- Sequential Proccess
  --------------------------------------------------------------------------
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.bus_busy_o   <= '0';
        r.cmd_rdy_o    <= '0';
        r.SclLast      <= '1';
        r.SdaLast      <= '1';
        r.BusBusyToCnt <= (others => '0');
        r.Fsm          <= BusIdle_s;
        r.SclOut       <= '1';
        r.SdaOut       <= '1';
        r.rsp_vld_o    <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiations
  --------------------------------------------------------------------------
  I2cScl_Input <= to_01X(i2c_scl_io) when internal_tri_state_g else i2c_scl_i;
  I2cSda_Input <= to_01X(i2c_sda_io) when internal_tri_state_g else i2c_sda_i;

  i_sync : entity work.psi_common_bit_cc
    generic map(
      num_bits_g => 2
    )
    port map(
      dat_i(0) => I2cScl_Input,
      dat_i(1) => I2cSda_Input,
      clk_i    => clk_i,
      dat_o(0) => I2cScl_Sync,
      dat_o(1) => I2cSda_Sync
    );

end architecture;