--=================================================================
-- Paul Scherrer Institut <PSI> Villigen, Schweiz
-- Copyright ©, 2024, Benoit STEF, all rights reserved 
--=================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;


use work.psi_tb_txt_util.all;
use work.psi_tb_activity_pkg.all;

entity psi_common_pulse_cc_tb is
  generic(a_freq_clk_g    : integer   := 1000E6;
          b_freq_clk_g    : integer   := 500E6;
          num_pulses_g    : positive  := 1;
          a_rst_pol_g     : std_logic := '1';
          b_rst_pol_g     : std_logic := '0';
          a_rst_before_g  : boolean   := true
  );
end entity;

architecture tb of psi_common_pulse_cc_tb is

constant a_period_c : time      := (1 sec)/a_freq_clk_g;
constant b_period_c : time      := (1 sec)/b_freq_clk_g;
signal tb_run       : boolean   := true;
signal a_clk_sti    : std_logic :='0';
signal a_rst_sti    : std_logic := a_rst_pol_g;
signal a_rst_obs    : std_logic;
signal a_dat_sti    : std_logic_vector(num_pulses_g - 1 downto 0):=(others=>'0');
signal b_clk_sti    : std_logic :='0';
signal b_rst_sti    : std_logic := b_rst_pol_g;
signal b_rst_obs    : std_logic;
signal b_dat_obs    : std_logic_vector(num_pulses_g - 1 downto 0);

begin
  --===========================================================
  --*** Reset generation ***
  proc_a_rst : process
  begin
    if a_rst_before_g then
      wait for 3 * a_period_c;
    else
      wait for 30 * a_period_c;
    end if;
    wait until rising_edge(a_clk_sti);
    wait until rising_edge(a_clk_sti);
    a_rst_sti <= not a_rst_pol_g;
    wait;
  end process;
  
  proc_b_rst : process
  begin
    wait for 10 * b_period_c;
    wait until rising_edge(b_clk_sti);
    wait until rising_edge(b_clk_sti);
    b_rst_sti <= not b_rst_pol_g;
    wait;
  end process;
  --===========================================================
  --*** clock process ***
  proc_a_clk : process
    variable tStop_v       : time;
  begin
    while tb_run or (now < tStop_v + 1 us) loop
      if tb_run then
        tStop_v := now;
      end if;
      wait for 0.5 * a_period_c;
      a_clk_sti <= not a_clk_sti;
      wait for 0.5 * a_period_c;
      a_clk_sti <= not a_clk_sti;
    end loop;
    wait;
  end process;
  
  --*** clock process ***
  proc_b_clk : process
    variable tStop_v       : time;
  begin
    while tb_run or (now < tStop_v + 1 us) loop
      if tb_run then
        tStop_v := now;
      end if;
      wait for 0.5 * b_period_c;
      b_clk_sti <= not b_clk_sti;
      wait for 0.5 * b_period_c;
      b_clk_sti <= not b_clk_sti;
    end loop;
    wait;
  end process;
  
  --===========================================================
  --*** DUT***
  inst_dut : entity work.psi_common_pulse_cc
    generic map(num_pulses_g  => 1,
                a_rst_pol_g   => a_rst_pol_g,
                b_rst_pol_g   => b_rst_pol_g)
    port map(   a_clk_i       => a_clk_sti,
                a_rst_i       => a_rst_sti,
                a_rst_o       => a_rst_obs,
                a_dat_i       => a_dat_sti,
                b_clk_i       => b_clk_sti,
                b_rst_i       => b_rst_sti,
                b_rst_o       => b_rst_obs,
                b_dat_o       => b_dat_obs);
  
  --===========================================================
  --*** stim process ***
  proc_stim : process
    variable lout_v : line;
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **          Paul Scherrer Institut             **  ");
    print(" **      psi_common_pulse_cc_tb TestBench       **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
   
    --if a_rst_pol_g and b_rst_pol_g then
      wait until b_rst_obs=not b_rst_pol_g and  a_rst_obs=not a_rst_pol_g;
    --end if;
    print(" >>  reset released at: " &  to_string(now));
    PulseSig(a_dat_sti(0), a_clk_sti);
    WaitForValueStdl(b_dat_obs(0), '1', 4*(1 sec )/(b_freq_clk_g), "pulse didn't go thru", "###ERROR###: ");
    wait for 20*a_period_c;
    tb_run <= false;
    wait;
  end process;
  
end architecture;
