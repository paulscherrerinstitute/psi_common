--=================================================================
--	Paul Scherrer Institut <PSI> Villigen, Schweiz
-- 	Copyright ©, 2019, Benoit STEF, all rights reserved 
--=================================================================
-- unit		:  psi_common_pp_buf_tb(tb)
-- file		:  psi_common_pp_buf_tb.vhd
-- project	: 
-- Author	: stef_b - 8221 DSV group WBBA/311
--					  benoit.stef@psi.ch
--					  PSI Aarebrücke
--					  CH-5232 Villigen - Switzerland
-- purpose	:  
-- SIM tool	: Modelsim SE 10.6
-- EDA tool	: 
-- Target	: Xilinx FPGA Virtex-6  - xc6vlx130t-1fff1156 
-- misc		:
-- date		: 04.10.2019
--=================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

use work.psi_tb_activity_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_tb_compare_pkg.all;

entity psi_common_pp_buf_tb is
	generic(freq_data_clk_g : real    := 97.0E6; -- data clock frequency 					<=> Hz
	        ratio_str_g     : real    := 10.0; -- ratio  between clock and data to write 	<=> clock cycle
	        freq_mem_clk_g  : real    := 120.0E6; -- read clock frequency						<=> Hz
	        ch_nb_g         : natural := 4; -- number of channels						<=> n/a
	        sample_nb_g     : natural := 6; -- number of sample per buffer				<=> n/a
	        dat_length_g    : natural := 14); -- number of bit, data						<=> n/a
end entity;

architecture tb of psi_common_pp_buf_tb is

	constant period_w_c : time      := (1 sec) / freq_data_clk_g;
	constant period_r_c : time      := (1 sec) / freq_mem_clk_g;
	signal proc_clk_sti : std_logic := '0';
	signal mem_clk_sti  : std_logic := '1';
	signal proc_rst_sti : std_logic := '1';

	signal proc_irq_s   	: std_logic                                                                := '0';
	signal proc_irq_sti   : std_logic                                                                := '0';
	signal proc_dat_sti   : std_logic_vector(ch_nb_g * dat_length_g - 1 downto 0)                    := (others => 'L');
	signal proc_str_s     : std_logic                                                                := '0';
	signal proc_str_sti   : std_logic                                                                := '0';
	signal mem_addr_s		: integer := 0;
	signal mem_addr_sti   : std_logic_vector(log2ceil(ch_nb_g) + log2ceil(sample_nb_g) - 1 downto 0) := (others => '0');
	signal mem_dat_obs    : std_logic_vector(dat_length_g - 1 downto 0);
	--
	signal tb_run_s       : boolean                                                                  := true;
	signal count_sample_s : integer                                                                  := 0;
	signal count_ch_s     : integer                                                                  := 0;
	--
	type data_array_t is array (0 to ch_nb_g - 1) of std_logic_vector(dat_length_g - 1 downto 0);
	signal data_array_s   : data_array_t                                                             := (others => (others => 'L'));
	signal mem_array_s   : data_array_t                                                             := (others => (others => 'L'));

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
	signal flag_s : std_logic;
	--
begin

	assert (real(ch_nb_g) < ratio_str_g) report "###ERROR###: The number of channel is too large comapred to the data strobe frequency" severity error;

	--===========================================================
	--*** TAG Reset generation ***
	proc_rst : process
	begin
		wait for 3 * period_w_c;
		wait until rising_edge(proc_clk_sti);
		wait until rising_edge(proc_clk_sti);
		proc_rst_sti <= '0';
		wait;
	end process;

	--===========================================================
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

	--===========================================================
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

	--=================================================================
	--*** TAG emulation Strobe/Valid for data input ***
	proc_strob_tdm : process
	begin
		while tb_run_s loop
			GenerateStrobe(freq_data_clk_g, 								-- frequency clock       
			               freq_data_clk_g / ratio_str_g, 					-- frequency strobe      
			               '1', proc_rst_sti, proc_clk_sti,proc_str_s);
		end loop;
		wait;
	end process;
	proc_str_sti <= transport proc_str_s after 2 * period_w_c;
	--=================================================================
	--*** TAG Strobe generation ***
	proc_strob_irq : process
	begin
		while tb_run_s loop
			GenerateStrobe(freq_data_clk_g, 								  -- frequency clock
			               freq_data_clk_g / ratio_str_g / real(sample_nb_g), -- frequency strobe
			               '1',proc_rst_sti,proc_clk_sti,proc_irq_s); 
		end loop;
		wait;
	end process;
	proc_irq_sti <= transport proc_irq_s after 3 * period_w_c;
	--===========================================================
	--*** TAG DUT***
	inst_dut : entity work.psi_common_pp_buf
		generic map(ch_nb_g      => ch_nb_g,
		            sample_nb_g  => sample_nb_g,
		            dat_length_g => dat_length_g,
		            behavior_g   => "RBW", --fixed read before write
		            rst_pol_g    => '1') --fixed active high
		port map(clk_i      => proc_clk_sti,
		         rst_i      => proc_rst_sti,
		         irq_i      => proc_irq_sti,
		         dat_i      => proc_dat_sti,
		         str_i      => proc_str_sti,
		         mem_clk_i  => mem_clk_sti,
		         mem_addr_i => mem_addr_sti,
		         mem_dat_o  => mem_dat_obs);

	--===========================================================
	--*** TAG stimuli process generate data to write ***
	proc_stim_dat : process(proc_clk_sti)
	begin
		if rising_edge(proc_clk_sti) then
			if proc_rst_sti = '1' then
				data_array_s <= (others=>(others=>'0'));
				proc_dat_sti <= (others=>'0');
			
			else
				if proc_str_s = '1' then
					
			
					for i in 0 to ch_nb_g - 1 loop
						data_array_s(i) <= std_logic_vector(to_unsigned((count_sample_s + i), dat_length_g));
					end loop;
					
					if count_sample_s = sample_nb_g then
						count_sample_s <= 0;
					else
						count_sample_s 	<= count_sample_s + 1;
					end if;
				end if;
			
				
				proc_dat_sti <= data_array_2_slv(data_array_s, ch_nb_g);
			end if;
		end if;
	end process;

	--===========================================================
	--*** TAG stimuli process generate data to write ***
	--proc_obs_dat : process(mem_clk_sti)
	--begin
	--	if rising_edge(mem_clk_sti) then
						
	--		if flag_s = '1' then
	--			count_ch_s <= mem_addr_s/sample_nb_g;--to_integer(unsigned(mem_addr_sti(mem_addr_sti'high downto 2**log2ceil(sample_nb_g) - 1)));	
	--		end if;
	--					
	--	end if;
	--end process;
	
	--===========================================================
	--*** convert int to slv for mem addr ***
	mem_addr_sti <= std_logic_vector(to_unsigned(mem_addr_s,mem_addr_sti'length));

	--===========================================================
	--*** check process ***
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
		for i in 0 to 7 loop
			wait until proc_irq_sti = '1' and rising_edge(mem_clk_sti);
			report "Burst read: Start" severity note;
			wait until rising_edge(mem_clk_sti);
			wait until rising_edge(mem_clk_sti);

			for i in 0 to ch_nb_g * 2**log2ceil(sample_nb_g) - 1 loop
				flag_s <= '1';
				--*** counter channel depending on address read ***
				count_ch_s <= mem_addr_s/(2**log2ceil(sample_nb_g));
				wait for period_r_c;
				mem_addr_s  <= mem_addr_s+1 ;
					
				
			end loop;	
			mem_addr_s <= 0;
			flag_s <= '0';
			report "Burst read: End" severity note;

		end loop;
		wait for period_w_c;
		tb_run_s <= false;
		wait;
	end process;

end architecture;
