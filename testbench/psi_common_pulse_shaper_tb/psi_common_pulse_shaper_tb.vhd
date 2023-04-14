------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

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

use work.psi_tb_compare_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_pulse_shaper_tb is
  generic(
    hold_in_g : boolean := false
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_pulse_shaper_tb is
  -- *** Fixed Generics ***
  constant duration_g : positive := 3;
  constant hold_off_g  : natural  := 20;

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 0) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 0) := (others => '1');
  constant TbProcNr_stimuli_c : integer                  := 0;

  -- *** DUT Signals ***
  signal clk_i      : std_logic := '1';
  signal rst_i      : std_logic := '1';
  signal dat_i  : std_logic := '0';
  signal dat_o : std_logic := '0';

  -- *** Helpers ***
  signal InPulseDff : std_logic;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_pulse_shaper
    generic map(
      duration_g => duration_g,
      hold_in_g   => hold_in_g,
      hold_off_g  => hold_off_g
    )
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      dat_i  => dat_i,
      dat_o => dat_o
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
  p_clock_Clk : process
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
  -- *** stimuli ***
  p_stimuli : process
    variable ExpectedInt_v : integer;
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- *** Test if pulse gets enlonged ***
    wait until falling_edge(clk_i);
    dat_i <= '1';
    StdlCompare(0, dat_o, "Too early");
    wait until falling_edge(clk_i);
    dat_i <= '0';
    StdlCompare(1, dat_o, "Not asserted 1");
    wait until falling_edge(clk_i);
    StdlCompare(1, dat_o, "Not asserted 2");
    wait until falling_edge(clk_i);
    StdlCompare(1, dat_o, "Not asserted 3");
    wait until falling_edge(clk_i);
    StdlCompare(0, dat_o, "Not deasserted");
    for i in 0 to 50 loop
      wait until falling_edge(clk_i);
      StdlCompare(0, dat_o, "Did not stay low");
    end loop;
    wait for 200 ns;

    -- *** Test if pulse gets shortened ***
    wait until falling_edge(clk_i);
    dat_i <= '1';
    StdlCompare(0, dat_o, "Too early");
    wait until falling_edge(clk_i);
    StdlCompare(1, dat_o, "Not asserted 1");
    wait until falling_edge(clk_i);
    StdlCompare(1, dat_o, "Not asserted 2");
    wait until falling_edge(clk_i);
    StdlCompare(1, dat_o, "Not asserted 3");
    wait until falling_edge(clk_i);
    -- expected output depends on HoldIn_g
    if hold_in_g then
      ExpectedInt_v := 1;
    else
      ExpectedInt_v := 0;
    end if;
    -- Test 
    StdlCompare(ExpectedInt_v, dat_o, "Not deasserted");
    for i in 0 to 50 loop
      wait until falling_edge(clk_i);
      StdlCompare(ExpectedInt_v, dat_o, "Did not stay low");
    end loop;
    dat_i <= '0';
    wait for 200 ns;
    StdlCompare(0, dat_o, "Too early");

    -- *** Test holdoff with large deviation ***
    for pair in 0 to 2 loop
      for pulse in 1 downto 0 loop      -- first pulse is detected, second not
        wait until falling_edge(clk_i);
        dat_i <= '1';
        StdlCompare(0, dat_o, "Too early");
        wait until falling_edge(clk_i);
        dat_i <= '0';
        StdlCompare(pulse, dat_o, "Assertion test 1");
        wait until falling_edge(clk_i);
        StdlCompare(pulse, dat_o, "Assertion test 2");
        wait until falling_edge(clk_i);
        StdlCompare(pulse, dat_o, "Assertion test3");
        wait until falling_edge(clk_i);
        StdlCompare(0, dat_o, "Not deasserted");
        wait until falling_edge(clk_i);
        StdlCompare(0, dat_o, "Not deasserted");
        for i in 0 to 10 loop
          wait until falling_edge(clk_i);
          StdlCompare(0, dat_o, "Did not stay low");
        end loop;
      end loop;
    end loop;
    wait for 200 ns;

    -- *** Test holdoff (one cycle too short) ***
    wait until falling_edge(clk_i);
    dat_i <= '1';
    for i in 0 to hold_off_g - 1 loop
      wait until falling_edge(clk_i);
      dat_i <= '0';
    end loop;
    dat_i <= '1';
    wait until falling_edge(clk_i);
    dat_i <= '0';
    StdlCompare(0, dat_o, "Wrongly detected pulse in hold-off time");
    wait for 200 ns;

    -- *** Test holdoff (exactly OK) ***
    wait until falling_edge(clk_i);
    dat_i <= '1';
    for i in 0 to hold_off_g loop
      wait until falling_edge(clk_i);
      dat_i <= '0';
    end loop;
    dat_i <= '1';
    wait until falling_edge(clk_i);
    dat_i <= '0';
    StdlCompare(1, dat_o, "Did not detect pulse directly after holdoff time");

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stimuli_c) <= '1';
    wait;
  end process;
end;
