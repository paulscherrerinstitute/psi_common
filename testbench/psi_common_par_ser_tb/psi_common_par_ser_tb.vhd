------------------------------------------------------------------------------
-- Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_tb_activity_pkg.all;
use work.psi_common_math_pkg.all;

entity psi_common_par_ser_tb is
  generic(length_g : natural := 32;
          msb_g    : boolean := false;
          ratio_g : natural  := 5);
end entity;

architecture tb of psi_common_par_ser_tb is

  constant period_c   : time                                    := (1 sec) / 100.0e6;
  signal clk_sti      : std_logic                               := '0';
  signal rst_sti      : std_logic                               := '1';
  signal tb_run_s     : boolean                                 := true;
  signal dat_sti      : std_logic_vector(length_g - 1 downto 0) := (others => '0');
  signal vld_sti      : std_logic                               := '0';
  signal dat_obs      : std_logic;
  signal err_obs      : std_logic;
  signal frm_obs      : std_logic;
  signal vld_obs      : std_logic;
  -- helpers
  signal ld_obs       : std_logic;
  -- signal out from DUT 2
  signal dat_dut2_obs : std_logic_vector(length_g - 1 downto 0);
  signal err_dut2_obs : std_logic;
  signal vld_dut2_obs : std_logic;
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

  --*** DUT SERIALIZER ***
  inst_dut : entity work.psi_common_par_ser
    generic map(rst_pol_g => '1',
                msb_g     => msb_g,
                ratio_g   => ratio_g,
                length_g  => length_g)
    port map(clk_i => clk_sti,
             rst_i => rst_sti,
             dat_i => dat_sti,
             vld_i => vld_sti,
             dat_o => dat_obs,
             err_o => err_obs,
             frm_o => frm_obs,
             ld_o  => ld_obs,
             vld_o => vld_obs);

  --*** DUT 2 DESERIALIZER ***
  inst_dut2 : entity work.psi_common_ser_par
    generic map(rst_pol_g => '1',
                length_g  => length_g,
                msb_g     => msb_g)
    port map(clk_i => clk_sti,
             rst_i => rst_sti,
             dat_i => dat_obs,
             ld_i  => ld_obs,
             vld_i => vld_obs,
             dat_o => dat_dut2_obs,
             err_o => err_dut2_obs,
             vld_o => vld_dut2_obs);

  --*** check process ***
  proc_check : process(clk_sti)
    variable i : integer := 0;
  begin
    if rising_edge(clk_sti) then
     if vld_dut2_obs = '1' then
       i:=i+1;
       assert dat_dut2_obs = to_uslv(i-1, length_g)
       report "###ERROR###: deserializer received : " & to_string(from_uslv(dat_dut2_obs)) & " expected : " & to_string(i-1)
       severity error;
     end if;
    end if;
  end process;
  
  --*** stim process ***
  proc_stim : process
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **       Paul Scherrer Institut                **  ");
    print(" **    psi_common_par_ser_tb TestBench          **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    wait for 15 * period_c;
    --*** stim at full speed with ratio > 1 ***
    for i in 0 to 16 loop
      dat_sti <= to_uslv(i, dat_sti'length);
      vld_sti <= '1';
      wait for period_c;
      vld_sti <= '0';
      if ratio_g > 1 then
        for j in 0 to length_g loop
          if j = length_g then
            exit;
          else
            print(" INFO : " & to_string(i) & " " & to_string(j));
            wait until vld_obs = '1';
          end if;
        end loop;
      else
        wait until frm_obs = '1';
      end if;
      --*** increase delay between input
      if i > 8 then
        wait until rising_edge(clk_sti);
        wait until rising_edge(clk_sti);
        wait until rising_edge(clk_sti);
      end if;
    end loop;
    --
    tb_run_s <= false;
    wait;
  end process;

end architecture;
