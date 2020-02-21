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
  use work.psi_tb_compare_pkg.all;  

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_trigger_generator_tb is
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_trigger_generator_tb is
  -- *** Fixed Generics ***
  constant digital_trg_g : boolean := true; -- digital trigger mechanism is generated
  constant digital_sources_width_g : integer := 1; -- number of digital trigger inputs
  constant analog_trg_g : boolean := true; -- analog trigger mechanism is generated
  constant analog_sources_width_g : integer := 32; -- number of analog trigger inputs
  constant analog_trg_width_g : integer := 16; -- analog trigger input signal width
  constant analog_trg_signed_g : boolean := true; -- analog trigger input signal width
  constant rst_pol_g   : std_logic := '1' ;   -- reset polarity
  
  -- *** Not Assigned Generics (default values) ***
  
  -- *** TB Control ***
  signal TbRunning : boolean := True;
  signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_inp_c : integer := 0;
  constant TbProcNr_outp_c : integer := 1;
  
  -- *** DUT Signals ***
  signal InClk : std_logic := '1';
  signal InRst : std_logic := '1';
  signal InTrgTypeCfg : std_logic_vector (1 downto 0) := (others => '0');
  signal InTrgModeCfg : std_logic_vector (1 downto 0) := (others => '0');
  signal InTrgArmCfg : std_logic := '0';
  signal InTrgEdgeCfg : std_logic_vector (1 downto 0):= (others => '0');
  signal InDigitalTrg  : std_logic_vector (digital_sources_width_g - 1 downto 0) := (others => '0'); 
  signal InTrgDigitalSourceCfg : integer range integer(ceil(log2(real(digital_sources_width_g)))) downto 0 := 0;
  signal InTrgAnalogSourceCfg : integer range integer(ceil(log2(real(analog_sources_width_g)))) downto 0 := 0;
  signal InAnalogTrg : t_aslv16 (analog_sources_width_g - 1 downto 0) := (others => (others => '0'));
  signal InAnalogThTrg : std_logic_vector (analog_trg_width_g - 1 downto 0) := (others => '0');
  signal OutTrgIsArmed :std_logic;
  signal OutTrigger  : std_logic;
  
  
  -- handwritten
  signal TestCase : integer := -1;
    
--  procedure Expect3Channels(  Values : in t_ainteger(0 to 2)) is
--  begin
--    wait until rising_edge(InClk) and ParallelVld = '1';
--    StdlvCompareInt (Values(0), Parallel(1*ChannelWidth_g-1 downto 0*ChannelWidth_g), "Wrong value Channel 0", false);  
--    StdlvCompareInt (Values(1), Parallel(2*ChannelWidth_g-1 downto 1*ChannelWidth_g), "Wrong value Channel 1", false);  
--    StdlvCompareInt (Values(2), Parallel(3*ChannelWidth_g-1 downto 2*ChannelWidth_g), "Wrong value Channel 2", false);  
--  end procedure;
--  
--  procedure Expect2Channels( Values : in t_ainteger(0 to 1)) is
--  begin
--    wait until rising_edge(InClk) and ParallelVld = '1';
--    StdlvCompareInt (Values(0), Parallel(1*ChannelWidth_g-1 downto 0*ChannelWidth_g), "Wrong value Channel 0", false);  
--    StdlvCompareInt (Values(1), Parallel(2*ChannelWidth_g-1 downto 1*ChannelWidth_g), "Wrong value Channel 1", false);
--  end procedure;  
--  
  procedure ExpectTriggerIs( Value : in integer) is
  begin
    wait until rising_edge(InClk);
    StdlCompare (Value, OutTrigger, "Wrong OutTrigger behaviour");  
  end procedure;
  
  procedure ExpectTrgIsArmedIs( Value : in integer) is
  begin
    wait until rising_edge(InClk);
    StdlCompare (Value, OutTrgIsArmed, "Wrong OutTrgIsArmed behaviour");  
  end procedure;
  
begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_trigger_generator 
  generic map(
    digital_trg_g  => digital_trg_g,
    digital_sources_width_g  => digital_sources_width_g,
    analog_trg_g => analog_trg_g,
    analog_sources_width_g  => analog_sources_width_g,
    analog_trg_width_g  => analog_trg_width_g,
    analog_trg_signed_g  => analog_trg_signed_g,
    rst_pol_g => rst_pol_g
  )
  port map (
    InClk => InClk,
    InRst => InRst,
    InTrgTypeCfg => InTrgTypeCfg,
    InTrgModeCfg => InTrgModeCfg,
    InTrgArmCfg => InTrgArmCfg,
    InTrgEdgeCfg => InTrgEdgeCfg,
    
    InDigitalTrg => InDigitalTrg,
    InTrgDigitalSourceCfg => InTrgDigitalSourceCfg,
    
    InTrgAnalogSourceCfg  => InTrgAnalogSourceCfg,
    InAnalogTrg => InAnalogTrg,
    InAnalogThTrg => InAnalogThTrg,
    
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
      wait for 0.5*(1 sec)/Frequency_c;
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
    
    
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    
    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 0;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "11"; -- both edges are sensitive
    InTrgDigitalSourceCfg <= 0;
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 1;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "11"; -- both edges are sensitive
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    InDigitalTrg(0) <= '0'; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 2;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgArmCfg  <=  '0'; -- not used in continuous mode
    InTrgEdgeCfg  <= "10"; -- rising edge sensitive
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
        
    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 3;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "10"; -- rising edge sensitive
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    InDigitalTrg(0) <= '0'; 
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);    
    
    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 4;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "01"; -- falling edge sensitive
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
        
    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 5;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "01"; -- falling edge sensitive
    
    wait until rising_edge(InClk);
    InDigitalTrg(0) <= '0';
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    InDigitalTrg(0) <= '0'; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);      
    
    -- Single mode, both edge, multi clock cycle input
    TestCase <= 6;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '1'; -- de-arm trigger
    InTrgEdgeCfg  <= "11"; 
    ExpectTrgIsArmedIs (0);
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (0);
    InTrgArmCfg  <=  '1'; -- arm trigger
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, both edge, single clock cycle input
    TestCase <= 7;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "11"; 
    ExpectTrgIsArmedIs (1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 8;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "10"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (0);
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, single clock cycle input
    TestCase <= 9;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "10"; 
    ExpectTrgIsArmedIs (1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);    
      
    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 10;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "01"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (0);
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '0'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, single clock cycle input
    TestCase <= 11;
    
    InTrgTypeCfg  <=  "00"; -- digital trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "01"; 
    ExpectTrgIsArmedIs (1);
    InDigitalTrg(0) <= '0';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InDigitalTrg(0) <= '1'; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    InDigitalTrg(0) <= '0'; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);  
    
    
    -- *** Analog input test ***
    
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    
    -- Continuous mode, two sensitive edges, multi clock cycle input
    TestCase <= 12;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "11"; -- both edges are sensitive
    InTrgAnalogSourceCfg <= 2;
    InAnalogThTrg <= x"0010"; 
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
---------------------------------------
-- Continuous mode, two sensitive edges, single clock cycle input
    TestCase <= 13;
    
    InTrgTypeCfg  <=  "01"; -- analog triggerr
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "11"; -- both edges are sensitive
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    InAnalogTrg(2) <= x"8020"; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Continuous mode, rising edge, multi clock cycle input
    TestCase <= 14;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "10"; -- rising edge sensitive
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
        
    -- Continuous mode, rising edge, single clock cycle input
    TestCase <= 15;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "10"; -- rising edge sensitive
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    InAnalogTrg(2) <= x"8020"; 
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);    
    
    -- Continuous mode, falling edge, multi clock cycle input
    TestCase <= 16;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "01"; -- falling edge sensitive
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);
        
    -- Continuous mode, falling edge, single clock cycle input
    TestCase <= 17;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "00"; -- continuous mode
    InTrgEdgeCfg  <= "01"; -- falling edge sensitive
    
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    InAnalogTrg(2) <= x"8020"; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    wait until rising_edge(InClk);      
    
    -- Single mode, both edge, multi clock cycle input
    TestCase <= 18;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgEdgeCfg  <= "11";
    
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1'; 
    ExpectTrgIsArmedIs (0);
    
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1'; -- arm trigger
    ExpectTrgIsArmedIs (1);
    
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, both edge, single clock cycle input
    TestCase <= 19;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "11"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    InAnalogTrg(2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 20;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "10"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (0);
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, single clock cycle input
    TestCase <= 21;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "10"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    InAnalogTrg(2) <= x"8020";
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);    
      
    -- Single mode, rising edge, multi clock cycle input
    TestCase <= 22;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "01"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '0'; -- de-arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (0);
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"8020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);
    
    -- Single mode, rising edge, single clock cycle input
    TestCase <= 23;
    
    InTrgTypeCfg  <=  "01"; -- analog trigger
    InTrgModeCfg  <=  "01"; -- single mode
    InTrgArmCfg  <=  '0'; -- arm trigger
    wait until rising_edge(InClk);
    InTrgArmCfg  <=  '1';
    wait until rising_edge(InClk);
    InTrgEdgeCfg  <= "01"; 
    ExpectTrgIsArmedIs (1);
    wait until rising_edge(InClk);
    ExpectTrgIsArmedIs (1);
    wait for 100 ns;
    InAnalogTrg(2) <= x"0020"; 
    wait until rising_edge(InClk);
    ExpectTriggerIs (0);
    InAnalogTrg(2) <= x"8020"; 
    ExpectTriggerIs (1);
    ExpectTrgIsArmedIs (0);
    wait for 100 ns;
    wait until rising_edge(InClk);  


    
    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_outp_c) <= '1';
    wait;
  end process;
  
  
end;
