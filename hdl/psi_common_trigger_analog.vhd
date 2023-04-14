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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;

-- @formatter:off
entity psi_common_trigger_analog is
  generic(trig_nb_g          : integer   := 32;                                        -- number of analog trigger inputs
          width_g            : integer   := 16;                                        -- analog trigger input signals width
          is_signed_g        : boolean   := true;                                      -- analog trigger input signals are signed
          rst_pol_g          : std_logic := '1');                                      -- reset polarity
  port(   clk_i              : in  std_logic;                                          -- clk in    $$ type=clk; freq=100.0 $$
          rst_i              : in  std_logic;                                          -- rst in    $$ type=rst; clk=clk_i $$
          trg_mode_cfg_i     : in  std_logic_vector(0 downto 0);                       -- Trigger mode (0:Continuous,1:Single) configuration register
          trg_arm_cfg_i      : in  std_logic;                                          -- Arm/dis--arm the trigger, rising edge sensitive
          trg_edge_cfg_i     : in  std_logic_vector(1 downto 0);                       -- Trigger edge direction configuration register (bit0:falling edge sensitive, bit1: rising edge sensitive)
          trg_anlg_src_cfg_i : in  std_logic_vector(log2ceil(trig_nb_g) - 1 downto 0); -- Trigger source configuration  register
          anl_th_trig_i      : in  std_logic_vector(width_g - 1 downto 0);             -- analog trigger threshold value
          anl_trig_i         : in  std_logic_vector(trig_nb_g * width_g - 1 downto 0); -- Analog input values
          ext_disarm_i       : in  std_logic;                                          -- if different trigger causes are armed at the same time for a single trigger all the other cause must be disarmed once a trigger is generated
          trg_is_armed_i     : out std_logic;                                          -- trigger is armed and ready to be released
          trig_o             : out std_logic);                                         -- trigger output
end entity;
-- @formatter:on

architecture rtl of psi_common_trigger_analog is

  type two_process_r is record
    RegAnalogValueSigned       : signed(width_g - 1 downto 0);
    RegAnalogValueSigned_dff   : signed(width_g - 1 downto 0);
    RegAnalogValueUnsigned     : unsigned(width_g - 1 downto 0);
    RegAnalogValueUnsigned_dff : unsigned(width_g - 1 downto 0);
    RegAnalogThSigned          : signed(width_g - 1 downto 0);
    RegAnalogThUnsigned        : unsigned(width_g - 1 downto 0);
    OTrg                       : std_logic;
    TrgArmed                   : std_logic;
    InTrgArmCfg_dff            : std_logic;
  end record;

  signal r, r_next : two_process_r;

begin

  -- Combinatorial Process
  p_comb : process(r, trg_mode_cfg_i, trg_arm_cfg_i, anl_th_trig_i, anl_trig_i, trg_edge_cfg_i, trg_anlg_src_cfg_i, ext_disarm_i)
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

    -- Analog trigger
    v.OTrg := '0';

    if is_signed_g = true then     -- the analog value is signed

      v.RegAnalogValueSigned := signed(anl_trig_i((width_g * to_integer(unsigned(trg_anlg_src_cfg_i))) + (width_g - 1) downto width_g * to_integer(unsigned(trg_anlg_src_cfg_i))));

      v.RegAnalogValueSigned_dff := r.RegAnalogValueSigned;
      v.RegAnalogThSigned        := signed(anl_th_trig_i);
      if r.TrgArmed = '1' then
        if r.RegAnalogValueSigned_dff < r.RegAnalogThSigned and r.RegAnalogValueSigned >= r.RegAnalogThSigned and trg_edge_cfg_i(1) = '1' then --rising edge
          v.OTrg := '1';
        end if;
        if r.RegAnalogValueSigned_dff > r.RegAnalogThSigned and r.RegAnalogValueSigned <= r.RegAnalogThSigned and trg_edge_cfg_i(0) = '1' then --falling edge
          v.OTrg := '1';
        end if;
      end if;
    end if;

    if is_signed_g = false then    -- the analog value is unsigned

      v.RegAnalogValueUnsigned := unsigned(anl_trig_i((width_g * to_integer(unsigned(trg_anlg_src_cfg_i))) + (width_g - 1) downto width_g * to_integer(unsigned(trg_anlg_src_cfg_i))));

      v.RegAnalogValueUnsigned_dff := r.RegAnalogValueUnsigned;
      v.RegAnalogThUnsigned        := unsigned(anl_th_trig_i);
      if r.TrgArmed = '1' then
        if r.RegAnalogValueUnsigned_dff < r.RegAnalogThUnsigned and r.RegAnalogValueUnsigned >= r.RegAnalogThUnsigned and trg_edge_cfg_i(1) = '1' then --rising edge
          v.OTrg := '1';
        end if;
        if r.RegAnalogValueUnsigned_dff > r.RegAnalogThUnsigned and r.RegAnalogValueUnsigned <= r.RegAnalogThUnsigned and trg_edge_cfg_i(0) = '1' then --falling edge
          v.OTrg := '1';
        end if;
      end if;
    end if;

    -- *** Outputs ***

    trig_o         <= r.OTrg;
    trg_is_armed_i <= r.TrgArmed;
    -- Apply to record
    r_next         <= v;
  end process;

  -- Sequential Process
  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.RegAnalogValueSigned       <= (others => '0');
        r.RegAnalogValueSigned_dff   <= (others => '0');
        r.RegAnalogValueUnsigned     <= (others => '0');
        r.RegAnalogValueUnsigned_dff <= (others => '0');
        r.RegAnalogThSigned          <= (others => '0');
        r.RegAnalogThUnsigned        <= (others => '0');
        r.OTrg                       <= '0';
        r.TrgArmed                   <= '0';
        r.InTrgArmCfg_dff            <= '0';
      end if;
    end if;
  end process;

end architecture;
