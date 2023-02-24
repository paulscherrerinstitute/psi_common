------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a conversion from time-division-multiplexed input
-- (multiple values transferred over the same signal one after the other) to
-- parallel (multiple values distributed over multiple parallel signals).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=inp,outp $$
entity psi_common_tdm_par is
  generic(
    channel_count_g : natural := 8;      -- $$ constant=3 $$
    channel_width_g : natural := 16      -- $$ constant=8 $$
  );
  port(
    -- Control Signals
    clk_i           : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    rst_i           : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    dat_i           : in  std_logic_vector(channel_width_g - 1 downto 0);
    vld_i        : in  std_logic;
    rdy_o        : out std_logic;
    TdmLast       : in  std_logic := '0';
    dat_o      : out std_logic_vector(channel_count_g * channel_width_g - 1 downto 0);
    vld_o   : out std_logic;
    rdy_i   : in  std_logic := '1';
    ParallelKeep  : out std_logic_vector(channel_count_g-1 downto 0);
    ParallelLast  : out std_logic
  );
end entity;

architecture rtl of psi_common_tdm_par is

  -- Two Process Method
  type two_process_r is record
    Idx      : integer range 0 to channel_count_g-1;
    LastReg  : std_logic;
    DataReg  : std_logic_vector(dat_o'range);
    VldReg   : std_logic_vector(channel_count_g - 1 downto 0);
    Odata    : std_logic_vector(dat_o'range);
    Olast    : std_logic;
    Ovld     : std_logic;
    Okeep    : std_logic_vector(channel_count_g-1 downto 0);
  end record;
  signal r, r_next : two_process_r;
begin

  p_comb : process(r, dat_i, vld_i, TdmLast, rdy_i)
    variable v : two_process_r;
    variable Blocked_v : boolean;
  begin
    -- hold variables stable
    v := r;

    -- *** Detect blocked state due to back pressure ***
    Blocked_v := ((r.VldReg(r.VldReg'high) = '1') or (r.LastReg = '1')) and (r.Ovld = '1') and (rdy_i = '0');

    -- *** Implementation ***
    if vld_i = '1' and not Blocked_v then
      v.DataReg((r.Idx+1)*channel_width_g-1 downto r.Idx*channel_width_g) := dat_i;
      v.VldReg(r.Idx) := '1';
      v.LastReg := TdmLast;
      if TdmLast = '1' or r.Idx = channel_count_g-1 then
        v.Idx := 0;
      else
        v.Idx := r.Idx+1;
      end if;
    end if;

    -- *** Latch ***
    if ((r.VldReg(r.VldReg'high) = '1') or (r.LastReg = '1')) and not Blocked_v then
      v.Ovld                             := '1';
      v.Odata                            := r.DataReg;
      v.Olast                            := r.LastReg;
      v.Okeep                            := r.VldReg;
      v.VldReg                           := (others => '0');
      v.VldReg(0)                        := vld_i;
      v.LastReg                          := vld_i and TdmLast;
    elsif r.Ovld = '1' and rdy_i = '1' then
      v.Ovld := '0';
    end if;

    -- *** Outputs ***
    dat_o      <= r.Odata;
    vld_o   <= r.Ovld;
    ParallelLast  <= r.Olast;
    ParallelKeep  <= r.Okeep;
    if Blocked_v then
      rdy_o <= '0';
    else 
      rdy_o <= '1';
    end if;

    -- Apply to record
    r_next <= v;

  end process;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = '1' then
        r.VldReg  <= (others => '0');
        r.LastReg <= '0';
        r.Ovld    <= '0';
        r.Idx     <= 0;
      end if;
    end if;
  end process;

end architecture;
