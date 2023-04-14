----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso, Radoslaw Rybaniec
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------------------
library IEEE;
use IEEE.MATH_REAL.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.psi_common_math_pkg.all;
use work.psi_tb_compare_pkg.all;

entity psi_common_prbs_tb is
  generic(width_g : natural range 2 to 32         := 10;
          seed_g  : natural := 2**3-1
         );
end psi_common_prbs_tb;

architecture behav of psi_common_prbs_tb is

  -- Constants
  constant N     : natural               := width_g;                                -- Data width
  constant X     : natural range 2 to 16 := 4;                                      -- 2^X slower than the current clock
  constant CYCLE : integer               := choose(width_g < 20, (2**N) - 1, 1024); -- Expected cycle

  -- Type
  type mem_t is array (0 to CYCLE - 1) of std_logic_vector((N - 1) downto 0);

  -- Signals
  signal rst   : std_logic := '1';
  signal clk   : std_logic := '0';
  signal istrb : std_logic := '0';
  signal ostrb : std_logic;

  signal seed : std_logic_vector((N - 1) downto 0) := (others => '0');
  signal data : std_logic_vector((N - 1) downto 0);

  signal delay : unsigned((X - 1) downto 0) := (others => '0');

  signal pulse : std_logic := '0';
  signal sync  : std_logic := '0';
  signal lsync : std_logic := '0';
  signal en    : std_logic := '1';

  signal tb_run : boolean   := true;
  signal done   : std_logic := '0';
  signal flag   : std_logic := '0';
  signal mem    : mem_t;
  signal count  : integer   := 0;
  
  -- helper for 9 bits lfsr
  signal data_test : std_logic_vector(9 downto 0);

begin

  istrb <= pulse when en = '1' else delay(X - 1);
  sync  <= delay(X - 1);

  tb_ctrl_p : process
  begin
    wait until done = '1';
    tb_run <= false;
    wait;
  end process;

  -- Clock generator
  clk_p : process
  begin
    while (tb_run = true) loop
      wait for 5 ns;
      clk <= not clk;
    end loop;
    wait;
  end process;

  -- Simple clock div
  cdiv_p : process(clk)
  begin
    if (rising_edge(clk)) then
      delay <= delay + 1;
    end if;
  end process;

  -- Simple strobe generator based on the delay period
  strb_p : process(clk)
  begin
    if (rising_edge(clk)) then
      if (sync = '1' and lsync = '0') then
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
    assert width_g < 20 report "####WARNING###: MEM ALLOCATION to big for tb Width > 20" severity warning;
    rst  <= '0' after 17 ns;
    wait until rising_edge(clk);
    seed <= to_uslv(seed_g,32)((N - 1) downto 0);
    --wait for 20 ns;
    --wait until rising_edge(clk);
    --seed <= to_uslv(from_uslv(seed) + 5, seed'length);
    wait;
  end process;

  -- Assertion process : It stores the first CYCLE generated data and then compares it
  -- with the next CYCLE generated data. The same data is expected.
  assrt_p : process(clk)
  begin
    if (rst = '0') then
      if rising_edge(clk) then
        if ostrb = '1' then
          StdlvCompareStdlv(data_test, data,"Mismatch data for PRBS-9");
          count <= count + 1;
        end if;
        if count = 1000 then
          done <= '1';
        end if;
      end if;
    else  -- reset
      count <= 0;
    end if;
  end process;

  -- DUT
  u_prbs : entity work.psi_common_prbs
    generic map(width_g   => N,
                rst_pol_g => '1'
               )
    port map(rst_i  => rst,
             clk_i  => clk,
             vld_i => istrb,
             seed_i => seed,
             vld_o => ostrb,
             dat_o => data);
             
  -----------------------------------------------------------
  -- TAG : check with doulos 10 bit lfsr version & seed FF
  -----------------------------------------------------------
  assert N = 10 report "Testbench supports only width_g = 10 bits" severity failure;
  
  GEN_LFSR: if N = 10 generate
    u_test : entity work.maximal_length_lfsr
    port map(
      clock    => clk,
      reset    => rst,
      seed     => seed(N-1 downto 0),
      str      => istrb,
      
      
      data_out => data_test);
  end generate GEN_LFSR;
       
end behav;
