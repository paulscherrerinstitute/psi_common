------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This arhitecture is using few elements within the psi common library in order
-- to generate a periodic pulse or trigger pulse with predefined parameters
-- the architecture target is to show a possible implementaion of 
-- psi_common_pulse_generator.vhd
-- if trig is set to 1 it will start a pulse from 0 to its max level depending
-- on data vector length selected and will return to 0.
-- if trig is let to 1 then repetitive pulse will be fired.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_logic_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_array_pkg.all;
-- @formatter:off
entity psi_common_pulse_generator_ctrl_static is
  generic(rst_pol_g     : std_logic:= '1';                   -- '1' active high, '0' active low
          width_g       : natural  :=      16;               -- Output data vector length
          clk_freq_g    : real     := 100.0e6;               -- Clock frequency in Hz
          str_freq_g    : real     :=  10.0e6;               -- Strobe output || increment strobe in Hz
          nb_step_up_g  : integer  := 100;                   -- ramp up param step in str
          nb_step_dw_g  : integer  := 50;                    -- ramp down param step in str
          nb_step_flh_g : integer  := 4000;                  -- flat level param step in str
          nb_step_fll_g : integer  := 4000);                 -- low level param step in str
  port   (clk_i : in  std_logic;                             -- clock
          rst_i : in  std_logic;                             -- reset
          trig_i: in  std_logic;                             -- Trigger a new pulse
          stop_i: in  std_logic;                             -- Abort pulse
          busy_o: out std_logic;                             -- pulse in action
          dat_o : out std_logic_vector(width_g-1 downto 0);  -- pulse output
          vld_o : out std_logic;                             -- pulse strobe
          dbg_o : out std_logic_vector(1 downto 0));         -- use for tb purpose and avoid using externalname GHDL
end entity;
-- @formatter:on

architecture RTL of psi_common_pulse_generator_ctrl_static is
 
 signal str_s : std_logic;
 signal sts_s : std_logic_vector(1 downto 0);
 signal dat_s : std_logic_vector(width_g-1 downto 0);
 
 -- set of constant for static pulse generation
 constant step_array_c  : t_ainteger(1 downto 0):=(nb_step_flh_g,nb_step_fll_g);
 constant max_step_c    : integer := max_a(step_array_c);
 constant tgt_lvl_c     : std_logic_vector(width_g-1 downto 0) := to_uslv(2**width_g-1,width_g);
 constant inc_step_up_c : integer := integer(round(real(from_uslv(tgt_lvl_c))/real(nb_step_up_g)));
 constant inc_step_dw_c : integer := integer(round(real(from_uslv(tgt_lvl_c))/real(nb_step_dw_g)));
 -- 2 process ctrl
 type two_process_t is record
  inc_val  : std_logic_vector(width_g-1 downto 0);
  ramp_cmd : std_logic;
  init_cmd : std_logic;
  sts_dff  : std_logic_vector(1 downto 0);
  count    : integer range 0 to max_step_c-1;
  lvl      : std_logic_vector(width_g-1 downto 0);
  trig_dff : std_logic;
  busy     : std_logic;
 end record;
 
 signal r, rin : two_process_t;
 
begin
  
  --*** Strobe generator ***
  inst_strobe : entity work.psi_common_strobe_generator
    generic map(
      freq_clock_g  => clk_freq_g,
      freq_strobe_g => str_freq_g,
      rst_pol_g     => rst_pol_g)
    port map(
      clk_i  => clk_i,
      rst_i  => rst_i,
      sync_i => trig_i,
      vld_o => str_s);
  
  --*** Pulse generator ***  
  inst_pulse : entity work.psi_common_ramp_gene
    generic map(
      width_g     => width_g,
      is_sign_g   => false,
      rst_pol_g   => rst_pol_g,
      init_val_g  => 0)
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      vld_i      => str_s,
      tgt_lvl_i  => r.lvl,
      ramp_inc_i => r.inc_val,
      ramp_cmd_i => r.ramp_cmd,
      init_cmd_i => r.init_cmd,
      sts_o      => sts_s,
      vld_o      => vld_o,
      puls_o     => dat_s);
  
  dbg_o  <= sts_s;  
  dat_o  <= dat_s;
  busy_o <= r.busy;
  
  proc_comb : process(sts_s,stop_i,trig_i,r,str_s,dat_s)
    variable v : two_process_t;
  begin
    v:=r;    
    -- edge detect
    v.trig_dff := trig_i;
    v.sts_dff  := sts_s;
    -- abort pulse
    if stop_i = '1' then
      v.init_cmd := '1';
      v.count    :=  nb_step_flh_g-1;
      v.busy     := '0';
    else  
      v.init_cmd := '0';
      -- wait for trigger
      if sts_s = "00" then 
        v.busy     := '0';
        v.count := nb_step_flh_g-1;
        v.lvl   := to_uslv(2**width_g-1,width_g);
        if trig_i ='1' and r.trig_dff = '0'  then
          v.inc_val  := to_uslv(inc_step_up_c,width_g);
          v.ramp_cmd := '1';
          v.busy     := '1';
        else
          v.ramp_cmd := '0';
        end if;
      -- counter flat top/bottom  
    elsif sts_s = "11" then      
         if str_s = '1' then
           if r.count /= 0 then
             v.count := r.count-1;
             v.ramp_cmd := '0';
             v.busy     := '1';
           else
             v.count := 0;
             if dat_s = to_uslv(0,width_g) then
               v.busy     := '0';
               if trig_i ='1' then
                 v.lvl      := to_uslv(2**width_g-1,width_g);
                 v.inc_val  := to_uslv(inc_step_up_c,width_g);
                 v.ramp_cmd := '1';
                 v.busy     := '1';
               end if;
             else
               v.busy     := '1';
               v.lvl      := (others=>'0');  
               v.inc_val  := to_uslv(inc_step_dw_c,width_g);
               v.ramp_cmd := '1';
             end if;
           end if;     
         end if;
      --reset counter start value    
      elsif (sts_s = "10" and r.sts_dff = "11") then
        v.ramp_cmd := '0';
        v.count := nb_step_fll_g-1;
      elsif sts_s= "01" and r.sts_dff = "11" then
        v.ramp_cmd := '0';
        v.count := nb_step_flh_g-1;
      end if;
     end if;
    rin <= v;
  end process;
  
  proc_clk : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        r.inc_val  <= (others=>'0');
        r.ramp_cmd <= '0';
        r.count    <=  nb_step_flh_g-1;
        r.lvl      <= (others=>'0');
        r.trig_dff <= '0';
        r.busy     <= '0';
      end if;
      r <= rin;
    end if;
  end process;
  
end architecture;
