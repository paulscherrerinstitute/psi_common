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
    Clk           : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    Rst           : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    Tdm           : in  std_logic_vector(ChannelWidth_g - 1 downto 0);
    TdmVld        : in  std_logic;
    TdmRdy        : out std_logic;
    TdmLast       : in  std_logic := '0';
    Parallel      : out std_logic_vector(ChannelCount_g * ChannelWidth_g - 1 downto 0);
    ParallelVld   : out std_logic;
    ParallelRdy   : in  std_logic := '1';
    ParallelKeep  : out std_logic_vector(ChannelCount_g-1 downto 0);
    ParallelLast  : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par is

  -- Two Process Method
  type two_process_r is record
    Idx      : integer range 0 to ChannelCount_g-1;
    LastReg  : std_logic;
    DataReg  : std_logic_vector(Parallel'range);
    VldReg   : std_logic_vector(ChannelCount_g - 1 downto 0);
    Odata    : std_logic_vector(Parallel'range);
    Olast    : std_logic;
    Ovld     : std_logic;
    Okeep    : std_logic_vector(ChannelCount_g-1 downto 0);
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
    Blocked_v := ((r.VldReg(r.VldReg'high) = '1') or (r.LastReg = '1')) and (r.Ovld = '1') and (ParallelRdy = '0');

    -- *** Implementation ***
    if TdmVld = '1' and not Blocked_v then
      v.DataReg((r.Idx+1)*ChannelWidth_g-1 downto r.Idx*ChannelWidth_g) := Tdm;
      v.VldReg(r.Idx) := '1';
      v.LastReg := TdmLast;
      if TdmLast = '1' or r.Idx = ChannelCount_g-1 then
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
      v.VldReg(0)                        := TdmVld;
      v.LastReg                          := TdmVld and TdmLast;
    elsif r.Ovld = '1' and ParallelRdy = '1' then
      v.Ovld := '0';
    end if;

    -- *** Outputs ***
    Parallel      <= r.Odata;
    ParallelVld   <= r.Ovld;
    ParallelLast  <= r.Olast;
    ParallelKeep  <= r.Okeep;
    if Blocked_v then
      TdmRdy <= '0';
    else 
      TdmRdy <= '1';
    end if;

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
        r.VldReg  <= (others => '0');
        r.LastReg <= '0';
        r.Ovld    <= '0';
        r.Idx     <= 0;
      end if;
    end if;
  end process;

end rtl;
