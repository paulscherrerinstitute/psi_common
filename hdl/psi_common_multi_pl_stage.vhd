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

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
-- $$ processes=stim,check $$
entity psi_common_multi_pl_stage is
  generic(
    Width_g  : positive := 8;
    UseRdy_g : boolean  := true;
    Stages_g : natural  := 1
  );
  port(
    -- Control Signals
    Clk     : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    Rst     : in  std_logic;            -- $$ type=rst; clk=Clk $$

    -- Input
    InVld   : in  std_logic;
    InRdy   : out std_logic;
    InData  : in  std_logic_vector(Width_g - 1 downto 0);
    -- Output
    OutVld  : out std_logic;
    OutRdy  : in  std_logic := '1';
    OutData : out std_logic_vector(Width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_multi_pl_stage is

  type Data_t is array (natural range <>) of std_logic_vector(Width_g - 1 downto 0);
  signal Data : Data_t(0 to Stages_g);
  signal Vld  : std_logic_vector(0 to Stages_g);
  signal Rdy  : std_logic_vector(0 to Stages_g);

begin

  g_nonzero : if Stages_g > 0 generate
    Vld(0)  <= InVld;
    InRdy   <= Rdy(0);
    Data(0) <= InData;

    g_stages : for i in 0 to Stages_g - 1 generate
      i_stg : entity work.psi_common_pl_stage
        generic map(
          Width_g  => Width_g,
          UseRdy_g => UseRdy_g
        )
        port map(
          Clk     => Clk,
          Rst     => Rst,
          InVld   => Vld(i),
          InRdy   => Rdy(i),
          InData  => Data(i),
          OutVld  => Vld(i + 1),
          OutRdy  => Rdy(i + 1),
          OutData => Data(i + 1)
        );
    end generate;

    OutVld        <= Vld(Stages_g);
    Rdy(Stages_g) <= OutRdy;
    OutData       <= Data(Stages_g);
  end generate;

  g_zero : if Stages_g = 0 generate
    OutVld  <= InVld;
    OutData <= InData;
    InRdy   <= OutRdy;
  end generate;

end;

