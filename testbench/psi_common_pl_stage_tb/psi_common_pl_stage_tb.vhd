------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

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
use work.psi_tb_compare_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_pl_stage_tb is
  generic(
    handle_rdy_g : boolean := true
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_pl_stage_tb is
  -- *** Fixed Generics ***

  -- *** Not Assigned Generics (default values) ***
  constant width_g : integer := 8;

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_check_c   : integer                  := 1;

  -- *** DUT Signals ***
  signal clk_i     : std_logic                              := '0';
  signal rst_i     : std_logic                              := '1';
  signal vld_i   : std_logic                              := '0';
  signal rdy_o   : std_logic                              := '0';
  signal dat_i  : std_logic_vector(width_g - 1 downto 0) := (others => '0');
  signal vld_o  : std_logic                              := '0';
  signal rdy_i  : std_logic                              := '0';
  signal dat_o : std_logic_vector(width_g - 1 downto 0) := (others => '0');

  -- Handwritten
  signal done     : boolean := False;
  signal testcase : integer := -1;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_pl_stage
    generic map(
      use_rdy_g => handle_rdy_g
    )
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i   => vld_i,
      rdy_o   => rdy_o,
      dat_i  => dat_i,
      vld_o  => vld_o,
      rdy_i  => rdy_i,
      dat_o => dat_o
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
  -- *** stim ***
  p_stim : process
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- Single Samples	
    print(">> Single Samples");
    testcase <= 0;
    wait until rising_edge(clk_i);
    for i in 0 to 4 loop
      assert rdy_o = '1' or not handle_rdy_g report "###ERROR###: rdy_o went low unexpectedly" severity error;
      dat_i <= std_logic_vector(to_unsigned(i, width_g));
      vld_i  <= '1';
      for i in 0 to 9 loop
        wait until rising_edge(clk_i);
        vld_i <= '0';
        assert rdy_o = '1' or not handle_rdy_g report "###ERROR###: rdy_o went low unexpectedly" severity error;
      end loop;
    end loop;
    if done /= true then
      wait until done = true;
    end if;

    -- Streaming	
    print(">> Streaming");
    testcase <= 1;
    wait until rising_edge(clk_i);
    vld_i    <= '1';
    for i in 0 to 15 loop
      assert rdy_o = '1' or not handle_rdy_g report "###ERROR###: rdy_o went low unexpectedly" severity error;
      dat_i <= std_logic_vector(to_unsigned(i, width_g));
      wait until rising_edge(clk_i);
    end loop;
    vld_i    <= '0';
    if done /= true then
      wait until done = true;
    end if;

    -- Test Back Pressure		
    if handle_rdy_g then
      print(">> Back Pressure");
      testcase <= 2;
      wait until rising_edge(clk_i);
      for inDel in 3 downto 0 loop
        for outDel in 0 to 3 loop
          for val in 1 to 8 loop
            vld_i  <= '1';
            dat_i <= std_logic_vector(to_unsigned(val, width_g));
            wait until rising_edge(clk_i) and rdy_o = '1';
            for j in 0 to inDel - 1 loop
              vld_i <= '0';
              wait until rising_edge(clk_i);
            end loop;
          end loop;
          vld_i <= '0';
          wait for 1 us;
          wait until rising_edge(clk_i);
        end loop;
      end loop;
      if done /= true then
        wait until done = true;
      end if;
    end if;

    -- Valid does not wait for Ready
    if handle_rdy_g then
      print(">> Valid does not wait for Ready");
      testcase <= 3;
      wait until rising_edge(clk_i);
      for outDel in 0 to 10 loop
        for val in 1 to 4 loop
          vld_i  <= '1';
          dat_i <= std_logic_vector(to_unsigned(val, width_g));
          wait until rising_edge(clk_i) and rdy_o = '1';
        end loop;
        vld_i <= '0';
        wait for 1 us;
        wait until rising_edge(clk_i);
      end loop;
      if done /= true then
        wait until done = true;
      end if;
    end if;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** check ***
  p_check : process
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- Test Single Samples
    wait until testcase = 0;
    done <= False;
    if handle_rdy_g then
      rdy_i <= '1';
    end if;
    for i in 0 to 4 loop
      wait until rising_edge(clk_i) and vld_o = '1';
      StdlvCompareInt(i, dat_o, "Wrong Data");
    end loop;
    done <= True;

    -- Test Streaming
    wait until testcase = 1;
    done <= False;
    if handle_rdy_g then
      rdy_i <= '1';
    end if;
    for i in 0 to 15 loop
      wait until rising_edge(clk_i) and vld_o = '1';
      StdlvCompareInt(i, dat_o, "Wrong Data");
    end loop;
    done <= True;

    -- Test Back Pressure
    if handle_rdy_g then
      wait until testcase = 2;
      done <= False;
      for inDel in 3 downto 0 loop
        for outDel in 0 to 3 loop
          for val in 1 to 8 loop
            rdy_i <= '1';
            wait until rising_edge(clk_i) and vld_o = '1';
            StdlvCompareInt(val, dat_o, "Wrong Data");
            for j in 0 to outDel - 1 loop
              rdy_i <= '0';
              wait until rising_edge(clk_i);
            end loop;
          end loop;
        end loop;
      end loop;
      done <= True;
    end if;

    -- Valid does not wait for Ready
    if handle_rdy_g then
      wait until testcase = 3;
      done   <= False;
      rdy_i <= '0';
      wait until rising_edge(clk_i);
      for outDel in 0 to 10 loop
        for val in 1 to 4 loop
          if vld_o /= '1' then
            wait until vld_o = '1';
          end if;
          for i in 0 to outDel - 1 loop
            wait until rising_edge(clk_i);
            assert vld_o = '1' report "###ERROR###: vld_o went low" severity error;
          end loop;
          wait for 1 ns;
          rdy_i <= '1';
          StdlvCompareInt(val, dat_o, "Wrong Data");
          wait until rising_edge(clk_i);
          wait for 1 ns;
          rdy_i <= '0';
        end loop;
      end loop;
      done   <= True;
    end if;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_check_c) <= '1';
    wait;
  end process;

end;
