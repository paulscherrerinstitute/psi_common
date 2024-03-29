------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
------------------------------------------------------------

------------------------------------------------------------
-- Testbench generated by TbGen.py
-- Adapted to run for cfg feature e.g. Transfer width  
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
use work.psi_common_array_pkg.all;

library work;
use work.psi_tb_compare_pkg.all;
use work.psi_tb_activity_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_spi_master_cfg_tb is
  generic(
    spi_cpol_g       : natural  := 0;
    spi_cpha_g       : natural  := 0;
    lsb_first_g      : boolean  := false;
    max_trans_width_g : positive := 32
  );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_spi_master_cfg_tb is
  -- *** Fixed Generics ***
  constant clock_divider_g : natural  := 8;
  --constant MaxTransWidth_g : positive := 8;
  constant cs_high_cycles_g : positive := 12;
  constant slave_cnt_g     : positive := 2;

  -- *** Not Assigned Generics (default values) ***

  -- *** TB Control ***
  signal TbRunning            : boolean                  := True;
  signal NextCase             : integer                  := -1;
  signal ProcessDone          : std_logic_vector(0 to 1) := (others => '0');
  constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
  constant TbProcNr_stim_c    : integer                  := 0;
  constant TbProcNr_spi_c     : integer                  := 1;

  -- *** DUT Signals ***
  signal clk_i             : std_logic                                            := '1';
  signal rst_i             : std_logic                                            := '1';
  signal start_i           : std_logic                                            := '0';
  signal slave_i           : std_logic_vector(log2ceil(slave_cnt_g) - 1 downto 0)  := (others => '0');
  signal busy_o            : std_logic                                            := '0';
  signal done_o            : std_logic                                            := '0';
  signal wr_dat_i          : std_logic_vector(max_trans_width_g - 1 downto 0)       := (others => '0');
  signal rd_dat_o          : std_logic_vector(max_trans_width_g - 1 downto 0)       := (others => '0');
  signal spi_sck_o          : std_logic                                            := '0';
  signal spi_mosi_o         : std_logic                                            := '0';
  signal spi_miso_i         : std_logic                                            := '0';
  signal spi_cs_n_o         : std_logic_vector(slave_cnt_g - 1 downto 0)            := (others => '0');
  signal trans_width_i      : std_logic_vector(log2ceil(max_trans_width_g) downto 0) := to_uslv(max_trans_width_g, log2ceil(max_trans_width_g) + 1);
  -- *** Handwritten Stuff ***
  signal SlaveTx         : std_logic_vector(max_trans_width_g - 1 downto 0);
  signal ExpectedSlaveRx : std_logic_vector(max_trans_width_g - 1 downto 0);
  signal SlaveNr         : integer;

  type array_type_t is array (0 to 4) of std_logic_vector(max_trans_width_g - 1 downto 0);

  constant MosiWords_c : array_type_t := --(X"AB", X"34", X"FC", X"73", X"AB");
  (to_uslv(171, SlaveTx'length),
   to_uslv(52,  SlaveTx'length),
   to_uslv(252, SlaveTx'length),
   to_uslv(115, SlaveTx'length),
   to_uslv(171, SlaveTx'length));

  constant MisoWords_c : array_type_t := --(X"7C", X"C8", X"35", X"BE", X"7C");
  (to_uslv(124, SlaveTx'length),
   to_uslv(200, SlaveTx'length),
   to_uslv(53,  SlaveTx'length),
   to_uslv(190, SlaveTx'length),
   to_uslv(124, SlaveTx'length));
begin
  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  i_dut : entity work.psi_common_spi_master_cfg
    generic map(
      max_trans_width_g => max_trans_width_g,
      spi_cpol_g       => spi_cpol_g,
      spi_cpha_g       => spi_cpha_g,
      lsb_first_g      => lsb_first_g,
      clock_divider_g  => clock_divider_g,
      cs_high_cycles_g  => cs_high_cycles_g,
      slave_cnt_g      => slave_cnt_g
    )
    port map(
      trans_width_i => trans_width_i,
      clk_i        => clk_i,
      rst_i        => rst_i,
      start_i      => start_i,
      slave_i      => slave_i,
      busy_o       => busy_o,
      done_o       => done_o,
      wr_dat_i     => wr_dat_i,
      rd_dat_o     => rd_dat_o,
      spi_sck_o     => spi_sck_o,
      spi_mosi_o    => spi_mosi_o,
      spi_miso_i    => spi_miso_i,
      spi_cs_n_o    => spi_cs_n_o
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
    -------------------------------------------------------------------
    print(" *********************************************************");
    print(" **            Paul Scherrer Institut                   **");
    print(" **      psi_common_spi_master_cfg_tb TestBench         **");
    print(" *********************************************************");
    -------------------------------------------------------------------
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- *** Simple Transfer ***
    for i in 0 to 4 loop
      SlaveTx         <= MisoWords_c(i);
      ExpectedSlaveRx <= MosiWords_c(i);
      SlaveNr         <= i mod 2;
      wait until rising_edge(clk_i);
      wr_dat_i          <= MosiWords_c(i);
      slave_i           <= std_logic_vector(to_unsigned(i mod 2, slave_i'length));
      start_i           <= '1';
      wait until rising_edge(clk_i);
      wr_dat_i          <= to_uslv(0, wr_dat_i'length);
      slave_i           <= "0";
      start_i           <= '0';
      wait until falling_edge(clk_i);
      StdlCompare(1, busy_o, "busy_o did not go high");
      wait until rising_edge(clk_i) and busy_o = '0';
      StdlvCompareStdlv(MisoWords_c(i), rd_dat_o, "SPI master received wrong data");
    end loop;

    -- *** Check Done Signal ***
    SlaveTx         <= to_uslv(85, SlaveTx'length);
    ExpectedSlaveRx <= to_uslv(170, ExpectedSlaveRx'length);
    SlaveNr         <= 0;
    wait until rising_edge(clk_i);
    wr_dat_i          <= to_uslv(170, wr_dat_i'length);
    slave_i           <= "0";
    start_i           <= '1';
    wait until rising_edge(clk_i);
    wr_dat_i          <= to_uslv(0, wr_dat_i'length);
    slave_i           <= "0";
    start_i           <= '0';
    wait until falling_edge(clk_i);
    StdlCompare(1, busy_o, "busy_o did not go high");
    while busy_o = '1' loop
      StdlCompare(0, done_o, "done_o high unexpectedly");
      wait until rising_edge(clk_i);
    end loop;
    StdlCompare(1, done_o, "done_o did not go high");
    StdlvCompareStdlv(to_uslv(85,rd_dat_o'length), rd_dat_o, "SPI master received wrong data");
    wait until rising_edge(clk_i);
    StdlCompare(0, done_o, "done_o did not go low again");

    -- *** Check Transfer start during busy ***
    SlaveTx         <= to_uslv(85, wr_dat_i'length);--X"55";
    ExpectedSlaveRx <= to_uslv(170, wr_dat_i'length);--X"AA";
    SlaveNr         <= 0;
    wait until rising_edge(clk_i);
    wr_dat_i          <= to_uslv(170, wr_dat_i'length);--X"AA";
    slave_i           <= "0";
    start_i           <= '1';
    wait until rising_edge(clk_i);
    wr_dat_i          <= to_uslv(0, wr_dat_i'length);
    slave_i           <= "0";
    wait until falling_edge(clk_i);
    StdlCompare(1, busy_o, "busy_o did not go high");
    for i in 0 to 20 loop
      wait until rising_edge(clk_i);
    end loop;
    start_i           <= '0';
    wait until rising_edge(clk_i) and busy_o = '0';
    StdlvCompareStdlv(to_uslv(85,rd_dat_o'length), rd_dat_o, "SPI master received wrong data");
    for i in 0 to 20 loop
      wait until rising_edge(clk_i);
      StdlCompare(0, busy_o, "busy_o did not stay low");
    end loop;
    StdlCompare(0, done_o, "done_o did not go low again");

    -- end of process !DO NOT EDIT!
    ProcessDone(TbProcNr_stim_c) <= '1';
    wait;
  end process;

  -- *** spi ***
  p_spi : process
    variable ShiftRegRx_v : std_logic_vector(max_trans_width_g - 1 downto 0);
    variable ShiftRegTx_v : std_logic_vector(max_trans_width_g - 1 downto 0);
  begin
    -- start of process !DO NOT EDIT
    wait until rst_i = '0';

    -- Do not wait for this process
    ProcessDone(TbProcNr_spi_c) <= '1';

    while TbRunning loop
      -- If start of transfer
      if spi_cs_n_o /= "11" then
        ShiftRegTx_v := SlaveTx;
        ShiftRegRx_v := (others => 'U');

        -- Check correct slave
        for s in 0 to slave_cnt_g - 1 loop
          if s = SlaveNr then
            StdlCompare(0, spi_cs_n_o(s), "slave_i " & to_string(s) & " not selected");
          else
            StdlCompare(1, spi_cs_n_o(s), "slave_i " & to_string(s) & " selected wrongly");
          end if;
        end loop;

        -- loop over bits
        for i in 0 to max_trans_width_g - 1 loop
          -- Wait for apply edge 
          if (spi_cpha_g = 1) and (i /= max_trans_width_g - 1) then
            if spi_cpol_g = 0 then
              wait until rising_edge(spi_sck_o);
            else
              wait until falling_edge(spi_sck_o);
            end if;
          elsif (spi_cpha_g = 0) and (i /= 0) then
            if spi_cpol_g = 0 then
              wait until falling_edge(spi_sck_o);
            else
              wait until rising_edge(spi_sck_o);
            end if;
          end if;
          -- Shift TX
          if lsb_first_g then
            spi_miso_i      <= ShiftRegTx_v(0);
            ShiftRegTx_v := 'U' & ShiftRegTx_v(max_trans_width_g - 1 downto 1);
          else
            spi_miso_i      <= ShiftRegTx_v(max_trans_width_g - 1);
            ShiftRegTx_v := ShiftRegTx_v(max_trans_width_g - 2 downto 0) & 'U';
          end if;
          -- Wait for transfer edge
          if ((spi_cpol_g = 0) and (spi_cpha_g = 0)) or ((spi_cpol_g = 1) and (spi_cpha_g = 1)) then
            wait until rising_edge(spi_sck_o);
          else
            wait until falling_edge(spi_sck_o);
          end if;
          -- Shift RX
          if lsb_first_g then
            ShiftRegRx_v := spi_mosi_o & ShiftRegRx_v(max_trans_width_g - 1 downto 1);
          else
            ShiftRegRx_v := ShiftRegRx_v(max_trans_width_g - 2 downto 0) & spi_mosi_o;
          end if;
        end loop;

        -- wait fir CS going high
        wait until spi_cs_n_o = "11";
        StdlvCompareStdlv(ExpectedSlaveRx, ShiftRegRx_v, "SPI slave_i received wrong data");
      else
        wait until rising_edge(clk_i);
      end if;
    end loop;

    wait;
  end process;

end;
