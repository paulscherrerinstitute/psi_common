------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements multiple pipelinestages with handshaking (AXI-S
-- RDY/VLD). The pipeline stage ensures all signals are registered in both
-- directions (including RDY). This is important to break long logic chains
-- that can occur in the RDY paths because Rdy is often forwarded asynchronously.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- @formatter:off
entity psi_common_multi_pl_stage is
  generic(width_g   : positive := 8;                              -- vector length
          use_rdy_g : boolean  := true;                           -- use ready signal to push back
          stages_g  : natural  := 1;                              -- number of pipe
          rst_pol_g : std_logic:='1');                            -- '1' active high, '0' active low
  port(   clk_i     : in  std_logic;                              -- system clock
          rst_i     : in  std_logic;                              -- system reset 
          vld_i     : in  std_logic;                              -- valid input signal
          rdy_o     : out std_logic;                              -- ready signal output
          dat_i     : in  std_logic_vector(width_g - 1 downto 0); -- data input
          vld_o     : out std_logic;                              -- valid output signal
          rdy_i     : in  std_logic := '1';                       -- ready signal input
          dat_o     : out std_logic_vector(width_g - 1 downto 0));-- data output
end entity;
-- @formatter:on

architecture rtl of psi_common_multi_pl_stage is

  type Data_t is array (natural range <>) of std_logic_vector(width_g - 1 downto 0);
  signal data_s : Data_t(0 to stages_g);
  signal vld_s  : std_logic_vector(0 to stages_g);
  signal rdy_s  : std_logic_vector(0 to stages_g);

begin

  g_nonzero : if stages_g > 0 generate
    vld_s(0)   <= vld_i;
    rdy_o <= rdy_s(0);
    data_s(0)  <= dat_i;

    g_stages : for i in 0 to stages_g - 1 generate
      i_stg : entity work.psi_common_pl_stage
        generic map(
          width_g   => width_g,
          use_rdy_g => use_rdy_g,
          rst_pol_g => rst_pol_g
        )
        port map(
          clk_i => clk_i,
          rst_i => rst_i,
          vld_i => vld_s(i),
          rdy_o => rdy_s(i),
          dat_i => data_s(i),
          vld_o => vld_s(i + 1),
          rdy_i => rdy_s(i + 1),
          dat_o => data_s(i + 1)
        );
    end generate;

    vld_o         <= vld_s(stages_g);
    rdy_s(stages_g) <= rdy_i;
    dat_o         <= data_s(stages_g);
  end generate;

  g_zero : if stages_g = 0 generate
    vld_o    <= vld_i;
    dat_o    <= dat_i;
    rdy_o <= rdy_i;
  end generate;

end architecture;