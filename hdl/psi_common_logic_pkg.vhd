------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_common_logic_pkg is

  function zeros_vector(size : in natural) return std_logic_vector;

  function ones_vector(size : in natural) return std_logic_vector;

  function partially_ones_vector(size    : in natural;
                                 ones_nb : in natural)
  return std_logic_vector;

  function shift_left(arg  : in std_logic_vector;
                      bits : in integer;
                      fill : in std_logic := '0')
  return std_logic_vector;

  function shift_right(arg  : in std_logic_vector;
                       bits : in integer;
                       fill : in std_logic := '0')
  return std_logic_vector;

  function binary_to_gray(binary : in std_logic_vector)
  return std_logic_vector;

  function gray_to_binary(gray : in std_logic_vector)
  return std_logic_vector;

  -- Parallel Prefix Computation of the OR function
  -- Input 	--> Output
  -- 0100		--> 0111
  -- 0101		--> 0111
  -- 0011		--> 0011
  -- 0010		--> 0011
  function ppc_or(inp : in std_logic_vector)
  return std_logic_vector;

  function int_to_std_logic(int : in integer)
  return std_logic;

  function reduce_or(vec : in std_logic_vector)
  return std_logic;

  function reduce_and(vec : in std_logic_vector)
  return std_logic;

  function to_01X(inp : in std_logic)
  return std_logic;

  function to_01X(inp : in std_logic_vector)
  return std_logic_vector;

  function invert_bit_order(inp : in std_logic_vector)
  return std_logic_vector;

end psi_common_logic_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_common_logic_pkg is

  -- *** ZerosVector ***
  function zeros_vector(size : in natural) return std_logic_vector is
    constant c : std_logic_vector(size - 1 downto 0) := (others => '0');
  begin
    return c;
  end function;

  -- *** OnesVector ***
  function ones_vector(size : in natural) return std_logic_vector is
    constant c : std_logic_vector(size - 1 downto 0) := (others => '1');
  begin
    return c;
  end function;

  -- *** PartiallyOnesVector ***
  function partially_ones_vector(size    : in natural;
                                 ones_nb : in natural)
  return std_logic_vector is
    variable v_low    : std_logic_vector(size downto 0);
    variable v_high   : std_logic_vector(size downto 0);
    variable v_plus_1 : std_logic_vector(size + 1 downto 0); -- We need this to avoid synthesis problems with Xilinx ISE
    variable v        : std_logic_vector(size - 1 downto 0);
  begin
    v_low    := (others => '1');
    v_high   := (others => '0');
    v_plus_1 := v_high(size - ones_nb downto 0) & v_low(ones_nb downto 0);
    v        := v_plus_1(size downto 1);
    return v;
  end function;

  -- *** ShiftLeft ***
  function shift_left(arg  : in std_logic_vector;
                      bits : in integer;
                      fill : in std_logic := '0')
  return std_logic_vector is
    constant argDt : std_logic_vector(arg'high downto arg'low) := arg;
    variable v     : std_logic_vector(argDt'range);
  begin
    if bits < 0 then
      return shift_right(argDt, -bits, fill);
    else
      v(v'left downto bits)      := argDt(argDt'left - bits downto argDt'right);
      v(bits - 1 downto v'right) := (others => fill);
      return v;
    end if;
  end function;

  -- *** ShiftRight ***
  function shift_right(arg  : in std_logic_vector;
                       bits : in integer;
                       fill : in std_logic := '0')
  return std_logic_vector is
    constant argDt : std_logic_vector(arg'high downto arg'low) := arg;
    variable v     : std_logic_vector(argDt'range);
  begin
    if bits < 0 then
      return shift_left(argDt, -bits, fill);
    else
      v(v'left - bits downto v'right)    := argDt(argDt'left downto bits);
      v(v'left downto v'left - bits + 1) := (others => fill);
      return v;
    end if;
  end function;

  -- *** BinaryToGray ***
  function binary_to_gray(binary : in std_logic_vector)
  return std_logic_vector is
    variable Gray_v : std_logic_vector(binary'range);
  begin
    Gray_v := binary xor ('0' & binary(binary'high downto binary'low + 1));
    return Gray_v;
  end function;

  -- *** GrayToBinary ***
  function gray_to_binary(gray : in std_logic_vector)
  return std_logic_vector is
    variable Binary_v : std_logic_vector(gray'range);
  begin
    Binary_v(Binary_v'high) := gray(gray'high);
    for b in gray'high - 1 downto gray'low loop
      Binary_v(b) := gray(b) xor Binary_v(b + 1);
    end loop;
    return Binary_v;
  end function;

  -- *** PpcOr ***
  function ppc_or(inp : in std_logic_vector)
  return std_logic_vector is
    constant Stages_c    : integer := log2ceil(inp'length);
    constant Pwr2Width_c : integer := 2**Stages_c;
    type StageOut_t is array (natural range <>) of std_logic_vector(Pwr2Width_c - 1 downto 0);
    variable StageOut_v  : StageOut_t(0 to Stages_c);
    variable BinCnt_v    : unsigned(Pwr2Width_c - 1 downto 0);
  begin
    StageOut_v(0)                          := (others => '0');
    StageOut_v(0)(inp'length - 1 downto 0) := inp;
    for stage in 0 to Stages_c - 1 loop
      BinCnt_v := (others => '0');
      for idx in 0 to Pwr2Width_c - 1 loop
        if BinCnt_v(stage) = '0' then
          StageOut_v(stage + 1)(idx) := StageOut_v(stage)(idx) or StageOut_v(stage)((idx / (2**stage) + 1) * 2**stage);
        else
          StageOut_v(stage + 1)(idx) := StageOut_v(stage)(idx);
        end if;
        BinCnt_v := BinCnt_v + 1;
      end loop;
    end loop;
    return StageOut_v(Stages_c)(inp'length - 1 downto 0);
  end function;

  function int_to_std_logic(int : in integer)
  return std_logic is
  begin
    if int = 1 then
      return '1';
    elsif int = 0 then
      return '0';
    else
      return 'X';
    end if;
  end function;

  function reduce_or(vec : in std_logic_vector)
  return std_logic is
    variable tmp : std_logic;
  begin
    tmp := '0';
    for i in vec'low to vec'high loop
      tmp := tmp or vec(i);
    end loop;
    return tmp;
  end function;

  function reduce_and(vec : in std_logic_vector)
  return std_logic is
    variable tmp : std_logic;
  begin
    tmp := '1';
    for i in vec'low to vec'high loop
      tmp := tmp and vec(i);
    end loop;
    return tmp;
  end function;

  function to_01X(inp : in std_logic)
  return std_logic is
  begin
    case inp is
      when '0' | 'L' => return '0';
      when '1' | 'H' => return '1';
      when others    => return 'X';
    end case;
  end function;

  function to_01X(inp : in std_logic_vector)
  return std_logic_vector is
    variable tmp : std_logic_vector(inp'range);
  begin
    for i in inp'low to inp'high loop
      tmp(i) := to_01X(inp(i));
    end loop;
    return tmp;
  end function;

  function invert_bit_order(inp : in std_logic_vector)
  return std_logic_vector is
    variable tmp : std_logic_vector(inp'range);
  begin
    for i in inp'low to inp'high loop
      tmp(tmp'high - i) := inp(i);
    end loop;
    return tmp;
  end function;

end package body;