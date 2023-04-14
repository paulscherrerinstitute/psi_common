------------------------------------------------------------------------------
--  Copyright (c) 2023 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;

entity psi_common_pwm_tb is
  generic(clk_freq_g : natural   := 125E6;
          str_freq_g : natural   := 100E3;
          min_freq_g : real      := 3.125E3;
          is_sync_g  : boolean   := True;
          rst_pol_g  : std_logic := '1');
end entity;

architecture tb of psi_common_pwm_tb is

  constant period_c       : time                                   := (1 sec) / clk_freq_g;
  signal clk_sti          : std_logic                              := '0';
  signal rst_sti          : std_logic                              := rst_pol_g;
  signal tb_run           : boolean                                := true;
  constant ratio_c        : natural                                := log2ceil(real(str_freq_g) / real(min_freq_g));
  constant max_c          : natural                                := integer(real(str_freq_g) / real(min_freq_g));
  signal trig_sti         : std_logic;
  signal rate_sti         : std_logic_vector(ratio_c - 1 downto 0) := to_uslv(1, ratio_c);
  signal pwm_sti          : std_logic_vector(ratio_c - 1 downto 0);
  signal dly_sti          : std_logic_vector(ratio_c - 1 downto 0);
  signal dat_obs          : std_logic;
  signal str_obs          : std_logic;
  signal dat_obs_dff_s    : std_logic;
  signal cpt_s, cpt_dly_s : integer;

begin
  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= not rst_pol_g;
    wait;
  end process;

  --*** clock process ***
  proc_clk : process
    variable tStop_v : time;
  begin
    while tb_run or (now < tStop_v + 1 us) loop
      if tb_run then
        tStop_v := now;
      end if;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
      wait for 0.5 * period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;

  --*** trigger generation
  inst_trig : entity work.psi_common_strobe_generator
    generic map(freq_clock_g  => real(clk_freq_g),
                freq_strobe_g => min_freq_g,
                rst_pol_g     => rst_pol_g)
    port map(clk_i  => clk_sti,
             rst_i  => rst_sti,
             sync_i => '0',
             vld_o  => trig_sti);

  --*** DUT***
  inst_dut : entity work.psi_common_pwm
    generic map(clk_freq_g => clk_freq_g,
                str_freq_g => str_freq_g,
                period_g => min_freq_g,
                is_sync_g  => is_sync_g,
                rst_pol_g  => rst_pol_g)
    port map   (clk_i      => clk_sti,
                rst_i      => rst_sti,
                trig_i     => trig_sti,
                rate_i     => rate_sti,
                pwm_i      => pwm_sti,
                dly_i      => dly_sti,
                dat_o      => dat_obs,
                vld_o      => str_obs);

  process(clk_sti)
  begin
    if rising_edge(clk_sti) then
      dat_obs_dff_s <= dat_obs;
      if trig_sti = '1' then
        cpt_s <= 0;
        else
        if dat_obs_dff_s = '1' and dat_obs = '0' then
          cpt_s <= cpt_s +1;
        end if;
      end if;
      if (dat_obs_dff_s = '0' and dat_obs = '1') or 
         (dat_obs = '1') or
         (trig_sti = '1') then
        cpt_dly_s <= 0;
      else
      if str_obs = '1' then
        cpt_dly_s <= cpt_dly_s + 1;
      end if;
    end if;
    end if;
  end process;
  --===========================================================
  --*** stim process ***
  proc_stim : process
    variable cpt_v : integer:= 0;
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **         Paul Scherrer Institut              **  ");
    print(" **      sls_llrf_pwm_tb TestBench              **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    wait for period_c;
    --*** primitive test
    print("### INFO : TEST 1 Pulse, no delay, DC:62.5%  ");
    rate_sti <= to_uslv(1,rate_sti'length);
    pwm_sti  <= to_uslv(20, pwm_sti'length);
    dly_sti  <= to_uslv(max_c-max_c,dly_sti'length);
    wait until falling_edge(trig_sti);
    for i in 0 to 3 loop
    wait until rising_edge(trig_sti);
    print(to_string(cpt_s));
    assert cpt_s = 1 report "###ERROR###: not right number of pulses, expected 1 got: " & to_string(cpt_s) severity error;
    end loop;
    --*** primitive test
    wait for 1 ms; 
    print("### INFO : TEST 2 Pulses, delay 50%, DC:12.5%  ");
    rate_sti <= to_uslv(2,rate_sti'length);
    pwm_sti  <= to_uslv(20, pwm_sti'length);
    dly_sti  <= to_uslv(max_c-max_c/2,dly_sti'length);
    wait until falling_edge(trig_sti);
    for i in 0 to 3 loop
    wait until rising_edge(trig_sti);
    print(to_string(cpt_s));
    assert cpt_s = 2 report "###ERROR###: not right number of pulses, expected 2 got: " & to_string(cpt_s) severity error;
    end loop;
    wait for 1 ms;
    --*** primitive test
    print("### INFO : TEST 2 Pulses, no delay, DC:87.5%  ");
    rate_sti <= to_uslv(2,rate_sti'length);
    pwm_sti  <= to_uslv(28, pwm_sti'length);
    dly_sti  <= to_uslv(max_c-max_c,dly_sti'length);
    wait until falling_edge(trig_sti);
    wait until falling_edge(trig_sti);
    for i in 0 to 3 loop
    wait until rising_edge(trig_sti);
    print(to_string(cpt_s));
    assert cpt_s = 2 report "###ERROR###: not right number of pulses, expected 2 got: " & to_string(cpt_s) severity error;
    end loop;
    wait for 1 ms;
    wait;
    tb_run <= false;
    wait;
  end process;

end architecture;
