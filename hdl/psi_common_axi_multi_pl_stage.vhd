------------------------------------------------------------------------------
--  Copyright (c) 2019 by Enclustra GmbH, Switzerland
--  All rights reserved.
--  Authors: Eduardo del Castillo
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements multiple pipeline stages for an axi mm slave interface.
-- It is based on
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- $$ processes=master,slave $$
entity psi_common_axi_multi_pl_stage is
  generic(
    addr_width_g : positive  := 32;
    data_width_g : positive  := 32;
    stages_g     : positive  := 1;
    rst_pol_g    : std_logic := '1'
  );
  port(
    -- global signals
    clk_i       : in  std_logic;        -- $$ type=clk; freq=100.0e6 $$
    rst_i       : in  std_logic;        -- $$ type=rst; clk=Clk $$

    -------------------------------------------------------------------------------------------
    -- input interface
    -------------------------------------------------------------------------------------------
    -- write address channel
    in_awaddr   : in  std_logic_vector(addr_width_g - 1 downto 0);
    in_awvalid  : in  std_logic;
    in_awready  : out std_logic;
    in_awlen    : in  std_logic_vector(7 downto 0);
    in_awsize   : in  std_logic_vector(2 downto 0);
    in_awburst  : in  std_logic_vector(1 downto 0);
    in_awlock   : in  std_logic;
    in_awcache  : in  std_logic_vector(3 downto 0);
    in_awprot   : in  std_logic_vector(2 downto 0);
    -- write data channel
    in_wdata    : in  std_logic_vector(data_width_g - 1 downto 0);
    in_wstrb    : in  std_logic_vector(data_width_g / 8 - 1 downto 0);
    in_wvalid   : in  std_logic;
    in_wready   : out std_logic;
    in_wlast    : in  std_logic;
    -- write response channel
    in_bresp    : out std_logic_vector(1 downto 0);
    in_bvalid   : out std_logic;
    in_bready   : in  std_logic;
    -- read address channel
    in_araddr   : in  std_logic_vector(addr_width_g - 1 downto 0);
    in_arvalid  : in  std_logic;
    in_arready  : out std_logic;
    in_arlen    : in  std_logic_vector(7 downto 0);
    in_arsize   : in  std_logic_vector(2 downto 0);
    in_arburst  : in  std_logic_vector(1 downto 0);
    in_arlock   : in  std_logic;
    in_arcache  : in  std_logic_vector(3 downto 0);
    in_arprot   : in  std_logic_vector(2 downto 0);
    -- read data channel
    in_rdata    : out std_logic_vector(data_width_g - 1 downto 0);
    in_rvalid   : out std_logic;
    in_rready   : in  std_logic;
    in_rresp    : out std_logic_vector(1 downto 0);
    in_rlast    : out std_logic;
    -------------------------------------------------------------------------------------------
    -- output interface
    -------------------------------------------------------------------------------------------
    -- write address channel
    out_awaddr  : out std_logic_vector(addr_width_g - 1 downto 0);
    out_awvalid : out std_logic;
    out_awready : in  std_logic;
    out_awlen   : out std_logic_vector(7 downto 0);
    out_awsize  : out std_logic_vector(2 downto 0);
    out_awburst : out std_logic_vector(1 downto 0);
    out_awlock  : out std_logic;
    out_awcache : out std_logic_vector(3 downto 0);
    out_awprot  : out std_logic_vector(2 downto 0);
    -- write data channel
    out_wdata   : out std_logic_vector(data_width_g - 1 downto 0);
    out_wstrb   : out std_logic_vector(data_width_g / 8 - 1 downto 0);
    out_wvalid  : out std_logic;
    out_wready  : in  std_logic;
    out_wlast   : out std_logic;
    -- write response channel
    out_bresp   : in  std_logic_vector(1 downto 0);
    out_bvalid  : in  std_logic;
    out_bready  : out std_logic;
    -- read address channel
    out_araddr  : out std_logic_vector(addr_width_g - 1 downto 0);
    out_arvalid : out std_logic;
    out_arready : in  std_logic;
    out_arlen   : out std_logic_vector(7 downto 0);
    out_arsize  : out std_logic_vector(2 downto 0);
    out_arburst : out std_logic_vector(1 downto 0);
    out_arlock  : out std_logic;
    out_arcache : out std_logic_vector(3 downto 0);
    out_arprot  : out std_logic_vector(2 downto 0);
    -- read data channel
    out_rdata   : in  std_logic_vector(data_width_g - 1 downto 0);
    out_rvalid  : in  std_logic;
    out_rready  : out std_logic;
    out_rresp   : in  std_logic_vector(1 downto 0);
    out_rlast   : in  std_logic
  );
end entity;

architecture rtl of psi_common_axi_multi_pl_stage is

  constant LenWidth_c   : positive := 8;
  constant SizeWidth_c  : positive := 3;
  constant BurstWidth_c : positive := 2;
  constant CacheWidth_c : positive := 4;
  constant ProtWidth_c  : positive := 3;
  constant RespWidth_c  : positive := 2;

  signal AwDataIn, AwDataOut : std_logic_vector(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c - 1 downto 0);
  signal WDataIn, WDataOut   : std_logic_vector(data_width_g + data_width_g / 8 + 1 - 1 downto 0);
  signal ArDataIn, ArDataOut : std_logic_vector(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c - 1 downto 0);
  signal RDataIn, RDataOut   : std_logic_vector(data_width_g + RespWidth_c + 1 - 1 downto 0);

begin

  -- write address channel
  AwDataIn <= in_awaddr & in_awlen & in_awsize & in_awburst & in_awlock & in_awcache & in_awprot;
  i_awch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g   => addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c,
      use_rdy_g => true,
      stages_g  => stages_g,
      rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i     => in_awvalid,
      rdy_in_o  => in_awready,
      dat_i     => AwDataIn,
      vld_o     => out_awvalid,
      rdy_out_i => out_awready,
      dat_o     => AwDataOut);

  out_awprot  <= AwDataOut(ProtWidth_c - 1 downto 0);
  out_awcache <= AwDataOut(CacheWidth_c - 1 + ProtWidth_c downto ProtWidth_c);
  out_awlock  <= AwDataOut(CacheWidth_c + ProtWidth_c);
  out_awburst <= AwDataOut(BurstWidth_c - 1 + CacheWidth_c + ProtWidth_c + 1 downto CacheWidth_c + ProtWidth_c + 1);
  out_awsize  <= AwDataOut(SizeWidth_c - 1 + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  out_awlen   <= AwDataOut(LenWidth_c - 1 + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  out_awaddr  <= AwDataOut(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c downto addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c - addr_width_g + 1);

  -- write data channel
  WDataIn <= in_wdata & in_wstrb & in_wlast;
  i_wch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g   => data_width_g + data_width_g / 8 + 1,
      use_rdy_g => true,
      stages_g  => stages_g,
      rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i     => in_wvalid,
      rdy_in_o  => in_wready,
      dat_i     => WDataIn,
      vld_o     => out_wvalid,
      rdy_out_i => out_wready,
      dat_o     => WDataOut);

  out_wlast <= WDataOut(0);
  out_wstrb <= WDataOut(data_width_g / 8 - 1 + 1 downto 1);
  out_wdata <= WDataOut(data_width_g + data_width_g / 8 downto data_width_g + data_width_g / 8 - data_width_g + 1);

  -- write response channel
  i_bch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g   => RespWidth_c,
      use_rdy_g => true,
      stages_g  => stages_g,
      rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i     => out_bvalid,
      rdy_in_o  => out_bready,
      dat_i     => out_bresp,
      vld_o     => in_bvalid,
      rdy_out_i => in_bready,
      dat_o     => in_bresp);

  -- read address channel
  ArDataIn <= in_araddr & in_arlen & in_arsize & in_arburst & in_arlock & in_arcache & in_arprot;
  i_arch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g   => addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c,
      use_rdy_g => true,
      stages_g  => stages_g,
      rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i     => in_arvalid,
      rdy_in_o  => in_arready,
      dat_i     => ArDataIn,
      vld_o     => out_arvalid,
      rdy_out_i => out_arready,
      dat_o     => ArDataOut);

  out_arprot  <= ArDataOut(ProtWidth_c - 1 downto 0);
  out_arcache <= ArDataOut(CacheWidth_c - 1 + ProtWidth_c downto ProtWidth_c);
  out_arlock  <= ArDataOut(CacheWidth_c + ProtWidth_c);
  out_arburst <= ArDataOut(BurstWidth_c - 1 + CacheWidth_c + ProtWidth_c + 1 downto CacheWidth_c + ProtWidth_c + 1);
  out_arsize  <= ArDataOut(SizeWidth_c - 1 + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  out_arlen   <= ArDataOut(LenWidth_c - 1 + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  out_araddr  <= ArDataOut(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c downto addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c - addr_width_g + 1);

  -- read data channel
  RDataIn <= out_rdata & out_rresp & out_rlast;
  i_rch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g   => data_width_g + RespWidth_c + 1,
      use_rdy_g => true,
      stages_g  => stages_g,
      rst_pol_g => rst_pol_g)
    port map(
      clk_i     => clk_i,
      rst_i     => rst_i,
      vld_i     => out_rvalid,
      rdy_in_o  => out_rready,
      dat_i     => RDataIn,
      vld_o     => in_rvalid,
      rdy_out_i => in_rready,
      dat_o     => RDataOut
    );

  in_rlast <= RDataOut(0);
  in_rresp <= RDataOut(RespWidth_c - 1 + 1 downto 1);
  in_rdata <= RDataOut(data_width_g + RespWidth_c downto data_width_g + RespWidth_c - data_width_g + 1);

end architecture;
