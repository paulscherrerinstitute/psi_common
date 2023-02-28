
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_txt_util.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_compare_pkg.all;
use work.psi_common_math_pkg.all;

entity psi_common_min_max_sum_tb is
  generic(clock_cycle_g : integer := 100;
          signed_data_g : boolean := true;
          data_length_g : natural := 16;
          accu_length_g : natural := 64;
          display_g     : boolean := false
         );
end entity;

architecture tb of psi_common_min_max_sum_tb is
  --internals
  constant freq_clk_c : real                                         := 100.0E6;
  constant period_c   : time                                         := (1 sec) / freq_clk_c;
  signal clk_sti      : std_logic                                    := '0';
  signal rst_sti      : std_logic                                    := '0';
  signal tb_run_s       : boolean                                      := true;
  signal str_sti      : std_logic                                    := '0';
  signal sync_sti     : std_logic                                    := '0';
  signal dat_sti      : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal str_obs      : std_logic;
  signal min_obs      : std_logic_vector(data_length_g - 1 downto 0);
  signal max_obs      : std_logic_vector(data_length_g - 1 downto 0);
  signal mean_obs     : std_logic_vector(accu_length_g - 1 downto 0);
  --helpers
  signal avrg_exp_s   : integer                                      := 0;
  signal avrg_s       : integer                                      := 0;
  signal sync_s       : std_logic                                    := '0';
  signal sync_s_s     : std_logic                                    := '0';
  signal sync_dff_s   : std_logic;
  signal min_s        : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal max_s        : std_logic_vector(data_length_g - 1 downto 0) := (others => '0');
  signal counter_s    : integer :=0;
begin
  assert data_length_g < 32 report "[ERROR]: for this test bench only data length less than 32 are authorized" severity failure;
  --*** Reset generation ***
  proc_rst : process
  begin
    wait for 3 * period_c;
    wait until rising_edge(clk_sti);
    wait until rising_edge(clk_sti);
    rst_sti <= '0';
    wait;
  end process;

  --*** strobe generation ***
  proc_irq : process
  begin
    while tb_run_s loop
      GenerateStrobe(freq_clock => freq_clk_c,
                     freq_str   => freq_clk_c / real(clock_cycle_g),
                     rst_pol_g  => '1',
                     rst        => rst_sti,
                     clk        => clk_sti,
                     str        => sync_s);
    end loop;
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
  inst_dut : entity work.psi_common_min_max_sum
    generic map(clock_cycle_g => clock_cycle_g,
                signed_data_g => signed_data_g,
                data_width_g => data_length_g,
                accu_width_g => accu_length_g,
                rst_pol_g     => '1')
    port map(clk_i  => clk_sti,
             rst_i  => rst_sti,
             vld_i  => str_sti,
             sync_i => sync_dff_s,
             dat_i  => dat_sti,
             vld_o  => str_obs,
             min_o  => min_obs,
             max_o  => max_obs,
             sum_o => mean_obs);

  process(clk_sti)
    variable seed1_v  : positive := 1;
    variable seed2_v  : positive := 3;
    variable rand_v : real     := 0.0;
  begin
    if rising_edge(clk_sti) then
      if rst_sti = '1' then
        counter_s <= 0;
      else
        sync_dff_s <= sync_sti;
        if sync_s_s = '0' then
          sync_sti <= '0';
          if counter_s = clock_cycle_g -1 then
            counter_s <= 0;
          else
            counter_s <= counter_s + 1;
          end if;
        else
          sync_sti <= sync_s;
          uniform(seed1_v, seed2_v, rand_v);
          counter_s <= integer(rand_v * 2.0**(data_length_g) - 1.0);
        end if;
      end if;
    end if;
  end process;
  
  gene_sign : if signed_data_g generate
  dat_sti <= to_sslv(counter_s,data_length_g);
  end generate;

 gene_usign : if not signed_data_g generate
  dat_sti <= to_uslv(counter_s,data_length_g);
  end generate;
  
  --*** stim process ***
  proc_stim : process
  begin
    ------------------------------------------------------------
    print(" *************************************************  ");
    print(" **       Paul Scherrer Institut                **  ");
    print(" **    psi_common_min_max_mean_tb TestBench     **  ");
    print(" *************************************************  ");
    ------------------------------------------------------------
    print("[INFO]: *** TEST with ramp and no sync ***");
    rst_sti  <= '0';
    wait for period_c;
    str_sti  <= '1';
    sync_s_s <= '0';
    wait until falling_edge(str_obs);
    for i in 0 to clock_cycle_g - 1 loop
      wait until rising_edge(clk_sti);
      if str_obs = '1' then
        exit;
      end if;
      if signed_data_g then
        if signed(min_s) >= signed(dat_sti) then
          min_s <= dat_sti;
        end if;
        if signed(max_s) < signed(dat_sti) then
          max_s <= dat_sti;
        end if;
        if display_g then
          print("[INFO] dat value is:" & to_string(from_sslv(dat_sti)));
          print("[INFO] Min theoritical value is:" & to_string(from_sslv(min_s)));
          print("[INFO] Max theoritical value is:" & to_string(from_sslv(max_s)));
        end if;
      else
        if unsigned(min_s) >= unsigned(dat_sti) then
          min_s <= dat_sti;
        end if;
        if unsigned(max_s) < unsigned(dat_sti) then
          max_s <= dat_sti;
        end if;
        if display_g then
          print("[INFO] dat value is:" & to_string(from_uslv(dat_sti)));
          print("[INFO] Min theoritical value is:" & to_string(from_uslv(min_s)));
          print("[INFO] Max theoritical value is:" & to_string(from_uslv(max_s)));
        end if;
      end if;
    end loop;
    --------------------------------------------------------------------------------
    --*** check max & check min & check mean ***
    if signed_data_g then
      avrg_s     <= (from_sslv(max_obs) + from_sslv(min_obs)) / 2;
      avrg_exp_s <= from_sslv(mean_obs) / clock_cycle_g;
      IntCompare(avrg_exp_s, avrg_s, "MEAN is not correct", 1);
      IntCompare(from_sslv(min_s), from_sslv(min_obs), "MIN data is not as expected");
      IntCompare(from_sslv(max_s), from_sslv(max_obs), "MAX data is not as expected");
    else
      avrg_s     <= (from_uslv(max_obs) + from_uslv(min_obs)) / 2;
      avrg_exp_s <= from_uslv(mean_obs) / clock_cycle_g;
      IntCompare(avrg_exp_s, avrg_s, "MEAN is not correct", 1);
      IntCompare(from_uslv(min_s), from_uslv(min_obs), "MIN data is not as expected");
      IntCompare(from_uslv(max_s), from_uslv(max_obs), "MAX data is not as expected");
    end if;
    ---------------------------------------------------------------------------------
    print("[INFO]: *** TEST with random value & with sync  ***");
    wait until rising_edge(sync_s);
    wait until rising_edge(clk_sti);
    sync_s_s <= '1';
    wait until rising_edge(sync_dff_s);
    for i in 0 to clock_cycle_g - 1 loop
    
      wait until rising_edge(clk_sti);
      if signed_data_g then    
        if i >= 1 and signed(min_s) > signed(dat_sti) then
          min_s <= dat_sti;
        elsif i = 0 then
          min_s <= dat_sti;
        end if;
        if i >= 1 and signed(max_s) < signed(dat_sti) then
          max_s <= dat_sti;
        elsif i = 0 then
          max_s <= dat_sti;
        end if;
        if display_g then
          print("[INFO] dat value is:" & to_string(from_sslv(dat_sti)));
          print("[INFO] Min theoritical value is:" & to_string(from_sslv(min_s)));
          print("[INFO] Max theoritical value is:" & to_string(from_sslv(max_s)));
        end if;
      else 
        if i >= 1 and unsigned(min_s) > unsigned(dat_sti) then
          min_s <= dat_sti;
        elsif i = 0 then
          min_s <= dat_sti;
        end if;
        if i >= 1 and unsigned(max_s) < unsigned(dat_sti) then
          max_s <= dat_sti;
        elsif i = 0 then
          max_s <= dat_sti;
        end if;
        if display_g then
          print("[INFO] dat value is:" & to_string(from_uslv(dat_sti)));
          print("[INFO] Min theoritical value is:" & to_string(from_uslv(min_s)));
          print("[INFO] Max theoritical value is:" & to_string(from_uslv(max_s)));
        end if;
      end if;  
    end loop;

    wait until rising_edge(str_obs);
    --*** check max & check min ***
    if signed_data_g then
      IntCompare(from_sslv(min_s), from_sslv(min_obs), "MIN data is not as expected");
      IntCompare(from_sslv(max_s), from_sslv(max_obs), "MAX data is not as expected");
    else
      IntCompare(from_uslv(min_s), from_uslv(min_obs), "MIN data is not as expected");
      IntCompare(from_uslv(max_s), from_uslv(max_obs), "MAX data is not as expected");
    end if;
    print("[INFO]: End of sim");
    tb_run_s <= false;
    wait;
  end process;

end architecture;
