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
entity psi_common_tdm_par is
  generic(
    ChannelCount_g : natural := 8;      -- $$ constant=3 $$
    ChannelWidth_g : natural := 16      -- $$ constant=8 $$
  );
  port(
    -- Control Signals
    Clk         : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    Rst         : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    Tdm         : in  std_logic_vector(ChannelWidth_g - 1 downto 0);
    TdmVld      : in  std_logic;
    TdmRdy      : out std_logic;
    Parallel    : out std_logic_vector(ChannelCount_g * ChannelWidth_g - 1 downto 0);
    ParallelVld : out std_logic;
    ParallelRdy : in  std_logic := '1'
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par is

  -- Two Process Method
  type two_process_r is record
    ShiftReg : std_logic_vector(Parallel'range);
    VldSr    : std_logic_vector(ChannelCount_g - 1 downto 0);
    Odata    : std_logic_vector(Parallel'range);
    Ovld     : std_logic;
  end record;
  signal r, r_next : two_process_r;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, Tdm, TdmVld, ParallelRdy)
    variable v : two_process_r;
    variable Blocked_v : boolean;
  begin
    -- hold variables stable
    v := r;

    -- *** Detect blocked state due to back pressure ***
    Blocked_v := (r.VldSr(0) = '1') and (r.Ovld = '1');

    -- *** Implementation ***
    if TdmVld = '1' and not Blocked_v then
      v.ShiftReg := Tdm & r.ShiftReg(r.ShiftReg'high downto ChannelWidth_g);
      v.VldSr    := '1' & r.VldSr(r.VldSr'high downto 1);
    end if;

    -- *** Latch ***
    if r.VldSr(0) = '1' and not Blocked_v then
      v.Ovld                             := '1';
      v.Odata                            := r.ShiftReg;
      v.VldSr(r.VldSr'high)              := TdmVld;
      v.VldSr(r.VldSr'high - 1 downto 0) := (others => '0');
    elsif r.Ovld = '1' and ParallelRdy = '1' then
      v.Ovld := '0';
    end if;

    -- *** Outputs ***
    Parallel    <= r.Odata;
    ParallelVld <= r.Ovld;
    TdmRdy      <= '0' when Blocked_v else '1';

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
      end if;
    end if;
  end process;

end rtl;
