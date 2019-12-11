------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoît Stef & Oliver Bruendler
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
use work.psi_tb_activity_pkg.all;

entity psi_common_delay_cfg_tb is
  generic(freq_clk_g    : integer  := 100E6; --clock frequency in Hz 
          Width_g       : positive := 16; --data width in bits
          MaxDelay_g    : positive := 100; -- max delay for the block
          Delay_g       : positive := 2; -- initial delay     
          RamBehavior_g : string   := "RBW" --RAM behavior 
         );
end entity;

architecture tb of psi_common_delay_cfg_tb is
  constant period_c : time                                                := (1 sec) / real(freq_clk_g);
  --*** stimuli ***
  signal clk_sti    : std_logic                                           := '0';
  signal rst_sti    : std_logic                                           := '1';
  signal dat_sti    : std_logic_vector(Width_g - 1 downto 0)              := (others => '0');
  signal str_sti    : std_logic                                           := '0';
  signal del_sti    : std_logic_vector(log2ceil(MaxDelay_g) - 1 downto 0) := to_uslv(Delay_g, log2ceil(MaxDelay_g));
  --*** observable signals ***
  signal dat_obs    : std_logic_vector((Width_g - 1) downto 0);
  --*** TB Control ***
  signal tb_run_s   : boolean                                             := true;
  --*** Procedure for constant delay check **
  procedure delay_cst_proc(signal delOut : out std_logic_vector;
                           signal strOut : out std_logic;
                           signal datOut : out std_logic_vector;
                           signal datIn  : in std_logic_vector;
                           signal clkIn  : in std_logic;
                           delayIn       : in integer) is
  begin
    delOut <= to_uslv(delayIn, del_sti'length);
    wait until rising_edge(clkIn);
    strOut <= '1';
    for i in 0 to delayIn + 30 loop
      datOut <= std_logic_vector(to_unsigned(i, datOut'length));
      if i < delayIn + 1 then           --
        StdlvCompareInt(0, datIn, "Out data wrong", false);
      else
        -- output is latched on the  next rising edge, therefore shift by one
        StdlvCompareInt(i - delayIn - 1, datIn, "Out data wrong", false);
      end if;
      wait until rising_edge(clkIn);
    end loop;
    datOut <= to_uslv(0, datOut'length);
    WaitClockCycles(3, clk_sti);
  end procedure;

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
  inst_dut : entity work.psi_common_delay_cfg
    generic map(Width_g       => Width_g,
                MaxDelay_g    => MaxDelay_g,
                RStPol_g      => '1',
                RamBehavior_g => RamBehavior_g,
                Hold_g        => True)-- DO NOT EDIT in this TESTBENCH
    port map(clk_i => clk_sti,
             rst_i => rst_sti,
             dat_i => dat_sti,
             str_i => str_sti,
             del_i => del_sti,
             dat_o => dat_obs);

  --*** stim process ***
  proc_stim : process
    variable hold_v       : std_logic_vector(dat_obs'range) := (others => '0');
    variable hold2_v      : std_logic_vector(dat_obs'range) := (others => '0');
    variable diff_v       : integer                         := 0;
    variable prev_value_v : integer                         := 0;
    variable prev_delay_v : integer                         := 0;
  begin
    -------------------------------------------------------------------
    print(" *************************************************  ");
    print(" **          Paul Scherrer Institut             **  ");
    print(" **        psi_common_delay2_tb TestBench       **  ");
    print(" **           HOLD MODE is checked here         **  ");
    print(" *************************************************  ");
    -------------------------------------------------------------------
    wait for period_c;

    -------------------------------------------------------------------
    -- *** Vld high constantly ***
    print(">> Strobe high constantly & initial delay");
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait until rising_edge(clk_sti);

    delay_cst_proc(del_sti, str_sti, dat_sti, dat_obs, clk_sti, Delay_g);

    -- *** Vld high constantly & delay = 1 ***
    print(">> Strobe high constantly & delay 1 ");
    delay_cst_proc(del_sti, str_sti, dat_sti, dat_obs, clk_sti, 1);

    -- *** Vld high constantly & delay = 2 ***
    print(">> Strobe high constantly & delay 2 ");
    delay_cst_proc(del_sti, str_sti, dat_sti, dat_obs, clk_sti, 2);

    -- *** Vld high constantly & delay = 3 ***
    print(">> Strobe high constantly & delay 3 ");
    delay_cst_proc(del_sti, str_sti, dat_sti, dat_obs, clk_sti, 3);

    -------------------------------------------------------------------
    --*** Vld high constantaly with a delay change ***
    print(">> Vld high constantly & delay change on the fly");
    wait for MaxDelay_g * period_c;
    del_sti <= to_uslv(33, del_sti'length);
    str_sti <= '0';
    wait for period_c;
    wait until rising_edge(clk_sti);

    str_sti <= '1';
    for i in 0 to from_uslv(del_sti) + 200 loop
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i = 75 then
        prev_delay_v := from_uslv(del_sti);
        del_sti      <= to_uslv(13, del_sti'length);
        print(">> change delay 33 -> 13");
      end if;

      if i < from_uslv(del_sti) + 1 then
        StdlvCompareInt(0, dat_obs, "Out data wrong", false);
      elsif i >= 75 and i <= 75 + 3 then
        StdlvCompareInt(i - 1 - prev_delay_v, dat_obs, "Out data wrong", false);
      else
        -- output is latched on the next rising edge, therefore shift by one
        StdlvCompareInt(i - 1 - from_uslv(del_sti), dat_obs, "Out data wrong", false);
      end if;
      wait until rising_edge(clk_sti);
    end loop;

    wait for from_uslv(del_sti) * period_c;

    -------------------------------------------------------------------
    --*** change delay from 15 to 10
    del_sti <= to_uslv(10, del_sti'length);
    str_sti <= '0';
    wait for period_c;
    wait until rising_edge(clk_sti);
    hold_v  := dat_obs;

    -- *** Vld toggling ***
    print(">> Vld toggling and a new change of delay on the fly");
    wait until rising_edge(clk_sti);

    for i in 0 to from_uslv(del_sti) + 30 loop
      str_sti <= '1';
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i < from_uslv(del_sti) then
        StdlvCompareStdlv(hold_v, dat_obs, "Out data wrong");
      else
        StdlvCompareInt(i - from_uslv(del_sti), dat_obs, " Out data wrong");
      end if;
      wait until rising_edge(clk_sti);
      str_sti <= '0';
      WaitClockCycles(3, clk_sti);
    end loop;
    prev_value_v := from_uslv(dat_sti);

    -------------------------------------------------------------------
    -- *** Vld toggling with max delay ***
    wait for from_uslv(del_sti) * period_c;
    diff_v       := MaxDelay_g - 1 - from_uslv(del_sti);
    prev_delay_v := from_uslv(del_sti);
    del_sti      <= to_uslv(MaxDelay_g - 1, del_sti'length);

    wait for period_c;
    wait until rising_edge(clk_sti);
    hold_v  := dat_obs;
    hold2_v := std_logic_vector(unsigned(dat_obs) + to_unsigned(2, hold_v'length));

    print(">> Vld toggling and a new change of delay on the fly with max delay value");
    wait until rising_edge(clk_sti);

    for i in 0 to from_uslv(del_sti) + 30 loop
      str_sti <= '1';
      dat_sti <= std_logic_vector(to_unsigned(i + 1 + prev_value_v, Width_g));
      --*** due to RAM latency of 2 clock cycle ***
      if i < 2 then
        StdlvCompareInt(from_uslv(hold_v) + i, dat_obs, "Out data wrong", false);
      elsif i = 110 then
        prev_delay_v := from_uslv(del_sti);
        del_sti      <= to_uslv(10, del_sti'length);
        print(">> change delay 100 -> 10");
      elsif i >= 110 and i < 110 + 3 then
        StdlvCompareInt(i + 1 + prev_value_v - (prev_delay_v), dat_obs, "Out data wrong", false);
      elsif i >= 113 then
        StdlvCompareInt(i + 1 + prev_value_v - from_uslv(del_sti), dat_obs, "Out data wrong", false);
      elsif i >= 2 and i < diff_v + 2 then
        StdlvCompareStdlv(hold2_v, dat_obs, "Out data wrong");
      else
        StdlvCompareInt(i + 1 + prev_value_v - diff_v - (prev_delay_v), dat_obs, "Out data wrong", false);
      end if;

      wait until rising_edge(clk_sti);
      str_sti <= '0';
      WaitClockCycles(3, clk_sti);
    end loop;
    ---
    str_sti <= '1';
    --re init
    dat_sti <= (others => '0');
    wait for from_uslv(del_sti) * period_c;
    WaitClockCycles(3, clk_sti);
    del_sti <= to_uslv(MaxDelay_g - 1, del_sti'length);
    str_sti <= '1';
    dat_sti <= to_uslv(100, dat_sti'length);
    wait for 2 * from_uslv(del_sti) * period_c;
    WaitClockCycles(3, clk_sti);

    -- end of process !DO NOT EDIT!
    tb_run_s <= false;
    wait;
  end process;

end architecture;
