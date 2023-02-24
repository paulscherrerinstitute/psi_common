------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple data-width conversion. The input width
-- must be an integer multiple of the output width (Wi = n*Wo)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=stim,check $$
entity psi_common_wconv_xn2n is
  generic(
    in_width_g  : natural;              -- $$ constant=16 $$
    out_width_g : natural               -- $$ constant=4 $$
  );
  port(
    -- Control Signals
    clk_i  : in  std_logic;             -- $$ type=clk; freq=100e6 $$
    rst_i  : in  std_logic;             -- $$ type=rst; clk=Clk $$

    -- Input
    vld_i  : in  std_logic;
    rdy_o  : out std_logic;
    dat_i  : in  std_logic_vector(in_width_g - 1 downto 0);
    last_i : in  std_logic                                               := '0';
    we_i   : in  std_logic_vector(in_width_g / out_width_g - 1 downto 0) := (others => '1');
    -- Output
    vld_o  : out std_logic;
    rdy_i  : in  std_logic                                               := '1';
    dat_o  : out std_logic_vector(out_width_g - 1 downto 0);
    last_o : out std_logic
  );
end entity;

architecture rtl of psi_common_wconv_xn2n is

  -- *** Constants ***
  constant RatioReal_c : real    := real(in_width_g) / real(out_width_g);
  constant RatioInt_c  : integer := integer(RatioReal_c);

  -- *** Two Process Method ***
  type two_process_r is record
    Data     : std_logic_vector(in_width_g - 1 downto 0);
    DataVld  : std_logic_vector(RatioInt_c - 1 downto 0);
    DataLast : std_logic_vector(RatioInt_c - 1 downto 0);
  end record;
  signal r, r_next : two_process_r;

begin
  assert floor(RatioReal_c) = ceil(RatioReal_c) report "psi_common_wconv_xn2n: Ratio out_width_g/in_width_g must be an integer number" severity error;

  p_comb : process(r, vld_i, dat_i, rdy_i, we_i, last_i)
    variable v         : two_process_r;
    variable IsReady_v : std_logic;
  begin
    -- *** hold variables stable ***
    v := r;

    -- Halt detection
    IsReady_v := '1';
    if unsigned(r.DataVld(r.DataVld'high downto 1)) /= 0 then
      IsReady_v := '0';
    elsif r.DataVld(0) = '1' and rdy_i = '0' then
      IsReady_v := '0';
    end if;

    -- Get new data
    if IsReady_v = '1' and vld_i = '1' then
      v.Data                     := dat_i;
      v.DataVld                  := we_i;
      -- Assert last to the correct data-word
      for i in 0 to RatioInt_c - 2 loop
        v.DataLast(i) := we_i(i) and not we_i(i + 1) and last_i;
      end loop;
      v.DataLast(RatioInt_c - 1) := we_i(RatioInt_c - 1) and last_i;
    elsif (rdy_i = '1') and (unsigned(r.DataVld) /= 0) then
      v.Data     := zeros_vector(out_width_g) & r.Data(r.Data'left downto out_width_g);
      v.DataVld  := '0' & r.DataVld(r.DataVld'left downto 1);
      v.DataLast := '0' & r.DataLast(r.DataLast'left downto 1);
    end if;

    -- Outputs
    dat_o  <= r.Data(out_width_g - 1 downto 0);
    rdy_o  <= IsReady_v;
    vld_o  <= r.DataVld(0);
    last_o <= r.DataLast(0);

    -- *** assign signal ***
    r_next <= v;
  end process;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = '1' then
        r.DataVld <= (others => '0');
      end if;
    end if;
  end process;

end process;
