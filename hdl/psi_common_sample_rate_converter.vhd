------------------------------------------------------------------------------
-- Copyright (c) 2024 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- @formatter:off
entity psi_common_sample_rate_converter is
  generic(rate_g                : integer := 2;                                 -- Sampling rate factor for up/down sampling
          mode_g                : string  := "DOWN";                            -- "DOWN" => downsampling, "UP" => upsampling
          length_g              : natural := 16;                                -- nb of bit 
          clk_to_vld_ratio_g    : integer := 10;                                -- Ratio between clock frequency and vld input frequency
          rst_pol_g             : std_logic := '1');
  port(   clk_i                 : in  std_logic;                                -- Clock 
          rst_i                 : in  std_logic;                                -- Synchronous rst
          vld_i                 : in  std_logic;                                -- Indicates when dat_i is vld
          dat_i                 : in  std_logic_vector(length_g - 1 downto 0);  -- Assuming 16-bit data in
          dat_o                 : out std_logic_vector(length_g - 1 downto 0);  -- Data output align with vld out
          vld_o                 : out std_logic);                               -- Indicates when dat_o is vld
end entity;
-- @formatter:on
architecture rtl of psi_common_sample_rate_converter is
  signal sample_count_s  : integer   := 0;
  signal dat_s           : std_logic_vector(length_g - 1 downto 0);
  signal vld_s           : std_logic := '0';
  signal sample_s        : std_logic_vector(length_g - 1 downto 0);
  signal vld_out_count_s : integer   := 0;
  signal vdl_dff_s       : std_logic := '0';
begin

  proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        -- Synchronous reset: reset everything on the rising edge of clk_i
        sample_count_s <= 0;
        dat_s          <= (others => '0');
        vld_s          <= '0';
        sample_s       <= (others => '0');
        vdl_dff_s      <= '0';
      else
        if mode_g = "DOWN" then
          if vld_i = '1'  then
            -- Downsampling logic
            if sample_count_s = (rate_g - 1) then
              dat_s          <= dat_i;
              vld_s          <= '1';
              sample_count_s <= 0;
            else
              vld_s          <= '0';
              sample_count_s <= sample_count_s + 1;
            end if;
          else
            -- No valid input, no valid output
            vld_s <= '0';
          end if;

        elsif mode_g = "UP" then
          -- Check for valid input transition
          if clk_to_vld_ratio_g = rate_g then
            dat_s <= dat_i;
            vld_s <= '1';
          else
            if vld_i = '1' and vdl_dff_s = '0' then
              -- Store the current input sample and initialize counters
              sample_s        <= dat_i;
              vld_out_count_s <= clk_to_vld_ratio_g / rate_g;
            end if;

            vdl_dff_s <= vld_i;
            if vld_out_count_s > 0 then
              -- Assert valid output
              dat_s           <= sample_s;
              vld_s           <= '0';
              vld_out_count_s <= vld_out_count_s - 1;
            elsif vld_out_count_s = 0 then
              vld_out_count_s <= clk_to_vld_ratio_g / rate_g;
              dat_s           <= sample_s;
              vld_s           <= '1';
            end if;
          end if;
        end if;

      end if;
    end if;
  end process;

  dat_o <= dat_s;
  vld_o <= vld_s;

end architecture;
