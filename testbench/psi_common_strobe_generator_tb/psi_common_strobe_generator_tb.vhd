------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_strobe_generator_tb is
  generic(
    freq_clock_g  : integer := 253e6;
    freq_strobe_g : integer := 10
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_strobe_generator_tb is
  -- *** Fixed Generics ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 0) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 0) := (others => '1');
  constant TbProcNr_Stimuli_c : integer                  := 0;

  -- *** DUT Signals ***
  signal InClk_sti  : std_logic := '0';
  signal InRst_sti  : std_logic := '1';
  signal OutVld_obs : std_logic := '0';
  signal InSync_sti : std_logic := '0';

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_strobe_generator
    generic map(
      freq_clock_g  => real(freq_clock_g),
      freq_strobe_g => real(freq_strobe_g)
    )
    port map(
      InClk  => InClk_sti,
      InRst  => InRst_sti,
      OutVld => OutVld_obs,
      InSync => InSync_sti
    );

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until InRst_sti = '0';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_clk_i : process
    constant Frequency_c : real := real(freq_clock_g);
  begin
    while TbRunning loop
      wait for 0.5 * (1 sec) / Frequency_c;
      InClk_sti <= not InClk_sti;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Resets
  ------------------------------------------------------------
  p_rst_rst_i : process
  begin
    wait for 1 us;
    -- Wait for two clk edges to ensure reset is active for at least one edge
    wait until rising_edge(InClk_sti);
    wait until rising_edge(InClk_sti);
    InRst_sti <= '0';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** Stimuli ***
  p_Stimuli : process
    variable last_edge   : time := 0 ns;
    variable period      : time;
    constant periodExp   : time := (1 sec) / real(freq_strobe_g);
    constant clockPeriod : time := (1 sec) / real(freq_clock_g);
  begin
    -- start of process !DO NOT EDIT
    wait until InRst_sti = '0';

    -- Test strobe frequency for 100 edges
    print(">> Freerunning strobe");
    wait until rising_edge(InClk_sti) and OutVld_obs = '1';
    last_edge := now;
    for i in 0 to 99 loop
      wait until rising_edge(InClk_sti) and OutVld_obs = '1';
      -- Calculate period
      period    := now - last_edge;
      last_edge := now;

      -- Period must match to +/- one clock cycle
      assert abs (period - periodExp) < clockPeriod
      report "###ERROR###: Received wrong clock period " & 
					to_string(period / 1 ns) & " ns instead of " & to_string(periodExp / 1 ns) & " ns" & 
					" +/- " & to_string(clockPeriod / 1 ns) & " ns"
      severity error;

    end loop;

    -- Test strobe synchronization with strobe
    print(">> Synchronization with strobe");
    wait until rising_edge(InClk_sti) and OutVld_obs = '1';
    wait for periodExp / 2;
    wait until rising_edge(InClk_sti);
    InSync_sti <= '1';
    wait until rising_edge(InClk_sti);
    InSync_sti <= '0';
    wait until rising_edge(InClk_sti);
    assert OutVld_obs = '1' report "###ERROR:### Strobe synchronization with pulse did not work 1" severity error;
    last_edge  := now;
    wait until rising_edge(InClk_sti);
    assert OutVld_obs = '0' report "###ERROR:### Strobe synchronization with pulse did not work 2" severity error;
    wait until rising_edge(InClk_sti) and OutVld_obs = '1';
    period     := now - last_edge;
    last_edge  := now;
    assert abs (period - periodExp) < clockPeriod
    report "###ERROR###: Received wrong clock period " & 
				to_string(period / 1 ns) & " ns instead of " & to_string(periodExp / 1 ns) & " ns" & 
				" +/- " & to_string(clockPeriod / 1 ns) & " ns"
    severity error;

    -- Test strobe synchronization with edge
    print(">> Synchronization with edge");
    wait until rising_edge(InClk_sti) and OutVld_obs = '1';
    wait for periodExp / 2;
    wait until rising_edge(InClk_sti);
    InSync_sti <= '1';
    wait until rising_edge(InClk_sti);
    wait until rising_edge(InClk_sti);
    assert OutVld_obs = '1' report "###ERROR:### Strobe synchronization with edge did not work 1" severity error;
    last_edge  := now;
    wait until rising_edge(InClk_sti);
    assert OutVld_obs = '0' report "###ERROR:### Strobe synchronization with edgep did not work 2" severity error;
    wait until rising_edge(InClk_sti) and OutVld_obs = '1';
    period     := now - last_edge;
    last_edge  := now;
    assert abs (period - periodExp) < clockPeriod
    report "###ERROR###: Received wrong clock period " & 
				to_string(period / 1 ns) & " ns instead of " & to_string(periodExp / 1 ns) & " ns" & 
				" +/- " & to_string(clockPeriod / 1 ns) & " ns"
    severity error;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_Stimuli_c) <= '1';
    wait;
  end process;

end;
