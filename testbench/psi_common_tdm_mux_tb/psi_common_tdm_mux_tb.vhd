------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is the time division multixed data mux testbench
-- One can select the wanted frequency clock and strobe signal then the TB
-- generates stimuli through the DUT as expected TDM data + strobe
-- data value geenrated are equal to channel number to ease the TB check 
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_tb_txt_util.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_tdm_mux_tb is
  generic(rst_pol_g     : std_logic := '1';
          freq_clock_g  : real      := 100.0e6;
          freq_str_g    : real      := 0.1e6;
          num_channel_g : natural   := 64;
          data_length_g : natural   := 24;
          str_del_g     : natural   := 0);
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture tb of psi_common_tdm_mux_tb is
  constant period_c         : time                                                   := (1 sec) / freq_clock_g;
  signal InClk_sti          : std_logic                                              := '0';
  signal InRst_sti          : std_logic                                              := rst_pol_g;
  signal InVld_sti          : std_logic                                              := '0';
  signal InChSel_sti        : std_logic_vector(log2ceil(num_channel_g) - 1 downto 0) := (others => '0');
  signal InTdmVld_sti       : std_logic;
  signal InTdmDat_sti       : std_logic_vector(data_length_g - 1 downto 0);
  signal OutTdmVld_obs      : std_logic;
  signal OutTdmDat_obs      : std_logic_vector(data_length_g - 1 downto 0);
  --
  signal tb_run             : boolean                                                := true;
  -- TODO modify
  shared variable str_dff_v : std_logic_vector(num_channel_g - 1 downto 0);
  ------------------------------------------------------------------------------
  -- this procedure simply fixed parallel array to TDM output
  -- data values are channel numbers for easy test	
  ------------------------------------------------------------------------------
  procedure par_tdm_tb_proc(constant n_ch      : natural   := 8;
                            constant width     : natural   := 16;
                            constant rst_pol_g : std_logic := '1';
                            signal rst         : in std_logic;
                            signal clk         : in std_logic;
                            signal tb_run      : in boolean;
                            signal str         : in std_logic;
                            signal str_o       : out std_logic;
                            signal dat_o       : out std_logic_vector) is
    type array_data_t is array (n_ch - 1 downto 0) of std_logic_vector(width - 1 downto 0);
    variable array_data_v : array_data_t;
    variable count_v      : integer range 0 to n_ch := 0;

  begin
    while tb_run loop
      wait until rising_edge(clk);
      if rst = rst_pol_g then
        for i in 0 to n_ch - 1 loop
          array_data_v(i) := std_logic_vector(to_unsigned(i, width));
        end loop;
        count_v   := 0;
        str_dff_v := (others => '0');
        str_o     <= '0';
      else
        str_dff_v(0)                       := str;
        str_dff_v(str_dff_v'high downto 1) := str_dff_v(str_dff_v'high - 1 downto 0);
        --shift reg
        if unsigned(str_dff_v) >= to_unsigned(0, str_dff_v'length) and count_v < n_ch then
          dat_o   <= array_data_v(count_v);
          count_v := count_v + 1;
          str_o   <= '1';
          if str_del_g > 0 then
            wait until rising_edge(clk);
            str_o <= '0';
            for i in 1 to str_del_g - 1 loop
              wait until rising_edge(clk);
            end loop;
          end if;
        elsif count_v = n_ch and InVld_sti = '0' then
          count_v := n_ch;
          str_o   <= '0';
        else
          count_v := 0;
          str_o   <= '0';
        end if;

      end if;
    end loop;
  end procedure;
  ------------------------------------------------------------------------------
  -- TODO set this procedure into testbench psi_testbench pkg 
  -- This procdure generate strobe signal depending on:
  -- clock freq &wanted strobe freq - strobe is one clock cycle
  ------------------------------------------------------------------------------
  procedure tb_str_proc(constant freq_clock : real      := 100.0E6;
                        constant freq_str   : real      := 1.0E6;
                        constant rst_pol_g  : std_logic := '1';
                        signal rst          : in std_logic;
                        signal clk          : in std_logic;
                        signal tb_run       : in boolean;
                        signal str_o        : out std_logic) is

    variable count_v : integer range 0 to (integer(ceil(freq_clock / freq_str))) := 0;

  begin
    while tb_run loop
      wait until rising_edge(clk);
      if rst = rst_pol_g then
        count_v := 0;
        str_o   <= '0';
      else
        if count_v /= integer(ceil(freq_clock / freq_str)) - 1 then
          str_o   <= '0';
          count_v := count_v + 1;
        else
          str_o   <= '1';
          count_v := 0;
        end if;

      end if;
    end loop;
  end procedure;

begin
  ------------------------------------------------------------
  -- Clocks
  ------------------------------------------------------------
  proc_ck : process
  begin
    while tb_run loop
      InClk_sti <= '0';
      wait for period_c / 2;
      InClk_sti <= '1';
      wait for period_c / 2;
    end loop;
    wait;
  end process;

  ------------------------------------------------------------
  -- Processes
  ------------------------------------------------------------
  -- *** Strobe generation ***
  proc_str : process
  begin
    tb_str_proc(freq_clock => freq_clock_g,
                freq_str   => freq_str_g,
                rst_pol_g  => rst_pol_g,
                rst        => InRst_sti,
                tb_run     => tb_run,
                clk        => InClk_sti,
                str_o      => InVld_sti);
    wait;
  end process;

  -- *** tdm data generation ***
  proc_tdm : process
  begin
    par_tdm_tb_proc(n_ch      => num_channel_g,
                    width     => data_length_g,
                    rst_pol_g => rst_pol_g,
                    rst       => InRst_sti,
                    clk       => InClk_sti,
                    tb_run    => tb_run,
                    str       => InVld_sti,
                    str_o     => InTdmVld_sti,
                    dat_o     => InTdmDat_sti);
    wait;
  end process;

  ------------------------------------------------------------
  -- DUT Instantiation
  ------------------------------------------------------------
  inst_dut : entity work.psi_common_tdm_mux
    generic map(rst_pol_g     => rst_pol_g,
                num_channel_g => num_channel_g,
                data_length_g => data_length_g)
    port map(InClk     => InClk_sti,
             InRst     => InRst_sti,
             InChSel   => InChSel_sti,
             InTdmVld  => InTdmVld_sti,
             InTdmDat  => InTdmDat_sti,
             OutTdmVld => OutTdmVld_obs,
             OutTdmDat => OutTdmDat_obs);

  -- *** check reading ***
  proc_check : process(InClk_sti)
  begin
    if rising_edge(InClk_sti) then
      if OutTdmVld_obs = '1' then
        assert to_integer(unsigned(InChSel_sti)) = to_integer(unsigned(OutTdmDat_obs))
        report "###ERROR###: ch. selected doesn't output the correct ch. -> exp: " &
				to_string(to_integer(unsigned(InChSel_sti))) & 	", got: " & to_string(to_integer(unsigned(OutTdmDat_obs)))
        severity error;
      end if;
    end if;
  end process;

  proc_stim : process
    variable count_v : integer range 0 to num_channel_g := 0;
  begin
    InRst_sti   <= rst_pol_g;
    InChSel_sti <= std_logic_vector(to_unsigned(0, InChSel_sti'length));
    wait for 10 * period_c;
    InRst_sti   <= not rst_pol_g;
    count_v     := 0;
    while count_v < num_channel_g loop
      InChSel_sti <= std_logic_vector(to_unsigned(count_v, InChSel_sti'length));
      wait for 1 sec / freq_str_g;
      count_v     := count_v + 1;
    end loop;
    report "INFO: end of simu";
    tb_run      <= false;
    wait;
  end process;

end architecture;
