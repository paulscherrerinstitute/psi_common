------------------------------------------------------------------------------
--  Copyright (c) 2020 by Oliver Bründler
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a dynamic shift implemented in multiple stages in 
-- order to achieve good timing.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ processes=inp,outp $$
entity psi_common_dyn_sft is
  generic(
    Direction_g           : string  	:= "LEFT";	-- $$ export=true $$ 	LEFT or RIGHT
    SelectBitsPerStage_g  : positive 	:= 4;       -- $$ export=true $$ 
    MaxShift_g            : positive  := 16;      -- $$ constant=20 $$ 
    Width_g               : positive  := 32;      -- $$ constant=32 $$
    SignExtend_g          : boolean   := true     -- $$ export=true $$
  );
  port(
    -- Control Signals
    Clk         : in  std_logic;        -- $$ type=clk; freq=100e6 $$
    Rst         : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -- Data Ports
    InVld       : in  std_logic;
    InShift     : in  std_logic_vector(log2ceil(MaxShift_g+1)-1 downto 0);
    InData      : in  std_logic_vector(Width_g-1 downto 0);
    OutVld      : out std_logic;
    OutData     : out std_logic_vector(Width_g-1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_dyn_sft is

  -- Constants
  constant Stages_c   : integer := integer(ceil(real(InShift'length)/real(SelectBitsPerStage_g)));
  
  -- Types
  type Data_a   is array (natural range <>) of std_logic_vector(InData'range);
  type Shift_a  is array (natural range <>) of std_logic_vector(InShift'range);

  -- Two Process Method
  type two_process_r is record
    Vld   : std_logic_vector(0 to Stages_c);
    Data  : Data_a(0 to Stages_c);
    Shift : Shift_a(0 to Stages_c);
  end record;
  signal r, r_next : two_process_r;
begin

  -- *** Assertions ***
  assert Direction_g = "LEFT" or Direction_g = "RIGHT" report "###ERROR###: psi_common_dyn_sft - Direction_g must be LEFT or RIGHT" severity error;

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, InVld, InData, InShift)
    variable v : two_process_r;
    variable StepSize_v : natural;
    variable Fill_v     : std_logic;
    variable Select_v   : natural range 0 to 2**SelectBitsPerStage_g-1;
    variable TempData_v : std_logic_vector(Width_g*2-1 downto 0);
  begin
    -- hold variables stable
    v := r;
    
    -- Input stages
    v.Data(0)   := InData;
    v.Shift(0)  := InShift;
    v.Vld(0)    := InVld;
    
    -- Shift stages
    for stg in 0 to Stages_c-1 loop
      -- Stage constants calculation
      StepSize_v := 2**(stg*SelectBitsPerStage_g);
      
      -- Shift implementation
      Select_v := to_integer(unsigned(r.Shift(stg)(SelectBitsPerStage_g-1 downto 0)));
      if Direction_g = "RIGHT" then
        if SignExtend_g then
          TempData_v := (others => r.Data(stg)(Width_g-1));
        else
          TempData_v := (others => '0');
        end if;
        TempData_v(2*Width_g-1-Select_v*StepSize_v downto Width_g-Select_v*StepSize_v) := r.Data(stg);
         v.Data(stg+1) := TempData_v(2*Width_g-1 downto Width_g);
      elsif Direction_g = "LEFT" then
        TempData_v := (others => '0');
        TempData_v(Select_v*StepSize_v+Width_g-1 downto Select_v*StepSize_v) := r.Data(stg);
        v.Data(stg+1) := TempData_v(Width_g-1 downto 0);
      else
        report "###ERROR###: psi_common_dyn_sft - Direction_g must be LEFT or RIGHT, is '" & Direction_g & "'" severity error;
      end if;
      v.Shift(stg+1)  := ShiftRight(r.Shift(stg), SelectBitsPerStage_g, '0'); 
      v.Vld(stg+1)    := r.Vld(stg);
    end loop;

    -- Outputs
    OutData <= r.Data(Stages_c);
    OutVld  <= r.Vld(Stages_c);

    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------	
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.Vld <= (others => '0');
      end if;
    end if;
  end process;

end rtl;
