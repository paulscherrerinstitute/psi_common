------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
--@formatter:off
entity psi_common_min_max_sum is
  generic(clock_cycle_g : positive  := 128;                                  -- clock cycle for accumulator time
          signed_data_g : boolean   := true;                                 -- data signed/unsigned
          data_width_g  : natural   := 16;                                   -- data length 
          accu_width_g  : natural   := 63;                                   -- mean output length
          rst_pol_g     : std_logic := '1');                                 -- polarity reset
  port(   clk_i         : in  std_logic;                                     -- clock
          rst_i         : in  std_logic;                                     -- reset
          vld_i         : in  std_logic;                                     -- input strobe/valid
          sync_i        : in  std_logic;                                     -- input to sync measurement 
          dat_i         : in  std_logic_vector(data_width_g - 1 downto 0);   -- input data
          vld_o         : out std_logic;                                     -- output strobe/valid
          min_o         : out std_logic_vector(data_width_g - 1 downto 0);   -- output min val
          max_o         : out std_logic_vector(data_width_g - 1 downto 0);   -- output max val
          sum_o         : out std_logic_vector(accu_width_g-1 downto 0));    -- output vector sum
end entity;
--@formatter:on
architecture RTL of psi_common_min_max_sum is
  --internals
  signal counter_s        : unsigned(log2ceil(clock_cycle_g) downto 0):=(others=>'0');
  signal raz_s            : std_logic;
  --min signal
  signal min_str_s        : std_logic;
  signal min_dat_s        : std_logic_vector(data_width_g - 1 downto 0);
  --max signal
  signal max_dat_s        : std_logic_vector(data_width_g - 1 downto 0);
  --sum signal
  signal mean_dat_sign_s  : signed(accu_width_g-1 downto 0);
  signal mean_dat_usign_s : unsigned(accu_width_g-1 downto 0);
  signal mean_s           : std_logic_vector(accu_width_g-1 downto 0);

begin
  
  --*** check accu output length ***
  assert accu_width_g > log2ceil(clock_cycle_g)+data_width_g
  report "###ERROR###: mean vector lenght output is too small" 
  severity failure;
  
  --*** counter accu for mean calc (VECTOR SUM) *** 
  proc_count : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        counter_s        <= (others => '0');
        mean_dat_sign_s  <= (others => '0');
        mean_dat_usign_s <= (others => '0');
      else
        --*** time window mngt ***
        if sync_i = '1' or counter_s = clock_cycle_g - 1 then
          counter_s        <= (others => '0');
          mean_dat_sign_s  <= to_signed(0,accu_width_g)  + signed(dat_i);
          mean_dat_usign_s <= to_unsigned(0,accu_width_g)+ unsigned(dat_i);
          -- *** sign/unsigned for mean calc ***
          if signed_data_g then
            mean_s <= std_logic_vector(mean_dat_sign_s);
          else
            mean_s <= std_logic_vector(mean_dat_usign_s);
          end if;
        else
          if vld_i = '1' then
            counter_s <= counter_s + 1;
            -- *** sign/unsigned for mean calc ***
            if signed_data_g then
              mean_dat_sign_s <= mean_dat_sign_s + signed(dat_i);
            else
              mean_dat_usign_s <= mean_dat_usign_s + unsigned(dat_i);
            end if;
          end if;
        end if;
        --*** sum vector ***
        if (counter_s = clock_cycle_g - 1 and vld_i = '1') or sync_i ='1' then
          raz_s <= '1';         
        else
          raz_s <= '0';
        end if;

        --*** output latch ***
        if min_str_s = '1' then
          vld_o  <= '1';
          min_o  <= min_dat_s;
          max_o  <= max_dat_s;
          sum_o <= mean_s;
        else
          vld_o <= '0';
        end if;
      end if;
    end if;
  end process;

  --*** TAG Min ***
  inst_min : entity work.psi_common_find_min_max
    generic map(rst_pol_g => rst_pol_g,
                width_g  => data_width_g,
                signed_g  => signed_data_g,
                mode_g    => "MIN")
    port map(clk_i  => clk_i,
             rst_i  => rst_i,
             vld_i  => vld_i,
             raz_i  => raz_s,
             dat_i => dat_i,
             vld_o  => min_str_s,
             dat_o => min_dat_s);

  --*** TAG Max ***
  inst_max : entity work.psi_common_find_min_max
    generic map(rst_pol_g => rst_pol_g,
                width_g  => data_width_g,
                signed_g  => signed_data_g,
                mode_g    => "MAX")
    port map(clk_i  => clk_i,
             rst_i  => rst_i,
             vld_i  => vld_i,
             raz_i  => raz_s,
             dat_i => dat_i,
             vld_o  => open,
             dat_o => max_dat_s);

end architecture;
