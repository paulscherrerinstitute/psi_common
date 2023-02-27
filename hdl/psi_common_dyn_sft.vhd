------------------------------------------------------------------------------
--  Copyright (c) 2020 by Oliver BrÃÂÃÂ¼ndler
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a dynamic shift implemented in multiple stages in
-- order to achieve good timing.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=inp,outp $$
entity psi_common_dyn_sft is
  generic(
    direction_g         : string   := "LEFT"; -- $$ export=true $$ 	LEFT or RIGHT
    sel_bit_per_stage_g : positive := 4;      -- $$ export=true $$
    max_shift_g         : positive := 16;     -- $$ constant=20 $$
    width_g             : positive := 32;     -- $$ constant=32 $$
    sign_extend_g       : boolean  := true;   -- $$ export=true $$
    rst_pol_g           : std_logic:= '1'
  );
  port(
    clk_i   : in  std_logic;                  -- $$ type=clk; freq=100e6 $$
    rst_i   : in  std_logic;                  -- $$ type=rst; clk=Clk $$
    vld_i   : in  std_logic;
    shift_i : in  std_logic_vector(log2ceil(max_shift_g + 1) - 1 downto 0);
    dat_i   : in  std_logic_vector(width_g - 1 downto 0);
    vld_o   : out std_logic;
    dat_o   : out std_logic_vector(width_g - 1 downto 0)
  );
end entity;

architecture rtl of psi_common_dyn_sft is

  -- Constants
  constant Stages_c : integer := integer(ceil(real(shift_i'length) / real(sel_bit_per_stage_g)));

  -- Types
  type Data_a is array (natural range <>) of std_logic_vector(dat_i'range);
  type Shift_a is array (natural range <>) of std_logic_vector(shift_i'range);

  -- Two Process Method
  type two_process_r is record
    Vld   : std_logic_vector(0 to Stages_c);
    Data  : Data_a(0 to Stages_c);
    Shift : Shift_a(0 to Stages_c);
  end record;
  signal r, r_next : two_process_r;
begin

  -- *** Assertions ***
  assert direction_g = "LEFT" or direction_g = "RIGHT" report "###ERROR###: psi_common_dyn_sft - direction_g must be LEFT or RIGHT" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, vld_i, dat_i, shift_i)
    variable v          : two_process_r;
    variable StepSize_v : natural;
    variable Select_v   : natural range 0 to 2**sel_bit_per_stage_g - 1;
    variable TempData_v : std_logic_vector(width_g * 2 - 1 downto 0);
  begin
    -- hold variables stable
    v := r;

    -- Input stages
    v.Data(0)  := dat_i;
    v.Shift(0) := shift_i;
    v.Vld(0)   := vld_i;

    -- Shift stages
    for stg in 0 to Stages_c - 1 loop
      -- Stage constants calculation
      StepSize_v := 2**(stg * sel_bit_per_stage_g);

      -- Shift implementation
      Select_v         := to_integer(unsigned(r.Shift(stg)(sel_bit_per_stage_g - 1 downto 0)));
      if direction_g = "RIGHT" then
        if sign_extend_g then
          TempData_v := (others => r.Data(stg)(width_g - 1));
        else
          TempData_v := (others => '0');
        end if;
        TempData_v(2 * width_g - 1 - Select_v * StepSize_v downto width_g - Select_v * StepSize_v) := r.Data(stg);
        v.Data(stg + 1)                                                                            := TempData_v(2 * width_g - 1 downto width_g);
      elsif direction_g = "LEFT" then
        TempData_v                                                                   := (others => '0');
        TempData_v(Select_v * StepSize_v + width_g - 1 downto Select_v * StepSize_v) := r.Data(stg);
        v.Data(stg + 1)                                                              := TempData_v(width_g - 1 downto 0);
      else
        report "###ERROR###: psi_common_dyn_sft - direction_g must be LEFT or RIGHT, is '" & direction_g & "'" severity error;
      end if;
      v.Shift(stg + 1) := shift_right(r.Shift(stg), sel_bit_per_stage_g, '0');
      v.Vld(stg + 1)   := r.Vld(stg);
    end loop;

    -- Outputs
    dat_o <= r.Data(Stages_c);
    vld_o <= r.Vld(Stages_c);

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
      if rst_i = rst_pol_g then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end architecture;
