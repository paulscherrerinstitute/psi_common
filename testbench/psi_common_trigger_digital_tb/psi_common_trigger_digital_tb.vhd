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
entity psi_common_trigger_digital_tb is
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_trigger_digital_tb is
  -- *** Fixed Generics ***
  constant digital_input_number_g : integer   := 4; -- number of digital trigger inputs
  constant rst_pol_g               : std_logic := '1'; -- reset polarity

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
  signal digital_trg_i          : std_logic_vector(digital_input_number_g - 1 downto 0) := (others => '0');
  signal trg_digital_source_cfg_i : std_logic_vector(choose(digital_input_number_g>1,log2ceil(digital_input_number_g)-1,0) downto 0):= (others => '0');
  signal ext_disarm_i           : std_logic  := '0';
  signal trg_is_armed_o         : std_logic;
  signal trigger_o            : std_logic;

  -- handwritten
  signal TestCase : integer := -1;

  procedure ExpectTriggerIs(Value : in integer) is
  begin
    wait until rising_edge(clk_i);
    wait until rising_edge(clk_i);
    StdlCompare(Value, trigger_o, "Wrong trigger_o behaviour");
  end procedure;

  procedure ExpectTrgIsArmedIs(Value : in integer) is
  begin
    wait until rising_edge(clk_i);
    StdlCompare(Value, trg_is_armed_o, "Wrong trg_is_armed_o behaviour");
  end procedure;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_trigger_digital
    generic map(
      digital_input_number_g => digital_input_number_g,
      rst_pol_g               => rst_pol_g
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      trg_mode_cfg_i => trg_mode_cfg_i,
      trg_arm_cfg_i => trg_arm_cfg_i,
      trg_edge_cfg_i => trg_edge_cfg_i,
      trg_digital_source_cfg_i => trg_digital_source_cfg_i,
      digital_trg_i => digital_trg_i,
      ext_disarm_i => ext_disarm_i,
      trg_is_armed_o => trg_is_armed_o,
      trigger_o => trigger_o
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

    -- *** digital trigger test ***

    trg_arm_cfg_i <= '0';                 -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i <= '1';
    wait until rising_edge(clk_i);

    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 0;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_edge_cfg_i          <= "11";      -- both edges are sensitive
    trg_digital_source_cfg_i <= std_logic_vector(to_unsigned(0,log2ceil(digital_input_number_g)));

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 1;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_edge_cfg_i <= "11";               -- both edges are sensitive

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    digital_trg_i(0) <= '0';
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 2;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_arm_cfg_i  <= '0';                -- not used in continuous mode
    trg_edge_cfg_i <= "10";               -- rising edge sensitive

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 3;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_edge_cfg_i <= "10";               -- rising edge sensitive

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    digital_trg_i(0) <= '0';
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 4;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_edge_cfg_i <= "01";               -- falling edge sensitive

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 5;

    trg_mode_cfg_i(0)          <= '0';      -- continuous mode
    trg_edge_cfg_i <= "01";               -- falling edge sensitive

    wait until rising_edge(clk_i);
    digital_trg_i(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    digital_trg_i(0) <= '0';
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, both edge, multi clock cycle input
    TestCase <= 6;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '1';             -- de-arm trigger
    trg_edge_cfg_i    <= "11";
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i     <= '0';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i     <= '1';             -- arm trigger
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, both edge, single clock cycle input
    TestCase <= 7;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i    <= "11";
    ExpectTrgIsArmedIs(1);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 8;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i    <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '0';             -- de-arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 9;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i    <= "10";
    ExpectTrgIsArmedIs(1);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 10;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i    <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '0';             -- de-arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(0);
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 11;

    trg_mode_cfg_i(0)          <= '1';      -- single mode
    trg_arm_cfg_i     <= '0';             -- arm trigger
    wait until rising_edge(clk_i);
    trg_arm_cfg_i     <= '1';
    wait until rising_edge(clk_i);
    trg_edge_cfg_i    <= "01";
    ExpectTrgIsArmedIs(1);
    digital_trg_i(0) <= '0';
    wait until rising_edge(clk_i);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    digital_trg_i(0) <= '0';
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
    ExpectTriggerIs(0);
    digital_trg_i(0) <= '1';
    wait until rising_edge(clk_i);
    ExpectTriggerIs(0);
    digital_trg_i(0) <= '0';
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(clk_i);

    -- end of process !DO NOT EDIT!
    ProcessDone(0) <= '1';
    wait;
  end process;

end;
