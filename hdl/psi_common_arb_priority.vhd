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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- @formatter:off
entity psi_common_arb_priority is
  generic(width_g    : natural   := 8;                             -- size of the arbiter
          out_reg_g : boolean   := true;                           -- True = Registered output False = Combinatorial output
          rst_pol_g : std_logic :='1');                            -- reset polarity
  port(   clk_i     : in  std_logic;                               -- clock
          rst_i     : in  std_logic;                               -- reset
          req_i     : in  std_logic_vector(width_g - 1 downto 0);  -- Request input signals, The highest (left-most) bit has highest priority
          grant_o   : out std_logic_vector(width_g - 1 downto 0)   -- Grant output signal
        );
end entity;
-- @formatter:on
architecture rtl of psi_common_arb_priority is

  signal Grant_I : std_logic_vector(grant_o'range);

begin

  -- Only generate code for non-zero sized arbiters to avoid illegal range delcarations
  g_non_zero : if width_g > 0 generate

    p_comb : process(req_i)
      variable OredRequest_v : std_logic_vector(req_i'range);
    begin
      -- Or request vector
      OredRequest_v := ppc_or(req_i);

      -- Calculate Grant with Edge Detection
      Grant_I <= OredRequest_v and not ('0' & OredRequest_v(OredRequest_v'high downto 1));
    end process;

    -- Registered
    g_reg : if out_reg_g generate
      p_outreg : process(clk_i)
      begin
        if rising_edge(clk_i) then
          if rst_i = rst_pol_g then
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
