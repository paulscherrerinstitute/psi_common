------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a delay element. It is either emplemented in BRAM or SRL. The output
-- is always a fabric register for improved timing.


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
--@formatter:off
entity psi_common_delay is
  generic(width_g          : positive := 16;                               -- vector length
          delay_g          : positive := 10;                               -- Delay
          resource_g       : string   := "AUTO";                           -- AUTO, SRL or BRAM
          bram_threshold_g : positive := 128;                              -- Number of delay taps to start using BRAM from (if Resource_g = AUTO)
          rst_state_g      : boolean  := True;                             -- True = '0' is outputted after reset, '1' after reset the existing state is outputted
          ram_behavior_g   : string   := "RBW" );                          -- "RBW" = read-before-write, "WBR" = write-before-read
  port(   clk_i            : in  std_logic;                                -- system clock
          rst_i            : in  std_logic;                                -- system reset
          dat_i            : in  std_logic_vector(width_g - 1 downto 0);   -- data input
          vld_i            : in  std_logic;                                -- valid input
          dat_o            : out std_logic_vector((width_g - 1) downto 0); -- data output
          vld_o            : out std_logic);                               -- valid output
end entity;
--@formatter:on
architecture rtl of psi_common_delay is
  signal MemOut           : std_logic_vector(width_g - 1 downto 0);
  constant MemTaps_c      : natural := delay_g - 1;
  signal RstStateCnt      : integer range 0 to delay_g - 1;
  attribute shreg_extract : string;
  attribute srl_style     : string;
  constant ground_c       : std_logic:='0';
begin

  -- *** Assertions ***
  assert resource_g = "AUTO" or resource_g = "SRL" or resource_g = "BRAM" report "###ERROR###: psi_common_delay: Unknown resource_g - " & resource_g severity error;
  assert resource_g /= "BRAM" or delay_g >= 3 report "###ERROR###: psi_common_delay: delay_g >= 3 required for resource_g=BRAM" severity error;
  assert bram_threshold_g > 3 report "###ERROR###: psi_common_delay: bram_threshold_g must be > 3" severity error;

  -- *** SRL ***
  g_srl : if (delay_g > 1) and ((resource_g = "SRL") or ((resource_g = "AUTO") and (delay_g < bram_threshold_g))) generate
    type Srl_t is array (0 to MemTaps_c - 1) of std_logic_vector(width_g - 1 downto 0);
    signal SrlSig : Srl_t := (others => (others => '0'));
    attribute shreg_extract of SrlSig : signal is "true";
    attribute srl_style of SrlSig : signal is "srl";
  begin
    p_srl : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if vld_i = '1' then
          SrlSig(0)                <= dat_i;
          SrlSig(1 to SrlSig'high) <= SrlSig(0 to SrlSig'high - 1);
        end if;
      end if;
    end process;
    MemOut <= SrlSig(SrlSig'high);
  end generate;

  -- *** BRAM ***
  g_bram : if (delay_g > 1) and ((resource_g = "BRAM") or ((resource_g = "AUTO") and (delay_g >= bram_threshold_g))) generate
    signal RdAddr, WrAddr : std_logic_vector(log2ceil(MemTaps_c) - 1 downto 0) := (others => '0');
  begin
    -- address control process
    p_bram : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = '1' then
          WrAddr <= std_logic_vector(to_unsigned(MemTaps_c - 1, WrAddr'length));
          RdAddr <= (others => '0');
        elsif vld_i = '1' then
          -- write address
          if unsigned(WrAddr) = MemTaps_c - 1 then
            WrAddr <= (others => '0');
          else
            WrAddr <= std_logic_vector(unsigned(WrAddr) + 1);
          end if;
          -- read address
          if unsigned(RdAddr) = MemTaps_c - 1 then
            RdAddr <= (others => '0');
          else
            RdAddr <= std_logic_vector(unsigned(RdAddr) + 1);
          end if;
        end if;
      end if;
    end process;

    -- memory instantiation
    i_bram : entity work.psi_common_sdp_ram
      generic map(
        depth_g        => MemTaps_c,
        width_g        => width_g,
        is_async_g     => false,
        ram_style_g    => "auto",
        ram_behavior_g => ram_behavior_g
      )
      port map(
        wr_clk_i  => clk_i,    
        wr_addr_i => WrAddr,
        wr_i      => vld_i,
        wr_dat_i  => dat_i,
        rd_clk_i  => ground_c,
        rd_addr_i => RdAddr,
        rd_i      => vld_i,
        rd_dat_o  => MemOut
      );
  end generate;

  -- *** Single Stage ***
  g_single : if delay_g = 1 generate
    MemOut <= dat_i;
  end generate;

  -- *** Output register ***
  p_outreg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = '1' then
        dat_o       <= (others => '0');
         vld_o      <= '0';
        RstStateCnt <= 0;
      elsif vld_i = '1' then
        if rst_state_g = false or RstStateCnt = delay_g - 1 then
          dat_o <= MemOut;
          vld_o <= '1';
        else
          dat_o       <= (others => '0');
          vld_o       <= '1';
          RstStateCnt <= RstStateCnt + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;