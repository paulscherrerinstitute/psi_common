------------------------------------------------------------------------------
--  Copyright (c) 2025 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic strobe generator. It produces pulses with a duration
-- of one clock period count
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.psi_common_math_pkg.all;

entity psi_common_strobe_generator_cfg is
  generic(rst_pol_g     : std_logic := '1';
          nb_g          : natural range 1 to 32);               -- reset polarity
  port(   clk_i         : in  std_logic;                        -- clk in
          rst_i         : in  std_logic;                        -- rst sync
          count_i       : in std_logic_vector(nb_g-1 downto 0); -- in clock cycle period
          sync_i        : in  std_logic := '0';                 -- synchronization input (srobe generation is synchronized to pulses on this optional input)
          vld_o         : out std_logic );                      -- output strobe
end entity;

architecture rtl of psi_common_strobe_generator_cfg is

  signal count        : integer      :=  0;
  signal count_dff_s  : std_logic_vector(nb_g-1 downto 0)      :=  (others=>'0'); 
  signal syncLast     : std_logic    := '0';

begin

  p_strobe : process(clk_i)
  begin
    if rising_edge(clk_i) then
      count_dff_s <= count_i;
      if rst_i = rst_pol_g or count_dff_s/=count_i then
        count    <= 0;
        vld_o    <= '0';
        syncLast <= '0';
      else
        if (count = from_uslv(count_i)-1 or (sync_i = '1')) and (syncLast = '0') then
          vld_o <= '1';
          count  <= 0;
        else
          vld_o <= '0';
          count  <= count + 1;
        end if;
        syncLast <= sync_i;
      end if;
    end if;
  end process;

end architecture;
