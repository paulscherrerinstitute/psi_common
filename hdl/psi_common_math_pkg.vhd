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

end psi_common_math_pkg;

------------------------------------------------------------------------------
-- Package Body
------------------------------------------------------------------------------
package body psi_common_math_pkg is

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
    return std_logic_vector(to_unsigned(input, len));
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
		variable Idx_v : integer := input'low;
		variable IsNeg_v : boolean := false;
		variable ValInt_v : integer := 0;
		variable ValFrac_v : real := 0.0;
		variable FracDigits_v : integer := 0;
		variable Exp_v : integer := 0;
		variable ExpNeg_v : boolean := false;
		variable ValAbs_v : real := 0.0;
	begin
		-- skip leading white-spaces
		while (Idx_v <= input'high) and input(Idx_v) = ' ' loop
			Idx_v := Idx_v + 1;
		end loop;
		
		-- Check sign
		if (Idx_v <= input'high) and (input(Idx_v) = '-') then
			IsNeg_v := true;
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
				if (Idx_v <= input'high) and (input(Idx_v) = '-') then
					ExpNeg_v := true;
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

end psi_common_math_pkg;
