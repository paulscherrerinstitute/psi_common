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
    AlmFullOn_g   : boolean              := true;
    AlmEmptyOn_g  : boolean              := true;
    Depth_g       : natural              := 32;
    RamBehavior_g : string               := "RBW";
    RdyRstState_g : integer range 0 to 1 := 1
  );
end entity psi_common_sync_fifo_tb;

architecture sim of psi_common_sync_fifo_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------	
  constant DataWidth_c     : integer := 16;
  constant AlmFullLevel_c  : natural := Depth_g - 3;
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
  signal Clk      : std_logic                                    := '0';
  signal Rst      : std_logic                                    := '1';
  signal InData   : std_logic_vector(DataWidth_c - 1 downto 0)   := (others => '0');
  signal InVld    : std_logic                                    := '0';
  signal InRdy    : std_logic                                    := '0';
  signal OutData  : std_logic_vector(DataWidth_c - 1 downto 0)   := (others => '0');
  signal OutVld   : std_logic                                    := '0';
  signal OutRdy   : std_logic                                    := '0';
  signal Full     : std_logic                                    := '0';
  signal Empty    : std_logic                                    := '0';
  signal AlmFull  : std_logic                                    := '0';
  signal AlmEmpty : std_logic                                    := '0';
  signal InLevel  : std_logic_vector(log2ceil(Depth_g) downto 0) := (others => '0');
  signal OutLevel : std_logic_vector(log2ceil(Depth_g) downto 0) := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_sync_fifo
    generic map(
      Width_g         => DataWidth_c,
      Depth_g         => Depth_g,
      AlmFullOn_g     => AlmFullOn_g,
      AlmFullLevel_g  => AlmFullLevel_c,
      AlmEmptyOn_g    => AlmEmptyOn_g,
      AlmEmptyLevel_g => AlmEmptyLevel_c,
      RamBehavior_g   => RamBehavior_g,
      RdyRstState_g   => IntToStdLogic(RdyRstState_g)
    )
    port map(
      Clk      => Clk,
      Rst      => Rst,
      InData   => InData,
      InVld    => InVld,
      InRdy    => InRdy,
      OutData  => OutData,
      OutVld   => OutVld,
      OutRdy   => OutRdy,
      Full     => Full,
      Empty    => Empty,
      AlmFull  => AlmFull,
      AlmEmpty => AlmEmpty,
      InLevel  => InLevel,
      OutLevel => OutLevel
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk : process
  begin
    Clk <= '0';
    while TbRunning loop
      wait for 0.5 * ClockPeriod_c;
      Clk <= '1';
      wait for 0.5 * ClockPeriod_c;
      Clk <= '0';
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
    Rst <= '1';
    wait until rising_edge(Clk);
    -- check if ready state during reset is correct
    assert InRdy = IntToStdLogic(RdyRstState_g) report "###ERROR###: InRdy reset state not according to generic" severity error;
    wait for 1 us;

    -- Remove reset
    wait until rising_edge(Clk);
    Rst <= '0';

    -- Check Reset State
    wait until rising_edge(Clk);
    assert InRdy = '1' report "###ERROR###: InRdy after reset state not '1'" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld reset state not '0'" severity error;
    assert Full = '0' report "###ERROR###: Full reset state not '0'" severity error;
    assert Empty = '1' report "###ERROR###: Empty reset state not '1'" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel reset state not 0" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: InLevel reset state not 0" severity error;
    if AlmFullOn_g then
      assert AlmFull = '0' report "###ERROR###: AlmFull reset state not '0'" severity error;
    end if;
    if AlmEmptyOn_g then
      assert AlmEmpty = '1' report "###ERROR###: AlmEmpty reset state not '1'" severity error;
    end if;

    -- *** Two words write then read ***
    print(">> Two words write then read");
    -- Write 1
    wait until falling_edge(Clk);
    InData <= X"0001";
    InVld  <= '1';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld wnt high unexpectedly" severity error;
    assert Empty = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not 0" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 0" severity error;
    -- Write 2
    wait until falling_edge(Clk);
    InData <= X"0002";
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld wnt high unexpectedly" severity error;
    assert Empty = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(InLevel) = 1 report "###ERROR###: InLevel not 1" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 0" severity error;
    -- Pause 1
    wait until falling_edge(Clk);
    InData <= X"0003";
    InVld  <= '0';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0001" report "###ERROR###: Illegal OutData 1" severity error;
    assert Empty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 1 report "###ERROR###: OutLevel not 1" severity error;
    -- Pause 2
    wait until falling_edge(Clk);
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0001" report "###ERROR###: Illegal OutData 1" severity error;
    assert Empty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 2 report "###ERROR###: OutLevel not 2" severity error;
    -- Read ack 1
    wait until falling_edge(Clk);
    OutRdy <= '1';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0001" report "###ERROR###: Illegal OutData 1" severity error;
    assert Empty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 2 report "###ERROR###: OutLevel not 2" severity error;
    -- Read ack 2
    wait until falling_edge(Clk);
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0002" report "###ERROR###: Illegal OutData 2" severity error;
    assert Empty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 1 report "###ERROR###: OutLevel not 2" severity error;
    -- empty 1
    wait until falling_edge(Clk);
    OutRdy <= '0';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld not high" severity error;
    assert Empty = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(InLevel) = 1 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 2" severity error;
    -- empty 2
    wait until falling_edge(Clk);
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld not high" severity error;
    assert Empty = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 2" severity error;

    -- *** Write into Full FIFO ***
    wait until falling_edge(Clk);
    print(">> Write into Full FIFO");
    -- Fill FIFO
    for i in 0 to Depth_g - 1 loop
      InVld  <= '1';
      InData <= std_logic_vector(to_unsigned(i, InData'length));
      wait until falling_edge(Clk);
    end loop;
    InVld  <= '0';
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Full = '1' report "###ERROR###: Fully not asserted" severity error;
    assert unsigned(InLevel) = Depth_g report "###ERROR###: InLevel not full" severity error;
    assert unsigned(OutLevel) = Depth_g report "###ERROR###: OutLevel not full" severity error;
    -- Add more data (not written because full)
    InVld  <= '1';
    InData <= X"ABCD";
    wait until falling_edge(Clk);
    InData <= X"8765";
    wait until falling_edge(Clk);
    InVld  <= '0';
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Full = '1' report "###ERROR###: Fully not asserted" severity error;
    assert unsigned(InLevel) = Depth_g report "###ERROR###: InLevel not full" severity error;
    assert unsigned(OutLevel) = Depth_g report "###ERROR###: OutLevel not full" severity error;
    -- Check read
    for i in 0 to Depth_g - 1 loop
      OutRdy <= '1';
      assert unsigned(OutData) = i report "###ERROR: Read wrong data in word " & integer'image(i) severity error;
      wait until falling_edge(Clk);
    end loop;
    OutRdy <= '0';
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
    assert Full = '0' report "###ERROR###: Fully not de-asserted" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not empty" severity error;

    -- *** Read from Empty Fifo ***
    wait until falling_edge(Clk);
    print(">> Read from Empty FIFO");
    assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
    -- read
    wait until falling_edge(Clk);
    OutRdy <= '1';
    wait until falling_edge(Clk);
    OutRdy <= '0';
    -- check correct functionality
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not empty" severity error;
    InVld  <= '1';
    InData <= X"8765";
    wait until falling_edge(Clk);
    InVld  <= '0';
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Empty = '0' report "###ERROR###: Empty not de-asserted" severity error;
    assert unsigned(InLevel) = 1 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 1 report "###ERROR###: OutLevel not empty" severity error;
    assert OutData = X"8765" report "###ERROR: Read wrong data" severity error;
    OutRdy <= '1';
    wait until falling_edge(Clk);
    OutRdy <= '0';
    wait until falling_edge(Clk);
    wait until falling_edge(Clk);
    assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not empty" severity error;

    -- *** Almost full/almost empty
    print(">> Almost full/almost empty");
    -- fill
    for i in 0 to Depth_g - 1 loop
      InVld  <= '1';
      InData <= std_logic_vector(to_unsigned(i, InData'length));
      wait until falling_edge(Clk);
      InVld  <= '0';
      wait until falling_edge(Clk);
      wait until falling_edge(Clk);
      assert unsigned(InLevel) = i + 1 report "###ERROR###: InLevel wrong" severity error;
      assert unsigned(OutLevel) = i + 1 report "###ERROR###: OutLevel wrong" severity error;
      if AlmFullOn_g then
        if i + 1 >= AlmFullLevel_c then
          assert AlmFull = '1' report "###ERROR###: Almost Full not set" severity error;
        else
          assert AlmFull = '0' report "###ERROR###: Almost Full set" severity error;
        end if;
      end if;
      if AlmEmptyOn_g then
        if i + 1 <= AlmEmptyLevel_c then
          assert AlmEmpty = '1' report "###ERROR###: Almost Empty not set" severity error;
        else
          assert AlmEmpty = '0' report "###ERROR###: Almost Empty set" severity error;
        end if;
      end if;
    end loop;
    -- flush
    for i in Depth_g - 1 downto 0 loop
      OutRdy <= '1';
      wait until falling_edge(Clk);
      OutRdy <= '0';
      wait until falling_edge(Clk);
      wait until falling_edge(Clk);
      assert unsigned(InLevel) = i report "###ERROR###: InLevel wrong" severity error;
      assert unsigned(OutLevel) = i report "###ERROR###: OutLevel wrong" severity error;
      if AlmFullOn_g then
        if i >= AlmFullLevel_c then
          assert AlmFull = '1' report "###ERROR###: Almost Full not set" severity error;
        else
          assert AlmFull = '0' report "###ERROR###: Almost Full set" severity error;
        end if;
      end if;
      if AlmEmptyOn_g then
        if i <= AlmEmptyLevel_c then
          assert AlmEmpty = '1' report "###ERROR###: Almost Empty not set" severity error;
        else
          assert AlmEmpty = '0' report "###ERROR###: Almost Empty set" severity error;
        end if;
      end if;
    end loop;

    -- Different duty cycles
    print(">> Different Duty Cycles");
    wait until falling_edge(Clk);
    for wrDel in 0 to 4 loop
      for rdDel in 0 to 4 loop
        assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
        -- Write data
        for i in 0 to 4 loop
          InVld  <= '1';
          InData <= std_logic_vector(to_unsigned(i, InData'length));
          wait until falling_edge(Clk);
          for k in 1 to wrDel loop
            InVld  <= '0';
            InData <= X"0000";
            wait until falling_edge(Clk);
          end loop;
        end loop;
        InVld  <= '0';
        -- Read data
        for i in 0 to 4 loop
          OutRdy <= '1';
          assert unsigned(OutData) = i report "###ERROR###: Wrong data" severity error;
          wait until falling_edge(Clk);
          for k in 1 to rdDel loop
            OutRdy <= '0';
            wait until falling_edge(Clk);
          end loop;
        end loop;
        OutRdy <= '0';
        assert Empty = '1' report "###ERROR###: Empty not asserted" severity error;
      end loop;
    end loop;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
