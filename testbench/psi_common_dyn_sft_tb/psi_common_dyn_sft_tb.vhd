------------------------------------------------------------
-- Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
------------------------------------------------------------

------------------------------------------------------------
-- Testbench generated by TbGen.py
------------------------------------------------------------
-- see Library/Python/TbGenerator

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	use ieee.math_real.all;

library work;
  use work.psi_common_array_pkg.all;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;
  use work.psi_tb_activity_pkg.all;
  use work.psi_tb_compare_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_dyn_sft_tb is
	generic (
		Direction_g : string := "LEFT" ;
		SelectBitsPerStage_g : positive := 4 ;
		SignExtend_g : boolean := true 
	);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_dyn_sft_tb is
	-- *** Fixed Generics ***
	constant MaxShift_g : positive := 20;
	constant Width_g : positive := 32;
	
	-- *** Not Assigned Generics (default values) ***
	
	-- *** TB Control ***
	signal TbRunning : boolean := True;
	signal NextCase : integer := -1;
	signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
	constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
	constant TbProcNr_inp_c : integer := 0;
	constant TbProcNr_outp_c : integer := 1;
	
	-- *** DUT Signals ***
	signal Clk : std_logic := '1';
	signal Rst : std_logic := '1';
	signal InVld : std_logic := '0';
	signal InShift : std_logic_vector(log2ceil(MaxShift_g+1)-1 downto 0) := (others => '0');
	signal InData : std_logic_vector(Width_g-1 downto 0) := (others => '0');
	signal OutVld : std_logic := '0';
	signal OutData : std_logic_vector(Width_g-1 downto 0) := (others => '0');
  
  constant ClkPerSpl_c    : integer := 1;
  type Random_a is array (natural range <>) of std_logic_vector(31 downto 0);
  constant Random_c : Random_a(0 to 3) := (X"ABCD1234", X"A1B2C3D4", X"12345678", X"87654321");
  constant Shift_c : t_ainteger(0 to 3) := (0, 10, 12, 20); 
	
begin
	------------------------------------------------------------
	-- DUT Instantiation
	------------------------------------------------------------
	i_dut : entity work.psi_common_dyn_sft
		generic map (
			Direction_g => Direction_g,
			SelectBitsPerStage_g => SelectBitsPerStage_g,
			SignExtend_g => SignExtend_g,
			MaxShift_g => MaxShift_g,
			Width_g => Width_g
		)
		port map (
			Clk => Clk,
			Rst => Rst,
			InVld => InVld,
			InShift => InShift,
			InData => InData,
			OutVld => OutVld,
			OutData => OutData
		);
	
	------------------------------------------------------------
	-- Testbench Control !DO NOT EDIT!
	------------------------------------------------------------
	p_tb_control : process
	begin
		wait until Rst = '0';
		wait until ProcessDone = AllProcessesDone_c;
		TbRunning <= false;
		wait;
	end process;
	
	------------------------------------------------------------
	-- Clocks !DO NOT EDIT!
	------------------------------------------------------------
	p_clock_Clk : process
		constant Frequency_c : real := real(100e6);
	begin
		while TbRunning loop
			wait for 0.5*(1 sec)/Frequency_c;
			Clk <= not Clk;
		end loop;
		wait;
	end process;
	
	
	------------------------------------------------------------
	-- Resets
	------------------------------------------------------------
	p_rst_Rst : process
	begin
		wait for 1 us;
		-- Wait for two clk edges to ensure reset is active for at least one edge
		wait until rising_edge(Clk);
		wait until rising_edge(Clk);
		Rst <= '0';
		wait;
	end process;
	
	
	------------------------------------------------------------
	-- Processes
	------------------------------------------------------------
	-- *** inp ***
	p_inp : process
	begin
		-- start of process !DO NOT EDIT
		wait until Rst = '0';
		
		-- User Code
		wait until rising_edge(Clk);
    
    for si in Shift_c'low to Shift_c'high loop
      -- Moving ones
      for i in 0 to Width_g-1 loop
        InData    <= (others => '0');
        InData(i) <= '1';
        InShift   <= to_uslv(Shift_c(si), InShift'length);
        InVld     <= '1';
        wait until rising_edge(Clk);
        if ClkPerSpl_c > 1 then
          InVld     <= '0';
          InShift   <= (others => '0');
          WaitClockCycles(ClkPerSpl_c-1, Clk);
        end if;
      end loop;
      
      -- Random numbers
      for i in Random_c'low to Random_c'high loop
        InData    <= Random_c(i);
        InVld     <= '1';
        InShift   <= to_uslv(Shift_c(si), InShift'length);
        wait until rising_edge(Clk);
        if ClkPerSpl_c > 1 then
          InVld     <= '0';
          InShift   <= (others => '0');
          WaitClockCycles(ClkPerSpl_c-1, Clk);
        end if;  
      end loop;
    end loop;
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_inp_c) <= '1';
		wait;
	end process;
	
	-- *** outp ***
	p_outp : process
    variable InData_v : std_logic_vector(31 downto 0);
    variable Shift_v : integer;
	begin
		-- start of process !DO NOT EDIT
		wait until Rst = '0';
		
    for si in Shift_c'low to Shift_c'high loop
      Shift_v := Shift_c(si);
      -- Moving ones
      for i in 0 to Width_g-1 loop
        InData_v    := (others => '0');
        InData_v(i) := '1';
        wait until rising_edge(Clk) and OutVld = '1';
        if Direction_g = "LEFT" then
          StdlvCompareStdlv(ShiftLeft(InData_v, Shift_v, '0'), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        elsif SignExtend_g then
          StdlvCompareStdlv(ShiftRight(InData_v, Shift_v, InData_v(InData_v'high)), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        else 
          StdlvCompareStdlv(ShiftRight(InData_v, Shift_v, '0'), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        end if;
      end loop;
      
      -- Random numbers
      for i in Random_c'low to Random_c'high loop
        InData_v    := Random_c(i);
        wait until rising_edge(Clk) and OutVld = '1';
        if Direction_g = "LEFT" then
          StdlvCompareStdlv(ShiftLeft(InData_v, Shift_v, '0'), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        elsif SignExtend_g then
          StdlvCompareStdlv(ShiftRight(InData_v, Shift_v, InData_v(InData_v'high)), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        else 
          StdlvCompareStdlv(ShiftRight(InData_v, Shift_v, '0'), OutData, "Wrong Data: SFT=" & to_string(Shift_v) & " IN=" & to_string(InData_v));
        end if;
      end loop;
    end loop;
		
		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_outp_c) <= '1';
		wait;
	end process;
	
	
end;
