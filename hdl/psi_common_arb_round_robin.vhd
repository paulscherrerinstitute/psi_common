------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements an efficient round-robin arbiter.

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
entity psi_common_arb_round_robin is
  generic(
    size_g : natural := 8               -- $$ constant=5 $$
  );
  port(
    -- Control Signals
    clk_i       : in  std_logic;          -- $$ type=clk; freq=100e6 $$
    rst_i       : in  std_logic;          -- $$ type=rst; clk=Clk $$

    -- Data Ports
    request_i   : in  std_logic_vector(size_g - 1 downto 0);
    grant_o     : out std_logic_vector(size_g - 1 downto 0);
    grant_rdy_o : in  std_logic;
    grant_vld_o : out std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

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
  g_non_zero : if size_g > 0 generate

    --------------------------------------------------------------------------
    -- Combinatorial Process
    --------------------------------------------------------------------------
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

    --------------------------------------------------------------------------
    -- Sequential Process
    --------------------------------------------------------------------------	
    p_seq : process(clk_i)
    begin
      if rising_edge(clk_i) then
        r <= r_next;
        if rst_i = '1' then
          r.Mask <= (others => '0');
        end if;
      end if;
    end process;

    --------------------------------------------------------------------------
    -- Component Instantiations
    --------------------------------------------------------------------------		
    i_prio_masked : entity work.psi_common_arb_priority
      generic map(
        size_g           => size_g,
        out_reg_g => false
      )
      port map(
        clk_i     => clk_i,
        rst_i     => rst_i,
        req_i => RequestMasked,
        grant_o   => GrantMasked
      );

    i_prio_unmasked : entity work.psi_common_arb_priority
      generic map(
        size_g           => size_g,
        out_reg_g => false
      )
      port map(
        clk_i     => clk_i,
        rst_i     => rst_i,
        req_i => request_i,
        grant_o   => GrantUnmasked
      );
  end generate;

end rtl;
