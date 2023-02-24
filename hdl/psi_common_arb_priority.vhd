------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements an efficient priority arbiter. The highest index of
-- the input has priority.

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
-- $$ processes=stimuli $$
entity psi_common_arb_priority is
  generic(
    size_g    : natural := 8;           -- $$ constant=5 $$
    out_reg_g : boolean := true         -- $$ constant=true &&
  );
  port(
    clk_i   : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    rst_i   : in  std_logic;            -- $$ type=rst; clk=Clk $$
    req_i   : in  std_logic_vector(size_g - 1 downto 0);
    grant_o : out std_logic_vector(size_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_arb_priority is

  signal Grant_I : std_logic_vector(grant_o'range);

begin

  -- Only generate code for non-zero sized arbiters to avoid illegal range delcarations
  g_non_zero : if size_g > 0 generate

    --------------------------------------------------------------------------
    -- Combinatorial Process
    --------------------------------------------------------------------------
    p_comb : process(req_i)
      variable OredRequest_v : std_logic_vector(req_i'range);
    begin
      -- Or request vector
      OredRequest_v := ppc_or(req_i);

      -- Calculate Grant with Edge Detection
      Grant_I <= OredRequest_v and not ('0' & OredRequest_v(OredRequest_v'high downto 1));
    end process;

    --------------------------------------------------------------------------
    -- Output Handling
    --------------------------------------------------------------------------
    -- Registered
    g_reg : if out_reg_g generate
      p_outreg : process(clk_i)
      begin
        if rising_edge(clk_i) then
          if rst_i = '1' then
            grant_o <= (others => '0');
          else
            grant_o <= Grant_I;
          end if;
        end if;
      end process;
    end generate;

    g_nreg : if not out_reg_g generate
      grant_o <= Grant_I;
    end generate;
  end generate;

end architecture;
