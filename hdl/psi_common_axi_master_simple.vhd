------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple AXI master. Simple means: It does not 
-- support any unaligned reads/writes and it does not do any width conversions.
-- It just executes the transfers requested and splits them into multiple AXI
-- transactions in order to not burst over 4k boundaries and respect the maximum
-- transaction size.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ testcases=simple_tf,max_transact,axi_hs,split,internals,highlat$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_master_simple is
  generic(
    axi_addr_width_g            : natural range 12 to 64  := 32; -- $$ constant=32 $$
    axi_data_width_g            : natural range 8 to 1024 := 32; -- $$ constant=16 $$
    axi_max_beats_g             : natural range 1 to 256  := 256; -- $$ constant=16 $$
    axi_max_open_transactions_g   : natural range 1 to 8    := 8; -- $$ constant=3 $$
    user_transaction_size_bits_g : natural                 := 32; -- $$ constant=10 $$
    data_fifo_depth_g           : natural                 := 1024; -- $$ constant=10 $$
    impl_read_g                : boolean                 := true; -- $$ export=true $$
    impl_write_g               : boolean                 := true; -- $$ export=true $$
    ram_behavior_g             : string                  := "RBW" -- $$ constant="RBW" $$
  );
  port(
    -- Control Signals
    m_axi_aclk    : in  std_logic;      -- $$ type=clk; freq=100e6 $$
    m_axi_aresetn : in  std_logic;      -- $$ type=rst; clk=M_Axi_Aclk; lowactive=true $$

    -- User Command Interface
    cmd_wr_addr_i    : in  std_logic_vector(axi_addr_width_g - 1 downto 0)            := (others => '0'); -- $$ proc=user_cmd $$
    cmd_wr_size_i    : in  std_logic_vector(user_transaction_size_bits_g - 1 downto 0) := (others => '0'); -- $$ proc=user_cmd $$
    cmd_wr_low_lat_i  : in  std_logic                                                := '0'; -- $$ proc=user_cmd $$
    cmd_wr_vld_i     : in  std_logic                                                := '0'; -- $$ proc=user_cmd $$
    cmd_wr_rdy_o     : out std_logic;      -- $$ proc=user_cmd $$

    -- User Command Interface
    cmd_rd_addr_i    : in  std_logic_vector(axi_addr_width_g - 1 downto 0)            := (others => '0'); -- $$ proc=user_cmd $$
    cmd_rd_size_o    : in  std_logic_vector(user_transaction_size_bits_g - 1 downto 0) := (others => '0'); -- $$ proc=user_cmd $$
    cmd_rd_low_lat_i  : in  std_logic                                                := '0'; -- $$ proc=user_cmd $$
    cmd_rd_vld_i     : in  std_logic                                                := '0'; -- $$ proc=user_cmd $$
    cmd_rd_rdy_o     : out std_logic;      -- $$ proc=user_cmd $$		

    -- Write Data
    wr_dat_i    : in  std_logic_vector(axi_data_width_g - 1 downto 0)            := (others => '0'); -- $$ proc=user_data $$
    wr_data_be      : in  std_logic_vector(axi_data_width_g / 8 - 1 downto 0)        := (others => '0'); -- $$ proc=user_data $$
    wr_vld_i     : in  std_logic                                                := '0'; -- $$ proc=user_data $$
    wr_rdy_o     : out std_logic;      -- $$ proc=user_data $$		

    -- Read Data
    rd_dat_o    : out std_logic_vector(axi_data_width_g - 1 downto 0); -- $$ proc=user_data $$
    rd_vld_o     : out std_logic;      -- $$ proc=user_data $$
    rd_rdy_i     : in  std_logic                                                := '0'; -- $$ proc=user_data $$			

    -- Response
    wr_done_o       : out std_logic;      -- $$ proc=user_resp $$
    wr_error_o      : out std_logic;      -- $$ proc=user_resp $$
    rd_done_o       : out std_logic;      -- $$ proc=user_resp $$
    rd_error_o      : out std_logic;      -- $$ proc=user_resp $$

    -- AXI Address Write Channel
    m_axi_awaddr  : out std_logic_vector(axi_addr_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_awlen   : out std_logic_vector(7 downto 0); -- $$ proc=axi $$
    m_axi_awsize  : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_awburst : out std_logic_vector(1 downto 0); -- $$ proc=axi $$
    m_axi_awlock  : out std_logic;      -- $$ proc=axi $$
    m_axi_awcache : out std_logic_vector(3 downto 0); -- $$ proc=axi $$
    m_axi_awprot  : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_awvalid : out std_logic;      -- $$ proc=axi $$
    m_axi_awready : in  std_logic                                                := '0'; -- $$ proc=axi $$

    -- AXI Write Data Channel                                                           					-- $$ proc=axi $$
    m_axi_wdata   : out std_logic_vector(axi_data_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_wstrb   : out std_logic_vector(axi_data_width_g / 8 - 1 downto 0); -- $$ proc=axi $$
    m_axi_wlast   : out std_logic;      -- $$ proc=axi $$
    m_axi_wvalid  : out std_logic;      -- $$ proc=axi $$
    m_axi_wready  : in  std_logic                                                := '0'; -- $$ proc=axi $$

    -- AXI Write Response Channel                                                      
    m_axi_bresp   : in  std_logic_vector(1 downto 0)                             := (others => '0'); -- $$ proc=axi $$
    m_axi_bvalid  : in  std_logic                                                := '0'; -- $$ proc=axi $$
    m_axi_bready  : out std_logic;      -- $$ proc=axi $$

    -- AXI Read Address Channel                                               
    m_axi_araddr  : out std_logic_vector(axi_addr_width_g - 1 downto 0); -- $$ proc=axi $$
    m_axi_arlen   : out std_logic_vector(7 downto 0); -- $$ proc=axi $$
    m_axi_arsize  : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_arburst : out std_logic_vector(1 downto 0); -- $$ proc=axi $$
    m_axi_arlock  : out std_logic;      -- $$ proc=axi $$
    m_axi_arcache : out std_logic_vector(3 downto 0); -- $$ proc=axi $$
    m_axi_arprot  : out std_logic_vector(2 downto 0); -- $$ proc=axi $$
    m_axi_arvalid : out std_logic;      -- $$ proc=axi $$
    m_axi_arready : in  std_logic                                                := '0'; -- $$ proc=axi $$

    -- AXI Read Data Channel                                                      
    m_axi_rdata   : in  std_logic_vector(axi_data_width_g - 1 downto 0)            := (others => '0'); -- $$ proc=axi $$
    m_axi_rresp   : in  std_logic_vector(1 downto 0)                             := (others => '0'); -- $$ proc=axi $$
    m_axi_rlast   : in  std_logic                                                := '0'; -- $$ proc=axi $$
    m_axi_rvalid  : in  std_logic                                                := '0'; -- $$ proc=axi $$
    m_axi_rready  : out std_logic       -- $$ proc=axi $$
  );
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_axi_master_simple is

  ------------------------------------------------------------------------------
  -- Constants
  ------------------------------------------------------------------------------	
  constant Axi_BurstType_Incr_c : std_logic_vector(1 downto 0) := "01";
  constant Axi_Resp_Okay_c      : std_logic_vector(1 downto 0) := "00";
  constant UnusedAddrBits_c     : natural                      := log2(axi_data_width_g / 8);

  constant BeatsBits_c       : natural := log2ceil(axi_max_beats_g + 1);
  subtype Trans_AddrRange_c is natural range cmd_wr_addr_i'high downto 0;
  subtype Trans_BurstRange_c is natural range BeatsBits_c + Trans_AddrRange_c'high downto Trans_AddrRange_c'high + 1;
  constant Trans_LowLatIdx_c : natural := Trans_BurstRange_c'high + 1;
  constant Trans_Size_c      : natural := Trans_LowLatIdx_c + 1;
  constant MaxBeatsNoCmd_c   : natural := max(axi_max_beats_g * axi_max_open_transactions_g, data_fifo_depth_g);

  ------------------------------------------------------------------------------
  -- Type
  ------------------------------------------------------------------------------	
  type WriteTfGen_s is (Idle_s, MaxCalc_s, GenTf_s, WriteTf_s);
  type ReadTfGen_s is (Idle_s, MaxCalc_s, GenTf_s, WriteTf_s);
  type AwFsm_s is (Idle_s, Wait_s);
  type ArFsm_s is (Idle_s, Wait_s);
  type WFsm_s is (Idle_s, NonLast_s, Last_s);

  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------	
  function AddrMasked_f(Addr : in std_logic_vector) return std_logic_vector is
    variable Masked_v : std_logic_vector(Addr'range);
  begin
    Masked_v                                := Addr;
    Masked_v(UnusedAddrBits_c - 1 downto 0) := (others => '0');
    return Masked_v;
  end function;

  ------------------------------------------------------------------------------
  -- Two Process Record
  ------------------------------------------------------------------------------		
  type two_process_r is record

    -- *** Write Related Registers ***
    -- Command Interface
    cmd_wr_rdy_o       : std_logic;
    wr_error_o        : std_logic;
    wr_done_o         : std_logic;
    -- Generate Write Transactions		
    WriteTfGenState : WriteTfGen_s;
    WrAddr          : unsigned(cmd_wr_addr_i'range);
    WrBeats         : unsigned(cmd_wr_size_i'range);
    WrLowLat        : std_logic;
    WrMaxBeats      : unsigned(BeatsBits_c - 1 downto 0);
    WrTfBeats       : unsigned(BeatsBits_c - 1 downto 0);
    WrTfVld         : std_logic;
    WrTfIsLast      : std_logic;
    -- Execute Aw Commands
    AwFsm           : AwFsm_s;
    AwFsmRdy        : std_logic;
    AwCmdSent       : std_logic;
    AwCmdSize       : unsigned(BeatsBits_c - 1 downto 0);
    AwCmdSizeMin1   : unsigned(BeatsBits_c - 1 downto 0); -- 	AwCmdSize-1 for timing optimization reasons
    WDataFifoWrite  : std_logic;
    -- Execute W Data
    WFsm            : WFsm_s;
    WDataFifoRd     : std_logic;
    WDataEna        : std_logic;
    WDataBeats      : unsigned(BeatsBits_c - 1 downto 0);
    -- Write Response
    WrRespError     : std_logic;
    -- Write General
    WrOpenTrans     : integer range -1 to axi_max_open_transactions_g;
    WrBeatsNoCmd    : signed(log2ceil(MaxBeatsNoCmd_c + 1) downto 0);
    -- AXI Signals
    m_axi_awaddr    : std_logic_vector(m_axi_awaddr'range);
    m_axi_awlen     : std_logic_vector(m_axi_awlen'range);
    m_axi_awvalid   : std_logic;
    m_axi_wlast     : std_logic;

    -- *** Read Related Registers *** 
    -- Command Interface
    cmd_rd_rdy_o       : std_logic;
    rd_error_o        : std_logic;
    rd_done_o         : std_logic;
    -- Generate Read Transactions		
    ReadTfGenState  : ReadTfGen_s;
    RdAddr          : unsigned(cmd_rd_addr_i'range);
    RdBeats         : unsigned(cmd_rd_size_o'range);
    RdLowLat        : std_logic;
    RdMaxBeats      : unsigned(BeatsBits_c - 1 downto 0);
    RdTfBeats       : unsigned(BeatsBits_c - 1 downto 0);
    RdTfVld         : std_logic;
    RdTfIsLast      : std_logic;
    -- Execute Ar Commands
    ArFsm           : ArFsm_s;
    ArFsmRdy        : std_logic;
    ArCmdSent       : std_logic;
    ArCmdSize       : unsigned(BeatsBits_c - 1 downto 0);
    ArCmdSizeMin1   : unsigned(BeatsBits_c - 1 downto 0); -- 	ArCmdSize-1 for timing optimization reasons
    RDataFifoRead   : std_logic;
    -- Write Response
    RdRespError     : std_logic;
    -- Read General
    RdOpenTrans     : unsigned(log2ceil(axi_max_open_transactions_g + 1) - 1 downto 0);
    RdFifoSpaceFree : signed(log2ceil(MaxBeatsNoCmd_c + 1) downto 0);
    -- AXI Signals
    m_axi_araddr    : std_logic_vector(m_axi_araddr'range);
    m_axi_arlen     : std_logic_vector(m_axi_arlen'range);
    m_axi_arvalid   : std_logic;

  end record;
  signal r, r_next : two_process_r;

  ------------------------------------------------------------------------------
  -- Instantiation Signals
  ------------------------------------------------------------------------------
  signal Rst               : std_logic;
  signal WrDataFifoORdy    : std_logic;
  signal WrDataFifoOVld    : std_logic;
  signal WrTransFifoInVld  : std_logic;
  signal WrTransFifoBeats  : std_logic_vector(BeatsBits_c - 1 downto 0);
  signal WrTransFifoOutVld : std_logic;
  signal WrRespIsLast      : std_logic;
  signal WrRespFifoVld     : std_logic;
  signal WrData_Rdy_I      : std_logic;
  signal RdTransFifoInVld  : std_logic;
  signal RdRespIsLast      : std_logic;
  signal RdRespFifoVld     : std_logic;
  signal RdDat_Vld_I       : std_logic;
  signal RdRespLast        : std_logic;
  signal M_Axi_RReady_I    : std_logic;

begin

  ------------------------------------------------------------------------------
  -- Assertions
  ------------------------------------------------------------------------------
  assert axi_data_width_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_simple axi_data_width_g must be a multiple of 8" severity failure;

  ------------------------------------------------------------------------------
  -- Combinatorial Process
  ------------------------------------------------------------------------------	
  p_comb : process(r, m_axi_awready, m_axi_bvalid, m_axi_bresp, WrDataFifoORdy, WrDataFifoOVld, WrTransFifoOutVld, WrTransFifoBeats, WrRespIsLast, WrRespFifoVld, cmd_wr_addr_i, cmd_wr_size_i, cmd_wr_low_lat_i, cmd_wr_vld_i, wr_vld_i, WrData_Rdy_I, m_axi_arready, RdRespIsLast, RdRespFifoVld, RdRespLast, cmd_rd_addr_i, cmd_rd_size_o, cmd_rd_low_lat_i, cmd_rd_vld_i, rd_rdy_i, RdDat_Vld_I)
    variable v               : two_process_r;
    variable WrMax4kBeats_v  : unsigned(13 - UnusedAddrBits_c downto 0);
    variable RdMax4kBeats_v  : unsigned(13 - UnusedAddrBits_c downto 0);
    variable Stdlv9Bit_v     : std_logic_vector(8 downto 0);
    variable WDataTransfer_v : boolean;
    variable StartWBurst_v   : boolean := true;
  begin
    -- *** Keep two process variables stable ***
    v := r;

    --------------------------------------------------------------------------
    -- Write Related Code
    --------------------------------------------------------------------------	
    if impl_write_g then

      -- *** Write Transfer Generation ***
      WrMax4kBeats_v := (others => '0');
      case r.WriteTfGenState is
        when Idle_s =>
          v.cmd_wr_rdy_o := '1';
          if (r.cmd_wr_rdy_o = '1') and (cmd_wr_vld_i = '1') then
            v.cmd_wr_rdy_o       := '0';
            v.WrAddr          := unsigned(AddrMasked_f(cmd_wr_addr_i));
            v.WrBeats         := unsigned(cmd_wr_size_i);
            v.WrLowLat        := cmd_wr_low_lat_i;
            v.WriteTfGenState := MaxCalc_s;
          end if;

        when MaxCalc_s =>
          WrMax4kBeats_v    := resize(unsigned('0' & not r.WrAddr(11 downto UnusedAddrBits_c)) + 1, WrMax4kBeats_v'length);
          if WrMax4kBeats_v > axi_max_beats_g then
            v.WrMaxBeats := to_unsigned(axi_max_beats_g, BeatsBits_c);
          else
            v.WrMaxBeats := WrMax4kBeats_v(BeatsBits_c - 1 downto 0);
          end if;
          v.WriteTfGenState := GenTf_s;

        when GenTf_s =>
          if (r.WrMaxBeats < r.WrBeats) then
            v.WrTfBeats  := r.WrMaxBeats;
            v.WrTfIsLast := '0';
          else
            v.WrTfBeats  := r.WrBeats(BeatsBits_c - 1 downto 0);
            v.WrTfIsLast := '1';
          end if;
          v.WrTfVld         := '1';
          v.WriteTfGenState := WriteTf_s;

        when WriteTf_s =>
          if (r.WrTfVld = '1') and (r.AwFsmRdy = '1') then
            v.WrTfVld := '0';
            v.WrBeats := r.WrBeats - r.WrTfBeats;
            v.WrAddr  := r.WrAddr + 2**UnusedAddrBits_c * r.WrTfBeats;
            if r.WrTfIsLast = '1' then
              v.WriteTfGenState := Idle_s;
            else
              v.WriteTfGenState := MaxCalc_s;
            end if;
          end if;

        when others => null;
      end case;

      -- *** AW Command Generation ***
      v.AwCmdSent      := '0';
      case r.AwFsm is
        when Idle_s =>
          if ((r.WrLowLat = '1') or (r.WrBeatsNoCmd >= signed('0' & r.WrTfBeats))) and (r.WrOpenTrans < axi_max_open_transactions_g) and (r.WrTfVld = '1') then
            v.AwFsmRdy := '1';
          end if;
          if (r.AwFsmRdy = '1') and (r.WrTfVld = '1') then
            v.AwFsmRdy      := '0';
            v.m_axi_awaddr  := std_logic_vector(r.WrAddr);
            Stdlv9Bit_v     := std_logic_vector(resize(r.WrTfBeats - 1, 9));
            v.m_axi_awlen   := Stdlv9Bit_v(7 downto 0);
            v.m_axi_awvalid := '1';
            v.AwFsm         := Wait_s;
            v.AwCmdSent     := '1';
            v.AwCmdSize     := r.WrTfBeats;
            v.AwCmdSizeMin1 := r.WrTfBeats - 1;
          end if;

        when Wait_s =>
          if m_axi_awready = '1' then
            v.WrOpenTrans   := r.WrOpenTrans + 1;
            v.m_axi_awvalid := '0';
            v.AwFsm         := Idle_s;
          end if;

        when others => null;
      end case;
      -- Update counter for FIFO entries that were not yet announced in a command
      -- .. Implementation is a bit weird for timing optimization reasons.
      -- Use registered WDataFifoWrite: This helps with timing and it does not introduce any risk since
      -- .. the decrement is still done immediately, the increment is delayed by one clock cycle. So worst
      -- .. case a High-Latency transfer is delayed by one cycle which is acceptable.		
      v.WDataFifoWrite := WrData_Rdy_I and wr_vld_i;
      if r.AwCmdSent = '1' then
        if r.WDataFifoWrite = '1' then
          v.WrBeatsNoCmd := r.WrBeatsNoCmd - signed('0' & r.AwCmdSizeMin1); -- Decrement by size and increment by one (timing opt)
        else
          v.WrBeatsNoCmd := r.WrBeatsNoCmd - signed('0' & r.AwCmdSize);
        end if;
      elsif r.WDataFifoWrite = '1' then
        v.WrBeatsNoCmd := r.WrBeatsNoCmd + 1;
      end if;

      -- *** W Data Generation ***
      WDataTransfer_v := (r.WDataEna = '1') and (WrDataFifoOVld = '1') and (WrDataFifoORdy = '1');
      v.WDataFifoRd   := '0';
      StartWBurst_v   := false;
      case r.WFsm is
        when Idle_s =>
          if WrTransFifoOutVld = '1' then
            StartWBurst_v := true;      -- shared code
          end if;

        when NonLast_s =>
          if WDataTransfer_v then
            if r.WDataBeats = 2 then
              v.m_axi_wlast := '1';
              v.WFsm        := Last_s;
            end if;
            v.WDataBeats := r.WDataBeats - 1;
          end if;

        when Last_s =>
          if WDataTransfer_v then
            -- Immediately start next transfer 
            -- .. WDataFifoRd is checked to leave time for the FIFO to complete the read in case of single cycle transfers
            if (WrTransFifoOutVld = '1') and (r.WDataFifoRd = '0') then
              StartWBurst_v := true;    -- shared code
              -- End of transfer without a next one back-to-back
            else
              v.WDataEna    := '0';
              v.WFsm        := Idle_s;
              v.m_axi_wlast := '0';
            end if;
          end if;

        when others => null;
      end case;
      -- implementation of shared code
      if StartWBurst_v then
        v.WDataFifoRd := '1';
        v.WDataEna    := '1';
        v.WDataBeats  := unsigned(WrTransFifoBeats);
        if unsigned(WrTransFifoBeats) = 1 then
          v.m_axi_wlast := '1';
          v.WFsm        := Last_s;
        else
          v.m_axi_wlast := '0';
          v.WFsm        := NonLast_s;
        end if;
      end if;

      -- *** W Response Generation ***
      v.wr_done_o  := '0';
      v.wr_error_o := '0';
      if m_axi_bvalid = '1' then
        assert WrRespFifoVld = '1' report "###ERROR###: psi_common_axi_master_simple internal error --> WrRespFifo Empty" severity error;
        v.WrOpenTrans := v.WrOpenTrans - 1; -- Use v. because it may have been modified above and this modification has not to be overriden
        if WrRespIsLast = '1' then
          if (m_axi_bresp /= Axi_Resp_Okay_c) then
            v.wr_error_o := '1';
          else
            v.wr_error_o    := r.WrRespError;
            v.wr_done_o     := not r.WrRespError;
            v.WrRespError := '0';
          end if;
        elsif m_axi_bresp /= Axi_Resp_Okay_c then
          v.WrRespError := '1';
        end if;
      end if;

    end if;

    --------------------------------------------------------------------------
    -- Read Related Code
    --------------------------------------------------------------------------	
    if impl_read_g then

      -- *** Read Transfer Generation ***
      RdMax4kBeats_v := (others => '0');
      case r.ReadTfGenState is
        when Idle_s =>
          v.cmd_rd_rdy_o := '1';
          if (r.cmd_rd_rdy_o = '1') and (cmd_rd_vld_i = '1') then
            v.cmd_rd_rdy_o      := '0';
            v.RdAddr         := unsigned(AddrMasked_f(cmd_rd_addr_i));
            v.RdBeats        := unsigned(cmd_rd_size_o);
            v.RdLowLat       := cmd_rd_low_lat_i;
            v.ReadTfGenState := MaxCalc_s;
          end if;

        when MaxCalc_s =>
          RdMax4kBeats_v   := resize(unsigned('0' & not r.RdAddr(11 downto UnusedAddrBits_c)) + 1, RdMax4kBeats_v'length);
          if RdMax4kBeats_v > axi_max_beats_g then
            v.RdMaxBeats := to_unsigned(axi_max_beats_g, BeatsBits_c);
          else
            v.RdMaxBeats := RdMax4kBeats_v(BeatsBits_c - 1 downto 0);
          end if;
          v.ReadTfGenState := GenTf_s;

        when GenTf_s =>
          if (r.RdMaxBeats < r.RdBeats) then
            v.RdTfBeats  := r.RdMaxBeats;
            v.RdTfIsLast := '0';
          else
            v.RdTfBeats  := r.RdBeats(BeatsBits_c - 1 downto 0);
            v.RdTfIsLast := '1';
          end if;
          v.RdTfVld        := '1';
          v.ReadTfGenState := WriteTf_s;

        when WriteTf_s =>
          if (r.RdTfVld = '1') and (r.ArFsmRdy = '1') then
            v.RdTfVld := '0';
            v.RdBeats := r.RdBeats - r.RdTfBeats;
            v.RdAddr  := r.RdAddr + 2**UnusedAddrBits_c * r.RdTfBeats;
            if r.RdTfIsLast = '1' then
              v.ReadTfGenState := Idle_s;
            else
              v.ReadTfGenState := MaxCalc_s;
            end if;
          end if;

        when others => null;
      end case;

      -- *** AR Command Generation ***
      v.ArCmdSent     := '0';
      case r.ArFsm is
        when Idle_s =>
          if ((r.RdLowLat = '1') or (r.RdFifoSpaceFree >= signed('0' & r.RdTfBeats))) and (r.RdOpenTrans < axi_max_open_transactions_g) and (r.RdTfVld = '1') then
            v.ArFsmRdy := '1';
          end if;
          if (r.ArFsmRdy = '1') and (r.RdTfVld = '1') then
            v.ArFsmRdy      := '0';
            v.m_axi_araddr  := std_logic_vector(r.RdAddr);
            Stdlv9Bit_v     := std_logic_vector(resize(r.RdTfBeats - 1, 9));
            v.m_axi_arlen   := Stdlv9Bit_v(7 downto 0);
            v.m_axi_arvalid := '1';
            v.ArFsm         := Wait_s;
            v.ArCmdSent     := '1';
            v.ArCmdSize     := r.RdTfBeats;
            v.ArCmdSizeMin1 := r.RdTfBeats - 1;
          end if;

        when Wait_s =>
          if m_axi_arready = '1' then
            v.RdOpenTrans   := r.RdOpenTrans + 1;
            v.m_axi_arvalid := '0';
            v.ArFsm         := Idle_s;
          end if;

        when others => null;
      end case;
      -- Update counter for FIFO entries that were not yet announced in a command
      -- .. Implementation is a bit weird for timing optimization reasons.
      -- Use registered RDataFifoRead: This helps with timing and it does not introduce any risk since
      -- .. the decrement is still done immediately, the increment is delayed by one clock cycle. So worst
      -- .. case a High-Latency transfer is delayed by one cycle which is acceptable.		
      v.RDataFifoRead := rd_rdy_i and RdDat_Vld_I;
      if r.ArCmdSent = '1' then
        if r.RDataFifoRead = '1' then
          v.RdFifoSpaceFree := r.RdFifoSpaceFree - signed('0' & r.ArCmdSizeMin1); -- Decrement by size and increment by one (timing opt)
        else
          v.RdFifoSpaceFree := r.RdFifoSpaceFree - signed('0' & r.ArCmdSize);
        end if;
      elsif r.RDataFifoRead = '1' then
        v.RdFifoSpaceFree := r.RdFifoSpaceFree + 1;
      end if;

      -- *** R Response Generation ***
      v.rd_done_o  := '0';
      v.rd_error_o := '0';
      if RdRespLast = '1' then
        assert RdRespFifoVld = '1' report "###ERROR###: psi_common_axi_master_simple internal error --> RdRespFifo Empty" severity error;
        v.RdOpenTrans := v.RdOpenTrans - 1; -- Use v. because it may have been modified above and this modification has not to be overriden
        if RdRespIsLast = '1' then
          if (m_axi_rresp /= Axi_Resp_Okay_c) then
            v.rd_error_o := '1';
          else
            v.rd_error_o    := r.RdRespError;
            v.rd_done_o     := not r.RdRespError;
            v.RdRespError := '0';
          end if;
        elsif m_axi_rresp /= Axi_Resp_Okay_c then
          v.RdRespError := '1';
        end if;
      end if;

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
          r.cmd_wr_rdy_o       <= '0';
          r.WriteTfGenState <= Idle_s;
          r.WrTfVld         <= '0';
          r.AwFsm           <= Idle_s;
          r.AwFsmRdy        <= '0';
          r.AwCmdSent       <= '0';
          r.m_axi_awvalid   <= '0';
          r.WDataFifoRd     <= '0';
          r.WDataEna        <= '0';
          r.WrOpenTrans     <= 0;
          r.WrRespError     <= '0';
          r.wr_done_o         <= '0';
          r.wr_error_o        <= '0';
          r.WrBeatsNoCmd    <= (others => '0');
          r.WFsm            <= Idle_s;
          r.WDataFifoWrite  <= '0';
        end if;
        -- *** Read Related Registers ***
        if impl_read_g then
          r.cmd_rd_rdy_o       <= '0';
          r.ReadTfGenState  <= Idle_s;
          r.RdTfVld         <= '0';
          r.ArFsmRdy        <= '0';
          r.ArCmdSent       <= '0';
          r.m_axi_arvalid   <= '0';
          r.ArFsm           <= Idle_s;
          r.RdOpenTrans     <= (others => '0');
          r.RdRespError     <= '0';
          r.rd_done_o         <= '0';
          r.rd_error_o        <= '0';
          r.RdFifoSpaceFree <= to_signed(data_fifo_depth_g, r.RdFifoSpaceFree'length);
          r.RDataFifoRead   <= '0';
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------		
  cmd_wr_rdy_o     <= r.cmd_wr_rdy_o;
  m_axi_awaddr  <= r.m_axi_awaddr;
  m_axi_awlen   <= r.m_axi_awlen;
  m_axi_awvalid <= r.m_axi_awvalid;
  m_axi_wlast   <= r.m_axi_wlast;
  wr_done_o       <= r.wr_done_o;
  wr_error_o      <= r.wr_error_o;
  cmd_rd_rdy_o     <= r.cmd_rd_rdy_o;
  m_axi_araddr  <= r.m_axi_araddr;
  m_axi_arlen   <= r.m_axi_arlen;
  m_axi_arvalid <= r.m_axi_arvalid;
  rd_done_o       <= r.rd_done_o;
  rd_error_o      <= r.rd_error_o;

  ------------------------------------------------------------------------------
  -- Constant Outputs
  ------------------------------------------------------------------------------	
  m_axi_awsize  <= std_logic_vector(to_unsigned(log2(axi_data_width_g / 8), 3));
  m_axi_arsize  <= std_logic_vector(to_unsigned(log2(axi_data_width_g / 8), 3));
  m_axi_awburst <= Axi_BurstType_Incr_c;
  m_axi_arburst <= Axi_BurstType_Incr_c;
  m_axi_awcache <= "0011";              -- According AXI reference guide
  m_axi_arcache <= "0011";              -- According AXI reference guide
  m_axi_awprot  <= "000";               -- According AXI reference guide
  m_axi_arprot  <= "000";               -- According AXI reference guide
  m_axi_awlock  <= '0';                 -- Exclusive access support not implemented 
  m_axi_arlock  <= '0';                 -- Exclusive access support not implemented 	
  m_axi_bready  <= '1' when impl_write_g else '0';

  ------------------------------------------------------------------------------
  -- Instantiations
  ------------------------------------------------------------------------------
  Rst <= not m_axi_aresetn;

  -- *** Write FIFOs ***
  g_write : if impl_write_g generate

    -- FIFO for data transfer FSM
    WrTransFifoInVld <= r.AwFsmRdy and r.WrTfVld;
    fifo_wr_trans : entity work.psi_common_sync_fifo
      generic map(
        width_g       => BeatsBits_c,
        depth_g       => axi_max_open_transactions_g,
        alm_full_on_g   => false,
        alm_empty_on_g  => false,
        ram_style_g    => "auto",
        ram_behavior_g => ram_behavior_g
      )
      port map(
        clk_i     => m_axi_aclk,
        rst_i     => Rst,
        dat_i  => std_logic_vector(r.WrTfBeats),
        vld_i   => WrTransFifoInVld,
        rdy_o   => open,                -- Not required since maximum of open transactions is limitted
        dat_o => WrTransFifoBeats,
        vld_o  => WrTransFifoOutVld,
        rdy_i  => r.WDataFifoRd
      );

    -- Write Data FIFO
    b_fifo_wr_data : block
      signal InData  : std_logic_vector(wr_dat_i'length + wr_data_be'length - 1 downto 0);
      signal OutData : std_logic_vector(InData'range);
    begin
      InData(wr_dat_i'high downto wr_dat_i'low)                        <= wr_dat_i;
      InData(wr_dat_i'high + wr_data_be'length downto wr_dat_i'high + 1) <= wr_data_be;
      fifo_wr_data : entity work.psi_common_sync_fifo
        generic map(
          width_g       => wr_dat_i'length + wr_data_be'length,
          depth_g       => data_fifo_depth_g,
          alm_full_on_g   => false,
          alm_empty_on_g  => false,
          ram_style_g    => "auto",
          ram_behavior_g => ram_behavior_g
        )
        port map(
          clk_i     => m_axi_aclk,
          rst_i     => Rst,
          dat_i  => InData,
          vld_i   => wr_vld_i,
          rdy_o   => WrData_Rdy_I,
          dat_o => OutData,
          vld_o  => WrDataFifoOVld,
          rdy_i  => WrDataFifoORdy
        );
      m_axi_wdata                                                          <= OutData(wr_dat_i'high downto wr_dat_i'low);
      m_axi_wstrb                                                          <= OutData(wr_dat_i'high + wr_data_be'length downto wr_dat_i'high + 1);

      m_axi_wvalid   <= WrDataFifoOVld and r.WDataEna;
      WrDataFifoORdy <= m_axi_wready and r.WDataEna;

      wr_rdy_o <= WrData_Rdy_I;
    end block;

    -- FIFO for write response FSM
    fifo_wr_resp : entity work.psi_common_sync_fifo
      generic map(
        width_g       => 1,
        depth_g       => axi_max_open_transactions_g,
        alm_full_on_g   => false,
        alm_empty_on_g  => false,
        ram_style_g    => "auto",
        ram_behavior_g => ram_behavior_g
      )
      port map(
        clk_i    => m_axi_aclk,
        rst_i    => Rst,
        dat_i(0)                                                                                                                                                                                                                                                                                                                => r.WrTfIsLast,
        vld_i  => WrTransFifoInVld,
        rdy_o  => open,                 -- Not required since maximum of open transactions is limitted
        dat_o(0)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  => WrRespIsLast,
        vld_o => WrRespFifoVld,
        rdy_i => m_axi_bvalid
      );
  end generate;

  -- Tie signals to ground if read not implemented
  g_nwrite : if not impl_write_g generate
    m_axi_wstrb  <= (others => '0');
    m_axi_wdata  <= (others => '0');
    m_axi_wvalid <= '0';
    wr_rdy_o    <= '0';
  end generate;

  -- *** Read FIFOs ***
  g_read : if impl_read_g generate

    -- Read Data FIFO
    b_fifo_rd_data : block
    begin
      fifo_wr_data : entity work.psi_common_sync_fifo
        generic map(
          width_g       => rd_dat_o'length,
          depth_g       => data_fifo_depth_g,
          alm_full_on_g   => false,
          alm_empty_on_g  => false,
          ram_style_g    => "auto",
          ram_behavior_g => ram_behavior_g
        )
        port map(
          clk_i     => m_axi_aclk,
          rst_i     => Rst,
          dat_i  => m_axi_rdata,
          vld_i   => m_axi_rvalid,
          rdy_o   => M_Axi_RReady_I,
          dat_o => rd_dat_o,
          vld_o  => RdDat_Vld_I,
          rdy_i  => rd_rdy_i
        );

      rd_vld_o    <= RdDat_Vld_I;
      m_axi_rready <= M_Axi_RReady_I;
    end block;

    -- FIFO for read response FSM
    RdTransFifoInVld <= r.ArFsmRdy and r.RdTfVld;
    RdRespLast       <= m_axi_rvalid and M_Axi_RReady_I and m_axi_rlast;
    fifo_rd_resp : entity work.psi_common_sync_fifo
      generic map(
        width_g       => 1,
        depth_g       => axi_max_open_transactions_g,
        alm_full_on_g   => false,
        alm_empty_on_g  => false,
        ram_style_g    => "auto",
        ram_behavior_g => ram_behavior_g
      )
      port map(
        clk_i    => m_axi_aclk,
        rst_i    => Rst,
        dat_i(0)                                                                                                                                                                                                                                                                                                                => r.RdTfIsLast,
        vld_i  => RdTransFifoInVld,
        rdy_o  => open,                 -- Not required since maximum of open transactions is limitted
        dat_o(0)                                                                                                                                                                                                                                                                                                                                                                                                                                                                  => RdRespIsLast,
        vld_o => RdRespFifoVld,
        rdy_i => RdRespLast
      );

  end generate;

  -- Tie signals to ground if read not implemented
  g_nread : if not impl_read_g generate
    m_axi_rready <= '0';
    rd_dat_o   <= (others => '0');
    rd_vld_o    <= '0';
  end generate;

end rtl;
