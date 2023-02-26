------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a clock crossing between two synchronous clocks where
-- the input clock period is an integer multiple of the output clock period
-- (output clock frequency is an integer multiple of the input clock frequency).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- $$ processes=stim,check $$
entity psi_common_sync_cc_n2xn is
  generic(
    width_g       : integer   := 8;
    in_rst_pol_g  : std_logic := '1';
    out_rst_pol_g : std_logic := '1'
  );
  port(
    -- Input
    in_clk_i  : in  std_logic;          -- $$ type=clk; freq=100e6 $$
    in_rst_i  : in  std_logic;          -- $$ type=rst; clk=InClk $$
    vld_i     : in  std_logic;
    in_rdy_o  : out std_logic;
    dat_i     : in  std_logic_vector(width_g - 1 downto 0);
    -- Output
    out_clk_i : in  std_logic;          -- $$ type=clk; freq=200e6 $$
    out_rst_i : in  std_logic := '0';   -- $$ type=rst; clk=OutClk $$
    vld_o     : out std_logic;
    out_rdy_i : in  std_logic := '1';
    dat_o     : out std_logic_vector(width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_sync_cc_n2xn is

  -- Input Side
  signal InCnt     : unsigned(1 downto 0);
  signal InDataReg : std_logic_vector(width_g - 1 downto 0);

  -- Output Side
  signal OutCnt   : unsigned(1 downto 0);
  signal OutVld_I : std_logic;

begin

  in_rdy_o <= '1' when InCnt - OutCnt /= 2 else '0';

  p_input : process(in_clk_i)
  begin
    if rising_edge(in_clk_i) then
      if (in_rst_i = in_rst_pol_g) or (out_rst_i = out_rst_pol_g) then
        InCnt <= (others => '0');
      else
        if vld_i = '1' and InCnt - OutCnt /= 2 then
          InCnt     <= InCnt + 1;
          InDataReg <= dat_i;
        end if;
      end if;
    end if;
  end process;

  p_output : process(out_clk_i)
  begin
    if rising_edge(out_clk_i) then
      if (in_rst_i = in_rst_pol_g) or (out_rst_i = out_rst_pol_g) then
        OutCnt   <= (others => '0');
        OutVld_I <= '0';
      else
        -- Forward new sample to output
        if InCnt /= OutCnt and (OutVld_I = '0' or out_rdy_i = '1') then
          dat_o    <= InDataReg;
          OutVld_I <= '1';
        end if;
        -- New sample was acknowledged
        if OutVld_I = '1' and out_rdy_i = '1' then
          OutVld_I <= '0';
          OutCnt   <= OutCnt + 1;
        end if;
      end if;
    end if;
  end process;

  vld_o <= OutVld_I;

end architecture;
