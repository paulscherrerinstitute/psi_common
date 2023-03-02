------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--	Authors: Patric Buche
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a timing generator that generates pulses on all 
-- important time units (seconds, milliseconds, microseconds).

library ieee;
use ieee.std_logic_1164.all;

-- @formatter:off
entity psi_common_tickgenerator is
  generic( clk_in_mhz_g             : integer := 8;  -- frequency clock in MHz
           tick_width_g             : integer := 1;  -- pulse length
           sim_sec_speedup_factor_g : integer := 1); -- Set to 1 for implementation!!! speedup factor for simulation, does only apply to sec, not to us/ms
  port(    clock_i                  : in  std_logic; -- system clock
           tick1us_o                : out std_logic; -- 1 us pulse
           tick1ms_o                : out std_logic; -- 1 ms pulse
           tick1sec_o               : out std_logic);-- 1 sec pulse
end entity;
-- @formatter:on

architecture rtl of psi_common_tickgenerator is

  -- Constant Declarations
  constant c_THRESHOLD : integer := 1000;

  -- Signal Declarations
  signal count_clk : integer range 1 to clk_in_mhz_g         := 1;
  signal count_1us : integer range 1 to c_THRESHOLD          := 1;
  signal count_1ms : integer range 1 to c_THRESHOLD          := 1;
  ---
  signal tick1us   : std_logic_vector(tick_width_g downto 0) := (others => '0');
  signal tick1ms   : std_logic_vector(tick_width_g downto 0) := (others => '0');
  signal tick1sec  : std_logic_vector(tick_width_g downto 0) := (others => '0');

begin

  prc_tickgen : process(clock_i)
    variable carry_1us  : std_logic := '0';
    variable carry_1ms  : std_logic := '0';
    variable carry_1sec : std_logic := '0';
  begin
    if rising_edge(clock_i) then
      -- default assignments			
      tick1us  <= tick1us(tick_width_g - 1 downto 0) & '0';
      tick1ms  <= tick1ms(tick_width_g - 1 downto 0) & '0';
      tick1sec <= tick1sec(tick_width_g - 1 downto 0) & '0';

      if (count_clk < clk_in_mhz_g) then
        count_clk <= count_clk + 1;
        carry_1us := '0';
      else
        carry_1us := '1';
        count_clk <= 1;
      end if;

      -- tick 1 us
      if (carry_1us = '1') then
        tick1us <= (others => '1');
        if (count_1us < c_THRESHOLD) then
          count_1us <= count_1us + 1;
          carry_1ms := '0';
        else
          count_1us <= 1;
          carry_1ms := '1';
        end if;
      end if;

      -- tick 1 ms
      if ((carry_1us and carry_1ms) = '1') then
        tick1ms <= (others => '1');
        if (count_1ms < c_THRESHOLD / sim_sec_speedup_factor_g) then
          count_1ms  <= count_1ms + 1;
          carry_1sec := '0';
        else
          count_1ms  <= 1;
          carry_1sec := '1';
        end if;
      end if;

      -- tick 1 sec
      if ((carry_1us and carry_1ms and carry_1sec) = '1') then
        tick1sec <= (others => '1');
      end if;
      ---
    end if;
  end process;

  -- port mapping
  tick1us_o  <= tick1us(tick_width_g - 1);
  tick1ms_o  <= tick1ms(tick_width_g - 1);
  tick1sec_o <= tick1sec(tick_width_g - 1);

end architecture;
