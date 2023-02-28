------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This TB shows a a non conventional way to use the pulse generator within
-- the PSI COMMON, the target level is always moidified and it doesn't produce 
-- pulse but allow the user to ramp up/down to a desired value, datagram can
-- be observed here below  
--                                                   ________
--                 _______                          /  
--                /       \       _____            /
--               /         \_____/     \          /
--        ______/                       \        /
-- ______/                               \______/

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_tb_activity_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;

entity psi_common_ramp_gene_tb is
  generic(freq_clk_g : real    := 100.0E6;
          width_g    : natural := 16
         );
end entity;

architecture tb of psi_common_ramp_gene_tb is

  constant period_c             : time                                   := (1 sec) / freq_clk_g;
  signal clk_i                  : std_logic                              := '0';
  signal tb_run                 : boolean                                := true;
  --------------------------------------------------------------------
  signal rst_i                  : std_logic                              := '1';
  signal InStr                  : std_logic                              := '0';
  signal RampInc                : std_logic_vector(width_g - 1 downto 0) := (std_logic_vector(to_unsigned(100, width_g)));
  signal RampCmd                : std_logic                              := '0';
  signal InInitCmd              : std_logic                              := '0';
  -------------------------------------------------------------------
  signal OutSts                 : std_logic_vector(1 downto 0);
  signal OutStr                 : std_logic;
  signal OutPuls, OutPuls_dff   : std_logic_vector(width_g - 1 downto 0);
  signal TgtLevel               : std_logic_vector(width_g - 1 downto 0) := (std_logic_vector(to_unsigned(2000, width_g)));
  -------------------------------------------------------------------
  signal TgtLevel2              : std_logic_vector(width_g - 1 downto 0) := to_sslv(2000, width_g);
  signal sOutSts                : std_logic_vector(1 downto 0);
  signal sOutStr                : std_logic;
  signal sOutPuls, sOutPuls_dff : std_logic_vector(width_g - 1 downto 0);

begin
  --*** automatic check process ***
  process(clk_i)
  begin
    if falling_edge(clk_i) then
      OutPuls_dff <= OutPuls;
      if RampCmd = '1' and OutSts = "11" then
        print("[info]: new ramp command sent at" & to_string(now, ns));
      else
        if OutStr = '1' then
          if OutSts = "01" then
            assert (OutPuls_dff < OutPuls) report "###ERROR### info: ramp is not increasing" severity error;
          elsif OutSts = "11" then
            if RampCmd = '0' then
              assert TgtLevel = OutPuls report "###ERROR### info: error arrival data, expected " &
                                        to_string(to_integer(unsigned(TgtLevel)))&
                                        ", got " & to_string(to_integer(unsigned(sOutPuls))) severity error;
            end if;
          elsif OutSts = "10" then
            assert (OutPuls_dff > OutPuls) report "###ERROR### info: ramp is not decreasing" severity error;
          end if;
        end if;
      end if;
    end if;
  end process;

  --*** automatic check process 2 ***
  process(clk_i)
  begin
    if falling_edge(clk_i) then
      sOutPuls_dff <= sOutPuls;
      if RampCmd = '1' and sOutSts = "11" then
        print("[info]: new ramp command sent at" & to_string(now, ns));
      else
        if sOutStr = '1' then
          if sOutSts = "01" then
            assert (signed(sOutPuls_dff) < signed(sOutPuls)) report "###ERROR### info: ramp is not increasing" severity error;
          elsif sOutSts = "11" then
            if RampCmd = '0' then
              assert TgtLevel2 = sOutPuls report "###ERROR### info: error arrival data, expected " &
                                        to_string(to_integer(signed(TgtLevel2)))&
                                        ", got " & to_string(to_integer(signed(sOutPuls))) severity error;
            end if;
          elsif sOutSts = "10" then
            assert (signed(sOutPuls_dff) > signed(sOutPuls)) report "###ERROR### info: ramp is not decreasing" severity error;
          end if;
        end if;
      end if;
    end if;
  end process;

  --*** clock process ***
  proc_ck : process
    variable count : integer := 0;
  begin
    while tb_run loop
      count := 0;
      while count /= 10 loop
        clk_i <= not clk_i;
        wait for period_c / 2;
        clk_i <= not clk_i;
        wait for period_c / 2;
        count := count + 1;
      end loop;
    end loop;
    wait;
  end process;

  --*** strobe process ***
  proc_st : process
  begin
    while tb_run loop
      GenerateStrobe(freq_clock => freq_clk_g,
                     freq_str   => 2.0e6,
                     rst_pol_g  => '1',
                     rst        => rst_i,
                     clk        => clk_i,
                     str        => InStr);
    end loop;
    wait;
  end process;

  --*** DUT ***
  i_dut : entity work.psi_common_ramp_gene
    generic map(width_g   => width_g,
                rst_pol_g => '1')
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      vld_i      => InStr,
      tgt_lvl_i  => TgtLevel,
      ramp_inc_i => RampInc,
      ramp_cmd_i => RampCmd,
      init_cmd_i => InInitCmd,
      sts_o      => OutSts,
      vld_o      => OutStr,
      puls_o     => OutPuls);

  i_dut_sign : entity work.psi_common_ramp_gene
    generic map(width_g   => width_g,
                rst_pol_g => '1',
                is_sign_g => true)
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      vld_i      => InStr,
      tgt_lvl_i  => TgtLevel2,
      ramp_inc_i => RampInc,
      ramp_cmd_i => RampCmd,
      init_cmd_i => InInitCmd,
      sts_o      => sOutSts,
      vld_o      => sOutStr,
      puls_o     => sOutPuls);

  --*** stimuli process ***
  proc_stim : process
  begin
    rst_i <= '1';

    wait for 10 * period_c;
    rst_i <= '0';
    wait for 20_000 * period_c;
    wait for 10 * period_c;
    PulseSig(RampCmd, clk_i);
    wait until OutSts = "11";

    wait for 30_000 * period_c;

    for i in 0 to 3 loop
      --go up
      RampInc   <= to_uslv(100, width_g); --std_logic_vector(to_unsigned(100, width_g));
      TgtLevel  <= to_uslv(8103, width_g); --std_logic_vector(to_unsigned(8103, width_g));
      TgtLevel2 <= to_sslv(8103 / 2, width_g);
      PulseSig(RampCmd, clk_i);
      wait until OutSts = "11";
      wait for 10_000 * period_c;
      --go dw
      TgtLevel  <= to_uslv(2000, width_g); --std_logic_vector(to_unsigned(2000, width_g));
      TgtLevel2 <= to_sslv(-8103 / 2, width_g);
      RampInc   <= to_uslv(300, width_g); --std_logic_vector(to_unsigned(300, width_g));
      PulseSig(RampCmd, clk_i);
      wait until OutSts = "11";
      wait for 20_000 * period_c;

    end loop;

    --go up
    RampInc   <= to_uslv(100, width_g); --std_logic_vector(to_unsigned(100, width_g));
    TgtLevel  <= to_uslv(8103, width_g); --std_logic_vector(to_unsigned(8103, width_g));
    TgtLevel2 <= to_sslv(8103 / 2, width_g);
    PulseSig(RampCmd, clk_i);
    wait until OutSts = "11";
    wait for 10_000 * period_c;
    --go dw
    RampInc   <= to_uslv(300, width_g); -- std_logic_vector(to_unsigned(300, width_g));
    TgtLevel  <= to_uslv(300, width_g); --std_logic_vector(to_unsigned(4009, width_g));
    TgtLevel2 <= to_sslv(150, width_g);
    PulseSig(RampCmd, clk_i);
    wait until OutSts = "11";
    wait for 50_000 * period_c;

    --go up
    RampInc   <= to_uslv(50, width_g);  --std_logic_vector(to_unsigned(50, width_g));
    TgtLevel  <= to_uslv(7029, width_g); --std_logic_vector(to_unsigned(7029, width_g));
    TgtLevel2 <= to_sslv(7029 / 2, width_g);
    PulseSig(RampCmd, clk_i);
    wait until OutSts = "11";
    wait for 50_000 * period_c;

    --go dw
    RampInc   <= to_uslv(200, width_g); --std_logic_vector(to_unsigned(200, width_g));
    TgtLevel  <= to_uslv(0, width_g);   --std_logic_vector(to_unsigned(0, width_g));
    TgtLevel2 <= to_sslv(-1000, width_g);
    PulseSig(RampCmd, clk_i);
    wait until OutSts = "11";
    wait for 50_000 * period_c;

    tb_run <= false;
    report "end of sim";
    wait;
  end process;

end architecture;
