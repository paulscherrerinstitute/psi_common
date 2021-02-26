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
    AlmFullOn_g   : boolean              := true;
    AlmEmptyOn_g  : boolean              := true;
    Depth_g       : natural              := 32;
    RamBehavior_g : string               := "RBW";
    RdyRstState_g : integer range 0 to 1 := 1
  );
end entity psi_common_async_fifo_tb;

architecture sim of psi_common_async_fifo_tb is

  -------------------------------------------------------------------------
  -- Constants
  -------------------------------------------------------------------------	
  constant DataWidth_c     : integer := 16;
  constant AlmFullLevel_c  : natural := Depth_g - 3;
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
  signal InClk       : std_logic                                    := '0';
  signal InRst       : std_logic                                    := '1';
  signal OutClk      : std_logic                                    := '0';
  signal OutRst      : std_logic                                    := '1';
  signal InData      : std_logic_vector(DataWidth_c - 1 downto 0)   := (others => '0');
  signal InVld       : std_logic                                    := '0';
  signal InRdy       : std_logic                                    := '0';
  signal OutData     : std_logic_vector(DataWidth_c - 1 downto 0)   := (others => '0');
  signal OutVld      : std_logic                                    := '0';
  signal OutRdy      : std_logic                                    := '0';
  signal InFull      : std_logic                                    := '0';
  signal OutFull     : std_logic                                    := '0';
  signal InEmpty     : std_logic                                    := '0';
  signal OutEmpty    : std_logic                                    := '0';
  signal InAlmFull   : std_logic                                    := '0';
  signal OutAlmFull  : std_logic                                    := '0';
  signal InAlmEmpty  : std_logic                                    := '0';
  signal OutAlmEmpty : std_logic                                    := '0';
  signal InLevel     : std_logic_vector(log2ceil(Depth_g) downto 0) := (others => '0');
  signal OutLevel    : std_logic_vector(log2ceil(Depth_g) downto 0) := (others => '0');

begin

  -------------------------------------------------------------------------
  -- DUT
  -------------------------------------------------------------------------
  i_dut : entity work.psi_common_async_fifo
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
      -- Control Ports
      InClk       => InClk,
      InRst       => InRst,
      OutClk      => OutClk,
      OutRst      => OutRst,
      -- Input Data
      InData      => InData,
      InVld       => InVld,
      InRdy       => InRdy,
      -- Output Data
      OutData     => OutData,
      OutVld      => OutVld,
      OutRdy      => OutRdy,
      -- Input Status
      InFull      => InFull,
      InEmpty     => InEmpty,
      InAlmFull   => InAlmFull,
      InAlmEmpty  => InAlmEmpty,
      InLevel     => InLevel,
      -- Output Status
      OutFull     => OutFull,
      OutEmpty    => OutEmpty,
      OutAlmFull  => OutAlmFull,
      OutAlmEmpty => OutAlmEmpty,
      OutLevel    => OutLevel
    );

  -------------------------------------------------------------------------
  -- Clock
  -------------------------------------------------------------------------
  p_clk_in : process
  begin
    InClk <= '0';
    while TbRunning loop
      wait for 0.5 * ClockInPeriod_c;
      InClk <= '1';
      wait for 0.5 * ClockInPeriod_c;
      InClk <= '0';
    end loop;
    wait;
  end process;

  p_clk_out : process
  begin
    OutClk <= '0';
    while TbRunning loop
      wait for 0.5 * ClockOutPeriod_c;
      OutClk <= '1';
      wait for 0.5 * ClockOutPeriod_c;
      OutClk <= '0';
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
    InRst  <= '1';
    OutRst <= '1';
    -- check if ready state during reset is correct
    wait for 20 ns;                     -- reset must be transferred to other clock domain
    wait until rising_edge(InClk);
    assert InRdy = IntToStdLogic(RdyRstState_g) report "###ERROR###: InRdy reset state not according to generic" severity error;
    wait for 1 us;

    -- Remove reset
    wait until rising_edge(InClk);
    InRst  <= '0';
    wait until rising_edge(OutClk);
    OutRst <= '0';
    wait for 100 ns;

    -- Check Reset State
    wait until rising_edge(InClk);
    assert InRdy = '1' report "###ERROR###: InRdy after reset state not '1'" severity error;
    assert InFull = '0' report "###ERROR###: InFull reset state not '0'" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty reset state not '1'" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel reset state not 0" severity error;
    if AlmFullOn_g then
      assert InAlmFull = '0' report "###ERROR###: InAlmFull reset state not '0'" severity error;
    end if;
    if AlmEmptyOn_g then
      assert InAlmEmpty = '1' report "###ERROR###: InAlmEmpty reset state not '1'" severity error;
    end if;

    wait until rising_edge(OutClk);
    assert OutVld = '0' report "###ERROR###: OutVld reset state not '0'" severity error;
    assert OutFull = '0' report "###ERROR###: OutFull reset state not '0'" severity error;
    assert OutEmpty = '1' report "###ERROR###: OutEmpty reset state not '1'" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel reset state not 0" severity error;
    if AlmFullOn_g then
      assert OutAlmFull = '0' report "###ERROR###: OutAlmFull reset state not '0'" severity error;
    end if;
    if AlmEmptyOn_g then
      assert OutAlmEmpty = '1' report "###ERROR###: OutAlmEmpty reset state not '1'" severity error;
    end if;

    -- *** Two words write then read ***
    print(">> Two words write then read");
    -- Write 1
    wait until falling_edge(InClk);
    InData <= X"0001";
    InVld  <= '1';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty not high" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not 0" severity error;
    -- Write 2
    wait until falling_edge(InClk);
    InData <= X"0002";
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert InEmpty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 1 report "###ERROR###: InLevel not 1" severity error;
    -- Pause 1
    wait until falling_edge(InClk);
    InData <= X"0003";
    InVld  <= '0';
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert InEmpty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    -- Pause 2
    for i in 0 to 4 loop
      wait until falling_edge(InClk);
      wait until falling_edge(OutClk);
    end loop;
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0001" report "###ERROR###: Illegal OutData 1" severity error;
    assert InEmpty = '0' report "###ERROR###: InEmpty not low" severity error;
    assert InFull = '0' report "###ERROR###: InFull not low" severity error;
    assert OutEmpty = '0' report "###ERROR###: InEmpty not low" severity error;
    assert OutFull = '0' report "###ERROR###: InFull not low" severity error;
    assert unsigned(InLevel) = 2 report "###ERROR###: InLevel not 2" severity error;
    assert unsigned(OutLevel) = 2 report "###ERROR###: OutLevel not 2" severity error;
    -- Read ack 1
    wait until falling_edge(OutClk);
    OutRdy <= '1';
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0001" report "###ERROR###: Illegal OutData 1" severity error;
    assert OutEmpty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(OutLevel) = 2 report "###ERROR###: OutLevel not 2" severity error;
    -- Read ack 2
    wait until falling_edge(OutClk);
    assert OutVld = '1' report "###ERROR###: OutVld not high" severity error;
    assert OutData = X"0002" report "###ERROR###: Illegal OutData 2" severity error;
    assert OutEmpty = '0' report "###ERROR###: Empty not low" severity error;
    assert unsigned(OutLevel) = 1 report "###ERROR###: OutLevel not 1" severity error;
    -- empty 1
    wait until falling_edge(OutClk);
    OutRdy <= '0';
    assert OutVld = '0' report "###ERROR###: OutVld not high" severity error;
    assert OutEmpty = '1' report "###ERROR###: Empty not high" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 0" severity error;
    -- empty 2
    for i in 0 to 4 loop
      wait until falling_edge(OutClk);
      wait until falling_edge(InClk);
    end loop;
    assert InRdy = '1' report "###ERROR###: InRdy went low unexpectedly" severity error;
    assert OutVld = '0' report "###ERROR###: OutVld not high" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty not high" severity error;
    assert OutEmpty = '1' report "###ERROR###: OutEmpty not high" severity error;
    assert InFull = '0' report "###ERROR###: InFull not low" severity error;
    assert OutFull = '0' report "###ERROR###: OutFull not low" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not 0" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not 0" severity error;

    -- *** Write into Full FIFO ***
    wait until falling_edge(InClk);
    print(">> Write into Full FIFO");
    -- Fill FIFO
    for i in 0 to Depth_g - 1 loop
      InVld  <= '1';
      InData <= std_logic_vector(to_unsigned(i, InData'length));
      wait until falling_edge(InClk);
    end loop;
    InVld  <= '0';
    wait for 1 us;
    assert InFull = '1' report "###ERROR###: InFull not asserted" severity error;
    assert OutFull = '1' report "###ERROR###: OutFull not asserted" severity error;
    assert unsigned(InLevel) = Depth_g report "###ERROR###: InLevel not full" severity error;
    assert unsigned(OutLevel) = Depth_g report "###ERROR###: OutLevel not full" severity error;
    -- Add more data (not written because full)
    wait until falling_edge(InClk);
    InVld  <= '1';
    InData <= X"ABCD";
    wait until falling_edge(InClk);
    InData <= X"8765";
    wait until falling_edge(InClk);
    InVld  <= '0';
    wait for 1 us;
    assert InFull = '1' report "###ERROR###: InFull not asserted" severity error;
    assert OutFull = '1' report "###ERROR###: OutFull not asserted" severity error;
    assert unsigned(InLevel) = Depth_g report "###ERROR###: InLevel not full" severity error;
    assert unsigned(OutLevel) = Depth_g report "###ERROR###: OutLevel not full" severity error;
    -- Check read
    wait until falling_edge(OutClk);
    for i in 0 to Depth_g - 1 loop
      OutRdy <= '1';
      assert unsigned(OutData) = i report "###ERROR: Read wrong data in word " & integer'image(i) severity error;
      wait until falling_edge(OutClk);
    end loop;
    OutRdy <= '0';
    wait for 1 us;
    assert InEmpty = '1' report "###ERROR###: InEmpty not asserted" severity error;
    assert OutEmpty = '1' report "###ERROR###: OutEmpty not asserted" severity error;
    assert InFull = '0' report "###ERROR###: InFull not de-asserted" severity error;
    assert OutFull = '0' report "###ERROR###: OutFull not de-asserted" severity error;

    -- *** Read from Empty Fifo ***
    wait until falling_edge(OutClk);
    print(">> Read from Empty FIFO");
    assert OutEmpty = '1' report "###ERROR###: OutEmpty not asserted" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty not asserted" severity error;
    -- read
    wait until falling_edge(OutClk);
    OutRdy <= '1';
    wait until falling_edge(OutClk);
    OutRdy <= '0';
    -- check correct functionality
    wait for 1 us;
    assert OutEmpty = '1' report "###ERROR###: OutEmpty not asserted" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty not asserted" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not empty" severity error;
    wait until falling_edge(InClk);
    InVld  <= '1';
    InData <= X"8765";
    wait until falling_edge(InClk);
    InVld  <= '0';
    wait for 1 us;
    assert OutEmpty = '0' report "###ERROR###: OutEmpty not de-asserted" severity error;
    assert InEmpty = '0' report "###ERROR###: InEmpty not de-asserted" severity error;
    assert unsigned(InLevel) = 1 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 1 report "###ERROR###: OutLevel not empty" severity error;
    wait until falling_edge(OutClk);
    assert OutData = X"8765" report "###ERROR: Read wrong data" severity error;
    OutRdy <= '1';
    wait until falling_edge(OutClk);
    OutRdy <= '0';
    wait for 1 us;
    assert OutEmpty = '1' report "###ERROR###: OutEmpty not asserted" severity error;
    assert InEmpty = '1' report "###ERROR###: InEmpty not asserted" severity error;
    assert unsigned(InLevel) = 0 report "###ERROR###: InLevel not empty" severity error;
    assert unsigned(OutLevel) = 0 report "###ERROR###: OutLevel not empty" severity error;

    -- *** Almost full/almost empty
    print(">> Almost full/almost empty");
    -- fill
    for i in 0 to Depth_g - 1 loop
      wait until falling_edge(InClk);
      InVld  <= '1';
      InData <= std_logic_vector(to_unsigned(i, InData'length));
      wait until falling_edge(InClk);
      InVld  <= '0';
      wait for 1 us;
      assert unsigned(InLevel) = i + 1 report "###ERROR###: InLevel wrong" severity error;
      assert unsigned(OutLevel) = i + 1 report "###ERROR###: OutLevel wrong" severity error;
      if AlmFullOn_g then
        if i + 1 >= AlmFullLevel_c then
          assert InAlmFull = '1' report "###ERROR###: InAlmost Full not set" severity error;
          assert OutAlmFull = '1' report "###ERROR###: OutAlmost Full not set" severity error;
        else
          assert InAlmFull = '0' report "###ERROR###: InAlmost Full set" severity error;
          assert OutAlmFull = '0' report "###ERROR###: OutAlmost Full set" severity error;
        end if;
      end if;
      if AlmEmptyOn_g then
        if i + 1 <= AlmEmptyLevel_c then
          assert InAlmEmpty = '1' report "###ERROR###: InAlmost Empty not set" severity error;
          assert OutAlmEmpty = '1' report "###ERROR###: OutAlmost Empty not set" severity error;
        else
          assert InAlmEmpty = '0' report "###ERROR###: InAlmost Empty set" severity error;
          assert OutAlmEmpty = '0' report "###ERROR###: OutAlmost Empty set" severity error;
        end if;
      end if;
    end loop;
    -- flush

    for i in Depth_g - 1 downto 0 loop
      wait until falling_edge(OutClk);
      OutRdy <= '1';
      wait until falling_edge(OutClk);
      OutRdy <= '0';
      wait for 1 us;
      assert unsigned(InLevel) = i report "###ERROR###: InLevel wrong" severity error;
      assert unsigned(OutLevel) = i report "###ERROR###: OutLevel wrong" severity error;
      if AlmFullOn_g then
        if i >= AlmFullLevel_c then
          assert InAlmFull = '1' report "###ERROR###: InAlmost Full not set" severity error;
          assert OutAlmFull = '1' report "###ERROR###: OutAlmost Full not set" severity error;
        else
          assert InAlmFull = '0' report "###ERROR###: InAlmost Full set" severity error;
          assert OutAlmFull = '0' report "###ERROR###: OutAlmost Full set" severity error;
        end if;
      end if;
      if AlmEmptyOn_g then
        if i <= AlmEmptyLevel_c then
          assert InAlmEmpty = '1' report "###ERROR###: InAlmost Empty not set" severity error;
          assert OutAlmEmpty = '1' report "###ERROR###: OutAlmost Empty not set" severity error;
        else
          assert InAlmEmpty = '0' report "###ERROR###: InAlmost Empty set" severity error;
          assert OutAlmEmpty = '0' report "###ERROR###: OutAlmost Empty set" severity error;
        end if;
      end if;
    end loop;

    -- Different duty cycles
    print(">> Different Duty Cycles");
    for wrDel in 0 to 4 loop
      for rdDel in 0 to 4 loop
        assert InEmpty = '1' report "###ERROR###: InEmpty not asserted" severity error;
        -- Write data
        wait until falling_edge(InClk);
        for i in 0 to 4 loop
          InVld  <= '1';
          InData <= std_logic_vector(to_unsigned(i, InData'length));
          wait until falling_edge(InClk);
          for k in 1 to wrDel loop
            InVld  <= '0';
            InData <= X"0000";
            wait until falling_edge(InClk);
          end loop;
        end loop;
        InVld  <= '0';
        -- Read data
        wait until falling_edge(OutClk);
        for i in 0 to 4 loop
          OutRdy <= '1';
          assert unsigned(OutData) = i report "###ERROR###: Wrong data" severity error;
          wait until falling_edge(OutClk);
          for k in 1 to rdDel loop
            OutRdy <= '0';
            wait until falling_edge(OutClk);
          end loop;
        end loop;
        OutRdy <= '0';
        assert OutEmpty = '1' report "###ERROR###: Empty not asserted" severity error;
        wait for 1 us;
      end loop;
    end loop;

    -- Output Ready before data available
    print(">> Output Ready before data available");
    OutRdy <= '1';
    for i in 0 to 9 loop
      wait until falling_edge(OutClk);
      wait until falling_edge(InClk);
    end loop;
    InData <= X"ABCD";
    InVld  <= '1';
    wait until falling_edge(InClk);
    InData <= X"4321";
    wait until falling_edge(InClk);
    InVld  <= '0';
    wait until OutVld = '1' and rising_edge(OutClk);
    assert OutEmpty = '0' report "###ERROR###: Empty asserted" severity error;
    assert OutData = X"ABCD" report "###ERROR###: Wrong data 0" severity error;
    wait until OutVld = '1' and falling_edge(OutClk);
    assert OutEmpty = '0' report "###ERROR###: Empty asserted" severity error;
    assert OutData = X"4321" report "###ERROR###: Wrong data 1" severity error;
    wait until falling_edge(OutClk);
    assert OutEmpty = '1' report "###ERROR###: Empty not asserted" severity error;
    assert OutVld = '0' report "###ERROR###: Valid asserted" severity error;

    -- TB done
    TbRunning <= false;
    wait;
  end process;

end sim;
