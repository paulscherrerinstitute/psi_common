------------------------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This component is a generic Ping Pong buffer which consists in having
-- two buffers in a single RAM block that alternates. The system flips back
-- and forth between the buffers, letting run the algorithm on one buffer. Once
-- the number of samples to read is reached, the IRQ output is set to one
-- This allows acquiring constant data flow without losing, generally in use
-- when transfer occurs at lowest ratio than processing.
-- It is possible to send data in TDM mode or in parallel
-- ! Beware: if one channel preferably use parallel implementation
-- dat:--|---|---|xxx|xxx|xxx|---|---|---|xxx|xxx|xxx|---|---|---|xxx|xxx|xxx|
--       Ping        Pong        Ping        Pong        Ping        Pong
-- irq:          |           |           |           |           |           |
------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;

entity psi_common_ping_pong is
  generic(ch_nb_g        : natural   := 16;     -- Channel number -> master 8
          sample_nb_g    : natural   := 1012;   -- sample number per memory space
          dat_length_g   : positive  := 16;     -- data width in bits
          tdm_g          : boolean   := false;  -- TDM* behavior if false PAR
          ram_behavior_g : string    := "RBW";  -- ram behavior "RBW"|"WBR" -> cf RAM
          rst_pol_g      : std_logic := '1');   -- reset polarity
  port(clk_i          : in  std_logic;          -- clock data
       rst_i          : in  std_logic;          -- rst data
       dat_i          : in  std_logic_vector(choose(tdm_g, dat_length_g - 1, ch_nb_g * dat_length_g - 1) downto 0); -- data input
       str_i          : in  std_logic;          -- strobe input (ie valid)
       --*** mem read interface ***
       mem_irq_o      : out std_logic;          -- indicate when a set of buffer has been filled
       mem_clk_i      : in  std_logic;          -- clock mem
       mem_addr_ch_i  : in  std_logic_vector(log2ceil(ch_nb_g) - 1 downto 0);     -- Channel selection for mem read
       mem_addr_spl_i : in  std_logic_vector(log2ceil(sample_nb_g) - 1 downto 0); -- Sample selection for mem read
       mem_dat_o      : out std_logic_vector(dat_length_g - 1 downto 0)           -- data mem read
      );
end entity;

architecture rtl of psi_common_ping_pong is
  -- internals
  constant ram_depth_c : integer := 2 * 2**log2ceil(ch_nb_g) * 2**(log2ceil(sample_nb_g)); -- cst to define the ram depth

  signal str_s, str_dff_s   : std_logic; -- pipe entry stage for strobe
  signal dpram_data_write_s : std_logic_vector(dat_length_g - 1 downto 0); -- data to write within RAMs
  signal ch_offs_count_s    : unsigned(log2ceil(ch_nb_g) - 1 downto 0); -- channel counter <=> helper
  signal sample_s           : unsigned(log2ceil(sample_nb_g) - 1 downto 0); -- sample counter  <=> base 	RAM address (LSB)
  signal dpram_add_s        : std_logic_vector(log2ceil(ram_depth_c) - 1 downto 0); -- RAMs address
  signal toggle_s           : std_logic; -- toggle bit for ping & pong
  signal cdc_toggle_s       : std_logic_vector(2 downto 0); -- select
  signal dpram_wren_s       : std_logic; -- write enable RAM1
  signal dpram_read_add_s   : std_logic_vector(log2ceil(ram_depth_c) - 1 downto 0) := (others => '0');
  signal dat_s              : std_logic_vector(dat_length_g - 1 downto 0);
  --
  type data_array_t is array (0 to ch_nb_g - 1) of std_logic_vector(dat_length_g - 1 downto 0);
  signal data_array_s       : data_array_t;

begin
  --*** General ASSERT ***
  assert not (tdm_g and ch_nb_g = 1)
  report "###ERROR###: preferably use no tdm mode for one channel"
  severity failure;

  --*** TAG Process CTRL ***
  proc_ctrl : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        --*** init ***
        sample_s        <= choose(tdm_g, to_unsigned(0, sample_s'length), to_unsigned(sample_nb_g - 1, sample_s'length));
        toggle_s        <= '0';
        str_s           <= '0';
        str_dff_s       <= '0';
        dpram_wren_s    <= '0';
        ch_offs_count_s <= (others => '0');
        dpram_add_s     <= (others => '0');

      else

        str_s <= str_i;
        --*** 1 pipe Entry gates PAR ***
        if not tdm_g then
          if ch_nb_g > 1 then
            for i in 0 to ch_nb_g - 1 loop
              data_array_s(i) <= dat_i(i * dat_length_g + dat_length_g - 1 downto i * dat_length_g);
            end loop;
          else
            dat_s <= dat_i;
          end if;
        --*** 1 pipe Entry gates TDM ***
        else
          dat_s <= dat_i;
        end if;

        --*** channel counter PAR ***
        if not tdm_g then
          if str_s = '1' then
            ch_offs_count_s <= (others => '0');
            str_dff_s       <= '1';
          else
            if ch_offs_count_s = ch_nb_g - 1 then
              ch_offs_count_s <= ch_offs_count_s;
              str_dff_s       <= '0';
            else
              ch_offs_count_s <= ch_offs_count_s + 1;
              str_dff_s       <= '1';
            end if;
          end if;

        --*** channel counter TDM ***
        else
          if ch_offs_count_s = ch_nb_g - 1 then
            ch_offs_count_s <= (others => '0');
          else
            if str_s = '1' then
              ch_offs_count_s <= ch_offs_count_s + 1;
            end if;
          end if;
        end if;

        --*** sample counter PAR ***
        if not tdm_g then
          if sample_s = sample_nb_g - 1 and str_s = '1' then
            sample_s <= (others => '0');
            toggle_s <= not toggle_s;
          else
            if str_s = '1' then
              sample_s <= sample_s + 1;
            end if;
          end if;
        else
          if ch_offs_count_s = ch_nb_g - 1 and str_s = '1' then
            if sample_s = sample_nb_g - 1 then
              sample_s <= (others => '0');
              toggle_s <= not toggle_s;
            else
              sample_s <= sample_s + 1;
            end if;
          end if;
        end if;

        --*** DPRAM address write & ena ***
        dpram_add_s  <= toggle_s & std_logic_vector(ch_offs_count_s) & std_logic_vector(sample_s(sample_s'high downto 0));
        dpram_wren_s <= choose(tdm_g, str_s, str_dff_s);

        --*** align data prior to write for PAR ***
        if not tdm_g then
          if ch_nb_g > 1 and str_dff_s = '1' then
            dpram_data_write_s             <= data_array_s(0);
            data_array_s(0 to ch_nb_g - 2) <= data_array_s(1 to ch_nb_g - 1);
          else
            dpram_data_write_s <= dat_s;
          end if;
        else
          --*** align data prior to write for TDM ***
          if str_s = '1' then
            dpram_data_write_s <= dat_s;
          end if;
        end if;
      end if;
    end if;
  end process;

  --*** TAG cdc for toggle - double stage synchronizer ***
  proc_cdc : process(mem_clk_i)
  begin
    if rising_edge(mem_clk_i) then
      cdc_toggle_s(0) <= toggle_s;
      cdc_toggle_s(1) <= cdc_toggle_s(0);
      cdc_toggle_s(2) <= cdc_toggle_s(1);
    end if;
  end process;
  mem_irq_o        <= cdc_toggle_s(1) xor cdc_toggle_s(2);
  dpram_read_add_s <= not cdc_toggle_s(1) & mem_addr_ch_i & mem_addr_spl_i;

  --*** TAG PING PONG Buffer ***
  inst_dpram_pp : entity work.psi_common_tdp_ram
    generic map(depth_g    => ram_depth_c,
                width_g    => dat_length_g,
                behavior_g => ram_behavior_g)
    port map(a_clk_i  => clk_i,
             a_addr_i => dpram_add_s,
             a_wr_i   => dpram_wren_s,
             a_dat_i  => dpram_data_write_s,
             a_dat_o  => open,
             --
             b_clk_i  => mem_clk_i,
             b_addr_i => dpram_read_add_s,
             b_wr_i   => '0',
             b_dat_i  => (others => '0'),
             b_dat_o  => mem_dat_o);

end architecture;
