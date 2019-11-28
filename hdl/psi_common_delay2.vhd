------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoît Stef & Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a delay element. It is either emplemented in BRAM or SRL. The output
-- is always a fabric register for improved timing.
-- The delay is settable by a register and not fixed as the psi_common_delay
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_delay2 is
  generic(Width_g         : positive  := 16; --data vector width
          Resource_g      : string    := "AUTO"; -- AUTO, SRL or BRAM
          BramThreshold_g : positive  := 20; -- Number of delay taps to start using BRAM from (if Resource_g = AUTO)
          MaxDelay_g      : positive  := 256; -- maximum delay wanted
          RStPol_g        : std_logic := '1'; -- reset polarity
          RstState_g      : boolean   := True; -- True = '0' is outputted after reset, '1' after reset the existing state is outputted
          RamBehavior_g   : string    := "RBW" -- "RBW" = read-before-write, "WBR" = write-before-read
         );
  port(clk_i : in  std_logic;           -- system clock
       rst_i : in  std_logic;           -- system reset
       -- Data
       dat_i : in  std_logic_vector(Width_g - 1 downto 0); --data input
       str_i : in  std_logic;           -- valid/strobe signal
       -- #
       del_i : in  std_logic_vector(log2ceil(MaxDelay_g) - 1 downto 0); --delay parameters input
       -- Out
       dat_o : out std_logic_vector((Width_g - 1) downto 0)); -- data output
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_delay2 is

  signal mem_out_s       : std_logic_vector(Width_g - 1 downto 0);
  signal rst_state_cnt_s : integer range 0 to MaxDelay_g - 1;

begin

  -- *** Assertions ***
  assert Resource_g = "AUTO" or Resource_g = "SRL" or Resource_g = "BRAM" report "###ERROR###: psi_common_delay: Unknown Resource_g - " & Resource_g severity error;
  assert Resource_g /= "BRAM" or MaxDelay_g >= 3 report "###ERROR###: psi_common_delay: MaxDelay_g >= 3 required for Resource_g=BRAM" severity error;
  assert BramThreshold_g > 3 report "###ERROR###: psi_common_delay: BramThreshold_g must be > 3" severity error;

  -- *** SRL ***
  g_srl : if (MaxDelay_g > 1) and ((Resource_g = "SRL") or ((Resource_g = "AUTO") and (MaxDelay_g < BramThreshold_g))) generate
    type srl_t is array (0 to MaxDelay_g - 1) of std_logic_vector(Width_g - 1 downto 0);
    signal srl_s : srl_t := (others => (others => '0'));
  begin

    p_srl : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if str_i = '1' then
          srl_s(0)               <= dat_i;
          srl_s(1 to srl_s'high) <= srl_s(0 to srl_s'high - 1);
        end if;
      end if;
    end process;
    mem_out_s <= srl_s(from_uslv(del_i) - 2);

  end generate;

  -- *** BRAM ***
  g_bram : if (MaxDelay_g > 1) and ((Resource_g = "BRAM") or ((Resource_g = "AUTO") and (MaxDelay_g >= BramThreshold_g))) generate
    signal rd_addr_s, wr_addr_s : std_logic_vector(log2ceil(MaxDelay_g) - 1 downto 0) := (others => '0');
  begin

    -- address control process
    p_bram : process(clk_i)
    begin
      if rising_edge(clk_i) then
        if rst_i = RStPol_g then
          wr_addr_s <= (others => '0');
          rd_addr_s <= (others => '0');
        elsif str_i = '1' then
          -- write address
          if unsigned(wr_addr_s) = unsigned(del_i) - 3 then
            wr_addr_s <= (others => '0');
          else
            wr_addr_s <= std_logic_vector(unsigned(wr_addr_s) + 1);
          end if;
          -- read address
          if unsigned(rd_addr_s) = unsigned(del_i) - 3 then
            rd_addr_s <= (others => '0');
          else
            rd_addr_s <= std_logic_vector(unsigned(rd_addr_s) + 1);
          end if;
        end if;
      end if;
    end process;

    -- memory instantiation
    i_bram : entity work.psi_common_sdp_ram
      generic map(                      -- @suppress "Generic map uses default values. Missing optional actuals: IsAsync_g, RamStyle_g" 
        Depth_g    => MaxDelay_g,
        Width_g    => Width_g,
        Behavior_g => RamBehavior_g)
      port map(                         -- @suppress "Port map uses default values. Missing optional actuals: RdClk"
        Clk    => clk_i,
        WrAddr => wr_addr_s,
        Wr     => str_i,
        WrData => dat_i,
        RdAddr => rd_addr_s,
        Rd     => str_i,
        RdData => mem_out_s
      );
  end generate;

  -- *** Single Stage ***
  g_single : if MaxDelay_g = 1 generate
    mem_out_s <= dat_i;
  end generate;

  -- *** Output register ***
  p_outreg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RStPol_g then
        dat_o           <= (others => '0');
        rst_state_cnt_s <= 0;
      elsif str_i = '1' then
        if RstState_g = false or rst_state_cnt_s = unsigned(del_i) - 1 then
          dat_o <= mem_out_s;
        else
          dat_o           <= (others => '0');
          rst_state_cnt_s <= rst_state_cnt_s + 1;
        end if;
      end if;
    end if;
  end process;

end architecture;
