------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic synchronous FIFO. It  has optional level- and
-- almost-full/empty ports.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;
--@formatter:off
entity psi_common_sync_fifo is
  generic(
    width_g           : positive  := 16; -- width
    depth_g           : positive  := 32; -- depth
    alm_full_on_g     : boolean   := false; -- almost full signal active
    alm_full_level_g  : natural   := 28; -- almost full level threshold val
    alm_empty_on_g    : boolean   := false; -- almost empty signal active
    alm_empty_level_g : natural   := 4; -- almost empty level threshold val
    ram_style_g       : string    := "auto"; -- RAM style selected -> "Auto" choose depedning size block-RAM or dist-RAM | "distributed" | "block"
    ram_behavior_g    : string    := "RBW"; -- "RBW" = read-before-write, "WBR" = write-before-read
    rdy_rst_state_g   : std_logic := '1'; -- Use '1' for minimal logic on Rdy path
    rst_pol_g         : std_logic := '1'
  );
  port(
    -- Control Ports
    clk_i       : in  std_logic;        -- clock in
    rst_i       : in  std_logic;        -- system reset
    -- Input Data
    dat_i       : in  std_logic_vector(width_g - 1 downto 0); -- data input
    vld_i       : in  std_logic;        -- AXI-S handshaking signal | strobe in
    rdy_o       : out std_logic;        -- AXI-S handshaking signal | not full
    -- Output Data
    dat_o       : out std_logic_vector(width_g - 1 downto 0); -- Read Data
    vld_o       : out std_logic;        -- AXI-S handshaking signal | strobe out
    rdy_i       : in  std_logic;        -- AXI-S handshaking signal | not empty
    -- Input Status
    full_o      : out std_logic;        -- FIFO full
    alm_full_o  : out std_logic;        -- FIFO Almost full
    in_level_o  : out std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0); -- FIFO in level
    -- Output Status
    empty_o     : out std_logic;        -- FIFO Empty
    alm_empty_o : out std_logic;        -- FIFO Almost empty
    out_level_o : out std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0) -- FIFO out leve
  );
end entity;
--@formatter:on

architecture rtl of psi_common_sync_fifo is

  type two_process_r is record
    WrLevel : std_logic_vector(in_level_o'range);
    RdLevel : std_logic_vector(out_level_o'range);
    RdUp    : std_logic;
    WrDown  : std_logic;
    WrAddr  : std_logic_vector(log2ceil(depth_g) - 1 downto 0);
    RdAddr  : std_logic_vector(log2ceil(depth_g) - 1 downto 0);
  end record;

  signal r, r_next : two_process_r;

  signal RamWr     : std_logic;
  signal RamRdAddr : std_logic_vector(log2ceil(depth_g) - 1 downto 0);

begin

  p_comb : process(vld_i, rdy_i, rst_i, r)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- Write side
    v.RdUp := '0';
    RamWr  <= '0';
    if unsigned(r.WrLevel) /= depth_g and vld_i = '1' then
      if unsigned(r.WrAddr) /= depth_g - 1 then
        v.WrAddr := std_logic_vector(unsigned(r.WrAddr) + 1);
      else
        v.WrAddr := (others => '0');
      end if;
      RamWr  <= '1';
      v.RdUp := '1';
      if r.WrDown = '0' then
        v.WrLevel := std_logic_vector(unsigned(r.WrLevel) + 1);
      end if;
    elsif r.WrDown = '1' then
      v.WrLevel := std_logic_vector(unsigned(r.WrLevel) - 1);
    end if;

    -- Write side status
    if unsigned(r.WrLevel) = depth_g then
      rdy_o  <= '0';
      full_o <= '1';
    else
      rdy_o  <= '1';
      full_o <= '0';
    end if;
    -- Artificially keep InRdy low during reset if required
    if (rdy_rst_state_g = '0') and (rst_i = '1') then
      rdy_o <= '0';
    end if;

    if alm_full_on_g and unsigned(r.WrLevel) >= alm_full_level_g then
      alm_full_o <= '1';
    else
      alm_full_o <= '0';
    end if;

    -- Read side
    v.WrDown  := '0';
    if unsigned(r.RdLevel) /= 0 and rdy_i = '1' then
      if unsigned(r.RdAddr) /= depth_g - 1 then
        v.RdAddr := std_logic_vector(unsigned(r.RdAddr) + 1);
      else
        v.RdAddr := (others => '0');
      end if;
      v.WrDown := '1';
      if r.RdUp = '0' then
        v.RdLevel := std_logic_vector(unsigned(r.RdLevel) - 1);
      end if;
    elsif r.RdUp = '1' then
      v.RdLevel := std_logic_vector(unsigned(r.RdLevel) + 1);
    end if;
    RamRdAddr <= v.RdAddr;

    -- Read side status
    if unsigned(r.RdLevel) > 0 then
      vld_o   <= '1';
      empty_o <= '0';
    else
      vld_o   <= '0';
      empty_o <= '1';
    end if;

    if alm_empty_on_g and unsigned(r.RdLevel) <= alm_empty_level_g then
      alm_empty_o <= '1';
    else
      alm_empty_o <= '0';
    end if;

    -- Assign signal
    r_next <= v;

  end process;

  -- Synchronous Outputs
  out_level_o <= r.RdLevel;
  in_level_o  <= r.WrLevel;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.WrLevel <= (others => '0');
        r.RdLevel <= (others => '0');
        r.RdUp    <= '0';
        r.WrDown  <= '0';
        r.WrAddr  <= (others => '0');
        r.RdAddr  <= (others => '0');
      end if;
    end if;
  end process;

  i_ram : entity work.psi_common_sdp_ram
    generic map(
      depth_g        => depth_g,
      width_g        => width_g,
      ram_style_g    => ram_style_g,
      ram_behavior_g => ram_behavior_g
    )
    port map(
      wr_clk_i  => clk_i,
      wr_addr_i => r.WrAddr,
      wr_i      => RamWr,
      wr_dat_i  => dat_i,
      rd_addr_i => RamRdAddr,
      rd_dat_o  => dat_o
    );

end architecture;
