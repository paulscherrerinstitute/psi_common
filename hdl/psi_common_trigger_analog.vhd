------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component generates a single clock pulse when its input 
-- value overpass a certain threshold.
-- The trigger pulse is generated with two clock cycle delay once the 
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
entity psi_common_trigger_analog is
  generic(
    analog_input_number_g : integer   := 32; -- number of analog trigger inputs
    analog_input_width_g  : integer   := 16; -- analog trigger input signals width
    analog_trg_signed_g   : boolean   := true; -- analog trigger input signals are signed
    rst_pol_g             : std_logic := '1' -- reset polarity
  );
  port(
    InClk                : in  std_logic; --clk in    $$ type=clk; freq=100.0 $$
    InRst                : in  std_logic; --rst in    $$ type=rst; clk=clk_i $$

    InTrgModeCfg         : in  std_logic_vector(0 downto 0); -- Trigger mode (0:Continuous,1:Single) configuration register
    InTrgArmCfg          : in  std_logic; -- Arm/dis--arm the trigger, rising edge sensitive
    InTrgEdgeCfg         : in  std_logic_vector(1 downto 0); -- Trigger edge direction configuration register (bit0:falling edge sensitive, bit1: rising edge sensitive)

    InTrgAnalogSourceCfg : in  std_logic_vector(log2ceil(analog_input_number_g)-1 downto 0); -- Trigger source configuration  register
    InAnalogThTrg        : in  std_logic_vector(analog_input_width_g - 1 downto 0); -- analog trigger threshold value
    InAnalogTrg          : in  std_logic_vector(analog_input_number_g * analog_input_width_g - 1 downto 0); -- Analog input values
    InExtDisarm          : in  std_logic; -- if different trigger causes are armed at the same time for a single trigger all the other cause must be disarmed once a trigger is generated

    OutTrgIsArmed        : out std_logic;
    OutTrigger           : out std_logic -- trigger output
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_trigger_analog is

  type two_process_r is record
    RegAnalogValueSigned        : signed(analog_input_width_g - 1 downto 0);
    RegAnalogValueSigned_dff    : signed(analog_input_width_g - 1 downto 0);
    RegAnalogValueUnsigned      : unsigned(analog_input_width_g - 1 downto 0);
    RegAnalogValueUnsigned_dff  : unsigned(analog_input_width_g - 1 downto 0);
    RegAnalogThSigned           : signed(analog_input_width_g - 1 downto 0);
    RegAnalogThUnsigned         : unsigned(analog_input_width_g - 1 downto 0);
    OTrg                        : std_logic;
    TrgArmed                    : std_logic;
    InTrgArmCfg_dff             : std_logic;
  end record;

  signal r, r_next : two_process_r;

begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, InTrgModeCfg, InTrgArmCfg, InAnalogThTrg, InAnalogTrg, InTrgEdgeCfg, InTrgAnalogSourceCfg, InExtDisarm)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.InTrgArmCfg_dff := InTrgArmCfg;

    v.TrgArmed := r.TrgArmed;

    if (r.OTrg = '1' or InExtDisarm = '1')  and InTrgModeCfg(0) = '1' then -- if single mode, the trigger is dis-armed once the trigger is generated
      v.TrgArmed := '0';
    elsif InTrgArmCfg = '1' and r.InTrgArmCfg_dff = '0' then -- toggle arm or dis-arm
      v.TrgArmed := not r.TrgArmed;
    end if;

    -- Analog trigger
    v.OTrg := '0';

    if analog_trg_signed_g = true then  -- the analog value is signed

      v.RegAnalogValueSigned := signed(InAnalogTrg((analog_input_width_g * to_integer(unsigned(InTrgAnalogSourceCfg))) + (analog_input_width_g - 1) downto analog_input_width_g * to_integer(unsigned(InTrgAnalogSourceCfg))));

      v.RegAnalogValueSigned_dff := r.RegAnalogValueSigned;
      v.RegAnalogThSigned      := signed(InAnalogThTrg);
      if r.TrgArmed = '1' then
        if r.RegAnalogValueSigned_dff < r.RegAnalogThSigned and r.RegAnalogValueSigned >= r.RegAnalogThSigned and InTrgEdgeCfg(1) = '1' then --rising edge
          v.OTrg := '1';
        end if;
        if r.RegAnalogValueSigned_dff > r.RegAnalogThSigned and r.RegAnalogValueSigned <= r.RegAnalogThSigned and InTrgEdgeCfg(0) = '1' then --falling edge
          v.OTrg := '1';
        end if;
      end if;
    end if;

    if analog_trg_signed_g = false then -- the analog value is unsigned

      v.RegAnalogValueUnsigned := unsigned(InAnalogTrg((analog_input_width_g * to_integer(unsigned(InTrgAnalogSourceCfg))) + (analog_input_width_g - 1) downto analog_input_width_g * to_integer(unsigned(InTrgAnalogSourceCfg))));

      v.RegAnalogValueUnsigned_dff := r.RegAnalogValueUnsigned;
      v.RegAnalogThUnsigned      := unsigned(InAnalogThTrg);
      if r.TrgArmed = '1' then
        if r.RegAnalogValueUnsigned_dff < r.RegAnalogThUnsigned and r.RegAnalogValueUnsigned >= r.RegAnalogThUnsigned and InTrgEdgeCfg(1) = '1' then --rising edge
          v.OTrg := '1';
        end if;
        if r.RegAnalogValueUnsigned_dff > r.RegAnalogThUnsigned and r.RegAnalogValueUnsigned <= r.RegAnalogThUnsigned and InTrgEdgeCfg(0) = '1' then --falling edge
          v.OTrg := '1';
        end if;
      end if;
    end if;

    -- *** Outputs ***

    OutTrigger    <= r.OTrg;
    OutTrgIsArmed <= r.TrgArmed;
    -- Apply to record
    r_next        <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------  
  p_seq : process(InClk)
  begin
    if rising_edge(InClk) then
      r <= r_next;
      if InRst = rst_pol_g then
        r.RegAnalogValueSigned     <= (others => '0');
        r.RegAnalogValueSigned_dff   <= (others => '0');
        r.RegAnalogValueUnsigned   <= (others => '0');
        r.RegAnalogValueUnsigned_dff <= (others => '0');
        r.RegAnalogThSigned        <= (others => '0');
        r.RegAnalogThUnsigned      <= (others => '0');
        r.OTrg                     <= '0';
        r.TrgArmed                 <= '0';
        r.InTrgArmCfg_dff            <= '0';
      end if;
    end if;
  end process;

end architecture;
