------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic strobe generator. It produces pulses with a duration
-- of one clock cycle at a given frequency.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_strobe_generator is
  generic(
    freq_clock_g  : real      := 253.0e6; -- Clock Frequency in Hz		$$ export=true $$
    freq_strobe_g : real      := 10.0;  -- Strobe frequency in Hz		$$ export=true $$
    rst_pol_g     : std_logic := '1'    -- reset polarity
  );
  port(
    InClk  : in  std_logic;             --clk in		$$ type=clk; freq=253.0e6 $$
    InRst  : in  std_logic;             --rst sync		$$ type=rst; clk=clk_i $$
    InSync : in  std_logic := '0';      --synchronization input (srobe generation is synchronized to pulses on this optional input)
    OutVld : out std_logic              --output strobe
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_strobe_generator is

  constant ratio_c : integer                    := integer(ceil(freq_clock_g / freq_strobe_g));
  signal count     : integer range 0 to ratio_c := 0;
  signal syncLast  : std_logic                  := '0';

begin

  p_strobe : process(InClk)
  begin
    if rising_edge(InClk) then
      if InRst = rst_pol_g then
        count    <= 0;
        OutVld   <= '0';
        syncLast <= '0';
      else
        if (count = ratio_c - 1) or ((InSync = '1') and (syncLast = '0')) then
          OutVld <= '1';
          count  <= 0;
        else
          OutVld <= '0';
          count  <= count + 1;
        end if;
        syncLast <= InSync;
      end if;
    end if;
  end process;

end architecture;
