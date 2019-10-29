------------------------------------------------------------------------------
--	Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Benoit Stef, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------


------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

entity psi_common_pp_buf  is
	generic(ch_nb_g  			: natural 	:= 16;															-- Channel number -> master 8
			sample_nb_g 		: natural 	:= 1012;														-- sample number per memory space 
			dat_length_g		: positive	:= 16;															-- data width in bits
			behavior_g			: string	:= "RBW";														-- ram behavior "RBW"|"WBR" -> cf RAM
			rst_pol_g			: std_logic	:= '1');														-- reset polarity
	port(	clk_i  				: in  std_logic;															-- clock data
	     	rst_i  				: in  std_logic;															-- rst data
	     	irq_i				: in  std_logic;															-- array strobe (ie expect freq -> ratio str & sample number)
	     	dat_i 				: in  std_logic_vector(ch_nb_g*dat_length_g-1 downto 0);					-- data input
			str_i				: in  std_logic;															-- strobe input (ie valid)
			--*** mem read interface ***
			mem_clk_i 			: in  std_logic;															-- clock mem 
			mem_addr_i			: in  std_logic_vector(log2ceil(ch_nb_g)+log2ceil(sample_nb_g)-1 downto 0); -- address mem read
	    	mem_dat_o 			: out std_logic_vector(dat_length_g-1 downto 0)								-- data mem read 
	    );
end entity;

architecture rtl of psi_common_pp_buf is
-- internals
attribute keep              : string;	
constant ram_depth_c		: integer := 2*ch_nb_g*2**(log2ceil(sample_nb_g/2))-1 ;	-- cst to define the ram depth
signal dat_s 				: std_logic_vector(dat_length_g-1 downto 0);			-- pipe entry stage for data
signal str_s 				: std_logic;											-- pipe entry stage for strobe
signal dpram_data_write_s	: std_logic_vector(dat_length_g-1 downto 0);			-- data to write within RAMs
signal ch_offs_count_s 		: unsigned(log2ceil(2*ch_nb_g) downto 0);				-- channel counter <=> helper
signal ch_offs_s 			: unsigned(log2ceil(2*ch_nb_g)-1 downto 0);				-- channel counter <=> offset 	RAM addres (MSB)
signal sample_s 			: unsigned(log2ceil(sample_nb_g)-1 downto 0);			-- sample counter  <=> base 	RAM address (LSB)
signal dpram_add_s			: std_logic_vector(log2ceil(ram_depth_c) downto 0);		-- RAMs address
signal irq_s				: std_logic;											-- used to make edge detect
signal toggle_s				: std_logic;											-- toggle bit for ping & pong
signal cdc_toggle_s			: std_logic_vector(1 downto 0);							-- select
signal wren_s 				: std_logic;											-- write enable RAM1
signal str_dff_s			: std_logic;
signal dat_dff_s			: std_logic_vector(dat_length_g-1 downto 0);
signal tmem_read_add_s 		: std_logic_vector(log2ceil(ram_depth_c) downto 0);

begin

	--=================================================================
	-- TAG Process CTRL
	--=================================================================
	proc_ctrl : process(clk_i)
	begin
		if rising_edge(clk_i) then
			if rst_i = rst_pol_g then
				--*** init ***
				sample_s			<= to_unsigned(sample_nb_g-1,sample_s'length);
				irq_s        		<= '0';
				toggle_s     		<= '0';			
				wren_s 	<= '0';	
				ch_offs_count_s 	<= (others=>'0');
				dpram_add_s 		<= (others=>'0');
				dat_s 				<= (others=>'0');
				str_s				<= '0' ;
				str_dff_s 		 	<= '0';
				dat_dff_s  			<= (others=>'0');
				
			else
				--*** 1 pipe ***
				irq_s 		<= irq_i;
				dat_s 		<= dat_i;
				str_s		<= str_i;
				
				--*** additional pipe to manage counter and logic properly ***
				str_dff_s <= str_s;
				dat_dff_s <= dat_s;
				
				--*** reset the counter upon IRQ 50Hz & toggle buffer & page counter ***
				if irq_i = '1' and irq_s='0' then
					toggle_s 	 		<= not toggle_s;
				end if;
								
				--*** channel counter  ***				
				if  ch_offs_count_s = 2*ch_nb_g then
					ch_offs_count_s <= (others=>'0');
				else		
					if str_s = '1' then
						ch_offs_count_s <= ch_offs_count_s+1;
					end if;			
				end if;
				
				--*** sample counter ***
				if sample_s = sample_nb_g-1 and str_s='1' and ch_offs_count_s = 0  then
					sample_s <= (others => '0');	
				else
					if str_s = '1' and ch_offs_count_s = 0 then
						sample_s <= sample_s+1;
					end if;
				end if; 
			
				--*** DPRAM address write ***
				dpram_add_s <= toggle_s & std_logic_vector(ch_offs_s) & std_logic_vector(sample_s(sample_s'high downto 1));
				
				--*** concat 16 -> 32 bits for tosca ***
				if ch_offs_s(0) = '0' and str_dff_s = '1' then
					dpram_data_write_s <= dat_dff_s;
				end if;
								
				--*** wrena RAM1 ***
				if 	str_dff_s = '1' and sample_s(0) = '0' then
					wren_s <= '1';
				else
					wren_s <= '0';
				end if;
					
			end if;
		end if;		
	end process;
	
	--*** keep as logic non clocked ***
	ch_offs_s 	<= ch_offs_count_s(log2ceil(2*ch_nb_g)-1 downto 0)-1 	when ch_offs_count_s > 0 else (others=>'0');

	--=================================================================
	-- TAG cdc for toggle 
	-- double stage synchronizer
	--=================================================================
	proc_cdc : process(mem_clk_i)
	begin
		if rising_edge(mem_clk_i) then
			cdc_toggle_s(0) <= toggle_s;
			cdc_toggle_s(1) <= cdc_toggle_s(0);
		end if;
	end process;
	tmem_read_add_s <= not cdc_toggle_s(1) & mem_addr_i;
	
	--=================================================================
	-- TAG PING PONG Buffer
	--=================================================================
	inst_dpram_pp_15to0 : entity work.psi_common_tdp_ram
		generic map(Depth_g    	=> 2**log2ceil(2*ram_depth_c),
					Width_g    	=> dat_length_g,
					Behavior_g 	=> behavior_g)
		port map(	ClkA  		=> clk_i,
					AddrA 		=> dpram_add_s,
					WrA   		=> wren_s,
					DinA  		=> dpram_data_write_s,
					DoutA 		=> open,
					--
					ClkB  		=> mem_clk_i,
					AddrB 		=> tmem_read_add_s,
					WrB   		=> '0',
					DinB  		=> (others=>'0'),
					DoutB 		=> mem_dat_o);
	
end architecture;