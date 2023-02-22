------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  Copyright (c) 2023 by Oliver BrÃÂÃÂ¼ndler
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
    width_g  : integer := 8;
    use_rdy_g : boolean := true
  );
  port(
    -- Control Signals
    clk_i     : in  std_logic;            -- $$ type=clk; freq=100e6 $$
    rst_i     : in  std_logic;            -- $$ type=rst; clk=Clk $$

    -- Input
    vld_i   : in  std_logic;
    rdy_o   : out std_logic;
    dat_i  : in  std_logic_vector(width_g - 1 downto 0);
    -- Output
    vld_o  : out std_logic;
    rdy_i  : in  std_logic := '1';
    dat_o : out std_logic_vector(width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_pl_stage is

  -- two process method
  type tp_r is record
    DataMain    : std_logic_vector(width_g - 1 downto 0);
    DataMainVld : std_logic;
    DataShad    : std_logic_vector(width_g - 1 downto 0);
    DataShadVld : std_logic;
    rdy_o       : std_logic;
  end record;
  signal r, r_next : tp_r;

begin
  --------------------------------------------------------------------------
  -- *** Pipeline Stage with RDY ***
  --------------------------------------------------------------------------	
  g_rdy : if use_rdy_g generate

    ----------------------------------------------------------------------
    -- Combinatorial Process
    ----------------------------------------------------------------------
    p_comb : process(vld_i, dat_i, rdy_i, r)
      variable v         : tp_r;
      variable IsStuck_v : boolean;
    begin
      -- *** Hold variables stable ***
      v := r;

      -- *** Simplification Variables ***
      IsStuck_v := (r.DataMainVld = '1' and rdy_i = '0' and (vld_i = '1' or r.DataShadVld = '1'));

      -- *** Handle output transactions ***
      if r.DataMainVld = '1' and rdy_i = '1' then
        v.DataMainVld := r.DataShadVld;
        v.DataMain    := r.DataShad;
        v.DataShadVld := '0';
      end if;

      -- *** Latch incoming data ***
      if r.rdy_o = '1' and vld_i = '1' then
        -- If we are stuck, save data in shadow register because ready is deasserted only after one clock cycle
        if IsStuck_v then
          v.DataShadVld := '1';
          v.DataShad    := dat_i;
        -- In normal case, forward data directly to the output registers
        else
          v.DataMainVld := '1';
          v.DataMain    := dat_i;
        end if;
      end if;

      -- *** Remove Rdy if stuck ***
      if IsStuck_v then
        v.rdy_o := '0';
      else
        v.rdy_o := '1';
      end if;

      -- *** Assign to signal ***
      r_next <= v;
    end process;

    rdy_o   <= r.rdy_o;
    vld_o  <= r.DataMainVld;
    dat_o <= r.DataMain;

    ----------------------------------------------------------------------
    -- Sequential Process
    ----------------------------------------------------------------------	
    p_seq : process(clk_i)
    begin
      if rising_edge(clk_i) then
        r <= r_next;
        if rst_i = '1' then
          r.DataMainVld <= '0';
          r.DataShadVld <= '0';
          r.rdy_o       <= '1';
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------
  -- *** Pipeline Stage without RDY ***
  --------------------------------------------------------------------------	
  g_nrdy : if not use_rdy_g generate
    rdy_o <= '0';
    p_stg : process(clk_i)
    begin
      if rising_edge(clk_i) then
        dat_o <= dat_i;
        vld_o  <= vld_i;
        if rst_i = '1' then
          vld_o <= '0';
        end if;
      end if;
    end process;
  end generate;

end;

