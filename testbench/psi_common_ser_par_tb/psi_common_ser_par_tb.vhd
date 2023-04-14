------------------------------------------------------------------------------
-- Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------
-- the TB is automatically checking if the deserializer run at full speed and 
-- with a lower input valid rate as shown here below (4 bits):
--    _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  
--CK   |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_
--        ___             ___               ___             ___
--VLDi___|   |___________|   |_____________|   |___________|   |_____________
--        ___
--LD_i___|   |_______________________________________________________________
--        _______________ _________________ _______________ _________________
--DATi___X_bit N___0_____X bit N+1____1____X bit N+2___1___X bit N+3___0_____
--                                                                ___
--VLDo___________________________________________________________|   |_______
--    ___________________________________________________________ ___________
--DATo___________________________________________________________X 0110______
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_activity_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;

entity psi_common_ser_par_tb is
  generic(length_g : natural := 8);
end entity;

architecture tb of psi_common_ser_par_tb is

  signal tb_run_s            : boolean                         := true;
  constant period_c          : time                            := (1 sec) / 100.0e6;
  signal clk_sti             : std_logic                       := '0';
  signal rst_sti             : std_logic                       := '1';
  signal dat_sti             : std_logic                       := '0';
  signal vld_sti             : std_logic                       := '0';
  signal ld_sti              : std_logic                       := '0';
  type stim_t is record
    dat : std_logic;
    vld : std_logic;
    ld  : std_logic;
  end record;
  constant stim_rst_c        : stim_t                          := ('0', '0', '0');
  signal tc0_s, tc1_s        : stim_t                          := stim_rst_c;
  --obs signals
  signal dat_obs             : std_logic_vector(length_g - 1 downto 0);
  signal vld_obs             : std_logic;
  -- helpers
  signal dat_s               : unsigned(length_g - 1 downto 0) := (others => '0');
  signal cnt_s               : integer                         := 0;
  signal mux_tc_s            : integer                         := 0;
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

  --*** DUT ***
  inst_dut : entity work.psi_common_ser_par
    generic map(rst_pol_g => '1',
                width_g  => length_g,
                msb_g     => false)
    port map(
      clk_i => clk_sti,
      rst_i => rst_sti,
      dat_i => dat_sti,
      ld_i  => ld_sti,
      vld_i => vld_sti,
      dat_o => dat_obs,
      err_o => open,
      vld_o => vld_obs);

  --*** strobe process ***
  proc_vld : process(clk_sti)
    variable cnt_v : integer := 0;
  begin
    if rising_edge(clk_sti) then
      if cnt_v = 9 then
        cnt_v := 0;
        tc1_s.vld <= '1';
      else
        cnt_v := cnt_v+1;
        tc1_s.vld <= '0';
      end if;
      
    end if;
  end process;

  proc_stimu : process(clk_sti)
  begin
    if rising_edge(clk_sti) then
      if cnt_s = length_g - 1 then
        cnt_s    <= 0;
        tc0_s.ld <= '1';
        dat_s    <= dat_s + to_unsigned(1, dat_s'length);
      else
        tc0_s.ld <= '0';
        cnt_s    <= cnt_s + 1;
      end if;
      tc0_s.vld <= '1';
    end if;
  end process;
  tc0_s.dat <= dat_s(cnt_s);

  vld_sti <= tc0_s.vld when mux_tc_s = 0 else tc1_s.vld;
  ld_sti  <= tc0_s.ld when mux_tc_s = 0 else tc1_s.ld;
  dat_sti <= tc0_s.dat when mux_tc_s = 0 else tc1_s.dat;

  --*** stim process ***
  proc_stim : process
    variable reg_in_v : unsigned(length_g - 1 downto 0) := (others => '0');
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **       Paul Scherrer Institut                **  ");
    print(" **   psi_common_ser_par_tb TestBench           **  ");
    print(" *************************************************  ");

    ------------------------------------------------------------
    print("TESTCASE 1: Max speed");
    for i in 0 to 10 loop
      wait until vld_obs = '1';
      assert unsigned(dat_obs) = to_unsigned(i+1, length_g)
      report "###ERROR###: Exp value is : " & to_string(i) & "received is: " & to_string(from_uslv(dat_obs))
      severity error;
    end loop;
    wait until vld_obs = '1';
    
    ------------------------------------------------------------
    print("TESTCASE 2: vld lower speed");
    mux_tc_s <= 1;
    for i in 0 to 10 loop
      wait until rising_edge(tc1_s.vld);
      tc1_s.ld  <= '1';
      tc1_s.dat <= reg_in_v(0);
      wait until rising_edge(clk_sti);
      tc1_s.ld  <= '0';
      for j in 1 to length_g - 1 loop
        wait until rising_edge(tc1_s.vld);
        tc1_s.dat <= reg_in_v(j);
      end loop;
      reg_in_v  := reg_in_v + 1;
      wait until vld_obs = '1';
      assert unsigned(dat_obs) = to_unsigned(i, length_g)
      report "###ERROR###: Exp value is : " & to_string(i) & "received is: " & to_string(dat_obs)
      severity error;
    end loop;
   ------------------------------------------------------------
    tb_run_s <= false;
    wait;
  end process;

end architecture;
