------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity takes multiple inputs in parallel and converts them to time-
-- division-multiplexed (i.e. the values are transferred one after the other
-- over a single signal)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=inp,outp $$
entity psi_common_par_tdm is
  generic(
    channel_count_g : natural := 8;     -- $$ constant=3 $$
    channel_width_g : natural := 16;     -- $$ constant=8 $$
    rst_pol_g       : std_logic:='1');
  port(
    clk_i  : in  std_logic;             -- $$ type=clk; freq=100e6 $$
    rst_i  : in  std_logic;             -- $$ type=rst; clk=Clk $$
    dat_i  : in  std_logic_vector(channel_count_g * channel_width_g - 1 downto 0);
    vld_i  : in  std_logic;
    rdy_o  : out std_logic;
    last_i : in  std_logic := '1';
    dat_o  : out std_logic_vector(channel_width_g - 1 downto 0);
    vld_o  : out std_logic;
    rdy_i  : in  std_logic := '1';
    last_o : out std_logic
  );
end entity;

architecture rtl of psi_common_par_tdm is
  -- Two Process Method
  type two_process_r is record
    ShiftReg : std_logic_vector(dat_i'range);
    LastSr   : std_logic_vector(channel_count_g - 1 downto 0);
    VldSr    : std_logic_vector(channel_count_g - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i, rdy_i, last_i)
    variable v             : two_process_r;
    variable ParallelRdy_v : std_logic;
  begin
    -- hold variables stable
    v := r;

    -- *** Back Pressure ***
    if unsigned(r.VldSr(r.VldSr'high downto 1)) = 0 and ((rdy_i = '1') or (r.VldSr(0) = '0')) then
      ParallelRdy_v := '1';
    else
      ParallelRdy_v := '0';
    end if;

    -- *** Implementation ***
    if (vld_i = '1') and (ParallelRdy_v = '1') then
      v.ShiftReg                    := dat_i;
      v.VldSr                       := (others => '1');
      v.LastSr                      := (others => '0');
      v.LastSr(channel_count_g - 1) := last_i;
    elsif rdy_i = '1' then
      v.ShiftReg := shift_right(r.ShiftReg, channel_width_g);
      v.LastSr   := shift_right(r.LastSr, 1);
      v.VldSr    := shift_right(r.VldSr, 1);
    end if;

    -- *** Outputs ***
    dat_o  <= r.ShiftReg(channel_width_g - 1 downto 0);
    vld_o  <= r.VldSr(0);
    last_o <= r.LastSr(0);
    rdy_o  <= ParallelRdy_v;

    -- Apply to record
    r_next <= v;

  end process;
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.VldSr <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
