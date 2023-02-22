------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a conversion from length-variable time-division-multiplexed input
-- (multiple values transferred over the same signal one after the other) to
-- parallel (multiple values distributed over multiple parallel signals).
-- The enabled channels order is (EnabledChannels -1 downto 0). 
-- This can be used with AXI stream.
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
entity psi_common_tdm_par_cfg is
  generic(
    channel_count_g : natural := 8;      -- $$ constant=3 $$
    channel_width_g : natural := 16      -- $$ constant=8 $$
  );
  port(
    -- Control Signals
    clk_i             : in  std_logic;    -- $$ type=clk; freq=100e6 $$
    rst_i             : in  std_logic;    -- $$ type=rst; clk=Clk $$
    enabled_channels_i : in  integer range 0 to channel_count_g := channel_count_g; -- Number of enabled output channels
    -- Data Ports
    dat_i             : in  std_logic_vector(channel_width_g - 1 downto 0);
    vld_i          : in  std_logic;
    last_i         : in  std_logic;
    dat_o        : out std_logic_vector(channel_count_g * channel_width_g - 1 downto 0);
    vld_o     : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_tdm_par_cfg is

  -- Two Process Method
  type two_process_r is record
    ParallelReg    : std_logic_vector(dat_o'range);
    ChCounter      : integer range 0 to channel_count_g + 1;
    EnChannelsMask : std_logic_vector(channel_count_g - 1 downto 0);
    Odata          : std_logic_vector(dat_o'range);
    Ovld           : std_logic;
    TdmLast_d      : std_logic;
  end record;
  signal r, r_next : two_process_r;
begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, dat_i, vld_i, enabled_channels_i, last_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.TdmLast_d := '0';
    if vld_i = '1' then
      if (v.ChCounter < enabled_channels_i) then
        v.ParallelReg((channel_width_g * v.ChCounter) + (channel_width_g - 1) downto channel_width_g * v.ChCounter) := dat_i;
      else
        v.ParallelReg((channel_width_g - 1) downto 0) := dat_i; -- Necessary if you have a stream and TdmVld stays at '1' between one data word and the next one
      end if;
      v.ChCounter := v.ChCounter + 1;
      v.TdmLast_d := last_i;

    end if;

    -- *** Latch ***
    v.Ovld := '0';

    if r.ChCounter = enabled_channels_i or r.TdmLast_d = '1' then
      v.Ovld           := '1';
      v.Odata          := r.ParallelReg;
      v.EnChannelsMask := partially_ones_vector(channel_count_g, enabled_channels_i);
      v.ChCounter      := to_integer(unsigned'('0' & vld_i)); -- Necessary if you have a stream and TdmVld stays at '1' between one data word and the next one
    end if;

    -- *** Outputs ***
    parallel_assign : for i in 0 to channel_count_g - 1 loop
      if r.EnChannelsMask(i) = '1' then
        dat_o((channel_width_g * i) + (channel_width_g - 1) downto channel_width_g * i) <= r.Odata((channel_width_g * i) + (channel_width_g - 1) downto channel_width_g * i);
      else
        dat_o((channel_width_g * i) + (channel_width_g - 1) downto channel_width_g * i) <= (others => '0');
      end if;
    end loop;
    vld_o <= r.Ovld;

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = '1' then
        r.ChCounter      <= 0;
        r.EnChannelsMask <= (others => '0');
        r.Ovld           <= '0';
        r.TdmLast_d      <= '0';
      end if;
    end if;
  end process;

end rtl;
