----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use IEEE.MATH_REAL.all;

library work;
use work.psi_common_prbs_pkg.all;

----------------------------------------------------------------------------------
-- Entity
----------------------------------------------------------------------------------

entity psi_common_prbs_tb is
--  Port ( );
end psi_common_prbs_tb;

----------------------------------------------------------------------------------
-- Architecture
----------------------------------------------------------------------------------

architecture sim of psi_common_prbs_tb is


	-- Constants
	constant N 		:	natural := 8;
	constant X 		:	natural range 2 to 16  := 4;					-- 2^X slower than the current clock
	constant CYCLE 	:	integer := (2**N) - 1; -- Expected cycle

	-- Type
	type mem_t is array(0 to CYCLE-1) of std_logic_vector((N-1) downto 0);

	-- Signals
	signal rst 	:	std_logic := '1';
	signal clk 	:	std_logic := '0';
	signal strb :	std_logic := '0';

	signal seed :	std_logic_vector((N-1) downto 0) := (others => '0');
	signal data :	std_logic_vector((N-1) downto 0);


	signal delay :	std_logic_vector((X-1) downto 0):= (others => '0');

	signal pulse :	std_logic := '0';
	signal sync  :	std_logic := '0';
	signal lsync :	std_logic := '0';
	signal en 	 :	std_logic := '1';


	signal tb_run:	boolean	  := true;
	signal done	 :	std_logic := '0';
	signal flag  :	std_logic := '0';
	signal mem	 :	mem_t;
	signal count : 	integer := 0;
begin

	strb <= pulse when en = '1' else delay(X-1);
	sync <= delay(X-1);

	tb_ctrl_p : process
	begin
  		wait until done = '1';
  		tb_run <= false;
  		wait;
	end process;


	-- Clock generator
	clk_p : process
	begin
		while(tb_run = true) loop
			wait for 5 ns;
			clk <= not clk;
		end loop;
		wait;
	end process;

	-- Simple clock div
	cdiv_p : process(clk)
	begin
  		if(rising_edge(clk)) then
    		delay <= delay + 1;
  		end if;
	end process;

	-- Simple strobe generator based on the delay period
	strb_p : process(clk)
	begin
		if(rising_edge(clk)) then
			if(sync = '1' and lsync = '0') then
				pulse <= '1';
			else
				pulse <= '0';	
			end if;
			lsync <= sync;
		end if;
	end process;

	-- Stimul process that provides a initial seed and then attempt to modify it
	-- after 20 ns, no modification is expected
	stim_p : process
	begin
		rst <= '0' after 17 ns;
		seed <= x"02";
		wait for 20 ns;
		seed <= x"10";
		wait;
	end process;

	-- Assertion process : It stores the first CYCLE generated data and then compares it
	-- with the next CYCLE generated data. The same data is expected.
	assrt_p : process(data)
	begin
		if(rst = '0') then
			if(count < CYCLE-1) then
				count <= count + 1;
			elsif(flag = '0') then
				flag <= '1';
				count <= 0;
			else
				done <= '1';
			end if;

			if(flag = '1') then
				assert data = mem(count) report "###ERROR### Mismatch on data!" severity error;
			else
				mem(count) <= data;
			end if;
		end if;
	end process;

	-- DUT
	u_prbs : entity work.psi_common_prbs
	generic map( width_g   => N,
				 rst_pol_g => '1'
			   )
	port map( rst_i	 => rst,
			  clk_i  => clk,
			  str_i  => strb,
			  seed_i => seed,
			  data_o => data
			);

end sim;