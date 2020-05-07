------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_compare_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_trigger_analog_tb is
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_trigger_analog_tb is
  -- *** Fixed Generics ***
  constant analog_input_number_g : integer   := 32; -- number of analog trigger inputs
  constant analog_input_width_g     : integer   := 16; -- analog trigger input signal width
  constant analog_trg_signed_g    : boolean   := true; -- analog trigger input signal width
  constant rst_pol_g              : std_logic := '1'; -- reset polarity

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal ProcessDone          : std_logic_vector(0 to 0) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 0) := (others => '1');

  -- *** DUT Signals ***
  signal InClk                 : std_logic                                                                  := '1';
  signal InRst                 : std_logic                                                                  := '1';
  signal InTrgModeCfg          : std_logic_vector(0 downto 0)                                               := (others => '0');
  signal InTrgArmCfg           : std_logic                                                                  := '0';
  signal InTrgEdgeCfg          : std_logic_vector(1 downto 0)                                               := (others => '0');
  signal InTrgAnalogSourceCfg  : std_logic_vector(log2ceil(analog_input_number_g )-1 downto 0):= (others => '0');
  signal InAnalogTrg           : std_logic_vector(analog_input_number_g * analog_input_width_g - 1 downto 0) := (others => '0');
  signal InAnalogThTrg         : std_logic_vector(analog_input_width_g - 1 downto 0)                          := (others => '0');
  signal InExtDisarm           : std_logic  := '0';
  signal OutTrgIsArmed         : std_logic;
  signal OutTrigger            : std_logic;

  -- handwritten
  signal TestCase : integer := -1;
  
  procedure ExpectTriggerIs(Value : in integer) is
  begin
    wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    StdlCompare(Value, OutTrigger, "Wrong OutTrigger behaviour");
  end procedure;

  procedure ExpectTrgIsArmedIs(Value : in integer) is
  begin
    wait until rising_edge(InClk);
    StdlCompare(Value, OutTrgIsArmed, "Wrong OutTrgIsArmed behaviour");
  end procedure;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_trigger_analog
    generic map(
      analog_input_number_g => analog_input_number_g,
      analog_input_width_g     => analog_input_width_g,
      analog_trg_signed_g    => analog_trg_signed_g,
      rst_pol_g              => rst_pol_g
    )
    port map(
      InClk => InClk,
      InRst => InRst,
      InTrgModeCfg => InTrgModeCfg,
      InTrgArmCfg => InTrgArmCfg,
      InTrgEdgeCfg => InTrgEdgeCfg,
      InTrgAnalogSourceCfg => InTrgAnalogSourceCfg,
      InAnalogThTrg => InAnalogThTrg,
      InAnalogTrg => InAnalogTrg,
      InExtDisarm => InExtDisarm,
      OutTrgIsArmed => OutTrgIsArmed,
      OutTrigger => OutTrigger
    );

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until InRst = '0';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_InClk : process
    constant Frequency_c : real := real(100e6);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
      InClk <= not InClk;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_InRst : process
  begin
    wait for 1 us;
    -- Wait for two InClk edges to ensure reset is active for at least one edge
    wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    InRst <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** inp ***
  p_inp : process
  begin
    -- start of process !DO NOT EDIT
    wait until InRst = '0';

    -- *** Analog input test ***

    InTrgArmCfg <= '0';                 -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg <= '1';
    wait until rising_edge(InClk);

    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 0;

    InTrgModeCfg(0)      <= '0';        -- continuous mode
    InTrgEdgeCfg         <= "11";       -- both edges are sensitive
    InTrgAnalogSourceCfg <= std_logic_vector(to_unsigned(2,log2ceil(analog_input_number_g)));
    InAnalogThTrg        <= x"0010";

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);
    ---------------------------------------
    -- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 1;

    InTrgModeCfg(0)      <= '0';               -- continuous mode
    InTrgEdgeCfg <= "11";               -- both edges are sensitive

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 2;

    InTrgModeCfg(0)      <= '0';        -- continuous mode
    InTrgEdgeCfg <= "10";               -- rising edge sensitive

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 3;

    InTrgModeCfg(0)      <= '0';        -- continuous mode
    InTrgEdgeCfg <= "10";               -- rising edge sensitive

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 4;

    InTrgModeCfg(0)      <= '0';        -- continuous mode
    InTrgEdgeCfg <= "01";               -- falling edge sensitive

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 5;

    InTrgModeCfg(0)      <= '0';        -- continuous mode
    InTrgEdgeCfg <= "01";               -- falling edge sensitive

    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, both edge, multi clock cycle input
    TestCase <= 6;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgEdgeCfg <= "11";

    InTrgArmCfg <= '0';                 -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);

    InTrgArmCfg <= '0';                 -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg <= '1';                 -- arm trigger
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);

    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, both edge, single clock cycle input
    TestCase <= 7;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "11";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 8;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 9;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 10;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 11;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, inExtDisarm test
    TestCase <= 12;

    InTrgModeCfg(0)      <= '1';        -- single mode
    InTrgArmCfg                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg                                                                                    <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg                                                                                   <= "01";
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);
    InExtDisarm  <= '1';
    wait until rising_edge(InClk);
    InExtDisarm  <= '0';
    ExpectTrgIsArmedIs(0);
    InAnalogTrg((analog_input_width_g * 2) + (analog_input_width_g - 1) downto analog_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- end of process !DO NOT EDIT!
    ProcessDone(0) <= '1';
    wait;
  end process;

end;
