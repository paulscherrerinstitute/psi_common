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
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;
use work.psi_tb_txt_util.all;
use work.psi_tb_compare_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_wconv_xn2n_tb is
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_wconv_xn2n_tb is
  -- *** Fixed Generics ***
  constant in_width_g  : natural := 16;
  constant out_width_g : natural := 4;

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_check_c   : integer                  := 1;

  -- *** DUT Signals ***
  signal clk_i     : std_logic                                             := '0';
  signal rst_i     : std_logic                                             := '1';
  signal vld_i   : std_logic                                             := '0';
  signal rdy_o   : std_logic                                             := '0';
  signal dat_i  : std_logic_vector(in_width_g - 1 downto 0)              := (others => '0');
  signal last_i  : std_logic                                             := '0';
  signal we_i    : std_logic_vector(in_width_g / out_width_g - 1 downto 0) := (others => '1');
  signal vld_o  : std_logic                                             := '0';
  signal rdy_i  : std_logic                                             := '0';
  signal dat_o : std_logic_vector(out_width_g - 1 downto 0)             := (others => '0');
  signal last_o : std_logic                                             := '0';

  -- user stuff --
  signal done     : boolean := False;
  signal testcase : integer := -1;

  procedure ApplyInput(StartValue    : in integer;
                       signal dat_i : out std_logic_vector;
                       signal last_i : out std_logic;
                       signal we_i   : out std_logic_vector(we_i'range);
                       IsLast        : in boolean := false;
                       LastByte      : in integer := 0) is
  begin
    for i in 0 to 3 loop
      dat_i(3 + i * 4 downto i * 4) <= std_logic_vector(to_unsigned(i + StartValue, 4));
    end loop;
    last_i <= '0';
    we_i   <= (others => '1');
    if IsLast then
      last_i                              <= '1';
      we_i(we_i'high downto LastByte + 1) <= (others => '0');
    end if;
  end procedure;

  procedure CheckOutput(StartValue : in integer;
                        offset     : in integer;
                        isLast     : in boolean := false) is
  begin
    StdlvCompareInt(StartValue + offset, dat_o, "received wrong output", false);
    if isLast then
      StdlCompare(1, last_o, "did not receive Last");
    else
      StdlCompare(0, last_o, "Received unexpected Last");
    end if;
  end procedure;

begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_wconv_xn2n
    generic map(
      width_in_g  => in_width_g,
      width_out_g => out_width_g
    )
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i   => vld_i,
      rdy_o   => rdy_o,
      dat_i  => dat_i,
      last_i  => last_i,
      we_i    => we_i,
      vld_o  => vld_o,
      rdy_i  => rdy_i,
      dat_o => dat_o,
      last_o => last_o
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
    variable LastWordNr_v : integer;
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- Test Single Serialization
    print(">> Single Serialization");
    testcase <= 0;
    wait until rising_edge(clk_i);
    for del in 0 to 3 loop
      vld_i <= '1';
      ApplyInput(del * 2, dat_i, last_i, we_i);
      wait until rising_edge(clk_i);
      vld_i <= '0';
      wait for 1 ns;
      StdlCompare(0, rdy_o, "rdy_o did not go low");
      for j in 0 to 10 loop
        wait until rising_edge(clk_i);
      end loop;
      wait until rising_edge(clk_i);
    end loop;
    if done /= true then
      wait until done = true;
    end if;

    -- Test Streaming Serialization
    print(">> Streaming Serialization");
    testcase <= 1;
    wait until rising_edge(clk_i);
    vld_i    <= '1';
    for del in 0 to 3 loop
      for data in 0 to 2 loop
        ApplyInput(del + data, dat_i, last_i, we_i);
        wait until rising_edge(clk_i) and rdy_o = '1';
      end loop;
    end loop;
    vld_i    <= '0';
    if done /= true then
      wait until done = true;
    end if;

    -- Test Last Handling
    print(">> Last Handling");
    testcase <= 2;
    wait until rising_edge(clk_i);
    for del in 0 to 3 loop
      for bytes in 1 to 12 loop
        vld_i        <= '1';
        LastWordNr_v := (bytes - 1) / 4;
        for data in 0 to LastWordNr_v loop
          if data = LastWordNr_v then
            ApplyInput(del + data * 4, dat_i, last_i, we_i, true, bytes - data * 4 - 1);
          else
            ApplyInput(del + data * 4, dat_i, last_i, we_i, false);
          end if;
          wait until rising_edge(clk_i) and rdy_o = '1';
        end loop;
        vld_i        <= '0';
      end loop;
    end loop;
    if done /= true then
      wait until done = true;
    end if;

    -- Test Alignment
    print(">> Alignment");
    testcase <= 3;
    wait until rising_edge(clk_i);
    for del in 0 to 3 loop
      for skipBytes in 0 to 3 loop
        for bytes in 4 to 8 loop
          vld_i        <= '1';
          LastWordNr_v := (bytes - 1) / 4;
          for data in 0 to LastWordNr_v loop
            if data = LastWordNr_v then
              ApplyInput(del + data * 4, dat_i, last_i, we_i, true, bytes - data * 4 - 1);
            else
              ApplyInput(del + data * 4, dat_i, last_i, we_i, false);
            end if;
            if data = 0 then
              we_i(skipBytes - 1 downto 0) <= (others => '0');
            end if;
            wait until rising_edge(clk_i) and rdy_o = '1';
          end loop;
          vld_i        <= '0';
        end loop;
      end loop;
    end loop;
    if done /= true then
      wait until done = true;
    end if;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** check ***
  p_check : process
    variable LastByteNr_v : integer;
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- Test Single Serialization
    wait until testcase = 0;
    done <= False;
    for del in 0 to 3 loop
      for i in 0 to 3 loop
        rdy_i <= '1';
        wait until rising_edge(clk_i) and vld_o = '1';
        CheckOutput(2 * del, i);
        for j in 0 to del - 1 loop
          rdy_i <= '0';
          wait until rising_edge(clk_i);
        end loop;
      end loop;
    end loop;
    done <= True;

    -- Test Streaming Serialization
    wait until testcase = 1;
    done <= False;
    for del in 0 to 3 loop
      for data in 0 to 2 loop
        for i in 0 to 3 loop
          rdy_i <= '1';
          wait until rising_edge(clk_i) and vld_o = '1';
          CheckOutput(del + data, i);
          for j in 0 to del - 1 loop
            rdy_i <= '0';
            wait until rising_edge(clk_i);
          end loop;
        end loop;
      end loop;
    end loop;
    done <= True;

    -- Test Last Handling
    wait until testcase = 2;
    done <= False;
    for del in 0 to 3 loop
      for bytes in 1 to 12 loop
        LastByteNr_v := bytes - 1;
        for data in 0 to LastByteNr_v loop
          rdy_i <= '1';
          wait until rising_edge(clk_i) and vld_o = '1';
          CheckOutput(del + data, 0, data = LastByteNr_v);
          for j in 0 to del - 1 loop
            rdy_i <= '0';
            wait until rising_edge(clk_i);
          end loop;
        end loop;
      end loop;
    end loop;
    done <= True;

    -- Alignment
    wait until testcase = 3;
    done <= False;
    for del in 0 to 3 loop
      for skipBytes in 0 to 3 loop
        for bytes in 4 to 8 loop
          LastByteNr_v := bytes - 1;
          for data in skipBytes to LastByteNr_v loop
            rdy_i <= '1';
            wait until rising_edge(clk_i) and vld_o = '1';
            CheckOutput(del + data, 0, data = LastByteNr_v);
            for j in 0 to del - 1 loop
              rdy_i <= '0';
              wait until rising_edge(clk_i);
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;
    done <= True;

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_check_c) <= '1';
    wait;
  end process;

end;
