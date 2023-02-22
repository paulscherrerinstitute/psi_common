------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple debouncer, one can seeect the in/out 
-- polarity as well the time length of the deboucing filter

-------------------------------------------------------------------------------
-- Libraries
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;

entity psi_common_debouncer is
  generic(dbnc_per_g : real       := 10.0e-3; -- filter time in sec
          freq_clk_g : real       := 100.0e6; -- clock frequency in Hz
          rst_pol_g  : std_logic  :='1';      -- polarity reset 
          len_g      : positive   := 1;       -- vector input lenght 
          in_pol_g   : std_logic  :='0';      -- active high or low
          out_pol_g  : std_logic  :='1';      -- active high or low
          sync_g     : boolean    := true);   -- add 2 DFF input sync
  port(   clk_i      : in  std_logic;
          rst_i      : in  std_logic;
          dat_i      : in  std_logic_vector(len_g-1 downto 0);
          dat_o      : out std_logic_vector(len_g-1 downto 0)
    );
end entity;

architecture RTL of psi_common_debouncer is
  
  constant clk_period_c   : real    := 1.0/freq_clk_g;
  constant count_max_c    : natural := integer(ceil(dbnc_per_g/clk_period_c))-1;
  constant pol_eq_c       : boolean := choose(in_pol_g=out_pol_g, true, false);
  
  type two_process_t is record
    counter : unsigned(log2ceil(count_max_c)-1 downto 0);
    inp_dff : std_logic_vector(len_g-1 downto 0); 
    output  : std_logic_vector(len_g-1 downto 0);
  end record; 
   
  constant rst_two_process_c  : two_process_t :=((others=>'0'), (others=>not in_pol_g), (others=>not out_pol_g));
  signal r, r_next            : two_process_t := rst_two_process_c;  
  signal inp_sync_s           : std_logic_vector(len_g-1 downto 0);


  
 
begin

  --*** double stage synchronizer ***  
  gene_sync : if sync_g generate
    i_sync : entity work.psi_common_bit_cc
      generic map (
        num_bits_g => len_g
      )
      port map (
        dat_i => dat_i,
        clk_i  => clk_i,
        dat_o => inp_sync_s
    );
  end generate;
  
  --*** no sync ***
  gene_nosync : if not sync_g generate
    inp_sync_s <= dat_i;
  end generate;

  proc_comb : process(inp_sync_s, r)
    variable v : two_process_t;
  begin
     --*** Hold variables stable ***
    v         := r;
    --*** 1 pipe ***
    v.inp_dff := inp_sync_s;
   
    --*** start counter ***
    if (r.inp_dff /= inp_sync_s) then
      v.counter := to_unsigned(count_max_c,v.counter'length);
    else
      if r.counter /= 0 then
        v.counter := r.counter-1;
      end if;
    end if;

    --*** check pol I/O and counter done => assign output ***
    if r.counter = 0 then
      if pol_eq_c then
        v.output := r.inp_dff;
      else
        v.output := not r.inp_dff;
      end if;
    end if;
    
    --*** out map ***
    dat_o <= r.output;
    
    --*** v in r next ***
    r_next <= v;
  end process;
  
  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next; 
      if rst_i = rst_pol_g then
        r <= rst_two_process_c;
      end if;      
    end if;
  end process;  

end architecture;