------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component generates a single trigger pulse when a rising and/or a 
-- falling edge of a std_logic signal is detected at the input.
-- The trigger pulse is generated with one clock cycle delay once the 
-- selected condition is satisfied. 

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_trigger_digital is
  generic(
    digital_input_number_g : integer   := 1; -- number of digital trigger inputs
    rst_pol_g              : std_logic := '1' -- reset polarity
  );
  port(
    clk_i                 : in  std_logic; --clk in    $$ type=clk; freq=100.0 $$
    rst_i                 : in  std_logic; --rst in    $$ type=rst; clk=clk_i $$
    --InDelay : real := 0.0; -- -- delay in us
    trg_mode_cfg_i          : in  std_logic_vector(0 downto 0); -- Trigger mode (0:Continuous,1:Single) configuration register
    trg_arm_cfg_i           : in  std_logic; -- Arm/dis--arm the trigger, rising edge sensitive
    trg_edge_cfg_i          : in  std_logic_vector(1 downto 0); -- Trigger edge direction configuration register (bit0:falling edge sensitive, bit1: rising edge sensitive)

    trg_digital_source_cfg_i : in  std_logic_vector(choose(digital_input_number_g>1,log2ceil(digital_input_number_g)-1,0) downto 0); -- Trigger source configuration  register
    digital_trg_i          : in  std_logic_vector(digital_input_number_g - 1 downto 0); -- digital trigger input 
    ext_disarm_i           : in  std_logic; -- if different trigger causes are armed at the same time for a single trigger all the other cause must be disarmed once a trigger is generated
    
    trg_is_armed_o         : out std_logic;
    trigger_o            : out std_logic -- trigger output
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_trigger_digital is

  type two_process_r is record
    RegDigitalValue_dff : std_logic;
    OTrg                : std_logic;
    TrgArmed            : std_logic;
    InTrgArmCfg_dff     : std_logic;
  end record;

  signal r, r_next : two_process_r;

begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, trg_mode_cfg_i, trg_arm_cfg_i, trg_edge_cfg_i, digital_trg_i, trg_digital_source_cfg_i, ext_disarm_i)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.InTrgArmCfg_dff := trg_arm_cfg_i;

    v.TrgArmed := r.TrgArmed;

    if (r.OTrg = '1' or ext_disarm_i = '1') and trg_mode_cfg_i(0) = '1' then -- if single mode, the trigger is dis-armed once the trigger is generated
      v.TrgArmed := '0';
    elsif trg_arm_cfg_i = '1' and r.InTrgArmCfg_dff = '0' then -- toggle arm or dis-arm
      v.TrgArmed := not r.TrgArmed;
    end if;

    v.OTrg := '0';
    -- Digital Trigger

    v.RegDigitalValue_dff := digital_trg_i(to_integer(unsigned(trg_digital_source_cfg_i)));
    if r.TrgArmed = '1' then
      if r.RegDigitalValue_dff = '0' and digital_trg_i(to_integer(unsigned(trg_digital_source_cfg_i))) = '1' and trg_edge_cfg_i(1) = '1' then --rising edge
        v.OTrg := '1';
      end if;
      if r.RegDigitalValue_dff = '1' and digital_trg_i(to_integer(unsigned(trg_digital_source_cfg_i))) = '0' and trg_edge_cfg_i(0) = '1' then --falling edge
        v.OTrg := '1';
      end if;
    end if;

    -- *** Outputs ***

    trigger_o    <= r.OTrg;
    trg_is_armed_o <= r.TrgArmed;
    -- Apply to record
    r_next        <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------  
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.RegDigitalValue_dff <= '0';
        r.OTrg              <= '0';
        r.TrgArmed          <= '0';
        r.InTrgArmCfg_dff     <= '0';
      end if;
    end if;
  end process;

end architecture;
