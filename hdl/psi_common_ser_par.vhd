------------------------------------------------------------------------------
-- Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component implements serialized to parllel data with a load input
-- and generics number to define the length of vector input.
-- Data bit 0 is rx last when msb_g if set true; if false bit 0 rx first
-- An error bit is active when a valid in occured while the serializer didn't 
-- finish its task.
-- A valid output strobe arises when data have been parallelized
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
-- @formatter:off
entity psi_common_ser_par is
  generic(rst_pol_g : std_logic := '1';                            -- reset polarity
          width_g   : natural   := 16;                             -- vector width
          msb_g     : boolean   := false);                         -- MSB first = true
  port(   clk_i     : in  std_logic;                               -- clock system
          rst_i     : in  std_logic;                               -- reset system
          dat_i     : in  std_logic;                               -- data in
          ld_i      : in  std_logic;                               -- load in
          vld_i     : in  std_logic;                               -- valid/strobe 
          dat_o     : out std_logic_vector(width_g - 1 downto 0);  -- data out
          err_o     : out std_logic;                               -- error out when input too fast
          vld_o     : out std_logic);                              -- valid/strobe
end entity;
-- @formatter:on
architecture RTL of psi_common_ser_par is

  type two_process_t is record
    cnt : unsigned(log2ceil(width_g) - 1 downto 0);
    dat : std_logic_vector(width_g - 1 downto 0);
    reg : std_logic_vector(width_g - 1 downto 0);
    vld : std_logic;
    err : std_logic;
    --
    i_dat : std_logic;
    i_vld : std_logic;
    i_ld  : std_logic;
  end record;

  signal r, r_next : two_process_t;

begin

  proc_comb : process(r, ld_i, dat_i, vld_i)
    variable v : two_process_t;
  begin
    -- *** r => v ***
    v:= r;
    
    --*** DFF in ***
    v.i_dat := dat_i;
    v.i_vld := vld_i;
    v.i_ld  := ld_i;
    
    --*** deserialize statement & MSB/LSB first mngt ***
    if r.i_ld='1' or (r.cnt = width_g - 1 and r.i_vld = '1') then
      v.cnt := (others => '0');
      v.reg := r.dat;
      v.vld := '1';
    elsif r.cnt < width_g - 1 then
      if r.i_vld = '1' then
        v.cnt := r.cnt + 1;
      end if;
      v.vld := '0';
    end if;

    --*** shifter ***
    if r.i_vld = '1' then
      if msb_g then
        v.dat := r.dat(width_g - 2 downto 0) & r.i_dat;
      else
        v.dat := r.i_dat & r.dat(width_g - 1 downto 1);
      end if;
    end if;

    --*** error when deserialize process isn't complete ***
    if r.i_ld = '1' and r.cnt /= width_g - 1 then
      v.err := '1';
      v.vld := '0';
      v.reg := r.reg;
    else
      v.err := '0';
    end if;

    --*** v => r next ***
    r_next <= v;
  end process;

  --*** output map ***
  dat_o <= r.reg;
  vld_o <= r.vld;
  err_o <= r.err;

  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.vld <= '0';
        r.dat <= (others => '0');
        r.cnt <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
