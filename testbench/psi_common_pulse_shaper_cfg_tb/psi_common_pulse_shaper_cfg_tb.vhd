------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_pulse_shaper_cfg_tb is
  generic(freq_clk_g    : integer  := 100E6; -- clock frequency in Hz
          HoldIn_g      : boolean  := false; -- Hold in enable (if pulse stays high)
          hold_off_ena_g  : boolean  := true; -- Hold off enable - ignore new pulse for a number of defined clock cycles
          max_duration_g : positive := 24; -- Hold off parameter in clock cycle
          HoldOff_g     : natural  := 20); -- Hold off paramater in clock cycle
end entity;

architecture tb of psi_common_pulse_shaper_cfg_tb is

  constant nbit_c     : integer                                                                     := log2ceil(max_duration_g);
  constant period_c   : time                                                                        := (1 sec) / real(freq_clk_g);
  --*** Stimuli ***
  signal clk_sti      : std_logic                                                                   := '0';
  signal rst_sti      : std_logic                                                                   := '1';
  signal width_sti    : std_logic_vector(nbit_c - 1 downto 0)                                       := to_uslv(0, nbit_c);
  signal dat_sti      : std_logic                                                                   := '0';
  signal dat_obs      : std_logic;
  --*** TB control ***
  signal tb_run_s     : boolean                                                                     := true;
  signal hold_off_sti : std_logic_vector(choose(hold_off_ena_g, log2ceil(HoldOff_g), 1) - 1 downto 0) := (others => '0');

begin

  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  --*** clock process ***
  proc_clk : process
    variable tStop_v : time;
  begin
    while tb_run_s or (now < tStop_v + 1 us) loop
      if tb_run_s then
        tStop_v := now;
      end if;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  --*** DUT***
  inst_dut : entity work.psi_common_pulse_shaper_cfg
    generic map(HoldIn_g      => HoldIn_g,
                hold_off_ena_g  => hold_off_ena_g,
                max_hold_off_g  => HoldOff_g,
                max_duration_g => max_duration_g,
                rst_pol_g      => '1')
    port map(clk_i   => clk_sti,
             rst_i   => rst_sti,
             width_i => width_sti,
             hold_i  => hold_off_sti,
             dat_i   => dat_sti,
             dat_o   => dat_obs);

  --*** stim process ***
  proc_stim : process
    variable ExpectedInt_v : integer;
  begin
    ------------------------------------------------------------------
    print("******************************************************  ");
    print("**              Paul Scherrer Institut              **  ");
    print("**       psi_common_pulse_shaper2_tb TestBench      **  ");
    print("******************************************************  ");
    ------------------------------------------------------------------
    -- start of process !DO NOT EDIT
    wait until rst_sti = '0';
    
    ------------------------------------------------------------------
    -- *** Test if parameters are stuck to 0 ***
    print("> Test if pulse width & hold off # set to 0");
    wait until falling_edge(clk_sti);
    dat_sti <= '1';
    StdlCompare(0, dat_obs, "Too early");
    wait until falling_edge(clk_sti);
    dat_sti <= '0';
    
    StdlCompare(0, dat_obs, "Did not stay low");
    for i in 0 to 10 loop
      wait until falling_edge(clk_sti);
      StdlCompare(0, dat_obs, "Did not stay low");
    end loop;
    wait for 200 ns;
    
   if hold_off_ena_g then
      hold_off_sti <= to_uslv(HoldOff_g, hold_off_sti'length);
    else
      hold_off_sti <= (others => '0');
    end if;    
    width_sti <= to_uslv(3,width_sti'length);
    ------------------------------------------------------------------
    -- *** Test if pulse gets enlonged ***
    print("> Test if pulse gets enlonged");
    wait until falling_edge(clk_sti);
    dat_sti <= '1';
    StdlCompare(0, dat_obs, "Too early");
    wait until falling_edge(clk_sti);
    dat_sti <= '0';

    for i in 0 to from_uslv(width_sti) - 1 loop
      StdlCompare(1, dat_obs, "Not asserted " & integer'image(i + 1));
      wait until falling_edge(clk_sti);
    end loop;

    wait until falling_edge(clk_sti);
    StdlCompare(0, dat_obs, "Not deasserted");
    for i in 0 to 50 loop
      wait until falling_edge(clk_sti);
      StdlCompare(0, dat_obs, "Did not stay low");
    end loop;
    wait for 200 ns;

    ------------------------------------------------------------------
    -- *** Test if pulse gets shortened ***
    print("> Test if pulse gets shortened");
    width_sti <= to_uslv(10, nbit_c);
    wait until falling_edge(clk_sti);
    dat_sti   <= '1';
    StdlCompare(0, dat_obs, "Too early");
    wait until falling_edge(clk_sti);
    for i in 0 to from_uslv(width_sti) - 1 loop
      StdlCompare(1, dat_obs, "Not asserted " & integer'image(i + 1));
      wait until falling_edge(clk_sti);
    end loop;
    -- expected output depends on HoldIn_g
    if HoldIn_g then
      ExpectedInt_v := 1;
    else
      ExpectedInt_v := 0;
    end if;
    -- Test 
    StdlCompare(ExpectedInt_v, dat_obs, "Not deasserted");
    for i in 0 to 50 loop
      wait until falling_edge(clk_sti);
      StdlCompare(ExpectedInt_v, dat_obs, "Did not stay low");
    end loop;
    dat_sti   <= '0';
    wait for 200 ns;
    StdlCompare(0, dat_obs, "Too early");

    if hold_off_ena_g then
      ------------------------------------------------------------------
      -- *** Test holdoff with large deviation ***
      print("> Test holdoff with large deviation");
      width_sti <= to_uslv(3, nbit_c);
      wait until falling_edge(clk_sti);

      for pair in 0 to 2 loop
        for pulse in 1 downto 0 loop    -- first pulse is detected, second not
          wait until falling_edge(clk_sti);
          dat_sti <= '1';
          StdlCompare(0, dat_obs, "Too early");
          wait until falling_edge(clk_sti);

          dat_sti <= '0';
          for i in 0 to from_uslv(width_sti) - 1 loop
            StdlCompare(pulse, dat_obs, "Assertion test " & integer'image(i + 1));
            wait until falling_edge(clk_sti);
          end loop;

          StdlCompare(0, dat_obs, "Not deasserted");
          wait until falling_edge(clk_sti);
          StdlCompare(0, dat_obs, "Not deasserted");

          for i in 0 to 10 loop
            wait until falling_edge(clk_sti);
            StdlCompare(0, dat_obs, "Did not stay low 2");
          end loop;

        end loop;
      end loop;
      wait for 200 ns;

      ------------------------------------------------------------------
      -- *** Test holdoff (one cycle too short) ***
      print("> Test holdoff (one cycle too short)");
      wait until falling_edge(clk_sti);
      dat_sti <= '1';
      for i in 0 to HoldOff_g - 1 loop
        wait until falling_edge(clk_sti);
        dat_sti <= '0';
      end loop;
      dat_sti <= '1';
      wait until falling_edge(clk_sti);
      dat_sti <= '0';
      StdlCompare(0, dat_obs, "Wrongly detected pulse in hold-off time");
      wait for 200 ns;

      ------------------------------------------------------------------
      -- *** Test holdoff (exactly OK) ***
      print("> Test holdoff (exactly OK)");
      wait until falling_edge(clk_sti);
      dat_sti <= '1';
      for i in 0 to HoldOff_g loop
        wait until falling_edge(clk_sti);
        dat_sti <= '0';
      end loop;
      dat_sti <= '1';
      wait until falling_edge(clk_sti);
      dat_sti <= '0';
      StdlCompare(1, dat_obs, "Did not detect pulse directly after holdoff time");
    end if;

    wait for period_c;
    tb_run_s <= false;
    wait;
  end process;

end architecture;
