------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic asynchronous FIFO. The clocks can be fully asynchronous
-- (unrelated). It  has optional level- and almost-full/empty ports.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_logic_pkg.all;
use work.psi_common_math_pkg.all;
--@formatter:off
entity psi_common_async_fifo is
  generic(width_g         : positive  := 16;                                         -- Width of the FIFO|
          depth_g         : positive  := 32;                                         -- Depth of the FIFO|
          afull_on_g      : boolean   := false;                                      -- **True** = Almost full output is provided, **False** = Almost full output is omitted|
          afull_lvl_g     : natural   := 28;                                         -- Almost full output is high if the level is \>= AlmFullLevel\_g|
          aempty_on_g     : boolean   := false;                                      -- True = Almost empty output is provided, False = Almost empty output is omitted|
          aempty_level_g  : natural   := 4;                                          -- Almost empty output is high if the level is \<= AlmFullLevel\_g|
          ram_style_g     : string    := "auto";                                     -- **"auto"** (default) Automatic choice of block- or distributed-RAM **"distributed"** Use distributed RAM (LUT-RAM), **"block"** Use block RAM|
          ram_behavior_g  : string    := "RBW";                                      -- **"RBW"** Read-before-write implementation, **"WBR"** Write-before-read implementation|
          rdy_rst_state_g : std_logic := '1';                                        -- State of *InRdy* signal during reset. Usually this does not play a role and the default setting ('1') that leads to the least logic on the InRdy path is fine. Setting the value to '0' may lead to less optimal performance in terms of FMAX.
          rst_pol_g       : std_logic := '1');                                       -- reset polarity, '1' high active & '0' low active|
  port(   -- Control Ports
          in_clk_i     : in  std_logic;                                               --    Write side clock
          in_rst_i     : in  std_logic;                                               --    Write side reset input (active high)
          out_clk_i    : in  std_logic;                                               --    Read side clock
          out_rst_i    : in  std_logic;                                               --    Read side reset  input (active high)
          -- data
          in_dat_i     : in  std_logic_vector(width_g - 1 downto 0);                  --    Write data
          in_vld_i     : in  std_logic;                                               --    AXI-S  handshaking signal
          in_rdy_o     : out std_logic;       -- not full                             --    AXI-S  handshaking signal
          out_dat_o    : out std_logic_vector(width_g - 1 downto 0);                  --    Read data
          out_vld_o    : out std_logic;       -- not empty                            --    AXI-S  handshaking signal
          out_rdy_o    : in  std_logic;                                               --    AXI-S handshaking signal
          -- status signal in
          in_full_o    : out std_logic;                                               --    FIFO full signal synchronous to *in_clk_i*
          in_empty_o   : out std_logic;                                               --    FIFO empty signal synchronous to *in_clk_i*
          in_afull_o   : out std_logic;                                               --    FIFO almost full signal synchronous to *in_clk_i*, Only exists if *AlmFullOn\_g*  = true
          in_aempty_o  : out std_logic;                                               --    FIFO almost empty signal synchronous to *in_clk_i*, Only exists if   *AlmEmptyOn\_g* = true|
          in_lvl_o     : out std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0);    --    FIFO level synchronous to  *in_clk_i*
          out_full_o   : out std_logic;                                               --    FIFO full  signal  synchronous to *out_clk_i*
          out_empty_o  : out std_logic;                                               --    FIFO empty signal   synchronous to *out_clk_i*        |
          out_afull_o  : out std_logic;                                               --    FIFO almost full signal synchronous to *out_clk_i* Only exists if *AlmFullOn\_g* = true
          out_aempty_o : out std_logic;                                               --    FIFO almost   empty signal  synchronous to *out_clk_i*  Only exists if  *AlmEmptyOn\_g* = true
          out_lvl_o    : out std_logic_vector(log2ceil(depth_g + 1) - 1 downto 0));   --    FIFO level synchronous to   *out_clk_i*
end entity;
--@formatter:on

architecture rtl of psi_common_async_fifo is

  type two_process_in_r is record
    WrAddr         : unsigned(log2ceil(depth_g) downto 0); -- One additional bit for full/empty detection
    WrAddrGray     : std_logic_vector(log2ceil(depth_g) downto 0);
    RdAddrGraySync : std_logic_vector(log2ceil(depth_g) downto 0);
    RdAddrGray     : std_logic_vector(log2ceil(depth_g) downto 0);
    RdAddr         : unsigned(log2ceil(depth_g) downto 0);
  end record;

  type two_process_out_r is record
    RdAddr         : unsigned(log2ceil(depth_g) downto 0); -- One additional bit for full/empty detection
    RdAddrGray     : std_logic_vector(log2ceil(depth_g) downto 0);
    WrAddrGraySync : std_logic_vector(log2ceil(depth_g) downto 0);
    WrAddrGray     : std_logic_vector(log2ceil(depth_g) downto 0);
    WrAddr         : unsigned(log2ceil(depth_g) downto 0);
    out_lvl_o      : unsigned(log2ceil(depth_g) downto 0);
  end record;

  signal ri, ri_next : two_process_in_r  := (WrAddr         => (others => '0'),
                                             WrAddrGray     => (others => '0'),
                                             RdAddrGraySync => (others => '0'),
                                             RdAddrGray     => (others => '0'),
                                             RdAddr         => (others => '0'));
  signal ro, ro_next : two_process_out_r := (RdAddr         => (others => '0'),
                                             RdAddrGray     => (others => '0'),
                                             WrAddrGraySync => (others => '0'),
                                             WrAddrGray     => (others => '0'),
                                             WrAddr         => (others => '0'),
                                             out_lvl_o      => (others => '0'));

  signal RstInInt  : std_logic;
  signal RstOutInt : std_logic;
  signal RamWr     : std_logic;
  signal RamRdAddr : std_logic_vector(log2ceil(depth_g) - 1 downto 0);
  signal RamWrAddr : std_logic_vector(log2ceil(depth_g) - 1 downto 0);

  attribute syn_srlstyle : string;
  attribute syn_srlstyle of ri : signal is "registers";
  attribute syn_srlstyle of ro : signal is "registers";

  attribute shreg_extract : string;
  attribute shreg_extract of ri : signal is "no";
  attribute shreg_extract of ro : signal is "no";

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of ri : signal is "TRUE";
  attribute ASYNC_REG of ro : signal is "TRUE";

begin

  assert log2(depth_g) = log2ceil(depth_g) report "###ERROR###: psi_common_async_fifo: only power of two depth_g is allowed" severity error;

  p_comb : process(in_vld_i, out_rdy_o, ri, ro, RstInInt)
    variable vi        : two_process_in_r;
    variable vo        : two_process_out_r;
    variable InLevel_v : unsigned(log2ceil(depth_g) downto 0);
  begin
    -- *** hold variables stable ***
    vi := ri;
    vo := ro;

    -- *** Write Side ***
    -- Defaults
    in_rdy_o    <= '0';
    in_full_o   <= '0';
    in_empty_o  <= '0';
    in_afull_o  <= '0';
    in_aempty_o <= '0';
    RamWr       <= '0';

    -- Level Detection
    InLevel_v := ri.WrAddr - ri.RdAddr;
    in_lvl_o  <= std_logic_vector(InLevel_v);

    -- Full
    if InLevel_v = depth_g then
      in_full_o <= '1';
    else
      in_rdy_o <= '1';
      -- Execute Write
      if in_vld_i = '1' then
        vi.WrAddr := ri.WrAddr + 1;
        RamWr     <= '1';
      end if;
    end if;
    -- Artificially keep InRdy low during reset if required
    if (rdy_rst_state_g = '0') and (RstInInt = '1') then
      in_rdy_o <= '0';
    end if;

    -- Status Detection
    if InLevel_v = 0 then
      in_empty_o <= '1';
    end if;
    if InLevel_v >= afull_lvl_g and afull_on_g then
      in_afull_o <= '1';
    end if;
    if InLevel_v <= aempty_level_g and aempty_on_g then
      in_aempty_o <= '1';
    end if;

    -- *** Read Side ***
    -- Defaults
    out_vld_o    <= '0';
    out_full_o   <= '0';
    out_empty_o  <= '0';
    out_afull_o  <= '0';
    out_aempty_o <= '0';

    -- Level Detection
    if ro.WrAddr = ro.RdAddr then
      vo.out_lvl_o := (others => '0');
    else
      vo.out_lvl_o := ro.WrAddr - ro.RdAddr;
      if (out_rdy_o = '1') and (ro.out_lvl_o /= 0) then
        vo.out_lvl_o := vo.out_lvl_o - 1;
      end if;
    end if;
    out_lvl_o <= std_logic_vector(ro.out_lvl_o);

    -- Empty
    if ro.out_lvl_o = 0 then
      out_empty_o <= '1';
    else
      out_vld_o <= '1';
      -- Execute read
      if out_rdy_o = '1' then
        vo.RdAddr := ro.RdAddr + 1;
      end if;
    end if;
    RamRdAddr <= std_logic_vector(vo.RdAddr(log2ceil(depth_g) - 1 downto 0));

    -- Status Detection
    if ro.out_lvl_o = depth_g then
      out_full_o <= '1';
    end if;
    if ro.out_lvl_o >= afull_lvl_g and afull_on_g then
      out_afull_o <= '1';
    end if;
    if ro.out_lvl_o <= aempty_level_g and aempty_on_g then
      out_aempty_o <= '1';
    end if;

    -- *** Address Clock domain crossings ***
    -- Bin->Gray is simple, can be done without additional FF
    vi.WrAddrGray := binary_to_gray(std_logic_vector(vi.WrAddr));
    vo.RdAddrGray := binary_to_gray(std_logic_vector(vo.RdAddr));

    -- Two stage synchronizer
    vi.RdAddrGraySync := ro.RdAddrGray;
    vi.RdAddrGray     := ri.RdAddrGraySync;
    vo.WrAddrGraySync := ri.WrAddrGray;
    vo.WrAddrGray     := ro.WrAddrGraySync;

    -- Gray->Bin involves some logic, needs additional FF
    vi.RdAddr := unsigned(gray_to_binary(ri.RdAddrGray));
    vo.WrAddr := unsigned(gray_to_binary(ro.WrAddrGray));

    -- *** Assign signal ***
    ri_next <= vi;
    ro_next <= vo;

  end process;

  p_seq_in : process(in_clk_i)
  begin
    if rising_edge(in_clk_i) then
      ri <= ri_next;
      if RstInInt = rst_pol_g then
        ri.WrAddr         <= (others => '0');
        ri.WrAddrGray     <= (others => '0');
        ri.RdAddrGraySync <= (others => '0');
        ri.RdAddrGray     <= (others => '0');
        ri.RdAddr         <= (others => '0');
      end if;
    end if;
  end process;

  p_seq_out : process(out_clk_i)
  begin
    if rising_edge(out_clk_i) then
      ro <= ro_next;
      if RstOutInt = rst_pol_g then
        ro.RdAddr         <= (others => '0');
        ro.RdAddrGray     <= (others => '0');
        ro.WrAddrGraySync <= (others => '0');
        ro.WrAddrGray     <= (others => '0');
        ro.WrAddr         <= (others => '0');
        ro.out_lvl_o      <= (others => '0');
      end if;
    end if;
  end process;

  RamWrAddr <= std_logic_vector(ri.WrAddr(log2ceil(depth_g) - 1 downto 0));
  i_ram : entity work.psi_common_sdp_ram
    generic map(
      depth_g        => depth_g,
      width_g        => width_g,
      ram_style_g    => ram_style_g,
      is_async_g     => true,
      ram_behavior_g => ram_behavior_g
    )
    port map(
      -- Port A
      wr_clk_i  => in_clk_i,
      wr_addr_i => RamWrAddr,
      wr_i      => RamWr,
      wr_dat_i  => in_dat_i,
      -- Port B
      rd_clk_i  => out_clk_i,
      rd_addr_i => RamRdAddr,
      rd_i      => '1',
      rd_dat_o  => out_dat_o
    );

  -- only used for reset crossing and oring
  i_rst_cc : entity work.psi_common_pulse_cc
    port map(
      -- Clock Domain A
      a_clk_i => in_clk_i,
      a_rst_i => in_rst_i,
      a_rst_o => RstInInt,
      a_dat_i => (others => '0'),
      -- Clock Domain B
      b_clk_i => out_clk_i,
      b_rst_i => out_rst_i,
      b_rst_o => RstOutInt,
      b_dat_o => open
    );
end architecture;
