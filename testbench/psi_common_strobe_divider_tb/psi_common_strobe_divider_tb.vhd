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

library work;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_common_math_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_strobe_divider_tb is
  generic(
    ratio_g : integer range 0 to 15 := 6
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_strobe_divider_tb is
  -- *** Fixed Generics ***
  constant length_g : natural := 4;

  -- *** TB Control ***
  signal TbRunning             : boolean                  := True;
  signal NextCase              : integer                  := -1;
  signal ProcessDone           : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c  : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_ctrl_c     : integer                  := 0;
  constant TbProcNr_countout_c : integer                  := 1;
  constant AppliedRatio_g      : integer                  := choose(ratio_g = 0, 1, ratio_g); -- Illegal condition Ratio=0 leads to no division

  -- *** DUT Signals ***
  signal InClk_sti   : std_logic                               := '0';
  signal InRst_sti   : std_logic                               := '0';
  signal InVld_sti   : std_logic                               := '0';
  signal InRatio_sti : std_logic_vector(length_g - 1 downto 0) := (others => '0');
  signal OutVld_obs  : std_logic                               := '0';

  -- TB Signals
  signal OutStrbCnt  : integer := 0;
  signal StimuliDone : boolean := false;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_strobe_divider
    generic map(
      length_g => length_g
    )
    port map(
      clk_i   => InClk_sti,
      rst_i   => InRst_sti,
      vld_i   => InVld_sti,
      ratio_i => InRatio_sti,
      vld_o  => OutVld_obs
    );

  ------------------------------------------------------------
  -- Testbench Control !DO NOT EDIT!
  ------------------------------------------------------------
  p_tb_control : process
  begin
    wait until InRst_sti = '1';
    wait until ProcessDone = AllProcessesDone_c;
    TbRunning <= false;
    wait;
  end process;

  ------------------------------------------------------------
  -- Clocks !DO NOT EDIT!
  ------------------------------------------------------------
  p_clock_clk_i : process
    constant Frequency_c : real := real(100e6);
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
    InRst_sti <= '1';
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** ctrl ***
  p_ctrl : process
  begin
    -- start of process !DO NOT EDIT
    wait until InRst_sti = '1';

    -- Apply Input strobes (with = 1 cycle)
    print(">> Strobes");
    InRatio_sti <= std_logic_vector(to_unsigned(AppliedRatio_g, length_g));
    wait until rising_edge(InClk_sti);
    for i in 0 to 599 loop
      wait until rising_edge(InClk_sti);
      InVld_sti <= '1';
      wait until rising_edge(InClk_sti);
      InVld_sti <= '0';
      wait for 100 ns;
    end loop;

    -- Check
    wait for 1 us;
    IntCompare(1 * 600 / AppliedRatio_g, OutStrbCnt, "Received unexpected strobe count " & to_string(OutStrbCnt));

    -- Apply Input Pulses (widht = 50%)
    print(">> Pulses");
    wait until rising_edge(InClk_sti);
    for i in 0 to 599 loop
      wait until rising_edge(InClk_sti);
      InVld_sti <= '1';
      wait for 50 ns;
      wait until rising_edge(InClk_sti);
      InVld_sti <= '0';
      wait for 50 ns;
    end loop;

    -- Check
    wait for 1 us;
    IntCompare(2 * 600 / AppliedRatio_g, OutStrbCnt, "Received unexpected strobe count " & to_string(OutStrbCnt));

    StimuliDone                  <= true;
    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_ctrl_c) <= '1';
    wait;
  end process;

  -- *** countout ***
  p_countout : process
    variable strLast : std_logic := '0';
  begin
    -- start of process !DO NOT EDIT
    wait until InRst_sti = '1';

    -- count output strobes
    while not StimuliDone loop
      wait until rising_edge(InClk_sti);
      assert strLast = '0' or OutVld_obs = '0' report "###ERROR###: Output strobe was longer than one cycle" severity error;
      if OutVld_obs = '1' then
        OutStrbCnt <= OutStrbCnt + 1;
      end if;
      strLast := OutVld_obs;
    end loop;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_countout_c) <= '1';
    wait;
  end process;

end;
