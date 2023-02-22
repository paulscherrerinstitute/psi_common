------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
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

use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_compare_pkg.all;

entity psi_common_find_min_max_tb is
  generic(length_g  : natural := 16;
          signed_g  : boolean := true;
          mode_g    : string  := "MAX";
          display_g : boolean := true);
end entity;

architecture tb of psi_common_find_min_max_tb is
  --internals
  constant period_c : time                                    := (1 sec) / 100.0E6;
  signal clk_sti    : std_logic                               := '0';
  signal rst_sti    : std_logic                               := '0';
  signal tb_run_s   : boolean                                 := true;
  signal raz_sti    : std_logic                               := '0';
  signal data_sti   : std_logic_vector(length_g - 1 downto 0) := (others => '0');
  signal str_obs    : std_logic;
  signal data_obs   : std_logic_vector(length_g - 1 downto 0);
  signal run_dat_obs : std_logic_vector(length_g - 1 downto 0);
  signal run_str_obs : std_logic;

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
  inst_dut : entity work.psi_common_find_min_max
    generic map(rst_pol_g => '1',
                length_g  => length_g,
                signed_g  => signed_g,
                mode_g    => mode_g)
    port map(clk_i     => clk_sti,
             rst_i     => rst_sti,
             str_i     => '1',
             raz_i     => raz_sti,
             dat_i    => data_sti,
             str_o     => str_obs,
             dat_o    => data_obs,
             run_dat_o => run_dat_obs,
             run_str_o => run_str_obs
            );

  --*** stim process ***
  proc_stim : process
    variable seed1_v : positive                                := 1;
    variable seed2_v : positive                                := 2;
    variable rand_v  : real                                    := 0.0;
    variable val_v   : std_logic_Vector(length_g - 1 downto 0) := (others => '0');
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **           Paul Scherrer Institut            **  ");
    print(" **       psi_common_compare_tb TestBench       **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    raz_sti  <= '0';
    data_sti <= (others => '0');
    wait for 10 * period_c;
    for i in 0 to 100 loop
      uniform(seed1_v, seed2_v, rand_v);
      if signed_g then
        data_sti <= to_sslv(integer(rand_v * 2.0**length_g - 1.0), length_g);
        if mode_g = "MIN" then
          if signed(val_v) > signed(data_sti) then
            val_v := data_sti;
          end if;
        else
          if signed(val_v) < signed(data_sti) then
            val_v := data_sti;
          end if;
        end if;
        if display_g then
          print(to_string(from_sslv(val_v)));
        end if;
      else
        data_sti <= to_uslv(integer(rand_v * 2.0**length_g - 1.0), length_g);
        if mode_g = "MIN" then
          if unsigned(val_v) > unsigned(data_sti) then
            val_v := data_sti;
          end if;
        else
          if unsigned(val_v) < unsigned(data_sti) then
            val_v := data_sti;
          end if;
        end if;
        if display_g then
          print(to_string(from_uslv(val_v)));
        end if;
      end if;
      wait for period_c;
    end loop;

    wait until rising_edge(clk_sti);
    raz_sti <= '1';
    wait until str_obs = '1';
    if signed_g then
      IntCompare(from_sslv(val_v), from_sslv(data_obs), "output data is not as expected");
    else
      IntCompare(from_uslv(val_v), from_uslv(data_obs), "otuput data is not as expected");
    end if;

    tb_run_s <= false;
    wait;
  end process;

end architecture;
