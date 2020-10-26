------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This arhitecture is using few elements within the psi common library in order
-- to generate the 

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

entity psi_common_pulse_generator_ctrl_static is
  generic(rst_pol_g   : std_logic:= '1';
          length_g    : natural  :=      16;                  -- Output data vector length
          clk_freq_g  : real     := 100.0e6;                  -- Clock frequency in Hz
          str_freq_g  : real     :=  10.0e6;                  -- Strobe output || increment strobe in Hz
          time_up_g   : real     :=  10.0e-6;                 -- Rising time in sec
          time_dw_g   : real     :=   1.0e-6;                 -- Falling time in sec
          time_flat_g : real     :=   1.0e-4                  -- Flat time in sec
  );
  port   (clk_i : in  std_logic;                             -- clock
          rst_i : in  std_logic;                             -- reset
          trig_i: in  std_logic;                             -- Trigger a new pulse
          stop_i: in  std_logic;                             -- Abort pulse
          dat_o : out std_logic_vector(length_g-1 downto 0); -- pulse output
          str_o : out std_logic);                            -- pulse strobe
end entity;

architecture RTL of psi_common_pulse_generator_ctrl_static is
 
 signal str_s : std_logic;
 signal sts_s : std_logic_vector(1 downto 0);
 signal dat_s : std_logic_vector(length_g-1 downto 0);
 -- set of constant for static pulse generation
 constant time_array_c  : t_areal(2 downto 0):=(time_up_g,time_dw_g,time_flat_g); -- defining the max time to bound counter value
 constant max_time_c    : real    := max_a(time_array_c);                         -- most probably the flat top
 
 -- TODO define try/catch function
 constant inc_up_c      : std_logic_vector(length_g-1 downto 0) := to_uslv(integer(real(2**length_g-1)/(time_up_g*str_freq_g)),length_g);
 constant inc_dw_c      : std_logic_vector(length_g-1 downto 0) := to_uslv(integer(real(2**length_g-1)/(time_dw_g*str_freq_g)),length_g);
 
 --helpers
 constant tgt_lvl_c     : std_logic_vector(length_g-1 downto 0) := to_uslv(2**length_g-1,length_g);
 constant rat_c : integer :=  ratio(1.0/str_freq_g,time_flat_g);
 -- 2 process ctrl
 type two_process_t is record
  inc_val  : std_logic_vector(length_g-1 downto 0);
  ramp_cmd : std_logic;
  init_cmd : std_logic;
  count    : integer range 0 to ratio(1.0/str_freq_g,time_flat_g);
  lvl      : std_logic_vector(length_g-1 downto 0);
  trig_dff : std_logic;
 end record;
 
 signal r, rin : two_process_t;
 
begin
  
  --*** assert declaration ***
  assert max_time_c = time_flat_g report "[INFO]: The maximum time set isn't the flat top" severity note;
  
  --*** Strobe generator ***
  inst_strobe : entity work.psi_common_strobe_generator
    generic map(
      freq_clock_g  => clk_freq_g,
      freq_strobe_g => str_freq_g,
      rst_pol_g     => rst_pol_g
    )
    port map(
      InClk  => clk_i,
      InRst  => rst_i,
      InSync => trig_i,
      OutVld => str_s
    );
  
  --*** Pulse generator ***  
  inst_pulse : entity work.psi_common_pulse_generator
    generic map(
      width_g   => length_g,
      rst_pol_g => rst_pol_g
    )
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      str_i      => str_s,
      tgt_lvl_i  => r.lvl,
      ramp_inc_i => r.inc_val,
      ramp_cmd_i => r.ramp_cmd,
      init_cmd_i => r.init_cmd,
      sts_o      => sts_s,
      str_o      => str_o,
      puls_o     => dat_s
    );
    
  dat_o <= dat_s;
  
  proc_comb : process(sts_s,stop_i,trig_i,r,str_s,dat_s)
    variable v : two_process_t;
  begin
    v:=r;    
    -- edge detect
    v.trig_dff := trig_i;
    -- abort pulse --
    if stop_i = '1' then
      v.init_cmd := '1';
      v.count    :=  ratio(1.0/str_freq_g,time_flat_g)-2;
    else  
      v.init_cmd := '0';
      -- wait for trigger --
      if sts_s = "00" then
        v.lvl := to_uslv(2**length_g-1,length_g);
        if trig_i ='1' and r.trig_dff = '0'  then
          v.inc_val  := inc_up_c;
          v.ramp_cmd := '1';
        else
          v.ramp_cmd := '0';
        end if;
      -- counter flat top/bottom --  
      elsif sts_s = "11" then
         if str_s = '1' then
           if r.count /= 0 then
             v.count := r.count-1;
             v.ramp_cmd := '0';
           else
             v.count := 0;
             if dat_s = to_uslv(0,length_g) then
               if trig_i ='1' then
                 v.lvl      := to_uslv(2**length_g-1,length_g);
                 v.inc_val  := inc_up_c;
                 v.ramp_cmd := '1';
               end if;
             else
               v.lvl      := (others=>'0');  
               v.inc_val  := inc_dw_c;
               v.ramp_cmd := '1';
             end if;
           end if;     
         end if;
       -- --  
      elsif sts_s = "10" or sts_s= "01" then
          v.ramp_cmd := '0';
          v.count := ratio(1.0/str_freq_g,time_flat_g)-2;
      end if;
     end if;
    rin <= v;
  end process;
  
  proc_clk:process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        r.inc_val  <= (others=>'0');
        r.ramp_cmd <= '0';
        r.count    <=  ratio(1.0/str_freq_g,time_flat_g)-2;
        r.lvl      <= (others=>'0');
        r.trig_dff <= '0';
      end if;
      r <= rin;
    end if;
  end process;
  
end architecture;
