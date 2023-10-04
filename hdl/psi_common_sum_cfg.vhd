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
use work.psi_common_logic_pkg.all;

--@formatter:off
entity psi_common_sum_cfg is
  generic(max_avg_g     : positive  := 128;                                  -- maximum possible number of averaged samples
          signed_data_g : boolean   := true;                                 -- data signed/unsigned
          data_width_g  : natural   := 16;                                   -- data length 
          rst_pol_g     : std_logic := '1');                                 -- polarity reset
  port(   clk_i         : in  std_logic;                                     -- clock
          rst_i         : in  std_logic;                                     -- reset
          vld_i         : in  std_logic;                                     -- input strobe/valid
          sync_i        : in  std_logic;                                     -- input to sync measurement 
          sample_i      : in  std_logic_vector(data_width_g - 1 downto 0);   -- number of sample to make the computation 
          fract_i       : in  std_logic_vector(data_width_g - 1 downto 0);   -- fractional part to multiple with
          dat_i         : in  std_logic_vector(data_width_g - 1 downto 0);   -- input data
          vld_o         : out std_logic;                                     -- output strobe/valid
          sum_o         : out std_logic_vector(data_width_g+log2ceil(max_avg_g) - 1 downto 0);   --
          avg_o         : out std_logic_vector(data_width_g - 1 downto 0));  -- output vector sum
end entity;
--@formatter:on
architecture RTL of psi_common_sum_cfg is
  --internals
  constant accu_witdh_c   : natural := data_width_g+log2ceil(max_avg_g);
  constant mult_witdh_c   : natural := data_width_g+accu_witdh_c;
  signal counter_s        : unsigned(log2ceil(max_avg_g) downto 0):=(others=>'0');
  
  signal mean_dat_sign_s  : signed(accu_witdh_c-1 downto 0);
  signal mean_dat_usign_s : unsigned(accu_witdh_c-1 downto 0);
  signal mean_s           : std_logic_vector(accu_witdh_c-1 downto 0);
  --avg calculation for low latency
  signal avg0_s           : unsigned(mult_witdh_c-1 downto 0);
  signal avg0_sign_s      : signed(mult_witdh_c-1 downto 0);
  signal avg_str          : std_logic;
  signal vld_o_s          : std_logic;
begin
  
  --*** counter accu for mean calc (VECTOR SUM) *** 
  proc_count : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        counter_s        <= (others => '0');
        mean_dat_sign_s  <= (others => '0');
        mean_dat_usign_s <= (others => '0');
      else
        if sample_i = zeros_vector(sample_i'length) then
          -- when averaging size zero then pass the data to the output
          vld_o <= vld_i;
          sum_o <= std_logic_vector(resize(unsigned(dat_i), sum_o'length));
          avg_o <= dat_i;
        else
          if sync_i = '1' or counter_s = unsigned(sample_i) - 1 then
            counter_s        <= (others => '0');
            mean_dat_sign_s  <= to_signed(0, accu_witdh_c) + signed(dat_i);
            mean_dat_usign_s <= to_unsigned(0, accu_witdh_c) + unsigned(dat_i);
            -- *** sign/unsigned for mean calc ***
            avg_str          <= '1';
            if signed_data_g then
              mean_s <= std_logic_vector(mean_dat_sign_s);
            else
              mean_s <= std_logic_vector(mean_dat_usign_s);
            end if;
          else
            avg_str <= '0';
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

          --*** average calculation ***
          vld_o_s <= avg_str;
          if avg_str = '1' then
            if signed_data_g then
              avg0_sign_s <= signed(mean_s) * signed(fract_i);
            else
              avg0_s <= unsigned(mean_s) * unsigned(fract_i);
            end if;
          end if;
          -- give output 
          vld_o <= vld_o_s;
          if vld_o_s = '1' then
            sum_o <= mean_s;
            if signed_data_g then
              avg_o <= std_logic_vector(resize(shift_right(avg0_sign_s, avg_o'length), avg_o'length));
            else
              avg_o <= std_logic_vector(resize(shift_right(avg0_s, avg_o'length), avg_o'length));
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

end architecture;
