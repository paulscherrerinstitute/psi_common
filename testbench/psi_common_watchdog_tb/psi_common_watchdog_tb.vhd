------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef 
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_compare_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;

entity psi_common_watchdog_tb is
  generic(freq_clk_g   : real     := 100.0E6; -- clock frequency
          freq_act_g   : real     := 10.0E5; -- event frequency
          length_g     : integer  := 15; -- length of data input
          thld_fault_g : positive := 10; -- threshold to rise an error
          thld_warn_g  : positive := 5); -- threshold to rise a warning
end entity;

architecture tb of psi_common_watchdog_tb is
  --internal declarations
  constant period_c : time      := (1 sec) / freq_clk_g;
  signal clk_sti    : std_logic := '0';
  signal rst_sti    : std_logic := '1';
  signal dat_sti    : std_logic_vector(length_g - 1 downto 0);
  signal warn_obs   : std_logic;
  signal miss_obs   : std_logic_vector(log2ceil(thld_fault_g) - 1 downto 0);
  signal fault_obs  : std_logic;
  signal tb_run_s   : boolean   := true;

begin

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
  inst_dut : entity work.psi_common_watchdog
    generic map(freq_clk_g   => freq_clk_g,
                freq_act_g   => freq_act_g,
                thld_fault_g => thld_fault_g,
                thld_warn_g  => thld_warn_g,
                length_g     => length_g,
                rst_pol_g    => '1')
    port map(clk_i   => clk_sti,
             rst_i   => rst_sti,
             dat_i   => dat_sti,
             warn_o  => warn_obs,
             miss_o  => miss_obs,
             fault_o => fault_obs);

  --*** stim process ***
  proc_stim : process
  begin
    ------------------------------------------------------------
    print(" *******************************************  ");
    print(" **       Paul Scherrer Institut          **  ");
    print(" **    psi_common_watchdog_tb TestBench   **  ");
    print(" *******************************************  ");
    ------------------------------------------------------------
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    dat_sti <= (others => '0');

    --*** check warning ***
    wait for thld_warn_g * integer(freq_clk_g / freq_act_g) * period_c;
    wait for 5 * period_c;
    StdlCompare(1, warn_obs, "warning didn't occur");
    StdlvCompareInt(thld_warn_g, miss_obs, "wrong missing counter value");

    --*** check error ***
    wait for thld_fault_g * integer(freq_clk_g / freq_act_g) * period_c;
    wait for 5 * period_c;
    StdlCompare(1, fault_obs, "fault didn't occur");

    --*** reset component ***
    wait for period_c;
    rst_sti <= '1';
    wait for period_c;
    rst_sti <= '0';
    
    for i in 0 to 10 loop
      dat_sti <= to_uslv(i, dat_sti'length);
      wait for (integer(freq_clk_g / freq_act_g)-2) * period_c;
    end loop;
    
    wait for thld_warn_g * integer(freq_clk_g / freq_act_g) * period_c;
    wait for 5 * period_c;
    StdlCompare(1, warn_obs, "warning didn't occur");
    StdlCompare(0, fault_obs, "fault occured");

    for i in 0 to 10 loop
      dat_sti <= to_uslv(i, dat_sti'length);
      wait for (integer(freq_clk_g / freq_act_g)-2) * period_c;
    end loop;
    
    wait for thld_warn_g * integer(freq_clk_g / freq_act_g) * period_c;
    wait for 5 * period_c;
    StdlCompare(1, fault_obs, "fault didn't occur");
    
    tb_run_s <= false;

    wait;
  end process;

end architecture;
