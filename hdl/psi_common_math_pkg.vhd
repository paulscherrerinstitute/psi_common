------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.psi_common_array_pkg.all;

------------------------------------------------------------------------------
-- Package Header
------------------------------------------------------------------------------
package psi_common_math_pkg is

  function log2(arg : in natural) return natural;

  function log2ceil(arg : in natural) return natural;

  function log2ceil(arg : in real) return natural;

  function isLog2(arg : in natural) return boolean;

  function max(a : in integer;
               b : in integer) return integer;

  function min(a : in integer;
               b : in integer) return integer;
    
  function max(a : in real;
               b : in real) return real;

  function min(a : in real;
               b : in real) return real;

  -- choose t if s=true else f
  function choose(s : in boolean;
                  t : in std_logic;
                  f : in std_logic) return std_logic;

  function choose(s : in boolean;
                  t : in std_logic_vector;
                  f : in std_logic_vector) return std_logic_vector;

  function choose(s : in boolean;
                  t : in integer;
                  f : in integer) return integer;

  function choose(s : in boolean;
                  t : in string;
                  f : in string) return string;

  function choose(s : in boolean;
                  t : in real;
                  f : in real) return real;

  function choose(s : in boolean;
                  t : in unsigned;
                  f : in unsigned) return unsigned;

  function choose(s : in boolean;
                  t : in boolean;
                  f : in boolean) return boolean;
				  
  function choose(s : in boolean;
                  t : in t_areal;
                  f : in t_areal) return t_areal;

  -- count occurence of a value inside an array
  function count(a : in t_ainteger;
                 v : in integer) return integer;

  function count(a : in t_abool;
                 v : in boolean) return integer;

  function count(a : in std_logic_vector;
                 v : in std_logic) return integer;

  -- conversion function int to slv
  function to_uslv(input : integer;
                   len   : integer) return std_logic_vector;

  function to_sslv(input : integer;
                   len   : integer) return std_logic_vector;

  -- conversion function slv to int
  function from_uslv(input : std_logic_vector) return integer;

  function from_sslv(input : std_logic_vector) return integer;
  
  -- convert string to real
  function from_str(input : string) return real;
  
  -- convert string  to real array
  function from_str(input : string) return t_areal; 

  -- get ratio constant for counter max value
  function ratio(ina : real;
                 inb : real) return integer;
 
  function ratio(ina : integer;
                 inb : integer) return integer; 
  
  -- get max/min from array type interger /real  
  function max_a(a : in t_ainteger) return integer;
    
  function max_a(a : in t_areal) return real;
    
  function min_a(a : in t_ainteger) return integer;
    
  function min_a(a : in t_areal) return real;
  
  -- function to determine if ratio clock/strobe is an integer
  function is_int_ratio(a : in real;    b : in real)   return boolean;
  function is_int_ratio(a : in integer; b: in integer) return boolean;
    
end psi_common_math_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_common_math_pkg is

  -- *************************************************************************
  -- Helpers 
  -- *************************************************************************
  -- Coun the number of elements in a array string (separated by ",")
  function count_array_str_elements(input : string) return natural is
    variable count  : natural := 1;
    variable idx  : integer := input'low;
  begin
    while idx <= input'high loop
      if input(idx) = ',' then
        count := count + 1;
      end if;
      idx := idx + 1;
    end loop;
    return count;
  end function;
  
  -- *************************************************************************
  -- Public Functions 
  -- *************************************************************************

  -- *** Log2 integer ***
  function log2(arg : in natural) return natural is
    variable v : natural := arg;
    variable r : natural := 0;
  begin
    while v > 1 loop
      v := v / 2;
      r := r + 1;
    end loop;
    return r;
  end function;

  -- *** Log2Ceil integer ***
  function log2ceil(arg : in natural) return natural is
  begin
    if arg = 0 then
      return 0;
    end if;
    return log2(arg * 2 - 1);
  end function;

  -- *** Log2Ceil real ***
  function log2ceil(arg : in real) return natural is
    variable v : real    := arg;
    variable r : natural := 0;
  begin
    while v > 1.0 loop
      v := v / 2.0;
      r := r + 1;
    end loop;
    return r;
  end function;

  -- *** isLog2 ***
  function isLog2(arg : in natural) return boolean is
  begin
    if log2(arg) = log2ceil(arg) then
      return true;
    else
      return false;
    end if;
  end function;

  -- *** Max ***
  function max(a : in integer;
               b : in integer) return integer is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;
  
  function max(a : in real;
               b : in real) return real is
  begin
    if a > b then
      return a;
    else
      return b;
    end if;
  end function;

  -- *** Min ***      
  function min(a : in integer;
               b : in integer) return integer is
  begin
    if a > b then
      return b;
    else
      return a;
    end if;
  end function;
  
  function min(a : in real;
               b : in real) return real is
  begin
    if a > b then
      return b;
    else
      return a;
    end if;
  end function;

  -- *** Choose (std_logic) *** 
  function choose(s : in boolean;
                  t : in std_logic;
                  f : in std_logic) return std_logic is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (std_logic_vector) ***  
  function choose(s : in boolean;
                  t : in std_logic_vector;
                  f : in std_logic_vector) return std_logic_vector is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (integer) *** 
  function choose(s : in boolean;
                  t : in integer;
                  f : in integer) return integer is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (string) ***  
  function choose(s : in boolean;
                  t : in string;
                  f : in string) return string is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (real) ***  
  function choose(s : in boolean;
                  t : in real;
                  f : in real) return real is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (unsigned) ***  
  function choose(s : in boolean;
                  t : in unsigned;
                  f : in unsigned) return unsigned is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;

  -- *** Choose (boolean) ***  
  function choose(s : in boolean;
                  t : in boolean;
                  f : in boolean) return boolean is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function;
  
  -- *** Choose (t_areal) ***  
  function choose(s : in boolean;
                  t : in t_areal;
                  f : in t_areal) return t_areal is
  begin
    if s then
      return t;
    else
      return f;
    end if;
  end function; 

  -- *** count (integer) ***  
  function count(a : in t_ainteger;
                 v : in integer) return integer is
    variable cnt_v : integer := 0;
  begin
    for idx in a'low to a'high loop
      if a(idx) = v then
        cnt_v := cnt_v + 1;
      end if;
    end loop;
    return cnt_v;
  end function;

  -- *** count (bool) ***   
  function count(a : in t_abool;
                 v : in boolean) return integer is
    variable cnt_v : integer := 0;
  begin
    for idx in a'low to a'high loop
      if a(idx) = v then
        cnt_v := cnt_v + 1;
      end if;
    end loop;
    return cnt_v;
  end function;

  -- *** count (std_logic) ***  
  function count(a : in std_logic_vector;
                 v : in std_logic) return integer is
    variable cnt_v : integer := 0;
  begin
    for idx in a'low to a'high loop
      if a(idx) = v then
        cnt_v := cnt_v + 1;
      end if;
    end loop;
    return cnt_v;
  end function;

  -- *** integer to unsigned slv  ***
  function to_uslv(input : integer;
                   len   : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(input, len));
  end function;

  -- *** integer to signed slv  ***
  function to_sslv(input : integer;
                   len   : integer) return std_logic_vector is
  begin
    return std_logic_vector(to_signed(input, len));
  end function;

  -- *** integer to unsigned slv  ***
  function from_uslv(input : std_logic_vector) return integer is
  begin
    return to_integer(unsigned(input));
  end function;

  -- *** integer to signed slv  ***
  function from_sslv(input : std_logic_vector) return integer is
  begin
    return to_integer(signed(input));
  end function;
  
  -- convert string to real
  function from_str(input : string) return real is
    constant Nbsp_c : character := character'val(160);
    variable Idx_v : integer := input'low;
    variable IsNeg_v : boolean := false;
    variable ValInt_v : integer := 0;
    variable ValFrac_v : real := 0.0;
    variable FracDigits_v : integer := 0;
    variable Exp_v : integer := 0;
    variable ExpNeg_v : boolean := false;
    variable ValAbs_v : real := 0.0;
  begin
    -- skip leading white-spaces (space, non-breaking space or horizontal tab)
    while (Idx_v <= input'high) and (input(Idx_v) = ' ' or input(Idx_v) = Nbsp_c or input(Idx_v) = HT) loop
      Idx_v := Idx_v + 1;
    end loop;
    
    -- Check sign
    if (Idx_v <= input'high) and ((input(Idx_v) = '-') or (input(Idx_v) = '+')) then
      IsNeg_v := (input(Idx_v) = '-');
      Idx_v := Idx_v + 1;
    end if;
    
    -- Parse Integer
    while (Idx_v <= input'high) and (input(Idx_v) <= '9') and (input(Idx_v) >= '0') loop
      ValInt_v := ValInt_v*10 + (character'pos(input(Idx_v))-character'pos('0'));
      Idx_v := Idx_v + 1;
    end loop;
    
    -- Check decimal point
    if (Idx_v <= input'high) then
      if input(Idx_v) = '.' then
        Idx_v := Idx_v + 1;
    
        -- Parse Fractional
        while (Idx_v <= input'high) and (input(Idx_v) <= '9') and (input(Idx_v) >= '0') loop
          ValFrac_v := ValFrac_v*10.0 + real((character'pos(input(Idx_v))-character'pos('0')));
          FracDigits_v := FracDigits_v + 1;
          Idx_v := Idx_v + 1;
        end loop;
      end if;
    end if;
    
    -- Check exponent
    if (Idx_v <= input'high) then
      if (input(Idx_v) = 'E') or (input(Idx_v) = 'e') then
        Idx_v := Idx_v + 1;
        -- Check sign
        if (Idx_v <= input'high) and ((input(Idx_v) = '-') or (input(Idx_v) = '+')) then
          ExpNeg_v := (input(Idx_v) = '-');
          Idx_v := Idx_v + 1;
        end if;
        
        -- Parse Integer
        while (Idx_v <= input'high) and (input(Idx_v) <= '9') and (input(Idx_v) >= '0') loop
          Exp_v := Exp_v*10 + (character'pos(input(Idx_v))-character'pos('0'));
          Idx_v := Idx_v + 1;
        end loop;
        if ExpNeg_v then
          Exp_v := -Exp_v;
        end if;
      end if;
    end if;
    
    -- Return
    ValAbs_v := (real(ValInt_v)+ValFrac_v/10.0**real(FracDigits_v))*10.0**real(Exp_v);
    if IsNeg_v then
      return -ValAbs_v;
    else
      return ValAbs_v;
    end if; 
  end function;
  
  -- convert string to real array
  function from_str(input : string) return t_areal is
    variable arr      : t_areal(0 to count_array_str_elements(input)-1) := (others => 0.0);
    variable aIdx     : natural   := 0;
    variable startIdx : natural   := 1;
    variable endIdx   : natural   := 1;
    variable idx      : natural   := input'low;
  begin
    while idx <= input'high loop
      if input(idx) = ',' then
        endIdx    := idx-1;
        arr(aIdx) := from_str(input(startIdx to endIdx));
        aIdx      := aIdx+1;
        startIdx  := idx+1;
      end if;
      idx := idx + 1;
    end loop;
    if startIdx <= input'high then
      arr(aIdx) := from_str(input(startIdx to input'high));
    end if;
    return arr;
  end function;

 --*** get ratio value between two values REAL, used for counter max ***
 function ratio(ina : real; inb : real) return integer is
  variable res : integer;
 begin
  if ina > inb then
    res := integer(ceil(ina/inb));
  elsif ina = inb then
    assert false report "both freq. are similar" severity warning; 
    res := 1;
  else
    res := integer(ceil(inb/ina));
  end if;
  return res;
 end function;
   
 --*** get ratio value between two values INT, used for counter max ***
 function ratio(ina : integer; inb : integer) return integer is
  variable res : integer;
 begin
   if ina > inb then
     res := integer(ceil(real(ina)/real(inb)));
   elsif ina = inb then
     assert false report "both freq. are similar" severity warning; 
     res := 1;
   else
     res := integer(ceil(real(inb)/real(ina)));
   end if;
 return res;
 end function;

 --*** get the maximum out of an array of integer ***
 function max_a(  a : in t_ainteger) return integer is
    variable max_v : integer := 0;
  begin
    for idx in a'low to a'high loop
      if max(max_v,a(idx))>max_v then
        max_v := a(idx);
      end if;
    end loop;
    return max_v;
  end function;

 --*** get the maximum out of an array of real ***
 function max_a(  a : in t_areal) return real is
    variable max_v : real := 0.0;
  begin
    for idx in a'low to a'high loop
      if max(max_v,a(idx))>max_v then
        max_v := a(idx);
      end if;
    end loop;
    return max_v;
 end function;
 
  --*** get the minimum out of an array of integer ***
 function min_a(  a : in t_ainteger) return integer is
    variable min_v : integer := 0;
  begin
    for idx in a'low to a'high loop
      if min(min_v,a(idx))<min_v then
        min_v := a(idx);
      end if;
    end loop;
    return min_v;
  end function;

 --*** get the minimum out of an array of real ***
 function min_a(  a : in t_areal) return real is
    variable min_v : real := 0.0;
  begin
    for idx in a'low to a'high loop
      if min(min_v,a(idx))<min_v then
        min_v := a(idx);
      end if;
    end loop;
    return min_v;
 end function;
 
 --*** is ratio an integer REAL ***
 function is_int_ratio(a : in real; b: in real) return boolean is
   variable a_v, b_v : real := 0.0;
 begin
   -- check > < prior to eval
   if a > b then
    a_v := real(a);
    b_v := real(b);
   else
    a_v := real(b);
    b_v := real(a);
   end if;
   
   --eval val 
   if a_v/b_v = ceil(a_v/b_v) or a_v/b_v= floor(a_v/b_v) then
     return true;
   else
     return false;
   end if;
 end function; 
 
  --*** is ratio an integer REAL ***
 function is_int_ratio(a : in integer; b: in integer) return boolean is
  variable a_v , b_v : real := 0.0;
begin
   -- check > < prior to eval
   if a > b then
    a_v := real(a);
    b_v := real(b);
   else
    a_v := real(b);
    b_v := real(a);
  end if;
  
   --eval val   
   if a_v/b_v = ceil(a_v/b_v ) or a_v/b_v = floor(a_v/b_v) then
     return true;
   else
     return false;
   end if;
   
 end function; 
end psi_common_math_pkg;
