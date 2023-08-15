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

entity psi_common_async_fifo_tb is
  generic(
    afull_on_g      : boolean              := true;
    aempty_on_g     : boolean              := true;
    depth_g         : natural              := 32;
    ram_behavior_g  : string               := "RBW";
    rdy_rst_state_g : integer range 0 to 1 := 1
  );
end entity psi_common_async_fifo_tb;

architecture sim of psi_common_async_fifo_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------
  constant DataWidth_c     : integer := 16;
  constant AlmFullLevel_c  : natural := depth_g - 3;
  constant AlmEmptyLevel_c : natural := 5;

  -------------------------------------------------------------------------
  -- TB Defnitions
  -------------------------------------------------------------------------
  constant ClockInFrequency_c  : real    := 100.0e6;
  constant ClockInPeriod_c     : time    := (1 sec) / ClockInFrequency_c;
  constant ClockOutFrequency_c : real    := 83.333e6;
  constant ClockOutPeriod_c    : time    := (1 sec) / ClockOutFrequency_c;
  signal TbRunning             : boolean := True;

  shared variable CheckNow : boolean := False;

  -------------------------------------------------------------------------
  -- Interface Signals
  -------------------------------------------------------------------------
  signal in_clk_i     : std_logic                                            := '0';
  signal in_rst_i     : std_logic                                            := '1';
  signal out_clk_i    : std_logic                                            := '0';
  signal out_rst_i    : std_logic                                            := '1';
  signal in_dat_i     : std_logic_vector(DataWidth_c - 1 downto 0)           := (others => '0');
  signal in_vld_i     : std_logic                                            := '0';
  signal in_rdy_o     : std_logic                                            := '0';
  signal out_dat_o    : std_logic_vector(DataWidth_c - 1 downto 0)           := (others => '0');
  signal out_vld_o    : std_logic                                            := '0';
  signal out_rdy_i    : std_logic                                            := '0';
  signal in_full_o    : std_logic                                            := '0';
  signal out_full_o   : std_logic                                            := '0';
  signal in_empty_o   : std_logic                                            := '0';
  signal out_empty_o  : std_logic                                            := '0';
  signal in_afull_o   : std_logic                                            := '0';
  signal out_afull_o  : std_logic                                            := '0';
  signal in_aempty_o  : std_logic                                            := '0';
  signal out_aempty_o : std_logic                                            := '0';
  signal in_lvl_o     : std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0) := (others => '0');
  signal out_lvl_o    : std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0) := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_async_fifo
    generic map(
      width_g         => DataWidth_c,
      depth_g         => depth_g,
      afull_on_g      => afull_on_g,
      afull_lvl_g     => AlmFullLevel_c,
      aempty_on_g     => aempty_on_g,
      aempty_level_g  => AlmEmptyLevel_c,
      ram_behavior_g  => ram_behavior_g,
      rdy_rst_state_g => int_to_std_logic(rdy_rst_state_g)
    )
    port map(
      -- Control Ports
      in_clk_i     => in_clk_i,
      in_rst_i     => in_rst_i,
      out_clk_i    => out_clk_i,
      out_rst_i    => out_rst_i,
      -- Input Data
      in_dat_i     => in_dat_i,
      in_vld_i     => in_vld_i,
      in_rdy_o     => in_rdy_o,
      -- Output Data
      out_dat_o    => out_dat_o,
      out_vld_o    => out_vld_o,
      out_rdy_i    => out_rdy_i,
      -- Input Status
      in_full_o    => in_full_o,
      in_empty_o   => in_empty_o,
      in_afull_o   => in_afull_o,
      in_aempty_o  => in_aempty_o,
      in_lvl_o     => in_lvl_o,
      -- Output Status
      out_full_o   => out_full_o,
      out_empty_o  => out_empty_o,
      out_afull_o  => out_afull_o,
      out_aempty_o => out_aempty_o,
      out_lvl_o    => out_lvl_o
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk_in : process
  begin
    in_clk_i <= '0';
    while TbRunning loop
      wait for 0.5 * ClockInPeriod_c;
      in_clk_i <= '1';
      wait for 0.5 * ClockInPeriod_c;
      in_clk_i <= '0';
    end loop;
    wait;
  end process;

  p_clk_out : process
  begin
    out_clk_i <= '0';
    while TbRunning loop
      wait for 0.5 * ClockOutPeriod_c;
      out_clk_i <= '1';
      wait for 0.5 * ClockOutPeriod_c;
      out_clk_i <= '0';
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
    in_rst_i  <= '1';
    out_rst_i <= '1';
    -- check if ready state during reset is correct
    wait for 20 ns;                     -- reset must be transferred to other clock domain
    wait until rising_edge(in_clk_i);
    assert in_rdy_o = int_to_std_logic(rdy_rst_state_g) report "###ERROR###: in_rdy_o reset state not according to generic" severity error;
    wait for 1 us;

    -- Remove reset
    wait until rising_edge(in_clk_i);
    in_rst_i  <= '0';
    wait until rising_edge(out_clk_i);
    out_rst_i <= '0';
    wait for 100 ns;

    -- Check Reset State
    wait until rising_edge(in_clk_i);
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o after reset state not '1'" severity error;
    assert in_full_o = '0' report "###ERROR###: in_full_o reset state not '0'" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o reset state not '1'" severity error;
    assert unsigned(in_lvl_o) = 0 report "###ERROR###: in_lvl_o reset state not 0" severity error;
    if afull_on_g then
      assert in_afull_o = '0' report "###ERROR###: in_afull_o reset state not '0'" severity error;
    end if;
    if aempty_on_g then
      assert in_aempty_o = '1' report "###ERROR###: in_aempty_o reset state not '1'" severity error;
    end if;

    wait until rising_edge(out_clk_i);
    assert out_vld_o = '0' report "###ERROR###: out_vld_o reset state not '0'" severity error;
    assert out_full_o = '0' report "###ERROR###: out_full_o reset state not '0'" severity error;
    assert out_empty_o = '1' report "###ERROR###: out_empty_o reset state not '1'" severity error;
    assert unsigned(out_lvl_o) = 0 report "###ERROR###: out_lvl_o reset state not 0" severity error;
    if afull_on_g then
      assert out_afull_o = '0' report "###ERROR###: out_afull_o reset state not '0'" severity error;
    end if;
    if aempty_on_g then
      assert out_aempty_o = '1' report "###ERROR###: out_aempty_o reset state not '1'" severity error;
    end if;

    -- *** Two words write then read ***
    print(">> Two words write then read");
    -- Write 1
    wait until falling_edge(in_clk_i);
    in_dat_i  <= X"0001";
    in_vld_i  <= '1';
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o went low unexpectedly" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not high" severity error;
    assert unsigned(in_lvl_o) = 0 report "###ERROR###: in_lvl_o not 0" severity error;
    -- Write 2
    wait until falling_edge(in_clk_i);
    in_dat_i  <= X"0002";
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o went low unexpectedly" severity error;
    assert in_empty_o = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(in_lvl_o) = 1 report "###ERROR###: in_lvl_o not 1" severity error;
    -- Pause 1
    wait until falling_edge(in_clk_i);
    in_dat_i  <= X"0003";
    in_vld_i  <= '0';
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o went low unexpectedly" severity error;
    assert in_empty_o = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(in_lvl_o) = 2 report "###ERROR###: in_lvl_o not 2" severity error;
    -- Pause 2
    for i in 0 to 4 loop
      wait until falling_edge(in_clk_i);
      wait until falling_edge(out_clk_i);
    end loop;
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o went low unexpectedly" severity error;
    assert out_vld_o = '1' report "###ERROR###: out_vld_o not high" severity error;
    assert out_dat_o = X"0001" report "###ERROR###: Illegal out_dat_o 1" severity error;
    assert in_empty_o = '0' report "###ERROR###: in_empty_o not low" severity error;
    assert in_full_o = '0' report "###ERROR###: in_full_o not low" severity error;
    assert out_empty_o = '0' report "###ERROR###: in_empty_o not low" severity error;
    assert out_full_o = '0' report "###ERROR###: in_full_o not low" severity error;
    assert unsigned(in_lvl_o) = 2 report "###ERROR###: in_lvl_o not 2" severity error;
    assert unsigned(out_lvl_o) = 2 report "###ERROR###: out_lvl_o not 2" severity error;
    -- Read ack 1
    wait until falling_edge(out_clk_i);
    out_rdy_i <= '1';
    assert out_vld_o = '1' report "###ERROR###: out_vld_o not high" severity error;
    assert out_dat_o = X"0001" report "###ERROR###: Illegal out_dat_o 1" severity error;
    assert out_empty_o = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(out_lvl_o) = 2 report "###ERROR###: out_lvl_o not 2" severity error;
    -- Read ack 2
    wait until falling_edge(out_clk_i);
    assert out_vld_o = '1' report "###ERROR###: out_vld_o not high" severity error;
    assert out_dat_o = X"0002" report "###ERROR###: Illegal out_dat_o 2" severity error;
    assert out_empty_o = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(out_lvl_o) = 1 report "###ERROR###: out_lvl_o not 1" severity error;
    -- empty 1
    wait until falling_edge(out_clk_i);
    out_rdy_i <= '0';
    assert out_vld_o = '0' report "###ERROR###: out_vld_o not high" severity error;
    assert out_empty_o = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(out_lvl_o) = 0 report "###ERROR###: out_lvl_o not 0" severity error;
    -- empty 2
    for i in 0 to 4 loop
      wait until falling_edge(out_clk_i);
      wait until falling_edge(in_clk_i);
    end loop;
    assert in_rdy_o = '1' report "###ERROR###: in_rdy_o went low unexpectedly" severity error;
    assert out_vld_o = '0' report "###ERROR###: out_vld_o not high" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not high" severity error;
    assert out_empty_o = '1' report "###ERROR###: out_empty_o not high" severity error;
    assert in_full_o = '0' report "###ERROR###: in_full_o not low" severity error;
    assert out_full_o = '0' report "###ERROR###: out_full_o not low" severity error;
    assert unsigned(in_lvl_o) = 0 report "###ERROR###: in_lvl_o not 0" severity error;
    assert unsigned(out_lvl_o) = 0 report "###ERROR###: out_lvl_o not 0" severity error;

    -- *** Write into Full FIFO ***
    wait until falling_edge(in_clk_i);
    print(">> Write into Full FIFO");
    -- Fill FIFO
    for i in 0 to depth_g - 1 loop
      in_vld_i <= '1';
      in_dat_i <= std_logic_vector(to_unsigned(i, in_dat_i'length));
      wait until falling_edge(in_clk_i);
    end loop;
    in_vld_i  <= '0';
    wait for 1 us;
    assert in_full_o = '1' report "###ERROR###: in_full_o not asserted" severity error;
    assert out_full_o = '1' report "###ERROR###: out_full_o not asserted" severity error;
    assert unsigned(in_lvl_o) = depth_g report "###ERROR###: in_lvl_o not full" severity error;
    assert unsigned(out_lvl_o) = depth_g report "###ERROR###: out_lvl_o not full" severity error;
    -- Add more data (not written because full)
    wait until falling_edge(in_clk_i);
    in_vld_i  <= '1';
    in_dat_i  <= X"ABCD";
    wait until falling_edge(in_clk_i);
    in_dat_i  <= X"8765";
    wait until falling_edge(in_clk_i);
    in_vld_i  <= '0';
    wait for 1 us;
    assert in_full_o = '1' report "###ERROR###: in_full_o not asserted" severity error;
    assert out_full_o = '1' report "###ERROR###: out_full_o not asserted" severity error;
    assert unsigned(in_lvl_o) = depth_g report "###ERROR###: in_lvl_o not full" severity error;
    assert unsigned(out_lvl_o) = depth_g report "###ERROR###: out_lvl_o not full" severity error;
    -- Check read
    wait until falling_edge(out_clk_i);
    for i in 0 to depth_g - 1 loop
      out_rdy_i <= '1';
      assert unsigned(out_dat_o) = i report "###ERROR: Read wrong data in word " & integer'image(i) severity error;
      wait until falling_edge(out_clk_i);
    end loop;
    out_rdy_i <= '0';
    wait for 1 us;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not asserted" severity error;
    assert out_empty_o = '1' report "###ERROR###: out_empty_o not asserted" severity error;
    assert in_full_o = '0' report "###ERROR###: in_full_o not de-asserted" severity error;
    assert out_full_o = '0' report "###ERROR###: out_full_o not de-asserted" severity error;

    -- *** Read from Empty Fifo ***
    wait until falling_edge(out_clk_i);
    print(">> Read from Empty FIFO");
    assert out_empty_o = '1' report "###ERROR###: out_empty_o not asserted" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not asserted" severity error;
    -- read
    wait until falling_edge(out_clk_i);
    out_rdy_i <= '1';
    wait until falling_edge(out_clk_i);
    out_rdy_i <= '0';
    -- check correct functionality
    wait for 1 us;
    assert out_empty_o = '1' report "###ERROR###: out_empty_o not asserted" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not asserted" severity error;
    assert unsigned(in_lvl_o) = 0 report "###ERROR###: in_lvl_o not empty" severity error;
    assert unsigned(out_lvl_o) = 0 report "###ERROR###: out_lvl_o not empty" severity error;
    wait until falling_edge(in_clk_i);
    in_vld_i  <= '1';
    in_dat_i  <= X"8765";
    wait until falling_edge(in_clk_i);
    in_vld_i  <= '0';
    wait for 1 us;
    assert out_empty_o = '0' report "###ERROR###: out_empty_o not de-asserted" severity error;
    assert in_empty_o = '0' report "###ERROR###: in_empty_o not de-asserted" severity error;
    assert unsigned(in_lvl_o) = 1 report "###ERROR###: in_lvl_o not empty" severity error;
    assert unsigned(out_lvl_o) = 1 report "###ERROR###: out_lvl_o not empty" severity error;
    wait until falling_edge(out_clk_i);
    assert out_dat_o = X"8765" report "###ERROR: Read wrong data" severity error;
    out_rdy_i <= '1';
    wait until falling_edge(out_clk_i);
    out_rdy_i <= '0';
    wait for 1 us;
    assert out_empty_o = '1' report "###ERROR###: out_empty_o not asserted" severity error;
    assert in_empty_o = '1' report "###ERROR###: in_empty_o not asserted" severity error;
    assert unsigned(in_lvl_o) = 0 report "###ERROR###: in_lvl_o not empty" severity error;
    assert unsigned(out_lvl_o) = 0 report "###ERROR###: out_lvl_o not empty" severity error;

    -- *** Almost full/almost empty
    print(">> Almost full/almost empty");
    -- fill
    for i in 0 to depth_g - 1 loop
      wait until falling_edge(in_clk_i);
      in_vld_i <= '1';
      in_dat_i <= std_logic_vector(to_unsigned(i, in_dat_i'length));
      wait until falling_edge(in_clk_i);
      in_vld_i <= '0';
      wait for 1 us;
      assert unsigned(in_lvl_o) = i + 1 report "###ERROR###: in_lvl_o wrong" severity error;
      assert unsigned(out_lvl_o) = i + 1 report "###ERROR###: out_lvl_o wrong" severity error;
      if afull_on_g then
        if i + 1 >= AlmFullLevel_c then
          assert in_afull_o = '1' report "###ERROR###: InAlmost Full not set" severity error;
          assert out_afull_o = '1' report "###ERROR###: OutAlmost Full not set" severity error;
        else
          assert in_afull_o = '0' report "###ERROR###: InAlmost Full set" severity error;
          assert out_afull_o = '0' report "###ERROR###: OutAlmost Full set" severity error;
        end if;
      end if;
      if aempty_on_g then
        if i + 1 <= AlmEmptyLevel_c then
          assert in_aempty_o = '1' report "###ERROR###: InAlmost Empty not set" severity error;
          assert out_aempty_o = '1' report "###ERROR###: OutAlmost Empty not set" severity error;
        else
          assert in_aempty_o = '0' report "###ERROR###: InAlmost Empty set" severity error;
          assert out_aempty_o = '0' report "###ERROR###: OutAlmost Empty set" severity error;
        end if;
      end if;
    end loop;
    -- flush

    for i in depth_g - 1 downto 0 loop
      wait until falling_edge(out_clk_i);
      out_rdy_i <= '1';
      wait until falling_edge(out_clk_i);
      out_rdy_i <= '0';
      wait for 1 us;
      assert unsigned(in_lvl_o) = i report "###ERROR###: in_lvl_o wrong" severity error;
      assert unsigned(out_lvl_o) = i report "###ERROR###: out_lvl_o wrong" severity error;
      if afull_on_g then
        if i >= AlmFullLevel_c then
          assert in_afull_o = '1' report "###ERROR###: InAlmost Full not set" severity error;
          assert out_afull_o = '1' report "###ERROR###: OutAlmost Full not set" severity error;
        else
          assert in_afull_o = '0' report "###ERROR###: InAlmost Full set" severity error;
          assert out_afull_o = '0' report "###ERROR###: OutAlmost Full set" severity error;
        end if;
      end if;
      if aempty_on_g then
        if i <= AlmEmptyLevel_c then
          assert in_aempty_o = '1' report "###ERROR###: InAlmost Empty not set" severity error;
          assert out_aempty_o = '1' report "###ERROR###: OutAlmost Empty not set" severity error;
        else
          assert in_aempty_o = '0' report "###ERROR###: InAlmost Empty set" severity error;
          assert out_aempty_o = '0' report "###ERROR###: OutAlmost Empty set" severity error;
        end if;
      end if;
    end loop;

    -- Different duty cycles
    print(">> Different Duty Cycles");
    for wrDel in 0 to 4 loop
      for rdDel in 0 to 4 loop
        assert in_empty_o = '1' report "###ERROR###: in_empty_o not asserted" severity error;
        -- Write data
        wait until falling_edge(in_clk_i);
        for i in 0 to 4 loop
          in_vld_i <= '1';
          in_dat_i <= std_logic_vector(to_unsigned(i, in_dat_i'length));
          wait until falling_edge(in_clk_i);
          for k in 1 to wrDel loop
            in_vld_i <= '0';
            in_dat_i <= X"0000";
            wait until falling_edge(in_clk_i);
          end loop;
        end loop;
        in_vld_i  <= '0';
        -- Read data
        wait until falling_edge(out_clk_i);
        for i in 0 to 4 loop
          out_rdy_i <= '1';
          assert unsigned(out_dat_o) = i report "###ERROR###: Wrong data" severity error;
          wait until falling_edge(out_clk_i);
          for k in 1 to rdDel loop
            out_rdy_i <= '0';
            wait until falling_edge(out_clk_i);
          end loop;
        end loop;
        out_rdy_i <= '0';
        assert out_empty_o = '1' report "###ERROR###: Empty not asserted" severity error;
        wait for 1 us;
      end loop;
    end loop;

    -- Output Ready before data available
    print(">> Output Ready before data available");
    out_rdy_i <= '1';
    for i in 0 to 9 loop
      wait until falling_edge(out_clk_i);
      wait until falling_edge(in_clk_i);
    end loop;
    in_dat_i  <= X"ABCD";
    in_vld_i  <= '1';
    wait until falling_edge(in_clk_i);
    in_dat_i  <= X"4321";
    wait until falling_edge(in_clk_i);
    in_vld_i  <= '0';
    wait until out_vld_o = '1' and rising_edge(out_clk_i);
    assert out_empty_o = '0' report "###ERROR###: Empty asserted" severity error;
    assert out_dat_o = X"ABCD" report "###ERROR###: Wrong data 0" severity error;
    wait until out_vld_o = '1' and falling_edge(out_clk_i);
    assert out_empty_o = '0' report "###ERROR###: Empty asserted" severity error;
    assert out_dat_o = X"4321" report "###ERROR###: Wrong data 1" severity error;
    wait until falling_edge(out_clk_i);
    assert out_empty_o = '1' report "###ERROR###: Empty not asserted" severity error;
    assert out_vld_o = '0' report "###ERROR###: Valid asserted" severity error;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
