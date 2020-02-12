------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Daniele Felici
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- 

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;

use work.psi_common_array_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_trigger_generator is
	generic (
		--freq_clock_g	: real		:= 100.0; -- Clock Frequency in MHz		$$ export=true $$
		digital_trg_g : boolean := true; -- digital trigger mechanism is generated
		digital_sources_width_g : integer := 1; -- number of digital trigger inputs
		analog_trg_g : boolean := true; -- analog trigger mechanism is generated
		analog_sources_width_g : integer := 32; -- number of analog trigger inputs
		analog_trg_width_g : integer := 16; -- analog trigger input signal width
		analog_trg_signed_g : boolean := true; -- analog trigger input signal width
		rst_pol_g		: std_logic	:= '1'		-- reset polarity
	);
	port (
		InClk	: in	std_logic;			--clk in		$$ type=clk; freq=100.0 $$
		InRst	: in	std_logic;			--rst in		$$ type=rst; clk=clk_i $$
		--InDelay : real := 0.0; -- -- delay in us
		InTrgTypeCfg : in std_logic_vector (1 downto 0); -- Trigger type (00:Digital,01:Analog, ...) configuration register
		InTrgModeCfg : in std_logic_vector (1 downto 0); -- Trigger mode (00:Continuous,01:Single) configuration register --in multi stream, but in general??
		InTrgArmCfg : in std_logic; -- Arm/de-arm the trigger, rising edge sensitive
    InTrgEdgeCfg : in std_logic_vector (1 downto 0); -- Trigger edge direction configuration register (bit0:fslling edge sensitive, bit1: rising edge sensitive)
    
    InTrgDigitalSourceCfg : in integer range integer(ceil(log2(real(digital_sources_width_g)))) downto 0; -- Trigger source configuration  register
    InDigitalTrg  : in  std_logic_vector (digital_sources_width_g - 1 downto 0);  -- digital trigger input 
		
		InTrgAnalogSourceCfg : in integer range integer(ceil(log2(real(analog_sources_width_g)))) downto 0; -- Trigger source configuration  register
		InAnalogThTrg : in std_logic_vector (analog_trg_width_g - 1 downto 0); -- analog trigger threshold value
		InAnalogTrg : in t_aslv16 (analog_sources_width_g - 1 downto 0); -- Analog input values
		
		OutTrgIsArmed :out std_logic;
		OutTrigger	: out	std_logic			-- trigger output
	);
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_trigger_generator is

	--constant ratio_c 	: integer := integer(ceil(freq_clock_g/freq_strobe_g));
	
	type two_process_r is record
	 --delay_cnt		: integer range 0 to ratio_c;
	 RegAnalogValueSigned : signed (analog_trg_width_g - 1 downto 0);
	 RegAnalogValueSigned_c : signed (analog_trg_width_g - 1 downto 0);
	 RegAnalogValueUnsigned : unsigned (analog_trg_width_g - 1 downto 0);
	 RegAnalogValueUnsigned_c : unsigned (analog_trg_width_g - 1 downto 0);
	 RegAnalogThSigned : signed (analog_trg_width_g - 1 downto 0);
	 RegAnalogThUnsigned : unsigned (analog_trg_width_g - 1 downto 0);
	 RegDigitalValue_c : std_logic;
	 OAnalogTrg : std_logic;
	 ODigitalTrg : std_logic;
	 OTrg : std_logic;
	 TrgArmed : std_logic;
	 InTrgArmCfg_c : std_logic;
  end record;
  
  signal r, r_next : two_process_r;

begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(r, InTrgModeCfg, InTrgTypeCfg, InTrgArmCfg, InAnalogThTrg, InAnalogTrg, InTrgEdgeCfg, InDigitalTrg)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- *** Implementation ***
    v.InTrgArmCfg_c := InTrgArmCfg;
    
    v.TrgArmed  := r.TrgArmed;
    
    if r.OTrg ='1' and InTrgModeCfg = "01"  then -- if single mode, the triggei is de-armed once the trigger is generated
      v.TrgArmed  := '0';
    elsif InTrgArmCfg = '1' and r.InTrgArmCfg_c ='0'  then -- toggle arm or de-arm
      v.TrgArmed  := not r.TrgArmed;
    end if;

    
    v.ODigitalTrg := '0';
    -- Digital Trigger
    if digital_trg_g = true then
      
      v. RegDigitalValue_c  := InDigitalTrg(InTrgDigitalSourceCfg);
      if InTrgTypeCfg = "00" and r.TrgArmed ='1' then
        if r.RegDigitalValue_c = '0' and InDigitalTrg(InTrgDigitalSourceCfg)='1' and InTrgEdgeCfg(1)='1'  then --rising edge
          v.ODigitalTrg := '1';
        end if;
        if r.RegDigitalValue_c = '1' and InDigitalTrg(InTrgDigitalSourceCfg)='0' and InTrgEdgeCfg(0)='1'  then --falling edge
          v.ODigitalTrg := '1';
        end if;
      end if;
    
    end if;  
    
    -- Analog trigger
    v.OAnalogTrg := '0';
    
    
    if analog_trg_g = true then
      
      if analog_trg_signed_g = true then -- the analog value is signed
  
        v.RegAnalogValueSigned  := signed(InAnalogTrg(InTrgAnalogSourceCfg));
        v.RegAnalogValueSigned_c  := v.RegAnalogValueSigned;
        v.RegAnalogThSigned := signed(InAnalogThTrg);
        if InTrgTypeCfg = "01" and r.TrgArmed ='1' then
          if r.RegAnalogValueSigned_c < v.RegAnalogThSigned  and v.RegAnalogValueSigned >= v.RegAnalogThSigned  and InTrgEdgeCfg(1)='1'  then --rising edge
            v.OAnalogTrg := '1';
          end if;
          if r.RegAnalogValueSigned_c > v.RegAnalogThSigned  and v.RegAnalogValueSigned <= v.RegAnalogThSigned  and InTrgEdgeCfg(0)='1'  then --falling edge
            v.OAnalogTrg := '1';
          end if;
        end if;
      end if;
      
      if analog_trg_signed_g = false then -- the analog value is unsigned
        
        v.RegAnalogValueUnsigned  := unsigned(InAnalogTrg(InTrgAnalogSourceCfg));
        v.RegAnalogValueUnsigned_c  := v.RegAnalogValueUnsigned;
        v.RegAnalogThUnsigned := unsigned(InAnalogThTrg);
        if InTrgTypeCfg = "01" and r.TrgArmed ='1' then
          if r.RegAnalogValueUnsigned_c < v.RegAnalogThUnsigned  and v.RegAnalogValueUnsigned >= v.RegAnalogThUnsigned  and InTrgEdgeCfg(1)='1'  then --rising edge
            v.OAnalogTrg := '1';
          end if;
          if r.RegAnalogValueUnsigned_c > v.RegAnalogThUnsigned  and v.RegAnalogValueUnsigned <= v.RegAnalogThUnsigned  and InTrgEdgeCfg(0)='1'  then --falling edge
            v.OAnalogTrg := '1';
          end if;
        end if;
      end if;
      
    end if; 
    
    v.OTrg := v.OAnalogTrg or v.ODigitalTrg;
    
    -- *** Outputs ***
    
    OutTrigger <= v.OTrg;
    OutTrgIsArmed <=v.TrgArmed; 
    -- Apply to record
    r_next <= v;

  end process;

  --------------------------------------------------------------------------
  -- Sequential Process
  --------------------------------------------------------------------------  
  p_seq : process(InClk)
  begin
    if rising_edge(InClk) then
      r <= r_next;
      if InRst = rst_pol_g then
        r.RegAnalogValueSigned  <= (others  => '0');
        r.RegAnalogValueSigned_c  <= (others  => '0');
        r.RegAnalogValueUnsigned  <= (others  => '0');
        r.RegAnalogValueUnsigned_c  <= (others  => '0');
        r.RegAnalogThSigned <= (others  => '0');
        r.RegAnalogThUnsigned <= (others  => '0');
        r.RegDigitalValue_c <= '0';
        r.OAnalogTrg <= '0';
        r.ODigitalTrg <= '0';
        r.OTrg <= '0';
        r.TrgArmed <= '0';
        r.InTrgArmCfg_c <= '0';
      end if;
    end if;
  end process;

end architecture;
