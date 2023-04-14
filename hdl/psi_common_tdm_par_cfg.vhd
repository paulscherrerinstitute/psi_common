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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- @formatter:off
entity psi_common_tdm_par_cfg is
  generic(ch_nb_g      : natural := 8;                                        -- number of channel
          width_g      : natural := 16;                                       -- data widthg in bit
          rst_pol_g    : std_logic := '1');                                   -- '1' active high, '0' active low 
  port(   clk_i        : in  std_logic;                                       -- system clock 
          rst_i        : in  std_logic;                                       -- system reset
          enabled_ch_i : in  integer range 0 to ch_nb_g := ch_nb_g;           -- Number of enabled output channels
          dat_i        : in  std_logic_vector(width_g - 1 downto 0);          -- data signal input
          vld_i        : in  std_logic;                                       -- valid signal input
          last_i       : in  std_logic;                                       -- Last input
          dat_o        : out std_logic_vector(ch_nb_g * width_g - 1 downto 0);-- data signaé  output
          vld_o        : out std_logic);                                      -- valid signal output
end entity;
-- @formatter:on

architecture rtl of psi_common_tdm_par_cfg is

  -- Two Process Method
  type two_process_r is record
    ParallelReg    : std_logic_vector(dat_o'range);
    ChCounter      : integer range 0 to ch_nb_g + 1;
    EnChannelsMask : std_logic_vector(ch_nb_g - 1 downto 0);
    Odata          : std_logic_vector(dat_o'range);
    Ovld           : std_logic;
    TdmLast_d      : std_logic;
  end record;
  signal r, r_next : two_process_r;
begin

  p_comb : process(r, dat_i, vld_i, enabled_ch_i, last_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.TdmLast_d := '0';
    if vld_i = '1' then
      if (v.ChCounter < enabled_ch_i) then
        v.ParallelReg((width_g * v.ChCounter) + (width_g - 1) downto width_g * v.ChCounter) := dat_i;
      else
        v.ParallelReg((width_g - 1) downto 0) := dat_i; -- Necessary if you have a stream and TdmVld stays at '1' between one data word and the next one
      end if;
      v.ChCounter := v.ChCounter + 1;
      v.TdmLast_d := last_i;

    end if;

    -- *** Latch ***
    v.Ovld := '0';

    if r.ChCounter = enabled_ch_i or r.TdmLast_d = '1' then
      v.Ovld           := '1';
      v.Odata          := r.ParallelReg;
      v.EnChannelsMask := partially_ones_vector(ch_nb_g, enabled_ch_i);
      v.ChCounter      := to_integer(unsigned'('0' & vld_i)); -- Necessary if you have a stream and TdmVld stays at '1' between one data word and the next one
    end if;

    -- *** Outputs ***
    parallel_assign : for i in 0 to ch_nb_g - 1 loop
      if r.EnChannelsMask(i) = '1' then
        dat_o((width_g * i) + (width_g - 1) downto width_g * i) <= r.Odata((width_g * i) + (width_g - 1) downto width_g * i);
      else
        dat_o((width_g * i) + (width_g - 1) downto width_g * i) <= (others => '0');
      end if;
    end loop;
    vld_o <= r.Ovld;

    -- Apply to record
    r_next <= v;

  end process;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.ChCounter      <= 0;
        r.EnChannelsMask <= (others => '0');
        r.Ovld           <= '0';
        r.TdmLast_d      <= '0';
      end if;
    end if;
  end process;

end architecture;
