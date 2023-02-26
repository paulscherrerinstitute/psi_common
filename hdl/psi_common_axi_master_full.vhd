------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a full AXI master. In contrast to psi_common_axi_master_full,
-- this entity can do unaligned transfers and it supports different width for the
-- AXI interface than for the data interface. The AXI interface can be wider than
-- the data interface but not vice versa.
-- The flexibility of doing unaligned transfers is paid by lower performance for
-- very small transfers. There is an overhead of some clock cycles per command.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ testcases=simple_tf,axi_hs,user_hs,all_shifts$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_master_full is
  generic(
    axi_addr_width_g             : natural range 12 to 64  := 32; -- $$ constant=32 $$
    axi_data_width_g             : natural range 8 to 1024 := 32; -- $$ export=true $$
    axi_max_beats_g              : natural range 1 to 256  := 256; -- $$ constant=16 $$
    axi_max_open_trasactions_g   : natural range 1 to 8    := 8; -- $$ constant=3 $$
    user_transaction_size_bits_g : natural                 := 32; -- $$ constant=10 $$
    data_fifo_depth_g            : natural                 := 1024; -- $$ constant=10 $$
    axi_fifo_depth_g             : natural                 := 512; -- $$ constant=32 $$
    data_width_g                 : natural                 := 32; -- $$ constant=16 $$
    impl_read_g                  : boolean                 := true; -- $$ export=true $$
    impl_write_g                 : boolean                 := true; -- $$ export=true $$
    ram_behavior_g               : string                  := "RBW" -- $$ constant="RBW" $$
  );
  port(
    -- Control Signals
    m_axi_aclk       : in  std_logic;   -- $$ type=clk; freq=100e6; proc=user_cmd,user_data,user_resp,axi $$
    m_axi_aresetn    : in  std_logic;   -- $$ type=rst; clk=M_Axi_Aclk; lowactive=true $$
    -- User Command Interface
    cmd_wr_addr_i    : in  std_logic_vector(axi_addr_width_g - 1 downto 0)             := (others => '0'); -- $$ proc=user_cmd $$
    cmd_wr_size_i    : in  std_logic_vector(user_transaction_size_bits_g - 1 downto 0) := (others => '0'); -- $$ proc=user_cmd $$
    cmd_wr_low_lat_i : in  std_logic                                                   := '0'; -- $$ proc=user_cmd $$
    cmd_wr_vld_i     : in  std_logic                                                   := '0'; -- $$ proc=user_cmd $$
    cmd_wr_rdy_o     : out std_logic;   -- $$ proc=user_cmd $$
    -- User Command Interface
    cmd_rd_addr_i    : in  std_logic_vector(axi_addr_width_g - 1 downto 0)             := (others => '0'); -- $$ proc=user_cmd $$
    cmd_rd_size_o    : in  std_logic_vector(user_transaction_size_bits_g - 1 downto 0) := (others => '0'); -- $$ proc=user_cmd $$
    cmd_rd_low_lat_i : in  std_logic                                                   := '0'; -- $$ proc=user_cmd $$
    cmd_rd_vld_i     : in  std_logic                                                   := '0'; -- $$ proc=user_cmd $$
    cmd_rd_rdy_o     : out std_logic;   -- $$ proc=user_cmd $$
    -- Write Data
    wr_dat_i         : in  std_logic_vector(data_width_g - 1 downto 0)                 := (others => '0'); -- $$ proc=user_data $$
    wr_vld_i         : in  std_logic                                                   := '0'; -- $$ proc=user_data $$
    wr_rdy_o         : out std_logic;   -- $$ proc=user_data $$
    -- Read Data
    rd_dat_o         : out std_logic_vector(data_width_g - 1 downto 0); -- $$ proc=user_data $$
    rd_vld_o         : out std_logic;   -- $$ proc=user_data $$
    rd_rdy_i         : in  std_logic                                                   := '0'; -- $$ proc=user_data $$
    -- Response
    wr_done_o        : out std_logic;   -- $$ proc=user_resp $$
    wr_error_o       : out std_logic;   -- $$ proc=user_resp $$
    rd_done_o        : out std_logic;   -- $$ proc=user_resp $$
    rd_error_o       : out std_logic;   -- $$ proc=user_resp $$
    -- AXI Address Write Channel
    m_axi_awaddr     : out std_logic_vector(axi_addr_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_awlen      : out std_logic_vector(7 downto 0); -- $$ proc=axi $$
    m_axi_awsize     : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_awburst    : out std_logic_vector(1 downto 0); -- $$ proc=axi $$
    m_axi_awlock     : out std_logic;   -- $$ proc=axi $$
    m_axi_awcache    : out std_logic_vector(3 downto 0); -- $$ proc=axi $$
    m_axi_awprot     : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_awvalid    : out std_logic;   -- $$ proc=axi $$
    m_axi_awready    : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    -- AXI Write Data Channel                                                           					-- $$ proc=axi $$
    m_axi_wdata      : out std_logic_vector(axi_data_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_wstrb      : out std_logic_vector(axi_data_width_g / 8 - 1 downto 0); -- $$ proc=axi $$
    m_axi_wlast      : out std_logic;   -- $$ proc=axi $$
    m_axi_wvalid     : out std_logic;   -- $$ proc=axi $$
    m_axi_wready     : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    -- AXI Write Response Channel
    m_axi_bresp      : in  std_logic_vector(1 downto 0)                                := (others => '0'); -- $$ proc=axi $$
    m_axi_bvalid     : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    m_axi_bready     : out std_logic;   -- $$ proc=axi $$
    -- AXI Read Address Channel
    m_axi_araddr     : out std_logic_vector(axi_addr_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_arlen      : out std_logic_vector(7 downto 0); -- $$ proc=axi $$
    m_axi_arsize     : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_arburst    : out std_logic_vector(1 downto 0); -- $$ proc=axi $$
    m_axi_arlock     : out std_logic;   -- $$ proc=axi $$
    m_axi_arcache    : out std_logic_vector(3 downto 0); -- $$ proc=axi $$
    m_axi_arprot     : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_arvalid    : out std_logic;   -- $$ proc=axi $$
    m_axi_arready    : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    -- AXI Read Data Channel
    m_axi_rdata      : in  std_logic_vector(axi_data_width_g - 1 downto 0)             := (others => '0'); -- $$ proc=axi $$
    m_axi_rresp      : in  std_logic_vector(1 downto 0)                                := (others => '0'); -- $$ proc=axi $$
    m_axi_rlast      : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    m_axi_rvalid     : in  std_logic                                                   := '0'; -- $$ proc=axi $$
    m_axi_rready     : out std_logic    -- $$ proc=axi $$
  );
end entity;

architecture rtl of psi_common_axi_master_full is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------
  constant AxiBytes_c   : natural := axi_data_width_g / 8;
  constant DataBytes_c  : natural := data_width_g / 8;

  ------------------------------------------------------------------------------
  -- Type
  ------------------------------------------------------------------------------
  type WriteCmdFsm_t is (Idle_s, Apply_s);
  type WriteWconvFsm_t is (Idle_s, Transfer_s);
  type WriteAlignFsm_t is (Idle_s, Transfer_s, Last_s);
  type ReadCmdFsm_t is (Idle_s, Apply_s, WaitDataFsm_s);
  type ReadDataFsm_t is (Idle_s, Transfer_s, Wait_s);

  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------
  function AlignedAddr_f(Addr : in unsigned(axi_addr_width_g-1 downto 0))
  return unsigned is
    variable Addr_v : unsigned(Addr'range) := (others => '0');
  begin
    Addr_v(Addr'left downto log2(AxiBytes_c)) := Addr(Addr'left downto log2(AxiBytes_c));
    return Addr_v;
  end function;

  ------------------------------------------------------------------------------
  -- Two Process Record
  ------------------------------------------------------------------------------
  type two_process_r is record

    -- *** Write Related Registers ***
    WrCmdFsm        : WriteCmdFsm_t;
    WrLastAddr      : unsigned(axi_addr_width_g - 1 downto 0);
    cmd_wr_rdy_o    : std_logic;
    AxiWrCmd_Addr   : std_logic_vector(axi_addr_width_g - 1 downto 0);
    AxiWrCmd_Size   : std_logic_vector(user_transaction_size_bits_g - 1 downto 0);
    WrAlignCmdSize  : std_logic_vector(user_transaction_size_bits_g - 1 downto 0);
    AxiWrCmd_LowLat : std_logic;
    AxiWrCmd_Vld    : std_logic;
    WrWconvFsm      : WriteWconvFsm_t;
    WrStartTf       : std_logic;
    WrWordsDone     : unsigned(user_transaction_size_bits_g - 1 downto 0);
    WrDataWordsCmd  : unsigned(user_transaction_size_bits_g - 1 downto 0);
    WrDataWordsWc   : unsigned(user_transaction_size_bits_g - 1 downto 0);
    WrAlignFsm      : WriteAlignFsm_t;
    WrAlignReg      : std_logic_vector(axi_data_width_g * 2 - 1 downto 0);
    WrAlignBe       : std_logic_vector(AxiBytes_c * 2 - 1 downto 0);
    WrShift         : unsigned(log2(AxiBytes_c) - 1 downto 0);
    WrAlignShift    : unsigned(log2(AxiBytes_c) - 1 downto 0);
    WrAlignVld      : std_logic;
    AxiWordCnt      : unsigned(user_transaction_size_bits_g - 1 downto 0);
    WrLastBe        : std_logic_vector(AxiBytes_c - 1 downto 0);
    WrAlignLastBe   : std_logic_vector(AxiBytes_c - 1 downto 0);
    WrAlignLast     : std_logic;

    -- *** Read Related Registers ***
    RdCmdFsm        : ReadCmdFsm_t;
    RdLastAddr      : unsigned(axi_addr_width_g - 1 downto 0);
    RdFirstAddrOffs : unsigned(log2(AxiBytes_c) - 1 downto 0);
    cmd_rd_rdy_o    : std_logic;
    AxiRdCmd_Addr   : std_logic_vector(axi_addr_width_g - 1 downto 0);
    AxiRdCmd_LowLat : std_logic;
    AxiRdCmd_Vld    : std_logic;
    AxiRdCmd_Size   : std_logic_vector(user_transaction_size_bits_g - 1 downto 0);
    RdFirstBe       : std_logic_vector(AxiBytes_c - 1 downto 0);
    RdLastBe        : std_logic_vector(AxiBytes_c - 1 downto 0);
    RdDataFsm       : ReadDataFsm_t;
    RdStartTf       : std_logic;
    RdDataEna       : std_logic;
    RdDatFirstBe    : std_logic_vector(AxiBytes_c - 1 downto 0);
    RdDatLastBe     : std_logic_vector(AxiBytes_c - 1 downto 0);
    RdDataWords     : unsigned(user_transaction_size_bits_g - 1 downto 0);
    RdCurrentWord   : unsigned(user_transaction_size_bits_g - 1 downto 0);
    RdShift         : unsigned(log2(AxiBytes_c) - 1 downto 0);
    RdLowIdx        : unsigned(log2(AxiBytes_c) downto 0);
    RdAlignShift    : unsigned(log2(AxiBytes_c) - 1 downto 0);
    RdAlignLowIdx   : unsigned(log2(AxiBytes_c) downto 0);
    RdAlignByteVld  : std_logic_vector(AxiBytes_c * 2 - 1 downto 0);
    RdAlignReg      : std_logic_vector(axi_data_width_g * 2 - 1 downto 0);
    RdAlignLast     : std_logic;
  end record;
  signal r, r_next : two_process_r;

  ------------------------------------------------------------------------------
  -- Instantiation Signals
  ------------------------------------------------------------------------------
  signal WrFifo_Data   : std_logic_vector(wr_dat_i'range);
  signal WrFifo_Vld    : std_logic;
  signal AxiWrCmd_Rdy  : std_logic;
  signal AxiWrDat_Rdy  : std_logic;
  signal AxiWrDat_Data : std_logic_vector(axi_data_width_g - 1 downto 0);
  signal WrFifo_Rdy    : std_logic;
  signal AxiWrDat_Be   : std_logic_vector(AxiBytes_c - 1 downto 0);
  signal WrWconvEna    : std_logic;
  signal WrWconv_Vld   : std_logic;
  signal WrWconv_Rdy   : std_logic;
  signal WrWconv_Last  : std_logic;
  signal WrData_Vld    : std_logic;
  signal WrData_Data   : std_logic_vector(axi_data_width_g - 1 downto 0);
  signal WrData_Last   : std_logic;
  signal WrData_We     : std_logic_vector(AxiBytes_c / DataBytes_c - 1 downto 0);
  signal WrData_Rdy    : std_logic;
  signal WrDataEna     : std_logic;
  signal AxiRdCmd_Rdy  : std_logic;
  signal AxiRdDat_Rdy  : std_logic;
  signal AxiRdDat_Vld  : std_logic;
  signal AxiRdDat_Data : std_logic_vector(axi_data_width_g - 1 downto 0);
  signal RdFifo_Rdy    : std_logic;
  signal RdFifo_Data   : std_logic_vector(data_width_g - 1 downto 0);
  signal RdFifo_Vld    : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Assertions
  ------------------------------------------------------------------------------
  assert axi_data_width_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full axi_data_width_g must be a multiple of 8" severity failure;
  assert data_width_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full data_width_g must be a multiple of 8" severity failure;
  assert axi_data_width_g mod data_width_g = 0 report "###ERROR###: psi_common_axi_master_full axi_data_width_g must be a multiple of data_width_g" severity failure;

  ------------------------------------------------------------------------------
  -- Combinatorial Process
  ------------------------------------------------------------------------------
  p_comb : process(r, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_vld_i, cmd_wr_low_lat_i, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_vld_i, cmd_rd_low_lat_i, AxiWrCmd_Rdy, AxiWrDat_Rdy, AxiRdCmd_Rdy, AxiRdDat_Vld, AxiRdDat_Data, WrWconv_Rdy, WrFifo_Vld, WrData_Vld, WrData_Data, WrData_Last, WrData_We, RdFifo_Rdy)
    variable v              : two_process_r;
    variable WriteBe_v      : std_logic_vector(AxiBytes_c - 1 downto 0);
    variable RdAlignReady_v : std_logic;
    variable RdLowIdxInt_v  : integer range 0 to AxiBytes_c;
    variable RdDatBe_v      : std_logic_vector(AxiBytes_c - 1 downto 0);
    variable RdDataLast_v   : std_logic;
  begin
    -- *** Keep two process variables stable ***
    v := r;

    --------------------------------------------------------------------------
    -- Write Related Code
    --------------------------------------------------------------------------
    if impl_write_g then

      -- *** Command FSM ***
      v.WrStartTf    := '0';
      v.AxiWrCmd_Vld := '0';
      case r.WrCmdFsm is

        when Idle_s =>
          v.cmd_wr_rdy_o    := '1';
          v.WrLastAddr      := unsigned(cmd_wr_addr_i) + unsigned(cmd_wr_size_i) - 1;
          if unsigned(cmd_wr_size_i(log2(DataBytes_c) - 1 downto 0)) = 0 then
            v.WrDataWordsCmd := resize(unsigned(cmd_wr_size_i(cmd_wr_size_i'high downto log2(DataBytes_c))), user_transaction_size_bits_g);
          else
            v.WrDataWordsCmd := resize(unsigned(cmd_wr_size_i(cmd_wr_size_i'high downto log2(DataBytes_c))) + 1, user_transaction_size_bits_g);
          end if;
          v.AxiWrCmd_Addr   := std_logic_vector(AlignedAddr_f(unsigned(cmd_wr_addr_i)));
          v.WrShift         := unsigned(cmd_wr_addr_i(v.WrShift'range));
          v.AxiWrCmd_LowLat := cmd_wr_low_lat_i;
          if cmd_wr_vld_i = '1' then
            v.cmd_wr_rdy_o := '0';
            v.WrCmdFsm     := Apply_s;
          end if;

        when Apply_s =>
          if (AxiWrCmd_Rdy = '1') and (r.WrWconvFsm = Idle_s) and (r.WrAlignFsm = Idle_s) then
            v.AxiWrCmd_Vld  := '1';
            v.WrStartTf     := '1';
            v.WrCmdFsm      := Idle_s;
            v.cmd_wr_rdy_o  := '1';
            v.AxiWrCmd_Size := std_logic_vector(resize(shift_right(AlignedAddr_f(r.WrLastAddr) - unsigned(r.AxiWrCmd_Addr), log2(AxiBytes_c)) + 1, user_transaction_size_bits_g));
            -- Calculate byte enables for last word
            for byte in 0 to AxiBytes_c - 1 loop
              if r.WrLastAddr(log2(AxiBytes_c) - 1 downto 0) >= byte then
                v.WrLastBe(byte) := '1';
              else
                v.WrLastBe(byte) := '0';
              end if;
            end loop;
          end if;

        when others => null;

      end case;

      -- *** With Conversion FSM ***
      WrWconvEna   <= '0';
      WrWconv_Last <= '0';
      case r.WrWconvFsm is

        -- Latch values that change for the next command that may be interpreted while the current one is running
        when Idle_s =>
          v.WrWordsDone   := to_unsigned(1, v.WrWordsDone'length);
          v.WrDataWordsWc := r.WrDataWordsCmd;
          if r.WrStartTf = '1' then
            v.WrWconvFsm := Transfer_s;
          end if;

        -- Execute transfer
        when Transfer_s =>
          WrWconvEna <= '1';
          if r.WrWordsDone = r.WrDataWordsWc then
            WrWconv_Last <= '1';
          end if;
          if (WrWconv_Rdy = '1') and (WrFifo_Vld = '1') then
            v.WrWordsDone := r.WrWordsDone + 1;
            if r.WrWordsDone = r.WrDataWordsWc then
              v.WrWconvFsm := Idle_s;
            end if;
          end if;

        when others => null;
      end case;

      -- *** Alignment FSM ***
      -- Initial values
      WrDataEna <= '0';
      --v.WrAlignVld := '0';
      -- Word- to Byte-Enable conversion
      for i in 0 to AxiBytes_c - 1 loop
        WriteBe_v(i) := WrData_We(i / data_width_g);
      end loop;
      -- FSM
      case r.WrAlignFsm is

        -- Latch values that change for the next command that may be interpreted while the current one is running
        when Idle_s =>
          v.WrAlignReg     := (others => '0');
          v.WrAlignBe      := (others => '0');
          v.AxiWordCnt     := to_unsigned(1, v.AxiWordCnt'length);
          v.WrAlignLast    := '0';
          v.WrAlignShift   := r.WrShift;
          v.WrAlignCmdSize := r.AxiWrCmd_Size;
          v.WrAlignLastBe  := r.WrLastBe;
          v.WrAlignVld     := '0';
          if r.WrStartTf = '1' then
            v.WrAlignFsm := Transfer_s;
          end if;

        -- Move data from the FIFO to AXI
        when Transfer_s =>
          WrDataEna <= '1';
          if (AxiWrDat_Rdy = '1') and ((WrData_Vld = '1') or (r.WrAlignLast = '1')) then
            -- Don't add new byte enables on last data flushing
            if r.WrAlignLast = '1' then
              WriteBe_v := (others => '0');
            end if;
            -- Shift
            v.WrAlignReg(axi_data_width_g - 1 downto 0)                                                           := r.WrAlignReg(r.WrAlignReg'left downto axi_data_width_g);
            v.WrAlignBe(AxiBytes_c - 1 downto 0)                                                                  := r.WrAlignBe(r.WrAlignBe'left downto AxiBytes_c);
            -- New Data
            v.WrAlignReg((to_integer(r.WrAlignShift) + AxiBytes_c) * 8 - 1 downto to_integer(r.WrAlignShift) * 8) := WrData_Data;
            v.WrAlignBe(to_integer(r.WrAlignShift) + AxiBytes_c - 1 downto to_integer(r.WrAlignShift))            := WriteBe_v;
            -- Flow control
            v.WrAlignVld                                                                                          := '1';
            if r.AxiWordCnt = unsigned(r.WrAlignCmdSize) then
              v.WrAlignFsm                         := Last_s;
              v.WrAlignBe(AxiBytes_c - 1 downto 0) := v.WrAlignBe(AxiBytes_c - 1 downto 0) and r.WrAlignLastBe;
            end if;
            v.AxiWordCnt                                                                                          := r.AxiWordCnt + 1;
            -- Force last data out
            v.WrAlignLast                                                                                         := WrData_Last;
          elsif AxiWrDat_Rdy = '1' then
            v.WrAlignVld := '0';
          end if;

        -- Wait for the last beat te be accepted without reading more data from the FIFO
        when Last_s =>
          v.WrAlignVld := '1';
          if AxiWrDat_Rdy = '1' then
            v.WrAlignVld := '0';
            v.WrAlignFsm := Idle_s;
          end if;

        when others => null;
      end case;
    end if;

    --------------------------------------------------------------------------
    -- Read Related Code
    --------------------------------------------------------------------------
    if impl_read_g then

      -- *** Variables ***
      RdLowIdxInt_v  := to_integer(r.RdAlignLowIdx);
      RdAlignReady_v := r.RdDataEna;
      -- Vivado workaround
      for i in 0 to AxiBytes_c loop
        if i = RdLowIdxInt_v then
          -- no new data fits into shifter, even if output is ready. This only happens for user width < axi width
          if (DataBytes_c < AxiBytes_c) and (unsigned(r.RdAlignByteVld(r.RdAlignByteVld'high downto i + DataBytes_c)) /= 0) then
            RdAlignReady_v := '0';
          -- if output is ready, new data can be accepted (back-to-back)
          elsif unsigned(r.RdAlignByteVld(r.RdAlignByteVld'high downto i)) /= 0 and RdFifo_Rdy = '0' then
            RdAlignReady_v := '0';
          end if;
        end if;
      end loop;

      -- *** Command FSM ***
      v.RdStartTf    := '0';
      v.AxiRdCmd_Vld := '0';
      case r.RdCmdFsm is

        when Idle_s =>

          v.cmd_rd_rdy_o    := '1';
          v.RdLastAddr      := unsigned(cmd_rd_addr_i) + unsigned(cmd_rd_size_o) - 1;
          v.RdFirstAddrOffs := unsigned(cmd_rd_addr_i(v.RdFirstAddrOffs'range));
          v.AxiRdCmd_Addr   := std_logic_vector(AlignedAddr_f(unsigned(cmd_rd_addr_i)));
          v.AxiRdCmd_LowLat := cmd_rd_low_lat_i;
          v.RdShift         := unsigned(cmd_rd_addr_i(v.RdShift'range));
          v.RdLowIdx        := to_unsigned(AxiBytes_c, v.RdLowIdx'length) - unsigned(cmd_rd_addr_i(v.RdShift'range));
          if cmd_rd_vld_i = '1' then
            v.cmd_rd_rdy_o := '0';
            v.RdCmdFsm     := Apply_s;
          end if;

        when Apply_s =>
          -- AXI command can be sent early
          if (AxiRdCmd_Rdy = '1') then
            v.AxiRdCmd_Vld  := '1';
            v.RdCmdFsm      := WaitDataFsm_s;
            v.RdStartTf     := '1';
            v.AxiRdCmd_Size := std_logic_vector(resize(shift_right(AlignedAddr_f(r.RdLastAddr) - unsigned(r.AxiRdCmd_Addr), log2(AxiBytes_c)) + 1, user_transaction_size_bits_g));
            -- Calculate byte enables for last byte
            for byte in 0 to AxiBytes_c - 1 loop
              if r.RdLastAddr(log2(AxiBytes_c) - 1 downto 0) >= byte then
                v.RdLastBe(byte) := '1';
              else
                v.RdLastBe(byte) := '0';
              end if;
            end loop;
            -- Calculate byte enables for first byte
            for byte in 0 to AxiBytes_c - 1 loop
              if r.RdFirstAddrOffs <= byte then
                v.RdFirstBe(byte) := '1';
              else
                v.RdFirstBe(byte) := '0';
              end if;
            end loop;
          end if;

        -- Start data FSM before sending next command to avoid owerwriting data before it was latched
        when WaitDataFsm_s =>
          v.RdStartTf := '1';
          if r.RdDataFsm = Idle_s then
            v.RdCmdFsm     := Idle_s;
            v.cmd_rd_rdy_o := '1';
            v.RdStartTf    := '0';
          end if;

        when others => null;
      end case;

      -- *** Data FSM ***
      v.RdDataEna  := '0';
      RdDatBe_v    := (others => '1');
      RdDataLast_v := '0';
      case r.RdDataFsm is

        when Idle_s =>
          v.RdDatFirstBe  := r.RdFirstBe;
          v.RdDatLastBe   := r.RdLastBe;
          v.RdDataWords   := unsigned(r.AxiRdCmd_Size);
          v.RdCurrentWord := to_unsigned(1, v.RdCurrentWord'length);
          v.RdAlignShift  := r.RdShift;
          v.RdAlignLowIdx := r.RdLowIdx;
          if r.RdStartTf = '1' then
            v.RdDataFsm := Transfer_s;
            v.RdDataEna := '1';
          end if;

        when Transfer_s =>
          v.RdDataEna := '1';
          if r.RdCurrentWord = 1 then
            RdDatBe_v := RdDatBe_v and r.RdDatFirstBe;
          end if;
          if r.RdCurrentWord = r.RdDataWords then
            RdDatBe_v    := RdDatBe_v and r.RdDatLastBe;
            RdDataLast_v := '1';
          end if;
          if (RdAlignReady_v = '1') and (AxiRdDat_Vld = '1') and (r.RdDataEna = '1') then
            v.RdCurrentWord := r.RdCurrentWord + 1;
            if r.RdCurrentWord = r.RdDataWords then
              v.RdDataEna := '0';
              v.RdDataFsm := Wait_s;
            end if;
          end if;

        -- Wait until reception of all data is done
        when Wait_s =>
          if unsigned(r.RdAlignByteVld) = 0 then
            v.RdDataFsm := Idle_s;
          end if;

        when others => null;
      end case;

      -- *** Data Alignment ***
      AxiRdDat_Rdy <= RdAlignReady_v;
      RdFifo_Vld   <= '0';
      -- shift
      if (RdFifo_Rdy = '1') and (RdAlignReady_v = '0' or AxiRdDat_Vld = '1' or r.RdAlignLast = '1') then
        -- Shift is only done if data can be consumed (RdFifo_Rdy) and either no new data is required for the next shift (RdAlignReady_v = '0'),
        -- .. the data is available (AxiRdDat_Vld = '1') or we are at the end of a transfer (r.RdAlignLast = '1')
        v.RdAlignReg     := zeros_vector(data_width_g) & r.RdAlignReg(r.RdAlignReg'left downto data_width_g);
        v.RdAlignByteVld := zeros_vector(DataBytes_c) & r.RdAlignByteVld(r.RdAlignByteVld'left downto DataBytes_c);
        if r.RdAlignLast = '1' then
          RdFifo_Vld <= reduce_or(r.RdAlignByteVld(DataBytes_c - 1 downto 0));
        else
          RdFifo_Vld <= reduce_and(r.RdAlignByteVld(DataBytes_c - 1 downto 0));
        end if;
      end if;
      -- get new data
      if RdAlignReady_v = '1' and AxiRdDat_Vld = '1' then
        v.RdAlignReg(RdLowIdxInt_v * 8 + axi_data_width_g - 1 downto RdLowIdxInt_v * 8) := AxiRdDat_Data;
        v.RdAlignByteVld(RdLowIdxInt_v + AxiBytes_c - 1 downto RdLowIdxInt_v)           := RdDatBe_v;
        v.RdAlignLast                                                                   := RdDataLast_v;
      end if;

      -- Send data to FIFO
      RdFifo_Data <= r.RdAlignReg(data_width_g - 1 downto 0);

    end if;

    -- *** Update Signal ***
    r_next <= v;
  end process;

  ------------------------------------------------------------------------------
  -- Registered Process
  ------------------------------------------------------------------------------
  p_reg : process(m_axi_aclk)
  begin
    if rising_edge(m_axi_aclk) then
      r <= r_next;
      if m_axi_aresetn = '0' then
        -- *** Write Related Registers ***
        if impl_write_g then
          r.WrCmdFsm     <= Idle_s;
          r.cmd_wr_rdy_o <= '0';
          r.AxiWrCmd_Vld <= '0';
          r.WrWconvFsm   <= Idle_s;
          r.WrStartTf    <= '0';
          r.WrAlignFsm   <= Idle_s;
          r.WrAlignVld   <= '0';
        end if;
        -- *** Read Related Registers ***
        if impl_read_g then
          r.RdCmdFsm       <= Idle_s;
          r.cmd_rd_rdy_o   <= '0';
          r.AxiRdCmd_Vld   <= '0';
          r.RdDataFsm      <= Idle_s;
          r.RdStartTf      <= '0';
          r.RdDataEna      <= '0';
          r.RdAlignByteVld <= (others => '0');
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------
  cmd_wr_rdy_o <= r.cmd_wr_rdy_o;
  cmd_rd_rdy_o <= r.cmd_rd_rdy_o;

  -- AXI Master Interface
  AxiWrDat_Data <= r.WrAlignReg(AxiWrDat_Data'range);
  AxiWrDat_Be   <= r.WrAlignBe(AxiWrDat_Be'range);
  i_axi : entity work.psi_common_axi_master_simple
    generic map(
      axi_addr_width_g             => axi_addr_width_g,
      axi_data_width_g             => axi_data_width_g,
      axi_max_beats_g              => axi_max_beats_g,
      axi_max_open_transactions_g  => axi_max_open_trasactions_g,
      user_transaction_size_bits_g => user_transaction_size_bits_g,
      data_fifo_depth_g            => axi_fifo_depth_g,
      impl_read_g                  => impl_read_g,
      impl_write_g                 => impl_write_g,
      ram_behavior_g               => ram_behavior_g)
    port map(
      -- Control Signals
      m_axi_aclk       => m_axi_aclk,
      m_axi_aresetn    => m_axi_aresetn,
      -- User Command Interface
      cmd_wr_addr_i    => r.AxiWrCmd_Addr,
      cmd_wr_size_i    => r.AxiWrCmd_Size,
      cmd_wr_low_lat_i => r.AxiWrCmd_LowLat,
      cmd_wr_vld_i     => r.AxiWrCmd_Vld,
      cmd_wr_rdy_o     => AxiWrCmd_Rdy,
      -- User Command Interface
      cmd_rd_addr_i    => r.AxiRdCmd_Addr,
      cmd_rd_size_o    => r.AxiRdCmd_Size,
      cmd_rd_low_lat_i => r.AxiRdCmd_LowLat,
      cmd_rd_vld_i     => r.AxiRdCmd_Vld,
      cmd_rd_rdy_o     => AxiRdCmd_Rdy,
      -- Write Data
      wr_dat_i         => AxiWrDat_Data,
      wr_data_be_i     => AxiWrDat_Be,
      wr_vld_i         => r.WrAlignVld,
      wr_rdy_o         => AxiWrDat_Rdy,
      -- Read Data
      rd_dat_o         => AxiRdDat_Data,
      rd_vld_o         => AxiRdDat_Vld,
      rd_rdy_i         => AxiRdDat_Rdy,
      -- Response
      wr_done_o        => wr_done_o,
      wr_error_o       => wr_error_o,
      rd_done_o        => rd_done_o,
      rd_error_o       => rd_error_o,
      -- AXI Address Write Channel
      m_axi_awaddr     => m_axi_awaddr,
      m_axi_awlen      => m_axi_awlen,
      m_axi_awsize     => m_axi_awsize,
      m_axi_awburst    => m_axi_awburst,
      m_axi_awlock     => m_axi_awlock,
      m_axi_awcache    => m_axi_awcache,
      m_axi_awprot     => m_axi_awprot,
      m_axi_awvalid    => m_axi_awvalid,
      m_axi_awready    => m_axi_awready,
      -- AXI Write Data Channel
      m_axi_wdata      => m_axi_wdata,
      m_axi_wstrb      => m_axi_wstrb,
      m_axi_wlast      => m_axi_wlast,
      m_axi_wvalid     => m_axi_wvalid,
      m_axi_wready     => m_axi_wready,
      -- AXI Write Response Channel
      m_axi_bresp      => m_axi_bresp,
      m_axi_bvalid     => m_axi_bvalid,
      m_axi_bready     => m_axi_bready,
      -- AXI Read Address Channel
      m_axi_araddr     => m_axi_araddr,
      m_axi_arlen      => m_axi_arlen,
      m_axi_arsize     => m_axi_arsize,
      m_axi_arburst    => m_axi_arburst,
      m_axi_arlock     => m_axi_arlock,
      m_axi_arcache    => m_axi_arcache,
      m_axi_arprot     => m_axi_arprot,
      m_axi_arvalid    => m_axi_arvalid,
      m_axi_arready    => m_axi_arready,
      -- AXI Read Data Channel
      m_axi_rdata      => m_axi_rdata,
      m_axi_rresp      => m_axi_rresp,
      m_axi_rlast      => m_axi_rlast,
      m_axi_rvalid     => m_axi_rvalid,
      m_axi_rready     => m_axi_rready);

  -- *** Write Releated Code ***
  g_write : if impl_write_g generate

    -- Write Data FIFO
    WrFifo_Rdy <= WrWconv_Rdy and WrWconvEna;
    i_fifo_wr_data : entity work.psi_common_sync_fifo
      generic map(
        width_g        => data_width_g,
        depth_g        => data_fifo_depth_g,
        alm_full_on_g  => false,
        alm_empty_on_g => false,
        ram_style_g    => "auto",
        ram_behavior_g => ram_behavior_g,
        rst_pol_g      => '0'
      )
      port map(
        clk_i => m_axi_aclk,
        rst_i => m_axi_aresetn,
        dat_i => wr_dat_i,
        vld_i => wr_vld_i,
        rdy_o => wr_rdy_o,
        dat_o => WrFifo_Data,
        vld_o => WrFifo_Vld,
        rdy_i => WrFifo_Rdy
      );

    -- Write Data With Conversion
    WrWconv_Vld <= WrWconvEna and WrFifo_Vld;
    WrData_Rdy  <= AxiWrDat_Rdy and WrDataEna;
    i_wc_wr : entity work.psi_common_wconv_n2xn
      generic map( width_in_g  => data_width_g,
                   width_out_g => axi_data_width_g,
                   rst_pol_g   => '0')
      port map(    clk_i     => m_axi_aclk,
                   rst_i     => m_axi_aresetn,
                   vld_i     => WrWconv_Vld,
                   rdy_in_i  => WrWconv_Rdy,
                   dat_i     => WrFifo_Data,
                   last_i    => WrWconv_Last,
                   vld_o     => WrData_Vld,
                   rdy_out_i => WrData_Rdy,
                   dat_o     => WrData_Data,
                   last_o    => WrData_Last,
                   we_o      => WrData_We);
  end generate;
  g_nwrite : if not impl_write_g generate
    wr_rdy_o <= '0';
  end generate;

  -- *** Read Releated Code ***
  g_read : if impl_read_g generate
    -- Read Data FIFO
    i_fifo_rd_data : entity work.psi_common_sync_fifo
      generic map(width_g        => data_width_g,
                  depth_g        => data_fifo_depth_g,
                  alm_full_on_g  => false,
                  alm_empty_on_g => false,
                  ram_style_g    => "auto",
                  ram_behavior_g => ram_behavior_g,
                  rst_pol_g      => '0'      )
      port map(     clk_i => m_axi_aclk,
                    rst_i => m_axi_aresetn,
                    dat_i => RdFifo_Data,
                    vld_i => RdFifo_Vld,
                    rdy_o => RdFifo_Rdy,
                    dat_o => rd_dat_o,
                    vld_o => rd_vld_o,
                    rdy_i => rd_rdy_i);
  end generate;
  g_nread : if not impl_read_g generate
    rd_vld_o <= '0';
    rd_dat_o <= (others => '0');
  end generate;

end architecture;