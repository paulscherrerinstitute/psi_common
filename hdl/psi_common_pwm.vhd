------------------------------------------------------------------------------
--  Copyright (c) 2023 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- It's a basic PWM generic that provide std_logic output, user defines few 
-- generic parameters and accordingly some command registers allows to produce
-- desired output. Rate increase the counter increment to be able to generate 
-- two or any integer multiple of pulses within a period with frequency set by
-- generics. In addition two comparator (not optimized for speed) allow to
-- add delay and bring back to zero the output, settings are set in sample defines
-- by strobe freqeuncy generics

library ieee;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.psi_common_math_pkg.all;

entity psi_common_pwm is
  generic(clk_freq_g : natural   := 125E6;  -- clock frequency
          str_freq_g : natural   := 100e3;  -- strobe frequency
          period_g   : real      := 3.125;  -- signal period
          is_sync_g  : boolean   := true;   -- sync paramter with trigger input is True or change on the fly if false
          rst_pol_g  : std_logic := '0');   -- reset polarity
  port(   clk_i      : in  std_logic;       -- system clock
          rst_i      : in  std_logic;       -- system reset
          trig_i     : in  std_logic;       -- trigger input, ideally same frequency that period generic
          rate_i     : in  std_logic_vector(log2ceil(real(str_freq_g) / period_g) - 1 downto 0);-- rate, increase pulse rate within a period, if set to 2 then 2 pulses
          pwm_i      : in  std_logic_vector(log2ceil(real(str_freq_g) / period_g) - 1 downto 0);-- pwm is equivalent to duty cycle but set in sample at str_freq
          dly_i      : in  std_logic_vector(log2ceil(real(str_freq_g) / period_g) - 1 downto 0);-- allow delaying pulse start in sample at str_freq 
          dat_o      : out std_logic;       -- data output, logic 'active high'    
          vld_o      : out std_logic);      -- vld output at str_freq rate
end entity;

architecture RTL of psi_common_pwm is
  constant ratio_c    : natural                       := natural(real(str_freq_g) / period_g);
  constant nbit_c     : natural                       := log2ceil(real(str_freq_g) / period_g);
  signal cpt_period_s : unsigned(nbit_c downto 0);
  signal str_100k_s   : std_logic;
  signal cpt_inc_s    : unsigned(nbit_c - 1 downto 0) := (others => '0');
  signal trig_dff_s   : std_logic;
  signal edge_s       : std_logic;
  signal pwm_s        : unsigned(pwm_i'range);
  signal dly_s        : unsigned(dly_i'range);
  signal pwm_plus_dly_s : unsigned(pwm_i'range);
begin

  --=================================================================
  inst_strobe_100k : entity work.psi_common_strobe_generator
    generic map(freq_clock_g  => real(clk_freq_g),
                freq_strobe_g => real(str_freq_g),
                rst_pol_g     => rst_pol_g)
    port map(clk_i  => clk_i,
             rst_i  => rst_i,
             sync_i => trig_i,
             vld_o  => str_100k_s);

  proc_cpt : process(clk_i)
  begin
    if rising_edge(clk_i) then
      trig_dff_s <= trig_i;
      --*** trig edge detect ***
      if trig_i = '1' and trig_dff_s = '0' then
        edge_s <= '1';
        pwm_s  <= unsigned(pwm_i);
        dly_s  <= unsigned(dly_i);
      else
        edge_s <= '0';
      end if;
      
      --*** compute pwm wit delay signal
      pwm_plus_dly_s <= pwm_s + dly_s;

      --*** is sync? new ratio ***
      if is_sync_g then
        if edge_s = '1' then
          cpt_inc_s <= unsigned(rate_i(cpt_inc_s'range));
        end if;
      end if;
      --
      if not is_sync_g then
        cpt_inc_s <= unsigned(rate_i(cpt_inc_s'range));
      end if;

      --*** super period counter ***
      if str_100k_s = '1' then
        if cpt_period_s >= ratio_c - cpt_inc_s then
          cpt_period_s <= (others => '0');
        else
          cpt_period_s <= cpt_period_s + cpt_inc_s;
        end if;
      end if;
      vld_o <= str_100k_s;
      if str_100k_s = '1' then
        if cpt_period_s >= dly_s and cpt_period_s <= pwm_plus_dly_s  and
            pwm_s /= to_unsigned(0,pwm_s'length)                     then
          dat_o <= '1';
        else
          dat_o <= '0';
        end if;
      end if;

      -- sync
      if (is_sync_g and edge_s = '1') then
        cpt_period_s <= (others => '0');
      end if;

      --*** reset sync ***
      if (rst_i = rst_pol_g) then
        cpt_period_s <= (others => '0');
        cpt_inc_s    <= (others => '0');
      end if;

    
    end if;
  end process;

end architecture;
