------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements an efficient round-robin arbiter.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

entity psi_common_arb_round_robin is
  generic( width_g    : natural := 8;                                 -- Size of the arbiter (number of input/output bits)
          rst_pol_g   : std_logic := '1');                            -- reset polarity
  port(   clk_i       : in  std_logic;                                -- system clock
          rst_i       : in  std_logic;                                -- system reset (sync)
          request_i   : in  std_logic_vector(width_g - 1 downto 0);   -- Request input signals, The highest(left-most) bit has highest priority  
          grant_o     : out std_logic_vector(width_g - 1 downto 0);   -- Grant output signal 
          grant_rdy_o : in  std_logic;                                -- AXI-S handshaking signal, Asserted whenever Grant != 0
          grant_vld_o : out std_logic);                               -- AXI-S handshaking signal The state of the  arbiter is updated  upon*Grant_Rdy =   '1'*
end entity;

architecture rtl of psi_common_arb_round_robin is

  -- Two Process Method
  type two_process_r is record
    Mask : std_logic_vector(request_i'range);
  end record;
  signal r, r_next : two_process_r;

  signal RequestMasked : std_logic_vector(request_i'range);
  signal GrantMasked   : std_logic_vector(grant_o'range);
  signal GrantUnmasked : std_logic_vector(grant_o'range);
begin
  -- Only generate code for non-zero sized arbiters to avoid illegal range delcarations
  g_non_zero : if width_g > 0 generate

    p_comb : process(r, request_i, grant_rdy_o, GrantMasked, GrantUnmasked)
      variable v       : two_process_r;
      variable Grant_v : std_logic_vector(grant_o'range);
    begin
      -- hold variables stable
      v := r;

      -- Round Robing Logic
      RequestMasked <= request_i and r.Mask;

      -- Generate Grant
      if unsigned(GrantMasked) = 0 then
        Grant_v := GrantUnmasked;
      else
        Grant_v := GrantMasked;
      end if;

      -- Update mask
      if (unsigned(Grant_v) /= 0) and (grant_rdy_o = '1') then
        v.Mask := '0' & ppc_or(Grant_v(Grant_v'high downto 1));
      end if;

      -- *** Outputs ***
      if unsigned(Grant_v) /= 0 then
        grant_vld_o <= '1';
      else
        grant_vld_o <= '0';
      end if;
      grant_o <= Grant_v;

      -- Apply to record
      r_next <= v;

    end process;

    p_seq : process(clk_i)
    begin
      if rising_edge(clk_i) then
        r <= r_next;
        if rst_i = rst_pol_g then
          r.Mask <= (others => '0');
        end if;
      end if;
    end process;

    i_prio_masked : entity work.psi_common_arb_priority
      generic map(
        width_g => width_g,
        out_reg_g => false,
        rst_pol_g => rst_pol_g
      )
      port map(
        clk_i   => clk_i,
        rst_i   => rst_i,
        req_i   => RequestMasked,
        grant_o => GrantMasked
      );

    i_prio_unmasked : entity work.psi_common_arb_priority
      generic map(
        width_g => width_g,
        out_reg_g => false,
        rst_pol_g => rst_pol_g
      )
      port map(
        clk_i   => clk_i,
        rst_i   => rst_i,
        req_i   => request_i,
        grant_o => GrantUnmasked
      );
  end generate;

end architecture;
