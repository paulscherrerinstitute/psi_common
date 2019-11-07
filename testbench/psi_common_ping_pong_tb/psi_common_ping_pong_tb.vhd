------------------------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
--This testbench verify if the ping pong buffer is able to manage different
--channel inputs with specific data frequency and number of sample to record.
--one assert is made to verify the nominal mechanism
--others asserts prevent misuses of the component    

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_activity_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_compare_pkg.all;

entity psi_common_ping_pong_tb is
	generic(freq_data_clk_g : real    := 100.0E6; -- data clock frequency <=> Hz
	        ratio_str_g     : real    := 10.0; -- ratio  between clock and data to write <=> clock cycle
	        freq_mem_clk_g  : real    := 120.0E6; -- read clock frequency <=> Hz
	        ch_nb_g         : natural := 4; -- number of channels <=> n/a
	        sample_nb_g     : natural := 6; -- number of sample per buffer <=> n/a
	        dat_length_g    : natural := 14; -- number of bit per data <=> n/a
	        tdm_g           : boolean := true); -- using the buffer in time division multiplexed mode
end entity;

architecture tb of psi_common_ping_pong_tb is
	
	constant period_w_c     : time                                                                     := (1 sec) / freq_data_clk_g;
	constant period_r_c     : time                                                                     := (1 sec) / freq_mem_clk_g;
	signal proc_clk_sti     : std_logic                                                                := '0';
	signal mem_clk_sti      : std_logic                                                                := '1';
	signal proc_rst_sti     : std_logic                                                                := '1';
	signal proc_dat_par_sti : std_logic_vector(ch_nb_g * dat_length_g - 1 downto 0)                    := (others => 'L');
	signal proc_dat_tdm_sti : std_logic_vector(dat_length_g - 1 downto 0)                              := (others => 'L');
	signal proc_dat_sti     : std_logic_vector(choose(tdm_g, dat_length_g-1, ch_nb_g*dat_length_g-1) downto 0);
	signal proc_str_s       : std_logic                                                                := '0';
	signal proc_str_par_sti : std_logic                                                                := '0';
	signal proc_str_tdm_sti : std_logic                                                                := '0';
	signal proc_str_sti     : std_logic                                                                := '0';
	signal mem_addr_s       : integer                                                                  := 0;
	signal mem_addr_sti     : std_logic_vector(log2ceil(ch_nb_g) + log2ceil(sample_nb_g) - 1 downto 0) := (others => '0');
	signal mem_addr_ch_sti	: std_logic_vector(log2ceil(ch_nb_g) - 1 downto 0) 						   := (others => '0');
	signal mem_addr_spl_sti : std_logic_vector(log2ceil(sample_nb_g) - 1 downto 0) 					   := (others => '0');
	signal mem_irq_obs      : std_logic;
	signal mem_dat_obs      : std_logic_vector(dat_length_g - 1 downto 0);
	signal mem_dat_check_s  : integer                                                                  := 0;
	signal tb_run_s         : boolean                                                                  := true;
	signal count_sample_s   : integer                                                                  := 0;
	signal count_ch_s       : integer                                                                  := 0;
	signal flag_s           : std_logic                                                                := '0';
	signal count_sp_s       : integer                                                                  := 0;
	type data_array_t is array (0 to ch_nb_g - 1) of std_logic_vector(dat_length_g - 1 downto 0);
	signal data_array_s     : data_array_t                                                             := (others => (others => 'L'));

	--*** TAG resolution function to trasnform array of EXT_FORMAT_c to slv ***
	function data_array_2_slv(signal data_i      : in data_array_t;
	                          constant ch_number : natural) return std_logic_vector is
		constant width_c : natural := dat_length_g;
		variable data_v  : std_logic_vector(ch_number * width_c - 1 downto 0);
	begin
		for i in 0 to ch_number - 1 loop
			data_v((i + 1) * width_c - 1 downto i * width_c) := data_i(i);
		end loop;
		return data_v;
	end function;

begin
	--*** General ASSERTs to use the component properly***
	assert (real(ch_nb_g) <= ratio_str_g)
	report "###ERROR###: The number of channel is too large comapred to the data strobe frequency"
	severity failure;

	assert not (freq_data_clk_g = freq_mem_clk_g and ratio_str_g = 1.0)
	report "###ERROR###: The data ratio and reading speeding clock are equivalent, it is not feasable"
	severity failure;

	--*** TAG Reset generation ***
	proc_rst : process
	begin
		wait for 3 * period_w_c;
		wait until rising_edge(proc_clk_sti);
		wait until rising_edge(proc_clk_sti);
		proc_rst_sti <= '0';
		wait until proc_str_tdm_sti = '1' and rising_edge(proc_clk_sti);
		--*** Sync because latency created by par2tdm bloc ***
		if tdm_g then
			proc_rst_sti <= '1';
			wait until rising_edge(proc_clk_sti);
			wait until rising_edge(proc_clk_sti);
			proc_rst_sti <= '0';
		end if;
		wait;
	end process;

	--*** TAG clock process ***
	proc_clk : process
		variable tStop_v : time;
	begin
		while tb_run_s or (now < tStop_v + 1 us) loop
			if tb_run_s then
				tStop_v := now;
			end if;
			wait for 0.5 * period_w_c;
			proc_clk_sti <= not proc_clk_sti;
			wait for 0.5 * period_w_c;
			proc_clk_sti <= not proc_clk_sti;
		end loop;
		wait;
	end process;

	--*** TAG clock process ***
	proc_mem_clk : process
		variable tStop_v : time;
	begin
		while tb_run_s or (now < tStop_v + 1 us) loop
			if tb_run_s then
				tStop_v := now;
			end if;
			wait for 0.5 * period_r_c;
			mem_clk_sti <= not mem_clk_sti;
			wait for 0.5 * period_r_c;
			mem_clk_sti <= not mem_clk_sti;
		end loop;
		wait;
	end process;

	--*** TAG emulation Strobe/Valid for data input ***
	proc_strob_tdm : process
	begin
		while tb_run_s loop
			GenerateStrobe(freq_data_clk_g, freq_data_clk_g / ratio_str_g,
			               '1', proc_rst_sti, proc_clk_sti, proc_str_s);
		end loop;
		wait;
	end process;
	proc_str_par_sti <= transport proc_str_s after 2 * period_w_c;

	--*** PAR2TDM ***
	tdm_gene : if tdm_g generate
		par2tdm_inst : entity work.psi_common_par_tdm
			generic map(ChannelCount_g => ch_nb_g,
			            ChannelWidth_g => dat_length_g)
			port map(Clk         => proc_clk_sti,
			         Rst         => proc_rst_sti,
			         Parallel    => proc_dat_par_sti,
			         ParallelVld => proc_str_par_sti,
			         Tdm         => proc_dat_tdm_sti,
			         TdmVld      => proc_str_tdm_sti);
	end generate;

	proc_dat_sti <= proc_dat_tdm_sti when tdm_g else proc_dat_par_sti;
	proc_str_sti <= proc_str_tdm_sti when tdm_g else proc_str_par_sti;

	--*** convert int to slv for mem addr ***
	mem_addr_sti <= std_logic_vector(to_unsigned(mem_addr_s, mem_addr_sti'length));

	--*** TAG DUT***
	mem_addr_ch_sti		<= mem_addr_sti(mem_addr_sti'high downto mem_addr_spl_sti'length);
	mem_addr_spl_sti	<= mem_addr_sti(mem_addr_spl_sti'range);
	inst_dut : entity work.psi_common_ping_pong
		generic map(ch_nb_g        => ch_nb_g,
		            sample_nb_g    => sample_nb_g,
		            dat_length_g   => dat_length_g,
		            tdm_g          => tdm_g,
		            ram_behavior_g => "RBW", --fixed read before write
		            rst_pol_g      => '1') --fixed active high
		port map(clk_i      	=> proc_clk_sti,
		         rst_i      	=> proc_rst_sti,
		         dat_i      	=> proc_dat_sti,
		         str_i      	=> proc_str_sti,
		         mem_irq_o  	=> mem_irq_obs,
		         mem_clk_i  	=> mem_clk_sti,
		         mem_addr_ch_i 	=> mem_addr_ch_sti,
				 mem_addr_spl_i => mem_addr_spl_sti,
		         mem_dat_o  	=> mem_dat_obs);

	--*** TAG stimuli process generate data to write ***
	proc_stim_dat : process(proc_clk_sti)
	begin
		if rising_edge(proc_clk_sti) then
			if proc_rst_sti = '1' then
				data_array_s     <= (others => (others => '0'));
				proc_dat_par_sti <= (others => '0');

			else
				if proc_str_s = '1' then

					for i in 0 to ch_nb_g - 1 loop
						data_array_s(i) <= std_logic_vector(to_unsigned((count_sample_s + i), dat_length_g));
					end loop;

					if count_sample_s = sample_nb_g - 1 then
						count_sample_s <= 0;
					else
						count_sample_s <= count_sample_s + 1;
					end if;
				end if;

				proc_dat_par_sti <= data_array_2_slv(data_array_s, ch_nb_g);
			end if;
		end if;
	end process;

	--*** TAG process helper to check data read clock proc ***
	proc_obs_dat : process(mem_clk_sti)
	begin
		if rising_edge(mem_clk_sti) then

			if flag_s = '1' then
				--*** count for sample ***
				if count_sp_s = 2**log2ceil(sample_nb_g) - 1 then
					count_sp_s <= 0;
				else
					count_sp_s <= count_sp_s + 1;
				end if;

				--*** counter channel depending on address read ***
				count_ch_s <= mem_addr_s / (2**log2ceil(sample_nb_g));
			else
				count_ch_s      <= 0;
				count_sp_s      <= 0;
			end if;

		end if;
	end process;
	
	--*** TAG calculate expected value ***
	process (count_ch_s, count_sp_s, flag_s)
		begin
			if flag_s = '1' then
				if count_sp_s >= sample_nb_g then
					mem_dat_check_s <= 0;
				else
					mem_dat_check_s <= count_sp_s + count_ch_s;
				end if;
			else
				mem_dat_check_s <= 0;
		end if;
	end process;
	
	--*** TAG check process ***
	proc_check : process
		variable lout_v : line;
	begin
		-------------------------------------------------------------------------------
		write(lout_v, string'(" *************************************************  "));
		writeline(output, lout_v);
		write(lout_v, string'(" **          Paul Scherrer Institut             **  "));
		writeline(output, lout_v);
		write(lout_v, string'(" **         psi_common_pp_buf_tb TestBench      **  "));
		writeline(output, lout_v);
		write(lout_v, string'(" *************************************************  "));
		writeline(output, lout_v);
		-------------------------------------------------------------------------------
		wait until mem_irq_obs = '1' and rising_edge(mem_clk_sti);
		
		for i in 0 to 7 loop
			wait until mem_irq_obs = '1' and rising_edge(mem_clk_sti);
			report "Burst Read Start" severity note;

			wait until rising_edge(mem_clk_sti);
			wait until rising_edge(mem_clk_sti);

			for i in 0 to ch_nb_g * 2**log2ceil(sample_nb_g) - 1 loop
				flag_s     <= '1';
				wait for period_r_c;
				mem_addr_s <= mem_addr_s + 1;
				--*** check value, it does then check sample and channel alignment ***
				assert mem_dat_check_s = to_integer(unsigned(mem_dat_obs)) report "###ERROR###: data expected is wrong" severity error;
			end loop;
			mem_addr_s <= 0;
			flag_s     <= '0';
		end loop;

		wait for period_w_c;
		tb_run_s <= false;
		wait;
	end process;

end architecture;
