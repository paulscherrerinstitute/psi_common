------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic clock crossing that allows passing pulses from one clock
-- domain to another. The pulse frequency must be significantly lower than then
-- slower clock speed.
-- Note that this entity only ensures that all pulses are transferred but not
-- that pulses arriving in the same clock cycle are transmitted in the same
-- clock cycle.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psi_common_pulse_cc is
  generic(
    num_pulses_g : positive := 1;
    a_rst_pol_g  : std_logic:= '1';
    b_rst_pol_g  : std_logic:='1'
  );
  port(
    -- Clock Domain A
    a_clk_i : in  std_logic;
    a_rst_i : in  std_logic;
    a_rst_o : out std_logic;
    a_dat_i : in  std_logic_vector(num_pulses_g - 1 downto 0);
    -- Clock Domain B
    b_clk_i : in  std_logic;
    b_rst_i : in  std_logic;
    b_rst_o : out std_logic;
    b_dat_o : out std_logic_vector(num_pulses_g - 1 downto 0)
  );
end entity;

architecture rtl of psi_common_pulse_cc is

  type Pulse_t is array (natural range <>) of std_logic_vector(num_pulses_g - 1 downto 0);

  -- Domain A signals
  signal RstSyncB2A  : std_logic_vector(3 downto 0);
  signal RstAI       : std_logic;
  -- Domain B signals
  signal RstSyncA2B  : std_logic_vector(3 downto 0);
  signal RstBI       : std_logic;
  -- Data transmit side
  signal ToggleA     : std_logic_vector(num_pulses_g - 1 downto 0);
  -- Data receive side
  signal ToggleSyncB : Pulse_t(2 downto 0);

  attribute syn_srlstyle : string;
  attribute syn_srlstyle of RstSyncB2A : signal is "registers";
  attribute syn_srlstyle of RstSyncA2B : signal is "registers";
  attribute syn_srlstyle of ToggleA : signal is "registers";
  attribute syn_srlstyle of ToggleSyncB : signal is "registers";

  attribute shreg_extract : string;
  attribute shreg_extract of RstSyncB2A : signal is "no";
  attribute shreg_extract of RstSyncA2B : signal is "no";
  attribute shreg_extract of ToggleA : signal is "no";
  attribute shreg_extract of ToggleSyncB : signal is "no";

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of RstSyncB2A : signal is "TRUE";
  attribute ASYNC_REG of RstSyncA2B : signal is "TRUE";
  attribute ASYNC_REG of ToggleA : signal is "TRUE";
  attribute ASYNC_REG of ToggleSyncB : signal is "TRUE";

begin

  -- Domain A reset sync
  ARstSync_p : process(a_clk_i, b_rst_i)
  begin
    if b_rst_i = b_rst_pol_g then
      RstSyncB2A <= (others => '1');
    elsif rising_edge(a_clk_i) then
      RstSyncB2A <= RstSyncB2A(RstSyncB2A'left - 1 downto 0) & '0';
    end if;
  end process;
  ARst_p : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if a_rst_pol_g then
        RstAI <= RstSyncB2A(RstSyncB2A'left) or a_rst_i;
      else
        RstAI <= RstSyncB2A(RstSyncB2A'left) and a_rst_i;  
      end if;
    end if;
  end process;
  a_rst_o <= RstAI;

  -- Domain B reset sync
  BRstSync_p : process(b_clk_i, a_rst_i)
  begin
    if a_rst_i = a_rst_pol_g then
      RstSyncA2B <= (others => '1');
    elsif rising_edge(b_clk_i) then
      RstSyncA2B <= RstSyncA2B(RstSyncA2B'left - 1 downto 0) & '0';
    end if;
  end process;
  BRst_p : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if b_rst_pol_g then
        RstBI <= RstSyncA2B(RstSyncA2B'left) or b_rst_i;
      else
        RstBI <= RstSyncA2B(RstSyncA2B'left) and b_rst_i;
      end if;
    end if;
  end process;
  b_rst_o <= RstBI;

  -- Pulse transmit side (A)
  PulseA_p : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if RstAI = a_rst_pol_g then
        ToggleA <= (others => '0');
      else
        ToggleA <= ToggleA xor a_dat_i;
      end if;
    end if;
  end process;

  -- Data receive side (B)
  PulseB_p : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if RstBI = b_rst_pol_g then
        ToggleSyncB <= (others => (others => '0'));
        b_dat_o     <= (others => '0');
      else
        ToggleSyncB <= ToggleSyncB(ToggleSyncB'left - 1 downto 0) & ToggleA;
        b_dat_o     <= ToggleSyncB(ToggleSyncB'left) xor ToggleSyncB(ToggleSyncB'left - 1);
      end if;
    end if;
  end process;
end architecture;

