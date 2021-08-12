------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a pipelinestage with handshaking (AXI-S RDY/VLD). The
-- pipeline stage ensures all signals are registered in both directions (including
-- RDY). This is important to break long logic chains that can occur in the RDY 
-- paths because Rdy is often forwarded asynchronously.

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
entity psi_common_pl_stage is
  generic(
    Width_g  : integer := 8;
    UseRdy_g : boolean := true
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
architecture rtl of psi_common_pl_stage is

  -- two process method
  type tp_r is record
    DataMain    : std_logic_vector(Width_g - 1 downto 0);
    DataMainVld : std_logic;
    DataShad    : std_logic_vector(Width_g - 1 downto 0);
    DataShadVld : std_logic;
    InRdy       : std_logic;
  end record;
  signal r, r_next : tp_r;

begin
  --------------------------------------------------------------------------
  -- *** Pipeline Stage with RDY ***
  --------------------------------------------------------------------------	
  g_rdy : if UseRdy_g generate

    ----------------------------------------------------------------------
    -- Combinatorial Process
    ----------------------------------------------------------------------
    p_comb : process(InVld, InData, OutRdy, r)
      variable v         : tp_r;
      variable IsStuck_v : boolean;
    begin
      -- *** Hold variables stable ***
      v := r;

      -- *** Simplification Variables ***
      IsStuck_v := (r.DataMainVld = '1' and OutRdy = '0');

      -- *** Handle output transactions ***
      if r.DataMainVld = '1' and OutRdy = '1' then
        v.DataMainVld := r.DataShadVld;
        v.DataMain    := r.DataShad;
        v.DataShadVld := '0';
      end if;

      -- *** Latch incoming data ***
      if r.InRdy = '1' and InVld = '1' then
        -- If we are stuck, save data in shadow register because ready is deasserted only after one clock cycle
        if IsStuck_v then
          v.DataShadVld := '1';
          v.DataShad    := InData;
        -- In normal case, forward data directly to the output registers
        else
          v.DataMainVld := '1';
          v.DataMain    := InData;
        end if;
      end if;

      -- *** Remove Rdy if stuck ***
      if IsStuck_v then
        v.InRdy := '0';
      else
        v.InRdy := '1';
      end if;

      -- *** Assign to signal ***
      r_next <= v;
    end process;

    InRdy   <= r.InRdy;
    OutVld  <= r.DataMainVld;
    OutData <= r.DataMain;

    ----------------------------------------------------------------------
    -- Sequential Process
    ----------------------------------------------------------------------	
    p_seq : process(Clk)
    begin
      if rising_edge(Clk) then
        r <= r_next;
        if Rst = '1' then
          r.DataMain <= (others => '0');
          r.DataMainVld <= '0';
          r.DataShad <= (others => '0');
          r.DataShadVld <= '0';
          r.InRdy       <= '1';
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------
  -- *** Pipeline Stage without RDY ***
  --------------------------------------------------------------------------	
  g_nrdy : if not UseRdy_g generate
    InRdy <= '0';
    p_stg : process(Clk)
    begin
      if rising_edge(Clk) then
        OutData <= InData;
        OutVld  <= InVld;
        if Rst = '1' then
          OutVld <= '0';
        end if;
      end if;
    end process;
  end generate;

end;

