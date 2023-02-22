------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Patric Bucher, Oliver Bruendler
------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
--                       Paul Scherrer Institute (PSI)
-- -----------------------------------------------------------------------------
-- Unit    : psi_common_tickgenerator_tb.vhd
-- Author  : Patric Bucher
-- -----------------------------------------------------------------------------
-- CopyrightÃÂÃÂ© PSI, Section DSV
-- -----------------------------------------------------------------------------
-- Comment : Testbench for Tick Generator.
-- -----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;

use work.psi_tb_txt_util.all;


entity psi_common_tickgenerator_tb is
  generic(
    clk_in_mhz_g  : integer := 8;
    tick_width_g  : integer := 1
  );
end psi_common_tickgenerator_tb;


architecture testbench of psi_common_tickgenerator_tb is
  
  -- ---------------------------------------------------------------------------
  -- Constant Declarations                                    
  -- --------------------------------------------------------------------------- 
  constant t_CLK          		: time      := (1 sec)/(clk_in_mhz_g * 1000000);
  constant SIM_SPEEDUP_FACTOR	: integer	:= 20;
  
  -- ---------------------------------------------------------------------------
  -- Signal Declarations                                    
  -- ---------------------------------------------------------------------------
  signal clock            : std_logic := '0'; 
  signal tick1us          : std_logic := '0'; 
  signal tick1ms          : std_logic := '0'; 
  signal tick1sec         : std_logic := '0';  
  

-- -----------------------------------------------------------------------------
-- /////////////////////         SIMULATION          ///////////////////////////
-- -----------------------------------------------------------------------------
begin

  clock <= not clock after t_CLK/2;
  
  ------------------------------------------------------------------------------
  -- DUT
  ------------------------------------------------------------------------------
  DUT: entity work.psi_common_tickgenerator
    generic map(
      clk_in_mhz_g  => clk_in_mhz_g,
      tick_width_g  => tick_width_g,
      sim_sec_speedup_factor_g => SIM_SPEEDUP_FACTOR
    )
    port map( 
      clock_i       => clock,                     
      tick1us_o     => tick1us,                      
      tick1ms_o     => tick1ms,                      
      tick1sec_o    => tick1sec                   
    );
  
  
  ------------------------------------------------------------------------------
  -- Testbench Stimulus
  ------------------------------------------------------------------------------
  stimulus : process
    variable t_start  : time;
    variable t_stop   : time;
	begin
		wait for 4 * t_CLK; -- startup delay
	
		print(">> Measure Microsecond Tick");
		wait until rising_edge(tick1us);
    t_start := now;
		wait until rising_edge(tick1us);
    t_stop  := now;
    assert (t_stop - t_start) = 1 us  report "###ERROR###: Microsecond Tick is not 1 us." severity error;	
    assert (t_stop - t_start) /= 1 us report "SUCCESS: Microsecond Tick is 1 us." severity note;	
    
		print(">> Measure Millisecond Tick");
		wait until rising_edge(tick1ms);
    t_start := now;
		wait until rising_edge(tick1ms);
    t_stop  := now;
    assert (t_stop - t_start) = 1 ms  report "###ERROR###: Millisecond Tick is not 1 ms." severity error;
    assert (t_stop - t_start) /= 1 ms report "SUCCESS: Millisecond Tick is 1 ms." severity note;	
 	
		print(">> Measure Second Tick");
		wait until rising_edge(tick1sec);
    t_start := now;
		wait until rising_edge(tick1sec);
    t_stop  := now;
    assert (t_stop - t_start) = (1 sec / SIM_SPEEDUP_FACTOR)  report "###ERROR###: Second Tick is not 1 sec." severity error;
    assert (t_stop - t_start) /= (1 sec / SIM_SPEEDUP_FACTOR) report "SUCCESS: Second Tick is 1 sec." severity note;	
    
    stop(0);
    wait;
  end process;
  

end testbench;
-- -----------------------------------------------------------------------------
-- /////////////////////////////////////////////////////////////////////////////
-- -----------------------------------------------------------------------------