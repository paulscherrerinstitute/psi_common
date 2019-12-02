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

entity psi_common_delay_cfg_tb is
  generic(freq_clk_g      : integer  := 100E6; --clock frequency in Hz 
          Width_g         : positive := 16; --data width in bits
          Resource_g      : string   := "AUTO"; --resource ram
          BramThreshold_g : positive := 64; -- threshold to use BRAM
          MaxDelay_g      : positive := 100; -- max delay for the block
          Delay_g         : positive := 10; -- initial delay     
          RstState_g      : boolean  := True; -- reset stat output 0 or 1
          RamBehavior_g   : string   := "RBW" --RAM behavior 
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
  -- *** TB Control ***
  signal tb_run_s   : boolean                                             := true;

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
    generic map(Width_g         => Width_g,
                Resource_g      => Resource_g,
                BramThreshold_g => BramThreshold_g,
                MaxDelay_g      => MaxDelay_g,
                RStPol_g        => '1',
                RstState_g      => RstState_g,
                RamBehavior_g   => RamBehavior_g)
    port map(clk_i => clk_sti,
             rst_i => rst_sti,
             dat_i => dat_sti,
             str_i => str_sti,
             del_i => del_sti,
             dat_o => dat_obs
            );

  --*** stim process ***
  proc_stim : process
  begin
    ----------------------------------------------------------------------------
    print(" *************************************************  ");
    print(" **          Paul Scherrer Institut             **  ");
    print(" **        psi_common_delay2_tb TestBench       **  ");

    if MaxDelay_g > BramThreshold_g then
      print(" **                Block RAM                    **  ");
    else
      print(" **               Shift Resgiter                **  ");
    end if;
    print(" *************************************************  ");
    ----------------------------------------------------------------------------
    wait for period_c;

    -- *** Vld high constantly ***
    print(">> Vld high constantly & initial delay");
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait until rising_edge(clk_sti);
    str_sti <= '1';
    for i in 0 to Delay_g + 30 loop
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i < Delay_g + 1 then           --
        assert unsigned(dat_obs) = 0 report "###ERROR###: Out data wrong, expected " & to_string(0) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      else
        -- output is latched on the  next rising edge, therefore shift by one
        assert unsigned(dat_obs) = i - 1 - Delay_g report "###ERROR###: Out data wrong, expected " & to_string(i-1-Delay_g) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      end if;
      wait until rising_edge(clk_sti);
    end loop;
    dat_sti <= (others => '0');

    --*** Vld high constantaly with a delay change ***
    print(">> Vld high constantly & delay change on the fly");
    wait for MaxDelay_g * period_c;
    del_sti <= to_uslv(15, del_sti'length);
    str_sti <= '0';
    wait for period_c;
    wait until rising_edge(clk_sti);

    str_sti <= '1';
    for i in 0 to from_uslv(del_sti) + 30 loop
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i < 15 + 1 then                --
        assert unsigned(dat_obs) = 0 report "###ERROR###: Out data wrong, expected " & to_string(0) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      else
        -- output is latched on the  next rising edge, therefore shift by one
        assert unsigned(dat_obs) = i - 1 - from_uslv(del_sti) report "###ERROR###: Out data wrong, expected " & to_string(i-1-from_uslv(del_sti)) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      end if;
      wait until rising_edge(clk_sti);
    end loop;

    --re init
    wait for from_uslv(del_sti) * period_c;
    del_sti <= to_uslv(20, del_sti'length);
    str_sti <= '0';
    wait for period_c;
    wait until rising_edge(clk_sti);

    -- *** Vld toggling ***
    print(">> Vld toggling and a new change of delay on the fly");
    rst_sti <= '1';
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait until rising_edge(clk_sti);
    for i in 0 to from_uslv(del_sti) + 30 loop
      str_sti <= '1';
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i < from_uslv(del_sti) then
        assert unsigned(dat_obs) = 0 report "###ERROR###: Out data wrong, expected " & to_string(0) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      else
        assert unsigned(dat_obs) = i - from_uslv(del_sti) report "###ERROR###: Out data wrong, expected " & to_string(i-from_uslv(del_sti)) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      end if;
      wait until rising_edge(clk_sti);
      str_sti <= '0';
      wait until rising_edge(clk_sti);
      wait until rising_edge(clk_sti);
      wait until rising_edge(clk_sti);
    end loop;
    str_sti <= '0';

    --re init
    wait for from_uslv(del_sti) * period_c;
    del_sti <= to_uslv(MaxDelay_g, del_sti'length);
    str_sti <= '0';
    wait for period_c;
    wait until rising_edge(clk_sti);

    -- *** Vld toggling with max delay ***
    print(">> Vld toggling and a new change of delay on the fly with max delay value");
    rst_sti <= '1';
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait until rising_edge(clk_sti);
    for i in 0 to from_uslv(del_sti) + 30 loop
      str_sti <= '1';
      dat_sti <= std_logic_vector(to_unsigned(i, Width_g));
      if i < from_uslv(del_sti) then
        assert unsigned(dat_obs) = 0 report "###ERROR###: Out data wrong, expected " & to_string(0) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      else
        assert unsigned(dat_obs) = i - from_uslv(del_sti) report "###ERROR###: Out data wrong, expected " & to_string(i-from_uslv(del_sti)) & ", got " & to_string(from_uslv(dat_obs)) severity error;
      end if;
      wait until rising_edge(clk_sti);
      str_sti <= '0';
      wait until rising_edge(clk_sti);
      wait until rising_edge(clk_sti);
      wait until rising_edge(clk_sti);
    end loop;
    str_sti <= '0';

    -- end of process !DO NOT EDIT!
    tb_run_s <= false;
    wait;
  end process;

end architecture;
