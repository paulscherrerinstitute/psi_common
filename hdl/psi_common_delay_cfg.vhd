------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef & Oliver Bruendler
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
entity psi_common_delay_cfg is
  generic(Width_g       : positive  := 16; --data vector width
          MaxDelay_g    : positive  := 256; -- maximum delay wanted
          RStPol_g      : std_logic := '1'; -- reset polarity
          RamBehavior_g : string    := "RBW" -- "RBW" = read-before-write, "WBR" = write-before-read
         ); 
         
  port(clk_i : in  std_logic;-- system clock
       rst_i : in  std_logic;-- system reset
       -- Data
       dat_i : in  std_logic_vector(Width_g - 1 downto 0); --data input
       str_i : in  std_logic;-- valid/strobe signal input
       -- #
       del_i : in  std_logic_vector(log2ceil(MaxDelay_g) - 1 downto 0);--delay parameter input
       -- Out
       dat_o : out std_logic_vector((Width_g - 1) downto 0));-- data output
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_delay_cfg is
  constant max_c              : unsigned(log2ceil(MaxDelay_g) - 1 downto 0)         := to_unsigned(MaxDelay_g-1, log2ceil(MaxDelay_g));
  type srl_t is array (0 to 2) of std_logic_vector(Width_g - 1 downto 0);
  signal srl_s                : srl_t                                               := (others => (others => '0'));
  signal mem_out_s            : std_logic_vector(Width_g - 1 downto 0);
  signal rd_addr_s, wr_addr_s : std_logic_vector(log2ceil(MaxDelay_g) - 1 downto 0) := (others => '0');
  signal mem_out2_s           : std_logic_vector(Width_g - 1 downto 0);
  ----------------------------------------------------------------------------
  signal del_dff_s            : std_logic_vector(del_i'range);
  signal latch_count_s        : unsigned(del_i'range)                               := (others => '0');
  signal diff_s               : unsigned(del_i'range)                               := (others => '0');
  signal rs_s                 : std_logic;

begin

  --*** address control process ***
  p_bram : process(clk_i)
    --  variable count_start_v : unsigned(wr_addr_s'range);
  begin
    if rising_edge(clk_i) then
      if rst_i = RStPol_g then
        wr_addr_s     <= (others => '0');
        rd_addr_s     <= (others => '0');
        del_dff_s     <= (others => '0');
        latch_count_s <= (others => '0');
        rs_s          <= '0';
      --       count_start_v := (others => '0');
      elsif str_i = '1' then
        del_dff_s <= del_i;
        if from_uslv(del_i) < 3 then
          wr_addr_s <= (others => '0');
          rd_addr_s <= (others => '0');
        else
          --*** write address mngt ***
          if unsigned(wr_addr_s) = to_unsigned(MaxDelay_g - 1, wr_addr_s'length) then
            wr_addr_s <= (others => '0');
          else
            wr_addr_s <= std_logic_vector(unsigned(wr_addr_s) + 1);
          end if;

          --*** read address mngt *** for special past observation comment this statement
          if (rs_s = '1' or del_dff_s < del_i) then
            rd_addr_s <= rd_addr_s;
          else
            if unsigned(wr_addr_s) >= unsigned(del_i) - 3 and unsigned(wr_addr_s) < max_c then
              rd_addr_s <= std_logic_vector(unsigned(wr_addr_s) - unsigned(del_i) + 3);
            elsif unsigned(wr_addr_s) = max_c then
              rd_addr_s <= std_logic_vector(max_c - unsigned(del_i) + 3);
            elsif unsigned(rd_addr_s) = max_c then
              rd_addr_s <= (others => '0');
            else
              rd_addr_s <= std_logic_vector(unsigned(rd_addr_s) + 1);
            end if;
          end if;

          --*** RS latch & counter  ***
          if del_dff_s < del_i then
            rs_s          <= '1';
            diff_s        <= unsigned(del_i) - unsigned(del_dff_s);
            latch_count_s <= (others => '0');
          elsif latch_count_s = diff_s - 2 then
            rs_s <= '0';
          end if;

          if rs_s = '1' then
            latch_count_s <= latch_count_s + 1;
          end if;

        end if;
      end if;
    end if;
  end process;

  --*** memory instantiation ***
  i_bram : entity work.psi_common_sdp_ram
    generic map( -- @suppress "Generic map uses default values. Missing optional actuals: IsAsync_g, RamStyle_g" 
      Depth_g    => MaxDelay_g,
      Width_g    => Width_g,
      Behavior_g => RamBehavior_g)
    port map( -- @suppress "Port map uses default values. Missing optional actuals: RdClk"
      Clk    => clk_i,
      WrAddr => wr_addr_s,
      Wr     => str_i,
      WrData => dat_i,
      RdAddr => rd_addr_s,
      Rd     => str_i,
      RdData => mem_out2_s);

  --*** case where the delay change below 3 -> using SRL on the fly ***
  p_srl : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if str_i = '1' then
        srl_s(0)               <= dat_i;
        srl_s(1 to srl_s'high) <= srl_s(0 to srl_s'high - 1);
      end if;
    end if;
  end process;

  -- take the output of a SRL instead --
  mem_out_s <= srl_s(from_uslv(del_i) - 2) when from_uslv(del_i) < 3 else mem_out2_s;

  -- *** Single Stage ***
  g_single : if MaxDelay_g = 1 generate
    mem_out_s <= dat_i;
  end generate;

  -- *** Output register ***
  p_outreg : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = RStPol_g then
        dat_o <= (others => '0');
      elsif str_i = '1' then
        dat_o <= mem_out_s;
      end if;
    end if;
  end process;

end architecture;
