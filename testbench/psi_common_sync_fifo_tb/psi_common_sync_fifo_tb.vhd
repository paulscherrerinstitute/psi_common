------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_tb_txt_util.all;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

entity psi_common_sync_fifo_tb is
  generic(
    alm_full_on_g   : boolean              := true;
    alm_empty_on_g  : boolean              := true;
    depth_g       : natural              := 32;
    ram_behavior_g : string               := "RBW";
    rdy_rst_state_g : integer range 0 to 1 := 1
  );
end entity psi_common_sync_fifo_tb;

architecture sim of psi_common_sync_fifo_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant DataWidth_c     : integer := 16;
  constant AlmFullLevel_c  : natural := depth_g - 3;
  constant AlmEmptyLevel_c : natural := 5;

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockFrequency_c : real    := 100.0e6;
  constant ClockPeriod_c    : time    := (1 sec) / ClockFrequency_c;
  signal TbRunning          : boolean := True;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal clk_i      : std_logic                                               := '0';
  signal rst_i      : std_logic                                               := '1';
  signal dat_i   : std_logic_vector(DataWidth_c - 1 downto 0)              := (others => '0');
  signal vld_i    : std_logic                                               := '0';
  signal rdy_o    : std_logic                                               := '0';
  signal dat_o  : std_logic_vector(DataWidth_c - 1 downto 0)              := (others => '0');
  signal vld_o   : std_logic                                               := '0';
  signal rdy_i   : std_logic                                               := '0';
  signal full_o     : std_logic                                               := '0';
  signal empty_o    : std_logic                                               := '0';
  signal alm_full_o  : std_logic                                               := '0';
  signal alm_empty_o : std_logic                                               := '0';
  signal in_level_o  : std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0)    := (others => '0');
  signal out_level_o : std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0)    := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_sync_fifo
    generic map(
      width_g         => DataWidth_c,
      depth_g         => depth_g,
      alm_full_on_g     => alm_full_on_g,
      alm_full_level_g  => AlmFullLevel_c,
      alm_empty_on_g    => alm_empty_on_g,
      alm_empty_level_g => AlmEmptyLevel_c,
      ram_behavior_g   => ram_behavior_g,
      rdy_rst_state_g   => int_to_std_logic(rdy_rst_state_g)
    )
    port map(
      clk_i      => clk_i,
      rst_i      => rst_i,
      dat_i   => dat_i,
      vld_i    => vld_i,
      rdy_o    => rdy_o,
      dat_o  => dat_o,
      vld_o   => vld_o,
      rdy_i   => rdy_i,
      full_o     => full_o,
      empty_o    => empty_o,
      alm_full_o  => alm_full_o,
      alm_empty_o => alm_empty_o,
      in_level_o  => in_level_o,
      out_level_o => out_level_o
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk : process
  begin
    clk_i <= '0';
    while TbRunning loop
      wait for 0.5 * ClockPeriod_c;
      clk_i <= '1';
      wait for 0.5 * ClockPeriod_c;
      clk_i <= '0';
    end loop;
    wait;
  end process;

  -------------------------------------------------------------------------
  -- TB Control
  -------------------------------------------------------------------------
  p_control : process
  begin
    -- *** Reset Tests ***
    print(">> Reset");
    -- Reset
    rst_i <= '1';
    wait until rising_edge(clk_i);
    -- check if ready state during reset is correct
    assert rdy_o = int_to_std_logic(rdy_rst_state_g) report "###ERROR###: rdy_o reset state not according to generic" severity error;
    wait for 1 us;

    -- Remove reset
    wait until rising_edge(clk_i);
    rst_i <= '0';

    -- Check Reset State
    wait until rising_edge(clk_i);
    assert rdy_o = '1' report "###ERROR###: rdy_o after reset state not '1'" severity error;
    assert vld_o = '0' report "###ERROR###: vld_o reset state not '0'" severity error;
    assert full_o = '0' report "###ERROR###: full_o reset state not '0'" severity error;
    assert empty_o = '1' report "###ERROR###: empty_o reset state not '1'" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o reset state not 0" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: in_level_o reset state not 0" severity error;
    if alm_full_on_g then
      assert alm_full_o = '0' report "###ERROR###: alm_full_o reset state not '0'" severity error;
    end if;
    if alm_empty_on_g then
      assert alm_empty_o = '1' report "###ERROR###: alm_empty_o reset state not '1'" severity error;
    end if;

    -- *** Two words write then read ***
    print(">> Two words write then read");
    -- Write 1
    wait until falling_edge(clk_i);
    dat_i <= X"0001";
    vld_i  <= '1';
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '0' report "###ERROR###: vld_o wnt high unexpectedly" severity error;
    assert empty_o = '1' report "###ERROR###: empty_o not high" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o not 0" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not 0" severity error;
    -- Write 2
    wait until falling_edge(clk_i);
    dat_i <= X"0002";
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '0' report "###ERROR###: vld_o wnt high unexpectedly" severity error;
    assert empty_o = '1' report "###ERROR###: empty_o not high" severity error;
    assert unsigned(in_level_o) = 1 report "###ERROR###: in_level_o not 1" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not 0" severity error;
    -- Pause 1
    wait until falling_edge(clk_i);
    dat_i <= X"0003";
    vld_i  <= '0';
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '1' report "###ERROR###: vld_o not high" severity error;
    assert dat_o = X"0001" report "###ERROR###: Illegal dat_o 1" severity error;
    assert empty_o = '0' report "###ERROR###: empty_o not low" severity error;
    assert unsigned(in_level_o) = 2 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 1 report "###ERROR###: out_level_o not 1" severity error;
    -- Pause 2
    wait until falling_edge(clk_i);
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '1' report "###ERROR###: vld_o not high" severity error;
    assert dat_o = X"0001" report "###ERROR###: Illegal dat_o 1" severity error;
    assert empty_o = '0' report "###ERROR###: empty_o not low" severity error;
    assert unsigned(in_level_o) = 2 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 2 report "###ERROR###: out_level_o not 2" severity error;
    -- Read ack 1
    wait until falling_edge(clk_i);
    rdy_i <= '1';
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '1' report "###ERROR###: vld_o not high" severity error;
    assert dat_o = X"0001" report "###ERROR###: Illegal dat_o 1" severity error;
    assert empty_o = '0' report "###ERROR###: empty_o not low" severity error;
    assert unsigned(in_level_o) = 2 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 2 report "###ERROR###: out_level_o not 2" severity error;
    -- Read ack 2
    wait until falling_edge(clk_i);
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '1' report "###ERROR###: vld_o not high" severity error;
    assert dat_o = X"0002" report "###ERROR###: Illegal dat_o 2" severity error;
    assert empty_o = '0' report "###ERROR###: empty_o not low" severity error;
    assert unsigned(in_level_o) = 2 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 1 report "###ERROR###: out_level_o not 2" severity error;
    -- empty 1
    wait until falling_edge(clk_i);
    rdy_i <= '0';
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '0' report "###ERROR###: vld_o not high" severity error;
    assert empty_o = '1' report "###ERROR###: empty_o not high" severity error;
    assert unsigned(in_level_o) = 1 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not 2" severity error;
    -- empty 2
    wait until falling_edge(clk_i);
    assert rdy_o = '1' report "###ERROR###: rdy_o went low unexpectedly" severity error;
    assert vld_o = '0' report "###ERROR###: vld_o not high" severity error;
    assert empty_o = '1' report "###ERROR###: empty_o not high" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o not 2" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not 2" severity error;

    -- *** Write into Full FIFO ***
    wait until falling_edge(clk_i);
    print(">> Write into full_o FIFO");
    -- Fill FIFO
    for i in 0 to depth_g - 1 loop
      vld_i  <= '1';
      dat_i <= std_logic_vector(to_unsigned(i, dat_i'length));
      wait until falling_edge(clk_i);
    end loop;
    vld_i  <= '0';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert full_o = '1' report "###ERROR###: Fully not asserted" severity error;
    assert unsigned(in_level_o) = depth_g report "###ERROR###: in_level_o not full_o" severity error;
    assert unsigned(out_level_o) = depth_g report "###ERROR###: out_level_o not full_o" severity error;
    -- Add more data (not written because full)
    vld_i  <= '1';
    dat_i <= X"ABCD";
    wait until falling_edge(clk_i);
    dat_i <= X"8765";
    wait until falling_edge(clk_i);
    vld_i  <= '0';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert full_o = '1' report "###ERROR###: Fully not asserted" severity error;
    assert unsigned(in_level_o) = depth_g report "###ERROR###: in_level_o not full_o" severity error;
    assert unsigned(out_level_o) = depth_g report "###ERROR###: out_level_o not full_o" severity error;
    -- Check read
    for i in 0 to depth_g - 1 loop
      rdy_i <= '1';
      assert unsigned(dat_o) = i report "###ERROR: Read wrong data in word " & integer'image(i) severity error;
      wait until falling_edge(clk_i);
    end loop;
    rdy_i <= '0';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
    assert full_o = '0' report "###ERROR###: Fully not de-asserted" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o not empty_o" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not empty_o" severity error;

    -- *** Read from Empty Fifo ***
    wait until falling_edge(clk_i);
    print(">> Read from empty_o FIFO");
    assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
    -- read
    wait until falling_edge(clk_i);
    rdy_i <= '1';
    wait until falling_edge(clk_i);
    rdy_i <= '0';
    -- check correct functionality
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o not empty_o" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not empty_o" severity error;
    vld_i  <= '1';
    dat_i <= X"8765";
    wait until falling_edge(clk_i);
    vld_i  <= '0';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert empty_o = '0' report "###ERROR###: empty_o not de-asserted" severity error;
    assert unsigned(in_level_o) = 1 report "###ERROR###: in_level_o not empty_o" severity error;
    assert unsigned(out_level_o) = 1 report "###ERROR###: out_level_o not empty_o" severity error;
    assert dat_o = X"8765" report "###ERROR: Read wrong data" severity error;
    rdy_i <= '1';
    wait until falling_edge(clk_i);
    rdy_i <= '0';
    wait until falling_edge(clk_i);
    wait until falling_edge(clk_i);
    assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
    assert unsigned(in_level_o) = 0 report "###ERROR###: in_level_o not empty_o" severity error;
    assert unsigned(out_level_o) = 0 report "###ERROR###: out_level_o not empty_o" severity error;

    -- *** Almost full/almost empty
    print(">> Almost full_o/almost empty_o");
    -- fill
    for i in 0 to depth_g - 1 loop
      vld_i  <= '1';
      dat_i <= std_logic_vector(to_unsigned(i, dat_i'length));
      wait until falling_edge(clk_i);
      vld_i  <= '0';
      wait until falling_edge(clk_i);
      wait until falling_edge(clk_i);
      assert unsigned(in_level_o) = i + 1 report "###ERROR###: in_level_o wrong" severity error;
      assert unsigned(out_level_o) = i + 1 report "###ERROR###: out_level_o wrong" severity error;
      if alm_full_on_g then
        if i + 1 >= AlmFullLevel_c then
          assert alm_full_o = '1' report "###ERROR###: Almost full_o not set" severity error;
        else
          assert alm_full_o = '0' report "###ERROR###: Almost full_o set" severity error;
        end if;
      end if;
      if alm_empty_on_g then
        if i + 1 <= AlmEmptyLevel_c then
          assert alm_empty_o = '1' report "###ERROR###: Almost empty_o not set" severity error;
        else
          assert alm_empty_o = '0' report "###ERROR###: Almost empty_o set" severity error;
        end if;
      end if;
    end loop;
    -- flush
    for i in depth_g - 1 downto 0 loop
      rdy_i <= '1';
      wait until falling_edge(clk_i);
      rdy_i <= '0';
      wait until falling_edge(clk_i);
      wait until falling_edge(clk_i);
      assert unsigned(in_level_o) = i report "###ERROR###: in_level_o wrong" severity error;
      assert unsigned(out_level_o) = i report "###ERROR###: out_level_o wrong" severity error;
      if alm_full_on_g then
        if i >= AlmFullLevel_c then
          assert alm_full_o = '1' report "###ERROR###: Almost full_o not set" severity error;
        else
          assert alm_full_o = '0' report "###ERROR###: Almost full_o set" severity error;
        end if;
      end if;
      if alm_empty_on_g then
        if i <= AlmEmptyLevel_c then
          assert alm_empty_o = '1' report "###ERROR###: Almost empty_o not set" severity error;
        else
          assert alm_empty_o = '0' report "###ERROR###: Almost empty_o set" severity error;
        end if;
      end if;
    end loop;

    -- Different duty cycles
    print(">> Different Duty Cycles");
    wait until falling_edge(clk_i);
    for wrDel in 0 to 4 loop
      for rdDel in 0 to 4 loop
        assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
        -- Write data
        for i in 0 to 4 loop
          vld_i  <= '1';
          dat_i <= std_logic_vector(to_unsigned(i, dat_i'length));
          wait until falling_edge(clk_i);
          for k in 1 to wrDel loop
            vld_i  <= '0';
            dat_i <= X"0000";
            wait until falling_edge(clk_i);
          end loop;
        end loop;
        vld_i  <= '0';
        -- Read data
        for i in 0 to 4 loop
          rdy_i <= '1';
          assert unsigned(dat_o) = i report "###ERROR###: Wrong data" severity error;
          wait until falling_edge(clk_i);
          for k in 1 to rdDel loop
            rdy_i <= '0';
            wait until falling_edge(clk_i);
          end loop;
        end loop;
        rdy_i <= '0';
        assert empty_o = '1' report "###ERROR###: empty_o not asserted" severity error;
      end loop;
    end loop;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
