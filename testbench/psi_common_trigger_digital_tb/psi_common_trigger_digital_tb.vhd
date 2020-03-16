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
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_inp_c     : integer                  := 0;
  constant TbProcNr_outp_c    : integer                  := 1;

  -- *** DUT Signals ***
  signal InClk                 : std_logic                                                                  := '1';
  signal InRst                 : std_logic                                                                  := '1';
  signal InTrgModeCfg          : std_logic_vector(0 downto 0)                                               := (others => '0');
  signal InTrgArmCfg           : std_logic                                                                  := '0';
  signal InTrgEdgeCfg          : std_logic_vector(1 downto 0)                                               := (others => '0');
  signal InDigitalTrg          : std_logic_vector(digital_input_number_g - 1 downto 0) := (others => '0');
  signal InTrgDigitalSourceCfg : std_logic_vector(log2ceil(digital_input_number_g)-1 downto 0):= (others => '0');
  signal InExtDisarm           : std_logic  := '0';
  signal OutTrgIsArmed         : std_logic;
  signal OutTrigger            : std_logic;

  -- handwritten
  signal TestCase : integer := -1;

  procedure ExpectTriggerIs(Value : in integer) is
  begin
    wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    StdlCompare(Value, OutTrigger, "Wrong OutTrigger behaviour");
  end procedure;

  procedure ExpectTrgIsArmedIs(Value : in integer) is
  begin
    --wait until rising_edge(InClk);
    wait until rising_edge(InClk);
    StdlCompare(Value, OutTrgIsArmed, "Wrong OutTrgIsArmed behaviour");
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
      InClk                 => InClk,
      InRst                 => InRst,
      InTrgModeCfg          => InTrgModeCfg,
      InTrgArmCfg           => InTrgArmCfg,
      InTrgEdgeCfg          => InTrgEdgeCfg,
      InDigitalTrg          => InDigitalTrg,
      InTrgDigitalSourceCfg => InTrgDigitalSourceCfg,
      InExtDisarm           => InExtDisarm,
      OutTrgIsArmed         => OutTrgIsArmed,
      OutTrigger            => OutTrigger
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

    -- *** digital trigger test ***

    InTrgArmCfg <= '0';                 -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg <= '1';
    wait until rising_edge(InClk);

    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 0;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgEdgeCfg          <= "11";      -- both edges are sensitive
    InTrgDigitalSourceCfg <= std_logic_vector(to_unsigned(0,log2ceil(digital_input_number_g)));

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 1;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgEdgeCfg <= "11";               -- both edges are sensitive

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    InDigitalTrg(0) <= '0';
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 2;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgArmCfg  <= '0';                -- not used in continuous mode
    InTrgEdgeCfg <= "10";               -- rising edge sensitive

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 3;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgEdgeCfg <= "10";               -- rising edge sensitive

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    InDigitalTrg(0) <= '0';
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 4;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgEdgeCfg <= "01";               -- falling edge sensitive

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 5;

    InTrgModeCfg(0)          <= '0';      -- continuous mode
    InTrgEdgeCfg <= "01";               -- falling edge sensitive

    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    InDigitalTrg(0) <= '0';
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, both edge, multi clock cycle input
    TestCase <= 6;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '1';             -- de-arm trigger
    InTrgEdgeCfg    <= "11";
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg     <= '0';             
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg     <= '1';             -- arm trigger
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, both edge, single clock cycle input
    TestCase <= 7;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg    <= "11";
    ExpectTrgIsArmedIs(1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 8;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg    <= "10";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '0';             -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 9;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg    <= "10";
    ExpectTrgIsArmedIs(1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 10;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg    <= "01";
    ExpectTrgIsArmedIs(1);
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '0';             -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(0);
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTriggerIs(1);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- Single mode, rising edge, single clock cycle input
    TestCase <= 11;

    InTrgModeCfg(0)          <= '1';      -- single mode
    InTrgArmCfg     <= '0';             -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg     <= '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg    <= "01";
    ExpectTrgIsArmedIs(1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs(1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    InDigitalTrg(0) <= '0';
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
    ExpectTriggerIs(0);
    InDigitalTrg(0) <= '1';
    wait until rising_edge(InClk);
    ExpectTriggerIs(0);
    InDigitalTrg(0) <= '0';
    ExpectTriggerIs(0);
    ExpectTrgIsArmedIs(0);
    wait for 100 ns;
    wait until rising_edge(InClk);

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_outp_c) <= '1';
    wait;
  end process;

end;
