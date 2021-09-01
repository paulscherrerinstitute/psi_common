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
use work.psi_tb_compare_pkg.all;
use work.psi_common_math_pkg.all;

entity psi_common_pulse_generator_ctrl_static_tb is
  generic(length_g   : integer := 16;
          freq_clk_g : integer := 100E6; --in Hz
          str_freq_g : integer := 10E6;  --in Hz
          step_dw_g  : integer := 129;
          step_up_g  : integer := 738;
          step_fll_g : integer := 12302;
          step_flh_g : integer := 8789
         );
end entity;

architecture tb of psi_common_pulse_generator_ctrl_static_tb is

  constant period_c : time      := (1 sec) / freq_clk_g;
  signal clk_sti    : std_logic := '0';
  signal rst_sti    : std_logic := '1';
  signal tb_run     : boolean   := true;
  signal trig_sti   : std_logic;
  signal stop_sti   : std_logic;
  signal dat_obs    : std_logic_vector(length_g - 1 downto 0);
  signal str_obs    : std_logic;  
  signal busy_obs : std_logic;
  -- helpers
  signal status_pulse_s     : std_logic_Vector(1 downto 0);
  signal status_pulse_dff_s : std_logic_vector(1 downto 0);

begin

  assert is_int_ratio(freq_clk_g, str_freq_g) report "[WARNING]: the ratio between clock and strobe isn't integer " severity warning;

  --*** External name declaration ***
  --externalname_elaboration_blk : block
  --begin
  --  status_pulse_s <= <<signal .psi_common_pulse_generator_ctrl_static_tb.inst_dut.sts_s : std_logic_vector(1 downto 0)  >>;
  --end block;

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

  --*** DUT***
  inst_dut : entity work.psi_common_pulse_generator_ctrl_static
    generic map(
      rst_pol_g     => '1',
      length_g      => length_g,
      clk_freq_g    => real(freq_clk_g),
      str_freq_g    => real(str_freq_g),
      nb_step_up_g  => step_up_g,
      nb_step_dw_g  => step_dw_g,
      nb_step_flh_g => step_flh_g,
      nb_step_fll_g => step_fll_g
    )
    port map(
      clk_i  => clk_sti,
      rst_i  => rst_sti,
      trig_i => trig_sti,
      stop_i => stop_sti,
      busy_o => busy_obs,
      dat_o  => dat_obs,
      str_o  => str_obs,
      dbg_o  => status_pulse_s
    );


  process(clk_sti)    
    variable count_up_v : integer := 0;
    variable count_dw_v  : integer := 0;
    variable count_fll_v : integer := 0;
    variable count_flh_v : integer := 0;
    variable up_v        : boolean := true;
  begin
    if rising_edge(clk_sti) then
    
     status_pulse_dff_s <= status_pulse_s;
     
     if status_pulse_dff_s ="01" and status_pulse_s ="11" then
       up_v := true;
     elsif status_pulse_dff_s = "10" and status_pulse_s = "11" then
       up_v := false;
     end if;
     
     if str_obs = '1' and status_pulse_s = "01" then
       count_up_v := count_up_v+1;
       count_dw_v := 0;
     end if;
     
     if str_obs = '1' and status_pulse_s = "11" and up_v then
       count_flh_v := count_flh_v+1;
       count_fll_v := 0;
     end if;
     
      if str_obs = '1' and status_pulse_s = "11" and not up_v and busy_obs ='1' then
       count_fll_v := count_fll_v+1;
       count_flh_v := 0;
     end if;
     
     if str_obs = '1' and status_pulse_s = "10" then
       count_dw_v := count_dw_v+1;
       count_up_v := 0;
     end if;
     
     if status_pulse_dff_s = "01" and status_pulse_s = "11" then
       if is_int_ratio(2**length_g - 1, step_up_g) then        
         IntCompare(step_up_g, count_up_v, "Calculated time ramp up is WRONG",0, "[ERROR]: ");
       else
         IntCompare(step_up_g, count_up_v, "Calculated time ramp up is WRONG", 1, "[ERROR]: ");
       end if;
     end if;
     
     if status_pulse_dff_s = "10" and status_pulse_s = "11" then
       if is_int_ratio(2**length_g - 1, step_dw_g) then        
         IntCompare(step_dw_g, count_dw_v, "Calculated time ramp dw is WRONG",0, "[ERROR]: ");
       else
         IntCompare(step_dw_g, count_dw_v, "Calculated time ramp dw is WRONG", 1, "[ERROR]: ");
       end if;
    end if;
    
    if status_pulse_dff_s = "11" and status_pulse_s = "10"  then
       IntCompare(step_flh_g, count_flh_v, "Calculated time flat top dw is WRONG",0, "[ERROR]: ");
    end if;
    
    if status_pulse_dff_s = "11" and status_pulse_s = "01" then
       IntCompare(step_fll_g, count_fll_v, "Calculated time flat dw dw is WRONG",0, "[ERROR]: ");
    end if;
    
     if status_pulse_s = "00" then
       count_up_v := 0;
       count_dw_v := 0;
       count_flh_v:= 0;
       count_fll_v:= count_fll_v;
     end if;
    
    end if;
  end procesS;

  --*** stim process ***
  proc_stim : process
  begin
    -------------------------------------------------------------------
    print(" *********************************************************");
    print(" **            Paul Scherrer Institut                   **");
    print(" ** psi_common_pulse_generator_ctrl_static_tb TestBench **");
    print(" *********************************************************");
    -------------------------------------------------------------------
    print("[INFO]: step ramp up set   : " & to_string(step_up_g));
    print("[INFO]: step flat top set  : " & to_string(step_flh_g));
    print("[INFO]: step ramp dw set   : " & to_string(step_dw_g));
    print("[INFO]: step flat zero set : " & to_string(step_fll_g));
    print(" *********************************************************");
    trig_sti     <= '0';
    stop_sti     <= '0';
    wait until rst_sti = '0';
    WaitClockCycles(10, clk_sti);
    print("[INFO]: performs 2 pulses with trigger");
    ------------------------------------------------------------------
    -- RAMP UP
    trig_sti     <= '1';
    print(" *********************************************************");
    print("[INFO]: pulse RAMP UP  at " & to_string(now, ns));
    wait until status_pulse_s = "01";
    trig_sti     <= '0';
    ------------------------------------------------------------------
    -- FLAT TOP
    wait until status_pulse_s = "11";
    print("[INFO]: pulse flat top at " & to_string(now, ns));
    wait until dat_obs /= to_uslv(2**length_g - 1, length_g);
    ------------------------------------------------------------------
    -- RAMP DOWN
    print("[INFO]: pulse RAMP DOWN  at " & to_string(now, ns));
    wait until dat_obs = to_uslv(0, length_g) and str_obs = '1';  
    wait for (step_fll_g+100)*(1 sec /str_freq_g);
    
    
    ------------------------------------------------------------------
    -- RAMP UP
    trig_sti     <= '1';
    print(" *********************************************************");
    print("[INFO]: pulse RAMP UP  at " & to_string(now, ns));
    wait until status_pulse_s = "01";
    trig_sti     <= '0';
    -- FLAT TOP
    wait until status_pulse_s = "11";
    print("[INFO]: pulse flat top at " & to_string(now, ns));
    wait until dat_obs /= to_uslv(2**length_g - 1, length_g);
    -- RAMP DOWN
    print("[INFO]: pulse RAMP DOWN  at " & to_string(now, ns));
    wait until dat_obs = to_uslv(0, length_g) and str_obs = '1';
    wait for (step_fll_g+100)*(1 sec /str_freq_g);
    
    ------------------------------------------------------------------
    -- RAMP UP
    print(" *********************************************************");
    print("[INFO]: pulse repetition at " & to_string(now, ns));
    trig_sti     <= '1';
    wait for (step_fll_g*200)*(1 sec /str_freq_g);
    stop_sti <= '1';
    print("[INFO]: pulse ABORT at " & to_string(now, ns));
    wait until rising_edge(str_obs);
    wait until rising_edge(str_obs);
    assert dat_obs =to_uslv(0,length_g) report"[ERROR]: It didn't stop " severity error; 
   
    print(" *********************************************************");
    print("[INFO]: End of Sim at " & to_string(now, ns));
    tb_run   <= false;
    wait;
  end process;

end architecture;
