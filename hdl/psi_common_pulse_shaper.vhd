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

-- $$ processes=stimuli $$
entity psi_common_pulse_shaper is
  generic(
    duration_g : positive := 3;         -- Output pulse duration in clock cycles
    hold_in_g  : boolean  := false;     -- Hold input pulse to the output
    hold_off_g : natural  := 0          -- Minimum number of clock cycles between input pulses, if pulses arrive faster, they are ignored	$$ constant=20 $$
  );
  port(
    clk_i : in  std_logic;              -- $$ type=clk; freq=100e6 $$
    rst_i : in  std_logic;              -- $$ type=rst; clk=Clk $$
    dat_i : in  std_logic;
    dat_o : out std_logic
  );
end entity;

architecture rtl of psi_common_pulse_shaper is
  -- Two Process Method
  type two_process_r is record
    PulseLast : std_logic;
    dat_o     : std_logic;
    DurCnt    : integer range 0 to duration_g - 1;
    HoCnt     : integer range 0 to hold_off_g;
  end record;
  signal r, r_next : two_process_r;

begin

  p_comb : process(r, dat_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.PulseLast := dat_i;
    if r.DurCnt = 0 then
      if hold_in_g then
        v.dat_o := r.dat_o and dat_i;   --keep the value of the input pulse
      else
        v.dat_o := '0';
      end if;
    else
      v.DurCnt := r.DurCnt - 1;
    end if;
    if r.HoCnt /= 0 then
      v.HoCnt := r.HoCnt - 1;
    end if;
    if (dat_i = '1') and (r.PulseLast = '0') and (r.HoCnt = 0) then
      v.dat_o  := '1';
      v.HoCnt  := hold_off_g;
      v.DurCnt := duration_g - 1;
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  -- *** Output ***
  dat_o <= r.dat_o;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = '1' then
        r.dat_o <= '0';
        r.HoCnt <= 0;
      end if;
    end if;
  end process;
end architecture;
