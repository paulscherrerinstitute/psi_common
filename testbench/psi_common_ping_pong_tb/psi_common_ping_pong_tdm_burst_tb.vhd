------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_common_array_pkg.all;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_ping_pong_tdm_burst_tb is
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_ping_pong_tdm_burst_tb is

	signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
	constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
	constant TbProcNr_inp_c     : integer                  := 0;
	constant TbProcNr_outp_c    : integer                  := 1;
	signal TbRunning            : boolean                  := true;

	signal clk_i          : std_logic                     := '0';
	signal rst_i          : std_logic                     := '1';
	signal dat_i          : std_logic_vector(15 downto 0) := (others => '0');
	signal str_i          : std_logic                     := '0';
	signal mem_irq_o      : std_logic                     := '0';
	signal mem_clk_i      : std_logic                     := '0';
	signal mem_addr_spl_i : std_logic_vector(2 downto 0)  := (others => '0');
	signal mem_addr_ch_i  : std_logic_vector(1 downto 0)  := (others => '0');
	signal mem_dat_o      : std_logic_vector(15 downto 0) := (others => '0');

begin
	------------------------------------------------------------
	-- DUT Instantiation
	------------------------------------------------------------
	i_dut : entity work.psi_common_ping_pong
		generic map(ch_nb_g        => 3,
		            depth_g    => 6,
		            width_g   => 16,
		            tdm_g          => true,
		            ram_behavior_g => "RBW",
		            rst_pol_g      => '1')
		port map(clk_i          => clk_i,
		         rst_i          => rst_i,
		         dat_i          => dat_i,
		         vld_i          => str_i,
		         mem_irq_o      => mem_irq_o,
		         mem_clk_i      => mem_clk_i,
		         mem_addr_spl_i => mem_addr_spl_i,
		         mem_addr_ch_i  => mem_addr_ch_i,
		         mem_dat_o      => mem_dat_o
		        );

	------------------------------------------------------------
	-- Testbench Control !DO NOT EDIT!
	------------------------------------------------------------
	p_tb_control : process
	begin
		wait until rst_i = '0';
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
			wait for 0.5 * (1 sec) / Frequency_c;
			clk_i <= not clk_i;
		end loop;
		wait;
	end process;

	p_clock_mem : process
		constant Frequency_c : real := real(80e6);
	begin
		while TbRunning loop
			wait for 0.5 * (1 sec) / Frequency_c;
			mem_clk_i <= not mem_clk_i;
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
		wait until rising_edge(clk_i);
		wait until rising_edge(clk_i);
		rst_i <= '0';
		wait;
	end process;

	------------------------------------------------------------
	-- Processes
	------------------------------------------------------------
	-- *** inp ***
	p_inp : process
		variable SampleNr_v : integer := 0;
	begin
		-- start of process !DO NOT EDIT
		wait until rst_i = '0';
		wait until rising_edge(clk_i);

		-- Produce 6 x sursts of 4 samples (on all channels) = 24 samples = iterate through both buffers twice
		for iteration in 0 to 5 loop
			for sample in 0 to 3 loop
				for channel in 0 to 2 loop
					dat_i <= std_logic_vector(to_unsigned(channel, 8) & to_unsigned(SampleNr_v, 8));
					str_i <= '1';
					wait until rising_edge(clk_i);
				end loop;
				SampleNr_v := SampleNr_v + 1;
			end loop;

			-- At the end of the iteration, wait for a while before next burst starts to not write faster than read is possible
			str_i <= '0';
			for i in 0 to 199 loop
				wait until rising_edge(clk_i);
			end loop;
		end loop;

		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_inp_c) <= '1';
		wait;
	end process;

	-- *** outp ***
	p_outp : process
		variable SampleNr_v : integer := 0;
	begin
		-- start of process !DO NOT EDIT
		wait until rst_i = '0';
		wait until rising_edge(mem_clk_i);

		-- We expect four buffers comming in
		for buf in 0 to 3 loop
			wait until rising_edge(mem_clk_i) and mem_irq_o = '1';
			for sample in 0 to 5 loop
				for channel in 0 to 2 loop
					wait until rising_edge(mem_clk_i);
					mem_addr_ch_i  <= std_logic_vector(to_unsigned(channel, 2));
					mem_addr_spl_i <= std_logic_vector(to_unsigned(sample, 3));
					wait until rising_edge(mem_clk_i);
					wait until falling_edge(mem_clk_i);
					StdlvCompareStdlv(std_logic_vector(to_unsigned(channel, 8) & to_unsigned(SampleNr_v, 8)), mem_dat_o,
					                  "Wrong data: buf=" & to_string(buf) & ", sample=" & to_string(sample) & ", channel=" & to_string(channel));
					assert mem_dat_o = std_logic_vector(to_unsigned(channel, 8) & to_unsigned(SampleNr_v, 8));
				end loop;
				SampleNr_v := SampleNr_v + 1;
			end loop;
		end loop;

		-- end of process !DO NOT EDIT!
		ProcessDone(TbProcNr_outp_c) <= '1';
		wait;
	end process;

end;
