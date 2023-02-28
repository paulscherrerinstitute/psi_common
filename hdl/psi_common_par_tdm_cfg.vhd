------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  Copyright (c) 2020 by Enclustra GmbH, Switherland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity takes multiple inputs in parallel and converts them to time-
-- division-multiplexed (i.e. the values are transferred one after the other
-- over a single signal)
-- The number of channels to be serialized can be configured at runtime.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
-- @formatter:off
entity psi_common_par_tdm_cfg is
  generic(ch_nb_g      : natural := 8;                                            -- maximum number of channel
          ch_width_g   : natural := 16;                                           -- vector length per channel
          rst_pol_g    : std_logic:='1');                                         -- '1' active high, '0' active low
  port(   clk_i        : in  std_logic;                                           -- system clock
          rst_i        : in  std_logic;                                           -- system reset
          enabled_ch_i : in  integer range 0 to ch_nb_g := ch_nb_g;               -- Number of enabled output channels (starting from index 0)
          dat_i        : in  std_logic_vector(ch_nb_g * ch_width_g - 1 downto 0); -- DATA big vector interpreted as // input
          vld_i        : in  std_logic;                                           -- valid input
          dat_o        : out std_logic_vector(ch_width_g - 1 downto 0);           -- DATa output in TDM fashion
          last_o       : out std_logic;                                           -- AXI-S TLAST signal, set for the last transfer in a packet
          vld_o        : out std_logic);                                          -- AXI-S handshaking signal
end entity;
-- @formatter:on
architecture rtl of psi_common_par_tdm_cfg is
  -- Two Process Method
  type two_process_r is record
    ShiftReg : std_logic_vector(dat_i'range);
    ChCnt    : integer range 0 to ch_nb_g;
  end record;
  signal r, r_next : two_process_r;
begin

  p_comb : process(r, dat_i, vld_i, enabled_ch_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    if vld_i = '1' then
      v.ShiftReg := dat_i;
      v.ChCnt    := enabled_ch_i;
    else
      v.ShiftReg := shift_right(r.ShiftReg, ch_width_g);
      if r.ChCnt /= 0 then
        v.ChCnt := r.ChCnt - 1;
      end if;
    end if;

    -- *** Outputs ***
    dat_o <= r.ShiftReg(ch_width_g - 1 downto 0);
    if r.ChCnt /= 0 then
      vld_o <= '1';
    else
      vld_o <= '0';
    end if;
    if r.ChCnt = 1 then
      last_o <= '1';
    else
      last_o <= '0';
    end if;

    -- Apply to record
    r_next <= v;

  end process;
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.ChCnt <= 0;
      end if;
    end if;
  end process;

end architecture;
