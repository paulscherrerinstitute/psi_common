------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a clock crossing between two synchronous clocks where
-- the output clock period is an integer multiple of the input clock period
-- (input clock frequency is an integer multiple of the output clock frequency).

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
-- $$ processes=stim,check $$
entity psi_common_sync_cc_xn2n is
  generic(
    width_g : integer := 8
  );
  port(
    -- Input
    clk_i   : in  std_logic;            -- $$ type=clk; freq=200e6 $$
    rst_i   : in  std_logic;            -- $$ type=rst; clk=InClk $$
    vld_i   : in  std_logic;
    rdy_o   : out std_logic;
    dat_i  : in  std_logic_vector(width_g - 1 downto 0);
    -- Output
    clk_o  : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    rst_o  : in  std_logic := '0';     -- $$ type=rst; clk=OutClk $$
    vld_o  : out std_logic;
    rdy_i  : in  std_logic := '1';
    dat_o : out std_logic_vector(width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_sync_cc_xn2n is

  -- Input Side
  signal InCnt         : unsigned(1 downto 0);
  signal InDataReg     : std_logic_vector(width_g - 1 downto 0);
  signal InDataRegLast : std_logic_vector(width_g - 1 downto 0);

  -- Output Side
  signal OutCnt   : unsigned(1 downto 0);
  signal OutVld_I : std_logic;

begin

  rdy_o <= '1' when InCnt - OutCnt /= 2 else '0';

  p_input : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if (rst_i = '1') or (rst_o = '1') then
        InCnt <= (others => '0');
      else
        if vld_i = '1' and InCnt - OutCnt /= 2 then
          InCnt         <= InCnt + 1;
          InDataReg     <= dat_i;
          InDataRegLast <= InDataReg;
        end if;
      end if;
    end if;
  end process;

  p_output : process(clk_o)
  begin
    if rising_edge(clk_o) then
      if (rst_i = '1') or (rst_o = '1') then
        OutCnt   <= (others => '0');
        OutVld_I <= '0';
      else
        -- New sample was acknowledged
        if OutVld_I = '1' and rdy_i = '1' then
          OutVld_I <= '0';
        end if;
        -- Forward new sample to output if ready
        if InCnt /= OutCnt and (OutVld_I = '0' or rdy_i = '1') then
          if InCnt - OutCnt = 1 then
            dat_o <= InDataReg;
          else
            dat_o <= InDataRegLast;
          end if;
          OutVld_I <= '1';
          OutCnt   <= OutCnt + 1;
        end if;
      end if;
    end if;
  end process;

  vld_o <= OutVld_I;

end;

