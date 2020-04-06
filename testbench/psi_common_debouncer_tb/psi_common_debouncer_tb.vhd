------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors:  Benoit Stef 
--  Purpose: TB for unint psi_common_debouncer.vhd
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

entity psi_common_debouncer_tb is
  generic(dbnc_per_g : real      := 20.0e-6; -- filter time in sec
          freq_clk_g : real      := 100.0e6; -- clock frequency in Hz
          rst_pol_g  : std_logic := '1'; -- polarity reset 
          len_g      : positive  := 10; -- vecto input length
          sync_g     : boolean   := true); -- add 2 DFF input sync
end entity;

architecture tb of psi_common_debouncer_tb is
  constant in_pol_c  : std_logic                            := '1'; -- active high or low
  constant out_pol_c : std_logic                            := '0'; -- active high or low
  --internal declarations
  constant period_c  : time                                 := (1 sec) / freq_clk_g;
  signal clk_sti     : std_logic                            := '1';
  signal rst_sti     : std_logic                            := '1';
  signal tb_run_s    : boolean                              := true;
  signal inp_sti     : std_logic_vector(len_g - 1 downto 0) := (others => not in_pol_c);
  signal out_obs     : std_logic_vector(len_g - 1 downto 0);

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
  inst_dut : entity work.psi_common_debouncer
    generic map(dbnc_per_g => dbnc_per_g,
                freq_clk_g => freq_clk_g,
                rst_pol_g  => rst_pol_g,
                len_g      => len_g,
                in_pol_g   => in_pol_c,
                out_pol_g  => out_pol_c,
                sync_g     => sync_g)
    port map(clk_i => clk_sti,
             rst_i => rst_sti,
             inp_i => inp_sti,
             out_o => out_obs);

  --*** stim process ***
  proc_stim : process
    constant test : std_logic_vector(len_g - 1 downto 0) := (others => (out_pol_c));
  begin
    ------------------------------------------------------------
    print(" *******************************************  ");
    print(" **       Paul Scherrer Institut          **  ");
    print(" **    psi_common_debouncer_tb TestBench  **  ");
    print(" *******************************************  ");
    ------------------------------------------------------------
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';

    for i in 0 to 3 loop
      inp_sti <= (others => not in_pol_c);
      wait for dbnc_per_g / 2.0 * sec;
      inp_sti <= not inp_sti;
      wait for dbnc_per_g / 2.0 * sec;
      StdlvCompareStdlv((not test), out_obs, "debounced output not preoperly filtered");
    end loop;

    wait for 5.0 * dbnc_per_g * sec;
    StdlvCompareStdlv(test, out_obs, "debounced didn't occur");

    for i in 0 to 3 loop
      inp_sti <= not inp_sti;
      wait for 2.0 * dbnc_per_g * sec;
      inp_sti <= not inp_sti;
      wait for 2.0 * dbnc_per_g * sec;
    end loop;
    inp_sti <= not inp_sti;

    tb_run_s <= false;

    wait;
  end process;

end architecture;

