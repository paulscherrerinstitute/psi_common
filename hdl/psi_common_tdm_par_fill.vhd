------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Elmar Schmid
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a conversion from time-division-multiplexed input
-- (multiple values transferred over the same signal one after the other) to
-- parallel (multiple values distributed over multiple parallel signals).
-- It also supports a termination of the transmission by activating TdmLast
-- at the serial input, causing the parallel output word to be filled with
-- zeros (if necessary) and presented to the output together with an active
-- ParallelLast.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------
-- $$ processes=inp,outp $$
entity psi_common_tdm_par_fill is
  generic(
    ChannelCount_g : natural := 8;      -- $$ constant=3 $$
    ChannelWidth_g : natural := 16      -- $$ constant=8 $$
  );
  port(
    -- Control Signals
    Clk          : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    Rst          : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    Tdm          : in  std_logic_vector(ChannelWidth_g - 1 downto 0);
    TdmVld       : in  std_logic;
    TdmRdy       : out std_logic;
    TdmLast      : in  std_logic := '0';
    Parallel     : out std_logic_vector(ChannelCount_g * ChannelWidth_g - 1 downto 0);
    ParallelVld  : out std_logic;
    ParallelRdy  : in  std_logic := '1';
    ParallelKeep : out std_logic_vector(ChannelCount_g - 1 downto 0);
    ParallelLast : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par_fill is

  constant TdmZeros_c : std_logic_vector(ChannelWidth_g - 1 downto 0) := (others=>'0');

  -- Two Process Method
  type two_process_r is record
    ShiftReg : std_logic_vector(Parallel'range);
    VldSr    : std_logic_vector(ChannelCount_g - 1 downto 0);
    Odata    : std_logic_vector(Parallel'range);
    Okeep    : std_logic_vector(ChannelCount_g - 1 downto 0);
    Ovld     : std_logic;
    Olst     : std_logic;
    Last     : std_logic;
    Keep     : std_logic_vector(ChannelCount_g - 1 downto 0);
    Fill     : std_logic;
  end record;
  signal r, r_next : two_process_r;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, Tdm, TdmVld, TdmLast, ParallelRdy)
    variable v : two_process_r;
    variable Blocked_v : boolean;
  begin
    -- hold variables stable
    v := r;

    -- *** Detect blocked state due to back pressure ***
    Blocked_v := (r.VldSr(0) = '1') and (r.Ovld = '1');

    -- *** Implementation ***
    if r.Fill = '1' and not Blocked_v then
      v.ShiftReg := TdmZeros_c & r.ShiftReg(r.ShiftReg'high downto ChannelWidth_g);
      v.VldSr    := '1' & r.VldSr(r.VldSr'high downto 1);
    elsif TdmVld = '1' and not Blocked_v then
      v.ShiftReg := Tdm & r.ShiftReg(r.ShiftReg'high downto ChannelWidth_g);
      v.VldSr    := '1' & r.VldSr(r.VldSr'high downto 1);
      v.Keep     := r.Keep(r.Keep'high - 1 downto 0) & '1';
      v.Last     := TdmLast;
      v.Fill     := TdmLast and not(r.VldSr(1));
    end if;

    -- *** Latch ***
    if r.VldSr(0) = '1' and not Blocked_v then
      v.Ovld                             := '1';
      v.Olst                             := r.Last;
      v.Okeep                            := r.Keep;
      v.Odata                            := r.ShiftReg;
      v.VldSr(r.VldSr'high)              := TdmVld;
      v.VldSr(r.VldSr'high - 1 downto 0) := (others => '0');
      v.Keep(r.Keep'low)                 := TdmVld;
      v.Keep(r.Keep'high downto 1)       := (others => '0');
      v.Last                             := TdmVld and TdmLast;
      v.Fill                             := TdmVld and TdmLast;
    elsif r.VldSr(1) = '1' and not Blocked_v then
      v.Fill                             := '0';
    elsif r.Ovld = '1' and ParallelRdy = '1' then
      v.Ovld := '0';
      v.Olst := '0';
    end if;

    -- *** Outputs ***
    Parallel     <= r.Odata;
    ParallelVld  <= r.Ovld;
    ParallelKeep <= r.Okeep;
    ParallelLast <= r.Olst;
--    TdmRdy      <= '0' when (Blocked_v or (r.Fill = '1' and r.VldSr(0) = '0')) else '1';
    TdmRdy      <= '0' when (Blocked_v or r.Fill = '1') else '1';

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.VldSr <= (others => '0');
        r.Ovld  <= '0';
        r.Olst  <= '0';
        r.Fill  <= '0';
      end if;
    end if;
  end process;

end rtl;
