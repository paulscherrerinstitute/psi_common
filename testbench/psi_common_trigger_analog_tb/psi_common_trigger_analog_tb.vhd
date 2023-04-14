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
  constant anl_input_number_g : integer   := 32; -- number of analog trigger inputs
  constant anl_input_width_g     : integer   := 16; -- analog trigger input signal width
  constant anl_trg_signed_g    : boolean   := true; -- analog trigger input signal width
  constant rst_pol_g              : std_logic := '1'; -- reset polarity

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal ProcessDone          : std_logic_vector(0 to 0) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 0) := (others => '1');

  -- *** DUT Signals ***
  signal clk_i                 : std_logic                                                                  := '1';
  signal rst_i                 : std_logic                                                                  := '1';
  signal trg_mode_cfg_i          : std_logic_vector(0 downto 0)                                               := (others => '0');
  signal trg_arm_cfg_i           : std_logic                                                                  := '0';
  signal trg_edge_cfg_i          : std_logic_vector(1 downto 0)                                               := (others => '0');
  signal trg_anlg_src_cfg_i  : std_logic_vector(log2ceil(anl_input_number_g )-1 downto 0):= (others => '0');
  signal anl_trig_i           : std_logic_vector(anl_input_number_g * anl_input_width_g - 1 downto 0) := (others => '0');
  signal anl_th_trig_i         : std_logic_vector(anl_input_width_g - 1 downto 0)                          := (others => '0');
  signal ext_disarm_i           : std_logic  := '0';
  signal trg_is_armed_i         : std_logic;
  signal trig_o            : std_logic;

  -- handwritten
  signal TestCase : integer := -1;
  
  procedure ExpectTriggerIs(Value : in integer) is
  begin
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    StdlCompare(Value, trig_o, "Wrong trig_o behaviour");
  end procedure;

  procedure ExpectTrgIsArmedIs(Value : in integer) is
  begin
    wait until rising_edge(clk_i);
    StdlCompare(Value, trg_is_armed_i, "Wrong trg_is_armed_i behaviour");
  end procedure;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_trigger_analog
    generic map(
      trig_nb_g => anl_input_number_g,
      width_g     => anl_input_width_g,
      is_signed_g    => anl_trg_signed_g,
      rst_pol_g              => rst_pol_g
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      trg_mode_cfg_i => trg_mode_cfg_i,
      trg_arm_cfg_i => trg_arm_cfg_i,
      trg_edge_cfg_i => trg_edge_cfg_i,
      trg_anlg_src_cfg_i => trg_anlg_src_cfg_i,
      anl_th_trig_i => anl_th_trig_i,
      anl_trig_i => anl_trig_i,
      ext_disarm_i => ext_disarm_i,
      trg_is_armed_i => trg_is_armed_i,
      trig_o => trig_o
    );

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
  p_clock_InClk : process
    constant Frequency_c : real := real(100e6);
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
  p_rst_InRst : process
  begin
    wait for 1 us;
    -- Wait for two InClk edges to ensure reset is active for at least one edge
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    rst_i <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** inp ***
  p_inp : process
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- *** Analog input test ***

    trg_arm_cfg_i <= '0';                 -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i <= '1';
    wait until rising_edge(clk_i);

    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 0;

    trg_mode_cfg_i(0)      <= '0';        -- continuous mode
    trg_edge_cfg_i         <= "11";       -- both edges are sensitive
    trg_anlg_src_cfg_i <= std_logic_vector(to_unsigned(2,log2ceil(anl_input_number_g)));
    anl_th_trig_i        <= x"0010";

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);
    ---------------------------------------
    -- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 1;

    trg_mode_cfg_i(0)      <= '0';               -- continuous mode
    trg_edge_cfg_i <= "11";               -- both edges are sensitive

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 2;

    trg_mode_cfg_i(0)      <= '0';        -- continuous mode
    trg_edge_cfg_i <= "10";               -- rising edge sensitive

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 3;

    trg_mode_cfg_i(0)      <= '0';        -- continuous mode
    trg_edge_cfg_i <= "10";               -- rising edge sensitive

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 4;

    trg_mode_cfg_i(0)      <= '0';        -- continuous mode
    trg_edge_cfg_i <= "01";               -- falling edge sensitive

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 5;

    trg_mode_cfg_i(0)      <= '0';        -- continuous mode
    trg_edge_cfg_i <= "01";               -- falling edge sensitive

    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, both edge, multi clock cycle input
    TestCase <= 6;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_edge_cfg_i <= "11";

    trg_arm_cfg_i <= '0';                 -- de-arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);

    trg_arm_cfg_i <= '0';                 -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i <= '1';                 -- arm trigger
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);

    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, both edge, single clock cycle input
    TestCase <= 7;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "11";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 8;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '0'; -- de-arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 9;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 10;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '0'; -- de-arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 11;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"0020";
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, inExtDisarm test
    TestCase <= 12;

    trg_mode_cfg_i(0)      <= '1';        -- single mode
    trg_arm_cfg_i                                                                                    <= '0'; -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i                                                                                    <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i                                                                                   <= "01";
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);
    ext_disarm_i  <= '1';
    wait until rising_edge(clk_i);
    ext_disarm_i  <= '0';
    ExpectTrgIsArmedIs(0);
    anl_trig_i((anl_input_width_g * 2) + (anl_input_width_g - 1) downto anl_input_width_g * 2) <= x"8020";
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- end of process !DO NOT EDIT!
    ProcessDone(0) <= '1';
    wait;
  end process;

end;
