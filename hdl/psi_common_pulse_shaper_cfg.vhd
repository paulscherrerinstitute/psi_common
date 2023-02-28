------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a pulse shaping block allowing to generate pulses of a fixed length
-- from pulses with an unknown length. Additionally input pulses occuring
-- during a configurable hold-off time can be ignored after one pulse was detected.
-- A new parameter has been added in order to hold, if wanted, the pulse value
-- when this mode is used the holdoff parameter is not releveant anymore -> 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- @formatter:off
entity psi_common_pulse_shaper_cfg is
  generic(HoldIn_g       : boolean   := false;                                                              -- Hold input pulse to the output
          hold_off_ena_g : boolean   := false;                                                              -- Hold off capability enable if true, if false stuck to '0' the corresponding input
          max_hold_off_g : natural   := 256;                                                                -- Minimum number of clock cycles between input pulses, if pulses arrive faster, they are ignored
          max_duration_g : positive  := 128;                                                                -- Maximum duratio
          rst_pol_g      : std_logic := '1');                                                               -- polarity reset
  port(   clk_i    : in  std_logic;                                                                         -- system clock
           rst_i   : in  std_logic;                                                                         -- system reset
           width_i : in  std_logic_vector(log2ceil(max_duration_g) - 1 downto 0);                           -- Output pulse duration in clock cycles
           hold_i  : in  std_logic_vector(choose(hold_off_ena_g, log2ceil(max_hold_off_g), 1) - 1 downto 0);-- 
           dat_i   : in  std_logic;                                                                         -- pulse/str/vld input
           dat_o   : out std_logic);                                                                        -- pulse/str/vld input
end entity;
-- @formatter:on

architecture rtl of psi_common_pulse_shaper_cfg is
  -- Two Process Method
  type two_process_t is record
    PulseLast : std_logic;
    OutPulse  : std_logic;
    DurCnt    : integer range 0 to max_duration_g - 1;
    HoCnt     : integer range 0 to max_hold_off_g;
  end record;
  signal r, r_next : two_process_t;

begin

  p_comb : process(r, dat_i, width_i, hold_i)
    variable v : two_process_t;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.PulseLast := dat_i;
    if r.DurCnt = 0 then
      if HoldIn_g then
        v.OutPulse := r.OutPulse and dat_i; --keep the value of the input pulse
      else
        v.OutPulse := '0';
      end if;
    else
      v.DurCnt := r.DurCnt - 1;
    end if;
    if r.HoCnt /= 0 then
      v.HoCnt := r.HoCnt - 1;
    end if;
    if unsigned(width_i) = 0 then
      v.DurCnt   := 0;
      v.OutPulse := '0';
    else
      if (dat_i = '1') and (r.PulseLast = '0') and (r.HoCnt = 0) then
        v.OutPulse := '1';
        v.HoCnt    := from_uslv(hold_i);
        v.DurCnt   := from_uslv(width_i) - 1;
      end if;
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  -- *** Output ***
  dat_o <= r.OutPulse;
  
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.OutPulse <= '0';
        r.HoCnt    <= 0;
      end if;
    end if;
  end process;
end architecture;
