------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler, Daniel Llorente
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity measures the frequency of a clock under the assumption that
-- the frequency of the main-clock is exactly correct.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--@fromatter:off
entity psi_common_clk_meas is
  generic( master_frequency_g    : positive := 125000000;       -- clock frequency in Hz for system clock
           max_meas_frequency_g  : positive := 250000000;       -- clock frequency in Hz for system clock
           rst_pol_g             : std_logic:= '1');            -- reset polarity
  port(   clk_master_i           : in  std_logic;                       -- system clock
          rst_i                  : in  std_logic;                       -- system reset
          frequency_hz_o         : out std_logic_vector(31 downto 0);   -- Synchronous to ClkMaster
          vld_o                  : out std_logic;                       -- Pulse when frequency is valid
          clk_test_i             : in  std_logic);                      -- clock to be tested
end entity;
--@fromatter:on
architecture rtl of psi_common_clk_meas is

  ----------------------------------------
  -- Signals Master Clock
  ----------------------------------------
  signal Cntr1Hz_M          : integer range 0 to master_frequency_g - 1;
  signal Toggle1Hz_M        : std_logic;
  signal ResultToggleSync_M : std_logic_vector(2 downto 0);
  signal AwaitResult_M      : std_logic;
  ----------------------------------------
  -- Signals Test Clock
  ----------------------------------------	
  signal Toggle1HzSync_T : std_logic_vector(2 downto 0);
  signal CntrTest_T      : integer range 0 to max_meas_frequency_g;
  signal Result_T        : integer range 0 to max_meas_frequency_g;
  signal ResultToggle_T  : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Reset Generation and Result Latching(Master Clock)
  ---------------------------------------------------------------------------
  p_rstGen : process(clk_master_i)
  begin
    if rising_edge(clk_master_i) then
      if rst_i = '1' then
        Cntr1Hz_M          <= master_frequency_g - 1;
        Toggle1Hz_M        <= '0';
        AwaitResult_M      <= '0';
        frequency_hz_o     <= (others => '0');
        ResultToggleSync_M <= (others => '0');
        vld_o              <= '0';
      else
        -- Default Value
        vld_o <= '0';

        -- Request new result
        if Cntr1Hz_M = 0 then
          Cntr1Hz_M     <= master_frequency_g - 1;
          Toggle1Hz_M   <= not Toggle1Hz_M;
          AwaitResult_M <= '1';
          if AwaitResult_M = '1' then
            frequency_hz_o <= (others => '0');
            vld_o          <= '1';
          end if;
        else
          Cntr1Hz_M <= Cntr1Hz_M - 1;
        end if;

        -- Latch new result
        ResultToggleSync_M <= ResultToggleSync_M(1 downto 0) & ResultToggle_T;
        if ResultToggleSync_M(2) /= ResultToggleSync_M(1) then
          frequency_hz_o <= std_logic_vector(to_unsigned(Result_T, 32));
          AwaitResult_M  <= '0';
          vld_o          <= '1';
        end if;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Edge Counter (Test Clock)
  ---------------------------------------------------------------------------
  p_meas : process(clk_test_i)
  begin
    if rising_edge(clk_test_i) then
      if rst_i = rst_pol_g then
        Toggle1HzSync_T <= (others => '0');
        ResultToggle_T  <= '0';
        Result_T        <= 0;
      else
        Toggle1HzSync_T <= Toggle1HzSync_T(1 downto 0) & Toggle1Hz_M;

        -- On every toggle, reset counter and output result
        if Toggle1HzSync_T(2) /= Toggle1HzSync_T(1) then
          CntrTest_T     <= 1;          --the first edge implicitly arrived
          Result_T       <= CntrTest_T;
          ResultToggle_T <= not ResultToggle_T;
        -- Otherwise count (prevent overflows!)
        elsif CntrTest_T /= max_meas_frequency_g then
          CntrTest_T <= CntrTest_T + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;