------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic strobe divider. Every Nth strobe is sent to the output.
-- Note that the output has a delay of one clock cycle compared to the input.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=ctrl,countout $$
entity psi_common_strobe_divider is
  generic(
    length_g  : natural   := 4;         -- ratio division bit width									$$ constant=4 $$
    rst_pol_g : std_logic := '0'        -- reset polarity
  );
  port(
    clk_i   : in  std_logic;            -- clk in													$$ type=clk; freq=100e6; $$
    rst_i   : in  std_logic;            -- synchornous reset										$$ type=rst; clk=clk_i; lowactive=true $$
    vld_i   : in  std_logic;            -- strobe in (if not strobe an edge detection is done)
    ratio_i : in  std_logic_vector(length_g - 1 downto 0); -- parameter ratio for division
    vld_o  : out std_logic);           -- strobe output
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_strobe_divider is
  signal str_dff_s : std_logic;
  signal counter_s : integer range 0 to 2**length_g - 1 := 0;
begin

  -- *** Implementation ***
  process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        counter_s <= 0;
        str_dff_s <= '0';
        vld_o    <= '0';
      else
        str_dff_s <= vld_i;
        vld_o    <= '0';
        if str_dff_s = '0' and vld_i = '1' then
          if (counter_s = unsigned(ratio_i) - 1) or (unsigned(ratio_i) = 0) then -- No division for illegal InRatio = 0 condition
            counter_s <= 0;
            vld_o    <= '1';
          else
            counter_s <= counter_s + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
end architecture;
