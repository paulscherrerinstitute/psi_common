------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors:  Benoit Stef 
--  Purpose:  Using to verify if value has been active (/= previous value) 
--            within a predefined time period - error/warning flag can be set
--            via generic
--            Two modes can be used either one wants to verify the successive
--            missing events or a total missing event during the time period.
--            In order to distinguish between both modes, affecting 0 for the 
--            generic thld_fault_succ_g will enable the total missing count 
--            behavior whereas setting a positive value activates the successive
--            missing event count.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

entity psi_common_watchdog is
  generic(freq_clk_g          : real      := 100.0e6;                                             -- clock frequency in Hz
          freq_act_g          : real      := 100.0e3;                                             -- event frequency in Hz
          thld_fault_total_g  : positive  := 10;                                                  -- threshold for total errors
          thld_warn_g         : positive  := 3;                                                   -- threshold for warning
          thld_fault_succ_g   : integer   := 0;                                                   -- threshold for successive errors
          length_g            : integer   := 9;                                                   -- data input length
          rst_pol_g           : std_logic := '1');                                                -- polarity reset
  port(   clk_i               : in  std_logic;                                                    -- clock 
          rst_i               : in  std_logic;                                                    -- reset 
          dat_i               : in  std_logic_vector(length_g - 1 downto 0);                      -- input data
          warn_o              : out std_logic;                                                    -- warning flag
          miss_o              : out std_logic_vector(log2ceil(thld_fault_total_g) - 1 downto 0);  -- missing counter  
          fault_o             : out std_logic);                                                   -- fault flag
end entity;

architecture rtl of psi_common_watchdog is
  constant thld_c        : integer  := integer(freq_clk_g / freq_act_g) - 1;
  constant nbit_count0_c : integer  := log2ceil(thld_c);
  constant thld_usign_c  : unsigned := to_unsigned(thld_c, nbit_count0_c);

  -- 2 Proc method
  type two_process_t is record
    activ_count     : unsigned(nbit_count0_c - 1 downto 0);
    miss_count      : unsigned(log2ceil(thld_fault_total_g) - 1 downto 0);
    evt_count       : unsigned(log2ceil(thld_fault_total_g) - 1 downto 0);
    succ_count      : unsigned(log2ceil(thld_fault_succ_g) - 1 downto 0);
    dat_dff         : std_logic_vector(dat_i'range);
    warn            : std_logic;
    fault           : std_logic;
  end record;

  signal r, r_next : two_process_t;
begin

  proc_comb : process(dat_i, r)
    variable v : two_process_t;
  begin
    -- *** Hold variables stable ***
    v         := r;
    --*** dff ***
    v.dat_dff := dat_i;

    if dat_i /= r.dat_dff then
      v.activ_count := (others => '0');
    else
      if r.fault = '0' then
        if r.activ_count >= thld_usign_c then
          v.activ_count := (others => '0');
        else
          v.activ_count := r.activ_count + 1;
        end if;
      end if;
    end if;

    --*** missing counter ***
    if r.fault = '0' then
      if r.activ_count >= thld_usign_c then
        v.miss_count := r.miss_count + 1;
      end if;
    end if;
    
   --*** successive counter ***
    if thld_fault_succ_g > 0 then 
      if r.fault = '0' then
        if r.activ_count >= thld_usign_c then
          v.succ_count := r.succ_count + 1;
         --*** successive counter ***
        elsif dat_i /= r.dat_dff and r.activ_count <= thld_usign_c then
           v.succ_count := (others => '0');
        end if;
      end if;
    end if;

    --*** output thld on total count independently of the succesive errors***
    if thld_fault_succ_g = 0 then
      if r.miss_count >= thld_warn_g - 1 and r.activ_count = thld_usign_c then
        v.warn := '1';
      end if;
  
      if r.miss_count >= thld_fault_total_g - 1 and r.activ_count = thld_usign_c then
        v.fault := '1';
      end if;
      
    --*** generating status on consecutive missing event ***  
    else
      if r.succ_count >= thld_warn_g - 1 and r.activ_count = thld_usign_c then
        v.warn := '1';
      end if;
  
      if r.succ_count >= thld_fault_succ_g - 1 and r.activ_count = thld_usign_c then
        v.fault := '1';
      end if;
    end if;

    --*** v in r next ***
    r_next <= v;
  end process;

  --*** out map ***
  warn_o  <= r.warn;
  fault_o <= r.fault;
  miss_o  <= std_logic_vector(r.miss_count);

  proc_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.activ_count <= (others => '0');
        r.miss_count     <= (others => '0');
        r.evt_count      <= (others => '0');
        r.succ_count     <= (others => '0');
        r.fault          <= '0';
        r.warn           <= '0';
      end if;
    end if;
  end process;

end architecture;
