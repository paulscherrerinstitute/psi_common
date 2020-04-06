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
entity psi_common_par_tdm is
  generic(
    ChannelCount_g : natural := 8;      -- $$ constant=3 $$
    ChannelWidth_g : natural := 16      -- $$ constant=8 $$
  );
  port(
    -- Control Signals
    Clk         : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    Rst         : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    Parallel    : in  std_logic_vector(ChannelCount_g * ChannelWidth_g - 1 downto 0);
    ParallelVld : in  std_logic;
    Tdm         : out std_logic_vector(ChannelWidth_g - 1 downto 0);
    TdmVld      : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_par_tdm is

  -- Two Process Method
  type two_process_r is record
    ShiftReg : std_logic_vector(Parallel'range);
    VldSr    : std_logic_vector(ChannelCount_g - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, Parallel, ParallelVld)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    if ParallelVld = '1' then
      v.ShiftReg := Parallel;
      v.VldSr    := (others => '1');
    else
      v.ShiftReg := shiftRight(r.ShiftReg, ChannelWidth_g);
      v.VldSr    := shiftRight(r.VldSr, 1);
    end if;

    -- *** Outputs ***
    Tdm    <= r.ShiftReg(ChannelWidth_g - 1 downto 0);
    TdmVld <= r.VldSr(0);

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
      end if;
    end if;
  end process;

end rtl;
