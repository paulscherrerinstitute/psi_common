------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_tb_txt_util.all;

entity psi_common_simple_cc_tb is
  generic(
    ClockRatioN_g : integer := 3;
    ClockRatioD_g : integer := 2
  );
end entity psi_common_simple_cc_tb;

architecture sim of psi_common_simple_cc_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------	
  constant ClockRatio_c : real    := real(ClockRatioN_g) / real(ClockRatioD_g);
  constant DataWidth_c  : integer := 8;

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockAFrequency_c : real    := 100.0e6;
  constant ClockAPeriod_c    : time    := (1 sec) / ClockAFrequency_c;
  constant ClockBFrequency_c : real    := ClockAFrequency_c * ClockRatio_c;
  constant ClockBPeriod_c    : time    := (1 sec) / ClockBFrequency_c;
  signal TbRunning           : boolean := True;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal ClkA    : std_logic                                  := '0';
  signal RstInA  : std_logic                                  := '1';
  signal RstOutA : std_logic;
  signal DataA   : std_logic_vector(DataWidth_c - 1 downto 0) := X"00";
  signal VldA    : std_logic                                  := '0';
  signal ClkB    : std_logic                                  := '0';
  signal RstInB  : std_logic                                  := '1';
  signal RstOutB : std_logic;
  signal DataB   : std_logic_vector(DataWidth_c - 1 downto 0);
  signal VldB    : std_logic;

  -------------------------------------------------------------------------
  -- Procedure
  -------------------------------------------------------------------------	

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_simple_cc
    generic map(
      DataWidth_g => DataWidth_c
    )
    port map(
      -- Clock Domain A
      ClkA    => ClkA,
      RstInA  => RstInA,
      RstOutA => RstOutA,
      DataA   => DataA,
      VldA    => VldA,
      -- Clock Domain B
      ClkB    => ClkB,
      RstInB  => RstInB,
      RstOutB => RstOutB,
      DataB   => DataB,
      VldB    => VldB
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_aclk : process
  begin
    ClkA <= '0';
    while TbRunning loop
      wait for 0.5 * ClockAPeriod_c;
      ClkA <= '1';
      wait for 0.5 * ClockAPeriod_c;
      ClkA <= '0';
    end loop;
    wait;
  end process;

  p_bclk : process
  begin
    ClkB <= '0';
    while TbRunning loop
      wait for 0.5 * ClockBPeriod_c;
      ClkB <= '1';
      wait for 0.5 * ClockBPeriod_c;
      ClkB <= '0';
    end loop;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- TB Control
  -------------------------------------------------------------------------
  p_control : process
  begin
    -- *** Reset Tests ***
    print("Reset Tests");

    -- Reset
    RstInA <= '1';
    RstInB <= '1';
    wait for 1 us;

    -- Check if both sides are in reset
    assert RstOutA = '1' report "###ERROR###: ResetOutA not asserted" severity error;
    assert RstOutB = '1' report "###ERROR###: ResetOutB not asserted" severity error;

    -- Remove reset
    wait until rising_edge(ClkA);
    RstInA <= '0';
    wait until rising_edge(ClkB);
    RstInB <= '0';
    wait for 1 us;

    -- Check if both sides exited reset
    assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted" severity error;
    assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted" severity error;

    -- Check if RstA is propagated to both sides
    wait until rising_edge(ClkA);
    RstInA <= '1';
    wait until rising_edge(ClkA);
    RstInA <= '0';
    wait for 1 us;
    assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted after reset A" severity error;
    assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted after reset A" severity error;
    assert RstOutA'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset A" severity error;
    assert RstOutB'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset A" severity error;

    -- Check if RstB is propagated to both sides
    wait until rising_edge(ClkB);
    RstInB <= '1';
    wait until rising_edge(ClkB);
    RstInB <= '0';
    wait for 1 us;
    assert RstOutA = '0' report "###ERROR###: ResetOutA not de-asserted after reset B" severity error;
    assert RstOutB = '0' report "###ERROR###: ResetOutB not de-asserted after reset B" severity error;
    assert RstOutA'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset B" severity error;
    assert RstOutB'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset B" severity error;

    -- *** Data Tests ***
    print("Dat Transfer Tests");

    wait until rising_edge(ClkA);
    DataA <= X"AB";
    VldA  <= '1';
    wait until rising_edge(ClkA);
    DataA <= X"00";
    VldA  <= '0';
    wait until rising_edge(ClkB) and VldB = '1';
    assert DataB = X"AB" report "###ERROR###: Received wrong value 1" severity error;
    for i in 0 to 10 loop
      wait until rising_edge(ClkB);
    end loop;
    assert DataB = X"AB" report "###ERROR###: Value was not kept after Vld going low 1" severity error;

    wait until rising_edge(ClkA);
    DataA <= X"CD";
    VldA  <= '1';
    wait until rising_edge(ClkA);
    DataA <= X"00";
    VldA  <= '0';
    wait until rising_edge(ClkB) and VldB = '1';
    assert DataB = X"CD" report "###ERROR###: Received wrong value 2" severity error;
    for i in 0 to 10 loop
      wait until rising_edge(ClkB);
    end loop;
    assert DataB = X"CD" report "###ERROR###: Value was not kept after Vld going low 2" severity error;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
