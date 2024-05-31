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

-- @formatter:off
entity psi_common_pulse_cc is
  generic(num_pulses_g : positive := 1;                                    -- fifo width
          a_rst_pol_g  : std_logic:= '1';                                  -- rst polarity port A
          b_rst_pol_g  : std_logic:= '1');                                 -- rst polarity port B
  port(   a_clk_i      : in  std_logic;                                    -- clock port a input
          a_rst_i      : in  std_logic;                                    -- rst input  port a
          a_rst_o      : out std_logic;                                    -- Clock domain A reset output, active if *a_rst_i* or *b_rst_i* is asserted, de-asserted synchronously to *a_clk_i*
          a_dat_i      : in  std_logic_vector(num_pulses_g - 1 downto 0);  -- dat input port a
          b_clk_i      : in  std_logic;                                    -- clock port b input
          b_rst_i      : in  std_logic;                                    -- rst input port b
          b_rst_o      : out std_logic;                                    -- Clock domain B reset output, active if *a_rst_i* or *b_rst_i* is asserted, de-asserted synchronously to *b_clk_i*
          b_dat_o      : out std_logic_vector(num_pulses_g - 1 downto 0)); -- dat output port b
end entity;
-- @formatter:on

architecture rtl of psi_common_pulse_cc is

  type Pulse_t is array (natural range <>) of std_logic_vector(num_pulses_g - 1 downto 0);

  -- Domain A signals
  signal RstSyncB2A  : std_logic_vector(3 downto 0);
  signal RstAI       : std_logic  :=  a_rst_pol_g;
  -- Domain B signals
  signal RstSyncA2B  : std_logic_vector(3 downto 0);
  signal RstBI       : std_logic  :=  b_rst_pol_g;
  -- Data transmit side
  signal ToggleA     : std_logic_vector(num_pulses_g - 1 downto 0);
  -- Data receive side
  signal ToggleSyncB : Pulse_t(2 downto 0);

  attribute syn_srlstyle                : string;
  attribute syn_srlstyle of RstSyncB2A  : signal is "registers";
  attribute syn_srlstyle of RstSyncA2B  : signal is "registers";
  attribute syn_srlstyle of ToggleA     : signal is "registers";
  attribute syn_srlstyle of ToggleSyncB : signal is "registers";

  attribute shreg_extract               : string;
  attribute shreg_extract of RstSyncB2A : signal is "no";
  attribute shreg_extract of RstSyncA2B : signal is "no";
  attribute shreg_extract of ToggleA    : signal is "no";
  attribute shreg_extract of ToggleSyncB: signal is "no";

  attribute ASYNC_REG                   : string;
  attribute ASYNC_REG of RstSyncB2A     : signal is "TRUE";
  attribute ASYNC_REG of RstSyncA2B     : signal is "TRUE";
  attribute ASYNC_REG of ToggleA        : signal is "TRUE";
  attribute ASYNC_REG of ToggleSyncB    : signal is "TRUE";

begin

  -- Domain A reset sync
  ARstSync_p : process(a_clk_i, b_rst_i)
  begin
    if b_rst_i = b_rst_pol_g then
      RstSyncB2A <= (others => b_rst_pol_g);
    elsif rising_edge(a_clk_i) then
      RstSyncB2A <= RstSyncB2A(RstSyncB2A'left - 1 downto 0) & not b_rst_pol_g;
    end if;
  end process;
  
  ARst_p : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if a_rst_pol_g = '1' then
        if b_rst_pol_g = '1' then
          RstAI <= RstSyncB2A(RstSyncB2A'left) or a_rst_i;
        else
          RstAI <= RstSyncB2A(RstSyncB2A'left) and a_rst_i;
        end if;
      else
       if b_rst_pol_g = '1' then
          RstAI <= RstSyncB2A(RstSyncB2A'left) or a_rst_i;
        else
          RstAI <= RstSyncB2A(RstSyncB2A'left) and a_rst_i;
        end if;
      end if;
    end if;
  end process;
  gene_a_rst_o : if a_rst_pol_g = '1' generate
  a_rst_o <= RstAI or a_rst_i;
  end generate;
  gene_a_rst_o_neg : if a_rst_pol_g = '0' generate
  a_rst_o <= RstAI and a_rst_i;
  end generate;

  -- Domain B reset sync
  BRstSync_p : process(b_clk_i, a_rst_i)
  begin
    if a_rst_i = a_rst_pol_g then
      RstSyncA2B <= (others => a_rst_pol_g);
    elsif rising_edge(b_clk_i) then
      RstSyncA2B <= RstSyncA2B(RstSyncA2B'left - 1 downto 0) & not a_rst_pol_g;
    end if;
  end process;
  
  BRst_p : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if b_rst_pol_g = '1' then
        if a_rst_pol_g = '1' then
          RstBI <= RstSyncA2B(RstSyncA2B'left) or b_rst_i;
        else
          RstBI <= RstSyncA2B(RstSyncA2B'left) and b_rst_i;
        end if;
      else
        if a_rst_pol_g = '1' then
          RstBI <= RstSyncA2B(RstSyncA2B'left) or b_rst_i;
        else
          RstBI <= RstSyncA2B(RstSyncA2B'left) and b_rst_i;
        end if;
      end if;
    end if;
  end process;
  gene_b_rst_o : if b_rst_pol_g = '1' generate
  b_rst_o <= RstBI or b_rst_i;
  end generate;
  gene_b_rst_o_neg : if b_rst_pol_g = '0' generate
  b_rst_o <= RstBI and b_rst_i;
  end generate;

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
