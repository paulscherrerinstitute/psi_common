------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
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
use work.psi_tb_activity_pkg.all;
use work.psi_common_math_pkg.all;

library modelsim_lib;
use modelsim_lib.util.all;

entity psi_common_pulse_generator_ctrl_static_tb is
  generic(length_g    : integer := 16;
          freq_clk_g  : real := 100.0E6;  --in Hz
          str_freq_g  : real :=  10.0E6;  --in Hz
          time_up_g   : real :=  10.0E-6; --in sec.
          time_dw_g   : real :=   5.0E-6; --in sec.
          time_flat_g : real := 300.0E-6  --in sec.
  );
end entity;

architecture tb of psi_common_pulse_generator_ctrl_static_tb is

constant period_c : time := (1 sec)/freq_clk_g;
signal clk_sti  : std_logic:='0';
signal rst_sti  : std_logic:='1';
signal tb_run   : boolean := true;
signal trig_sti : std_logic;
signal stop_sti : std_logic;
signal dat_obs  : std_logic_vector(length_g-1 downto 0);
signal str_obs  : std_logic;

-- helpers
signal status_pulse_s     : std_logic_Vector(1 downto 0);

begin
   --*** External name declaration ***
  externalname_elaboration_blk : block
  begin
    status_pulse_s  <= <<signal .psi_common_pulse_generator_ctrl_static_tb.inst_dut.sts_s : std_logic_vector(1 downto 0)  >>;
  end block;
  
  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 3*period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;
  
  --*** clock process ***
  proc_clk : process
    variable tStop_v       : time;
  begin
    while tb_run or (now < tStop_v + 1 us) loop
      if tb_run then
        tStop_v := now;
      end if;
      wait for 0.5*period_c;
      clk_sti <= not clk_sti;
      wait for 0.5*period_c;
      clk_sti <= not clk_sti;
    end loop;
    wait;
  end process;
  
  --*** DUT***
  inst_dut : entity work.psi_common_pulse_generator_ctrl_static
    generic map(
      rst_pol_g   => '1',
      length_g    => length_g,
      clk_freq_g  => freq_clk_g,
      str_freq_g  => str_freq_g,
      time_up_g   => time_up_g,
      time_dw_g   => time_dw_g,
      time_flat_g => time_flat_g
    )
    port map(
      clk_i  => clk_sti,
      rst_i  => rst_sti,
      trig_i => trig_sti,
      stop_i => stop_sti,
      dat_o  => dat_obs,
      str_o  => str_obs
    );
  
  --*** stim process ***
  proc_stim : process
    variable time_now_v   : time := 0.0 sec;
    variable time_start_v : time := 0.0 sec;
  begin
    -------------------------------------------------------------------
    print(" *********************************************************");
    print(" **            Paul Scherrer Institut                   **");
    print(" ** psi_common_pulse_generator_ctrl_static_tb TestBench **");
    print(" *********************************************************");
    -------------------------------------------------------------------
    print("[INFO]: time ramp up set  : " &to_string(time_up_g));
    print("[INFO]: time flat top set : " &to_string(time_flat_g));
    print("[INFO]: time ramp dw set  : " &to_string(time_dw_g));
    print(" *********************************************************");
    trig_sti <= '0';
    stop_sti <= '0';
    wait until rst_sti = '0';
    WaitClockCycles(10,clk_sti);
    print("[INFO]: performs 2 pulses with trigger");
    trig_sti <= '1';
    ------------------------------------------------------------------
    -- RAMP UP
    print(" *********************************************************");
    wait until dat_obs /= to_uslv(0,length_g);
    trig_sti <= '0';
    time_start_v := now;
    print("[INFO]: pulse ramp up at " & to_string(now,ns)); 
    wait until dat_obs = to_uslv(2**length_g-1,length_g);
    time_now_v := now;
    print("[INFO]: time calculated for ramp up is ***" & to_string(time_now_v-time_start_v,sec) & "***");
    -- ASSERT time duration on ramp up top
    assert (time_up_g*sec)-(time_now_v-time_start_v) = 0*sec 
    report "[ERROR]: Calculated time for ramp up top is not as set in Generic " & to_string(time_up_g*sec, ns)
    severity error;
    ------------------------------------------------------------------
    -- FLAT TOP
    time_start_v := now;    
    print(" *********************************************************");
    print("[INFO]: pulse flat top at " & to_string(now,ns)); 
    wait until dat_obs /= to_uslv(2**length_g-1,length_g);
    time_now_v := now;
    print("[INFO]: time calculated for flat top is ***" & to_string(time_now_v-time_start_v,sec)& "***");
    -- ASSERT time duration on flat top
    assert (time_flat_g*sec)-(time_now_v-time_start_v) = 0*sec 
    report "[ERROR]: Calculated time for flat top is not as set in Generic " & to_string(time_flat_g*sec, ns)
    severity error;
    ------------------------------------------------------------------
    -- RAMP DOWN
    print(" *********************************************************");
    time_start_v := now;
    print("[INFO]: pulse start ramp down at " & to_string(now,ns));
    wait until dat_obs = to_uslv(0,length_g) and str_obs ='1';
    WaitClockCycles(2,clk_sti);
    wait until str_obs = '1';
    time_now_v := now;
    print("[INFO]: time calculated for ramp down top is ***" & to_string(time_now_v-time_start_v,sec)& "***");
    -- ASSERT time duration ramp down
    assert (time_dw_g*sec)-(time_now_v-time_start_v) = 0*sec 
    report "[ERROR]: Calculated time for ramp down top is not as set in Generic " & to_string(time_dw_g*sec, ns)
    severity error;
    ------------------------------------------------------------------
    print(" *********************************************************");
    print("[INFO]: pulse flat bottom at " & to_string(now,ns));
    wait for 2.0*time_flat_g*sec;
    trig_sti <= '1';
    WaitClockCycles(10,clk_sti);
    trig_sti <= '0';
    wait until dat_obs = to_uslv(2**length_g-1,length_g);
    print("[INFO]: pulse flat top at " & to_string(now,ns)); 
    wait until dat_obs = to_uslv(0,length_g);
    print("[INFO]: pulse flat bottom at " & to_string(now,ns));
    wait for 2.0*time_flat_g*sec;
    
    ------------------------------------------------------------------
    print(" *********************************************************");
    print("[INFO]: Trigger let to 1");
    trig_sti <= '1';
    WaitClockCycles(10,clk_sti);
    wait until dat_obs = to_uslv(2**length_g-1,length_g);
    print("[INFO]: pulse flat top at " & to_string(now,ns)); 
    wait until dat_obs = to_uslv(0,length_g);
    print("[INFO]: pulse flat bottom at " & to_string(now,ns));
    wait until status_pulse_s = "10"; 
    wait until dat_obs = to_uslv(0,length_g);
    time_start_v := now;
    print(" *********************************************************");
    print("[INFO]: pulse flat bottom at " & to_string(now,ns)); 
    wait until dat_obs /= to_uslv(0,length_g);
    time_now_v := now;
    print("[INFO]: time calculated for flat bottom is ***" & to_string(time_now_v-time_start_v,sec)& "***");
    -- ASSERT time duration on flat top
    assert (time_flat_g*sec)-(time_now_v-time_start_v) = 0*sec 
    report "[ERROR]: Calculated time for flat bottom is not as set in Generic " & to_string(time_flat_g*sec, ns)
    severity error;
    
    ------------------------------------------------------------------
    wait until status_pulse_s = "11";
    stop_sti <= '1';
    wait until dat_obs = to_uslv(0,length_g);
    trig_sti <= '0';
    stop_sti <= '0';
    print("[INFO]: End of Sim at " & to_string(now,ns));
    tb_run <= false;
    wait;
  end process;
  


end architecture;
