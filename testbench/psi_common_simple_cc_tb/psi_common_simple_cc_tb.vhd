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
    clock_ratio_n_g : integer := 3;
    clock_ratio_d_g : integer := 2
  );
end entity psi_common_simple_cc_tb;

architecture sim of psi_common_simple_cc_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------	
  constant ClockRatio_c : real    := real(clock_ratio_n_g) / real(clock_ratio_d_g);
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
  signal a_clk_i    : std_logic                                  := '0';
  signal a_rst_i  : std_logic                                  := '1';
  signal a_rst_o : std_logic;
  signal a_dat_i   : std_logic_vector(DataWidth_c - 1 downto 0) := X"00";
  signal a_vld_i    : std_logic                                  := '0';
  signal b_clk_i    : std_logic                                  := '0';
  signal b_rst_i  : std_logic                                  := '1';
  signal b_rst_o : std_logic;
  signal b_dat_o   : std_logic_vector(DataWidth_c - 1 downto 0);
  signal b_vld_o    : std_logic;

  -------------------------------------------------------------------------
  -- Procedure
  -------------------------------------------------------------------------	

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_simple_cc
    generic map(
      width_g => DataWidth_c
    )
    port map(
      -- Clock Domain A
      a_clk_i    => a_clk_i,
      a_rst_i  => a_rst_i,
      a_rst_o => a_rst_o,
      a_dat_i   => a_dat_i,
      a_vld_i    => a_vld_i,
      -- Clock Domain B
      b_clk_i    => b_clk_i,
      b_rst_i  => b_rst_i,
      b_rst_o => b_rst_o,
      b_dat_o   => b_dat_o,
      b_vld_o    => b_vld_o
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_aclk : process
  begin
    a_clk_i <= '0';
    while TbRunning loop
      wait for 0.5 * ClockAPeriod_c;
      a_clk_i <= '1';
      wait for 0.5 * ClockAPeriod_c;
      a_clk_i <= '0';
    end loop;
    wait;
  end process;

  p_bclk : process
  begin
    b_clk_i <= '0';
    while TbRunning loop
      wait for 0.5 * ClockBPeriod_c;
      b_clk_i <= '1';
      wait for 0.5 * ClockBPeriod_c;
      b_clk_i <= '0';
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
    a_rst_i <= '1';
    b_rst_i <= '1';
    wait for 1 us;

    -- Check if both sides are in reset
    assert a_rst_o = '1' report "###ERROR###: ResetOutA not asserted" severity error;
    assert b_rst_o = '1' report "###ERROR###: ResetOutB not asserted" severity error;

    -- Remove reset
    wait until rising_edge(a_clk_i);
    a_rst_i <= '0';
    wait until rising_edge(b_clk_i);
    b_rst_i <= '0';
    wait for 1 us;

    -- Check if both sides exited reset
    assert a_rst_o = '0' report "###ERROR###: ResetOutA not de-asserted" severity error;
    assert b_rst_o = '0' report "###ERROR###: ResetOutB not de-asserted" severity error;

    -- Check if RstA is propagated to both sides
    wait until rising_edge(a_clk_i);
    a_rst_i <= '1';
    wait until rising_edge(a_clk_i);
    a_rst_i <= '0';
    wait for 1 us;
    assert a_rst_o = '0' report "###ERROR###: ResetOutA not de-asserted after reset A" severity error;
    assert b_rst_o = '0' report "###ERROR###: ResetOutB not de-asserted after reset A" severity error;
    assert a_rst_o'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset A" severity error;
    assert b_rst_o'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset A" severity error;

    -- Check if RstB is propagated to both sides
    wait until rising_edge(b_clk_i);
    b_rst_i <= '1';
    wait until rising_edge(b_clk_i);
    b_rst_i <= '0';
    wait for 1 us;
    assert a_rst_o = '0' report "###ERROR###: ResetOutA not de-asserted after reset B" severity error;
    assert b_rst_o = '0' report "###ERROR###: ResetOutB not de-asserted after reset B" severity error;
    assert a_rst_o'last_event < 1 us report "###ERROR###: ResetOutA not asserted after reset B" severity error;
    assert b_rst_o'last_event < 1 us report "###ERROR###: ResetOutB not asserted after reset B" severity error;

    -- *** Data Tests ***
    print("Dat Transfer Tests");

    wait until rising_edge(a_clk_i);
    a_dat_i <= X"AB";
    a_vld_i  <= '1';
    wait until rising_edge(a_clk_i);
    a_dat_i <= X"00";
    a_vld_i  <= '0';
    wait until rising_edge(b_clk_i) and b_vld_o = '1';
    assert b_dat_o = X"AB" report "###ERROR###: Received wrong value 1" severity error;
    for i in 0 to 10 loop
      wait until rising_edge(b_clk_i);
    end loop;
    assert b_dat_o = X"AB" report "###ERROR###: Value was not kept after Vld going low 1" severity error;

    wait until rising_edge(a_clk_i);
    a_dat_i <= X"CD";
    a_vld_i  <= '1';
    wait until rising_edge(a_clk_i);
    a_dat_i <= X"00";
    a_vld_i  <= '0';
    wait until rising_edge(b_clk_i) and b_vld_o = '1';
    assert b_dat_o = X"CD" report "###ERROR###: Received wrong value 2" severity error;
    for i in 0 to 10 loop
      wait until rising_edge(b_clk_i);
    end loop;
    assert b_dat_o = X"CD" report "###ERROR###: Value was not kept after Vld going low 2" severity error;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
