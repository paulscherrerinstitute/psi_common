------------------------------------------------------------------------------
-- Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component implements a parallel to serialized data with a load input
-- and generics number to define the length of vector input.
-- Data bit 0 is sent last. when msb_g if set true; if false bit 0 sent first
-- An error bit is active when a valid occured while the serializer didn't 
-- finish its task. A frame output flag arises at last serialized bit
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

entity psi_common_par_ser is
  generic(rst_pol_g : std_logic               := '1';       -- reset polarity
          msb_g     : boolean                 := true;      -- msb first in the frame
          ratio_g   : natural range 1 to 4096 := 2;         -- output valid speed related to clock
          length_g  : natural                 := 16);       -- vetor in width
  port(clk_i : in  std_logic;                               -- clock system
       rst_i : in  std_logic;                               -- reset system
       dat_i : in  std_logic_vector(length_g - 1 downto 0); -- data in parallel
       vld_i : in  std_logic;                               -- valid/strobe/load in
       dat_o : out std_logic;                               -- data out serialized
       err_o : out std_logic;                               -- error out when input valid too fast
       frm_o : out std_logic;                               -- frame out
       ld_o  : out std_logic;                               -- start of frame out
       vld_o : out std_logic);                              -- valid/strobe
end entity;

architecture RTL of psi_common_par_ser is

  type two_process_t is record
    cnt    : unsigned(log2ceil(length_g) - 1 downto 0);
    dat    : std_logic_vector(length_g - 1 downto 0);
    idat   : std_logic_vector(length_g - 1 downto 0);
    frm    : std_logic;
    vld    : std_logic;
    err    : std_logic;
    ld     : std_logic;
    -- active process of serializing when ratio > 1
    active : std_logic;
    -- increase setting with lower data rate
    count  : unsigned(log2ceil(ratio_g) - 1 downto 0);
    tick   : std_logic;
  end record;

  signal r, r_next : two_process_t;

begin
 
  proc_comb : process(r, vld_i, dat_i)
    variable v : two_process_t;
  begin
    -- *** r => v ***
    v       := r;   
    
    --*** ratio counter sync with vld_i for slower throughput ***
    if ratio_g > 1 then
      if vld_i = '1' then
        if ratio_g = 2 then
          v.count := (others=>'0');
          v.tick  := '1';
        else
          v.count := r.count+1;
          v.tick  := '0';
        end if;
        v.idat  := dat_i;
      else
        if r.active = '1' then
          if r.count = ratio_g - 1 then
            v.count := (others => '0');
          else
            v.count := r.count + 1;
          end if;
          
          --*** mng vld output ***
          if ratio_g = 2 then
            if r.count = ratio_g - 1 then
               v.tick := '1';
            else
               v.tick := '0';
            end if;
          else
             if r.count = ratio_g - 2 then
               v.tick := '1';
            else
               v.tick := '0';
            end if;
          end if;
        end if;
      end if;   
             
      --*** load output handling ***
      if ratio_g = 2 then
        if r.active ='1' and r.cnt=0 and r.count = 0 then
          v.ld := '1';   
        else
          v.ld := '0';
        end if;
      else
        if r.active ='1' and r.cnt=0 and r.count = to_unsigned(ratio_g-1,r.count'length) then
          v.ld := '1';   
        else
          v.ld := '0';
        end if;  
      end if;
       
      --*** serializer active ***
      if vld_i = '1' then
        v.active := '1';
      elsif r.cnt = length_g - 1 and r.tick = '1' and vld_i='0' then
        v.active := '0';
      end if;
      
      --*** serialize statement ***
      if r.cnt <= length_g - 1 then
        v.vld := r.tick;
        
        --*** cnt statements upon tick ***
        if r.tick = '1' and r.active = '1' then
          v.cnt := r.cnt + 1;
          v.dat := r.idat;
          --*** shifter left MSB or right LSB ***
            if msb_g then
              v.idat := r.idat(length_g - 2 downto 0) & '0';
            else
              v.idat := '0' & r.idat(length_g - 1 downto 1);
            end if;
        end if;
        
        -- *** end of frame output ***
        if r.cnt = length_g - 1 and r.tick = '1' then
          v.frm := '1';
        else
          v.frm := '0';
        end if;
      end if;      
      
      --*** error when serialize process isn't complete ***
      if vld_i = '1' and r.cnt /= 0 then
        v.err := '1';
      else
        v.err := '0';
      end if;
      
    --*** full speed througput ***
    else
      if vld_i = '1' then
        v.cnt := (others=>'0');
        v.vld := '1';
        v.ld  := '1';
        v.frm := '0';
        v.dat := dat_i;
      else
        v.ld  := '0';
        if r.cnt < length_g-1 then
          v.cnt := r.cnt+1;
          
          --*** shifter left MSB or right LSB ***
          if msb_g then
            v.dat := r.dat(length_g - 2 downto 0) & '0';
          else
            v.dat := '0' & r.dat(length_g - 1 downto 1);
          end if;
          
          --*** end of frame handling ***
          if r.cnt = length_g-2 then
            v.frm := '1';
          else
            v.frm := '0';
          end if;
        else
          v.cnt := r.cnt;
          v.vld := '0';
          v.frm := '0';
        end if;
      end if;    
        
      --*** error when serialize process isn't complete ***
      if vld_i = '1' and r.cnt /= length_g - 1 then
        v.err := '1';
      else
        v.err := '0';
      end if;
    end if;    
    
    --*** v => r next ***
    r_next <= v;
  end process;

  --*** output map ***
  dat_o <= r.dat(length_g - 1) when msb_g else r.dat(0);
  vld_o <= r.vld;
  err_o <= r.err;
  ld_o  <= r.ld;
  frm_o <= r.frm;

  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.active <= '0';
        r.tick   <= '0';
        r.vld    <= '0';
        r.err    <= '0';
        r.frm    <= '0';
        r.cnt    <= (others => '0');
        r.count  <= (others => '0');
        r.dat    <= (others => '0');
        r.ld     <= '0';
      end if;
    end if;
  end process;

end architecture;
