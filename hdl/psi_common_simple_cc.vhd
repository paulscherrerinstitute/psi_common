------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic clock crossing that allows passing single samples of data
-- from one clock domain to another. It only works if sample rates are significantly
-- lower than the clock speed of both domains.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- @formatter:off
entity psi_common_simple_cc is
  generic(width_g      : positive := 16;
          a_rst_pol_g  : std_logic:='1';
          b_rst_pol_g  : std_logic:='1');
  port(   a_clk_i      : in  std_logic;
          a_rst_i      : in  std_logic;
          a_rst_o      : out std_logic;
          a_dat_i      : in  std_logic_vector(width_g - 1 downto 0);
          a_vld_i      : in  std_logic;
          b_clk_i      : in  std_logic;
          b_rst_i      : in  std_logic;
          b_rst_o      : out std_logic;
          b_dat_o      : out std_logic_vector(width_g - 1 downto 0);
          b_vld_o      : out std_logic);
end entity;
-- @formatter:on

architecture rtl of psi_common_simple_cc is
  -- Domain A signals
  signal RstAI      : std_logic;
  signal DataLatchA : std_logic_vector(width_g - 1 downto 0);
  -- Domain B signals
  signal RstBI      : std_logic;
  signal VldBI      : std_logic;

begin

  i_pulse_cc : entity work.psi_common_pulse_cc
    generic map(
      num_pulses_g => 1,
      a_rst_pol_g => a_rst_pol_g,
      b_rst_pol_g => b_rst_pol_g
    )
    port map(
      a_clk_i    => a_clk_i,
      a_rst_i    => a_rst_i,
      a_rst_o    => RstAI,
      a_dat_i(0) => a_vld_i,
      b_clk_i    => b_clk_i,
      b_rst_i    => b_rst_i,
      b_rst_o    => RstBI,
      b_dat_o(0) => VldBI
    );
  a_rst_o <= RstAI;
  b_rst_o <= RstBI;

  -- Data transmit side (A)
  DataA_p : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if RstAI = a_rst_pol_g then
        DataLatchA <= (others => '0');
      else
        if a_vld_i = '1' then
          DataLatchA <= a_dat_i;
        end if;
      end if;
    end if;
  end process;

  -- Data receive side (B)
  DataB_p : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if RstBI = b_rst_pol_g then
        b_dat_o <= (others => '0');
        b_vld_o <= '0';
      else
        b_vld_o <= VldBI;
        if VldBI = '1' then
          b_dat_o <= DataLatchA;
        end if;
      end if;
    end if;
  end process;
  
end architecture;

