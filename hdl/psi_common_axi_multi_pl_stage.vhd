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
-- $$ processes=master,slave $$
entity psi_common_axi_multi_pl_stage is
  generic(
    addr_width_g : positive := 32;
    data_width_g : positive := 32;
    stages_g    : positive := 1
  );
  port(
    -- global signals
    clk_i        : in  std_logic;         -- $$ type=clk; freq=100.0e6 $$
    rst_i        : in  std_logic;         -- $$ type=rst; clk=Clk $$

    -------------------------------------------------------------------------------------------
    -- input interface
    -------------------------------------------------------------------------------------------

    -- write address channel
    InAwAddr   : in  std_logic_vector(addr_width_g - 1 downto 0);
    InAwValid  : in  std_logic;
    InAwReady  : out std_logic;
    InAwLen    : in  std_logic_vector(7 downto 0);
    InAwSize   : in  std_logic_vector(2 downto 0);
    InAwBurst  : in  std_logic_vector(1 downto 0);
    InAwLock   : in  std_logic;
    InAwCache  : in  std_logic_vector(3 downto 0);
    InAwProt   : in  std_logic_vector(2 downto 0);
    -- write data channel
    InWData    : in  std_logic_vector(data_width_g - 1 downto 0);
    InWStrb    : in  std_logic_vector(data_width_g / 8 - 1 downto 0);
    InWValid   : in  std_logic;
    InWReady   : out std_logic;
    InWLast    : in  std_logic;
    -- write response channel
    InBResp    : out std_logic_vector(1 downto 0);
    InBValid   : out std_logic;
    InBReady   : in  std_logic;
    -- read address channel
    InArAddr   : in  std_logic_vector(addr_width_g - 1 downto 0);
    InArValid  : in  std_logic;
    InArReady  : out std_logic;
    InArLen    : in  std_logic_vector(7 downto 0);
    InArSize   : in  std_logic_vector(2 downto 0);
    InArBurst  : in  std_logic_vector(1 downto 0);
    InArLock   : in  std_logic;
    InArCache  : in  std_logic_vector(3 downto 0);
    InArProt   : in  std_logic_vector(2 downto 0);
    -- read data channel
    InRData    : out std_logic_vector(data_width_g - 1 downto 0);
    InRValid   : out std_logic;
    InRReady   : in  std_logic;
    InRResp    : out std_logic_vector(1 downto 0);
    InRLast    : out std_logic;
    -------------------------------------------------------------------------------------------
    -- output interface
    -------------------------------------------------------------------------------------------

    -- write address channel
    OutAwAddr  : out std_logic_vector(addr_width_g - 1 downto 0);
    OutAwValid : out std_logic;
    OutAwReady : in  std_logic;
    OutAwLen   : out std_logic_vector(7 downto 0);
    OutAwSize  : out std_logic_vector(2 downto 0);
    OutAwBurst : out std_logic_vector(1 downto 0);
    OutAwLock  : out std_logic;
    OutAwCache : out std_logic_vector(3 downto 0);
    OutAwProt  : out std_logic_vector(2 downto 0);
    -- write data channel
    OutWData   : out std_logic_vector(data_width_g - 1 downto 0);
    OutWStrb   : out std_logic_vector(data_width_g / 8 - 1 downto 0);
    OutWValid  : out std_logic;
    OutWReady  : in  std_logic;
    OutWLast   : out std_logic;
    -- write response channel
    OutBResp   : in  std_logic_vector(1 downto 0);
    OutBValid  : in  std_logic;
    OutBReady  : out std_logic;
    -- read address channel
    OutArAddr  : out std_logic_vector(addr_width_g - 1 downto 0);
    OutArValid : out std_logic;
    OutArReady : in  std_logic;
    OutArLen   : out std_logic_vector(7 downto 0);
    OutArSize  : out std_logic_vector(2 downto 0);
    OutArBurst : out std_logic_vector(1 downto 0);
    OutArLock  : out std_logic;
    OutArCache : out std_logic_vector(3 downto 0);
    OutArProt  : out std_logic_vector(2 downto 0);
    -- read data channel
    OutRData   : in  std_logic_vector(data_width_g - 1 downto 0);
    OutRValid  : in  std_logic;
    OutRReady  : out std_logic;
    OutRResp   : in  std_logic_vector(1 downto 0);
    OutRLast   : in  std_logic
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
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
  AwDataIn <= InAwAddr & InAwLen & InAwSize & InAwBurst & InAwLock & InAwCache & InAwProt;
  awch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g  => addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c,
      stages_g => stages_g
    )
    port map(
      -- Control Signals
      clk_i     => clk_i,
      rst_i     => rst_i,
      -- Input
      dat_i  => AwDataIn,
      vld_i   => InAwValid,
      rdy_in_i   => InAwReady,
      -- Output
      dat_o => AwDataOut,
      vld_o  => OutAwValid,
      rdy_out_i  => OutAwReady
    );

  OutAwProt  <= AwDataOut(ProtWidth_c - 1 downto 0);
  OutAwCache <= AwDataOut(CacheWidth_c - 1 + ProtWidth_c downto ProtWidth_c);
  OutAwLock  <= AwDataOut(CacheWidth_c + ProtWidth_c);
  OutAwBurst <= AwDataOut(BurstWidth_c - 1 + CacheWidth_c + ProtWidth_c + 1 downto CacheWidth_c + ProtWidth_c + 1);
  OutAwSize  <= AwDataOut(SizeWidth_c - 1 + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  OutAwLen   <= AwDataOut(LenWidth_c - 1 + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  OutAwAddr  <= AwDataOut(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c downto addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c - addr_width_g + 1);

  -- write data channel
  WDataIn <= InWData & InWStrb & InWLast;
  wch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g  => data_width_g + data_width_g / 8 + 1,
      stages_g => stages_g
    )
    port map(
      -- Control Signals
      clk_i     => clk_i,
      rst_i     => rst_i,
      -- Input
      dat_i  => WDataIn,
      vld_i   => InWValid,
      rdy_in_i   => InWReady,
      -- Output
      dat_o => WDataOut,
      vld_o  => OutWValid,
      rdy_out_i  => OutWReady
    );

  OutWLast <= WDataOut(0);
  OutWStrb <= WDataOut(data_width_g / 8 - 1 + 1 downto 1);
  OutWData <= WDataOut(data_width_g + data_width_g / 8 downto data_width_g + data_width_g / 8 - data_width_g + 1);

  -- write response channel
  bch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g  => RespWidth_c,
      stages_g => stages_g
    )
    port map(
      -- Control Signals
      clk_i     => clk_i,
      rst_i     => rst_i,
      -- Input
      dat_i  => OutBResp,
      vld_i   => OutBValid,
      rdy_in_i   => OutBReady,
      -- Output
      dat_o => InBResp,
      vld_o  => InBValid,
      rdy_out_i  => InBReady
    );

  -- read address channel
  ArDataIn <= InArAddr & InArLen & InArSize & InArBurst & InArLock & InArCache & InArProt;
  arch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g  => addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + 1 + CacheWidth_c + ProtWidth_c,
      stages_g => stages_g
    )
    port map(
      -- Control Signals
      clk_i     => clk_i,
      rst_i     => rst_i,
      -- Input
      dat_i  => ArDataIn,
      vld_i   => InArValid,
      rdy_in_i   => InArReady,
      -- Output
      dat_o => ArDataOut,
      vld_o  => OutArValid,
      rdy_out_i  => OutArReady
    );

  OutArProt  <= ArDataOut(ProtWidth_c - 1 downto 0);
  OutArCache <= ArDataOut(CacheWidth_c - 1 + ProtWidth_c downto ProtWidth_c);
  OutArLock  <= ArDataOut(CacheWidth_c + ProtWidth_c);
  OutArBurst <= ArDataOut(BurstWidth_c - 1 + CacheWidth_c + ProtWidth_c + 1 downto CacheWidth_c + ProtWidth_c + 1);
  OutArSize  <= ArDataOut(SizeWidth_c - 1 + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  OutArLen   <= ArDataOut(LenWidth_c - 1 + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1 downto SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c + 1);
  OutArAddr  <= ArDataOut(addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c downto addr_width_g + LenWidth_c + SizeWidth_c + BurstWidth_c + CacheWidth_c + ProtWidth_c - addr_width_g + 1);

  -- read data channel
  RDataIn <= OutRData & OutRResp & OutRLast;
  rch_multi_stage : entity work.psi_common_multi_pl_stage
    generic map(
      width_g  => data_width_g + RespWidth_c + 1,
      stages_g => stages_g
    )
    port map(
      -- Control Signals
      clk_i     => clk_i,
      rst_i     => rst_i,
      -- Input
      dat_i  => RDataIn,
      vld_i   => OutRValid,
      rdy_in_i   => OutRReady,
      -- Output
      dat_o => RDataOut,
      vld_o  => InRValid,
      rdy_out_i  => InRReady
    );

  InRLast <= RDataOut(0);
  InRResp <= RDataOut(RespWidth_c - 1 + 1 downto 1);
  InRData <= RDataOut(data_width_g + RespWidth_c downto data_width_g + RespWidth_c - data_width_g + 1);

end;

