------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Goran Marinkovic, Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a full AXI-4 slave for simple IP-Core interfaces. It
-- supports the implementation of registers as well as access to memories.
-- Its only main limitations are, that data for memory accesses must be available for
-- reading after one clock cycle. So except using a synchronous RAM, no additional
-- pipelining is possible and that it only supports 64-bit wide AXI bus.
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.psi_common_array_pkg.all;
use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- $$ processes=axi,ip $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_slave_ipif64 is
  generic(
    -- IP Interface Config
    num_reg_g        : integer  := 32;  -- $$ export=true $$
    rst_val_g        : t_aslv64 := (0 => (others => '0')); -- $$ constant=(X"0001A123B123C123", X"0002123456789ABC") $$
    use_mem_g        : boolean  := true; -- $$ export=true $$
    -- AXI Config
    axi_id_width_g   : integer  := 1;
    axi_addr_width_g : integer  := 9;
    axi_data_width_g : integer  := 64;
    axi_byte_width_g : integer  := 64 / 8
  );
  port(
    --------------------------------------------------------------------------
    -- AXI Slave Bus Interface
    --------------------------------------------------------------------------
    -- System
    s_axi_aclk    : in  std_logic;                                          -- $$ type=clk; freq=100e6 $$
    s_axi_aresetn : in  std_logic;                                          -- $$ type=rst; clk=s_axi_aclk; lowactive=true $$
    -- Read address channel
    s_axi_arid    : in  std_logic_vector(axi_id_width_g - 1 downto 0);      -- $$ proc=axi $$
    s_axi_araddr  : in  std_logic_vector(axi_addr_width_g - 1 downto 0);    -- $$ proc=axi $$
    s_axi_arlen   : in  std_logic_vector(7 downto 0);                       -- $$ proc=axi $$
    s_axi_arsize  : in  std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
    s_axi_arburst : in  std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
    s_axi_arlock  : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_arcache : in  std_logic_vector(3 downto 0);                       -- $$ proc=axi $$
    s_axi_arprot  : in  std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
    s_axi_arvalid : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_arready : out std_logic;                                          -- $$ proc=axi $$
    -- Read data channel
    s_axi_rid     : out std_logic_vector(axi_id_width_g - 1 downto 0);      -- $$ proc=axi $$
    s_axi_rdata   : out std_logic_vector(axi_data_width_g - 1 downto 0);    -- $$ proc=axi $$
    s_axi_rresp   : out std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
    s_axi_rlast   : out std_logic;                                          -- $$ proc=axi $$
    s_axi_rvalid  : out std_logic;                                          -- $$ proc=axi $$
    s_axi_rready  : in  std_logic;                                          -- $$ proc=axi $$
    -- Write address channel
    s_axi_awid    : in  std_logic_vector(axi_id_width_g - 1 downto 0);      -- $$ proc=axi $$
    s_axi_awaddr  : in  std_logic_vector(axi_addr_width_g - 1 downto 0);    -- $$ proc=axi $$
    s_axi_awlen   : in  std_logic_vector(7 downto 0);                       -- $$ proc=axi $$
    s_axi_awsize  : in  std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
    s_axi_awburst : in  std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
    s_axi_awlock  : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_awcache : in  std_logic_vector(3 downto 0);                       -- $$ proc=axi $$
    s_axi_awprot  : in  std_logic_vector(2 downto 0);                       -- $$ proc=axi $$
    s_axi_awvalid : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_awready : out std_logic;                                          -- $$ proc=axi $$
    -- Write data channel
    s_axi_wdata   : in  std_logic_vector(axi_data_width_g - 1 downto 0);    -- $$ proc=axi $$
    s_axi_wstrb   : in  std_logic_vector(axi_byte_width_g - 1 downto 0);    -- $$ proc=axi $$
    s_axi_wlast   : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_wvalid  : in  std_logic;                                          -- $$ proc=axi $$
    s_axi_wready  : out std_logic;                                          -- $$ proc=axi $$
    -- Write response channel
    s_axi_bid     : out std_logic_vector(axi_id_width_g - 1 downto 0);      -- $$ proc=axi $$
    s_axi_bresp   : out std_logic_vector(1 downto 0);                       -- $$ proc=axi $$
    s_axi_bvalid  : out std_logic;                                          -- $$ proc=axi $$
    s_axi_bready  : in  std_logic;                                          -- $$ proc=axi $$
    -- Register Interface
    o_reg_rd      : out std_logic_vector(num_reg_g - 1 downto 0);           -- $$ proc=ip $$
    i_reg_rdata   : in  t_aslv64(0 to num_reg_g - 1) := (others => (others => '0')); -- $$ proc=ip $$
    o_reg_wr      : out std_logic_vector(num_reg_g - 1 downto 0);           -- $$ proc=ip $$
    o_reg_wdata   : out t_aslv64(0 to num_reg_g - 1);                       -- $$ proc=ip $$
    -- Memory Interface
    o_mem_addr    : out std_logic_vector(axi_addr_width_g - 1 downto 0);    -- $$ proc=ip $$
    o_mem_wr      : out std_logic_vector(axi_byte_width_g - 1 downto 0);    -- $$ proc=ip $$
    o_mem_wdata   : out std_logic_vector(axi_data_width_g - 1 downto 0);    -- $$ proc=ip $$
    i_mem_rdata   : in  std_logic_vector(axi_data_width_g - 1 downto 0) := (others => '0') -- $$ proc=ip $$
  );
end entity;

architecture behav of psi_common_axi_slave_ipif64 is

  -----------------------------------------------------------------------------
  -- AXI slave bus interface
  -----------------------------------------------------------------------------
  type axi_fsm_type is (
    axi_fsm_idle,
    axi_fsm_rd_data,
    axi_fsm_wr_data,
    axi_fsm_wr_resp_delay,
    axi_fsm_wr_done
  );
  signal axi_fsm_comb          : axi_fsm_type;
  signal axi_fsm               : axi_fsm_type;
  -- ADDR_INDEX_LOW is used for addressing 32/64 bit registers/memories
  -- ADDR_INDEX_LOW = 2 for 32 bits (n downto 2)
  -- ADDR_INDEX_LOW = 3 for 64 bits (n downto 3)
  constant REG_ADDR_INDEX_LOW  : integer                                         := 3;
  constant REG_ADDR_WIDTH      : integer                                         := integer(log2ceil(num_reg_g)) + REG_ADDR_INDEX_LOW;
  constant REG_ADDR_INDEX_HIGH : integer                                         := REG_ADDR_WIDTH - 1;
  constant MEM_ADDR_START      : unsigned(axi_addr_width_g - 1 downto 0)         := to_unsigned(2**(REG_ADDR_WIDTH), axi_addr_width_g);
  constant RESP_OKAY_c         : std_logic_vector(1 downto 0)                    := "00";
  constant RESP_EXOKAY_c       : std_logic_vector(1 downto 0)                    := "01";
  constant RESP_SLVERR_c       : std_logic_vector(1 downto 0)                    := "10";
  constant RESP_DECERR_c       : std_logic_vector(1 downto 0)                    := "11";
  -- Read address channel
  signal axi_arid              : std_logic_vector(axi_id_width_g - 1 downto 0)   := (others => '0');
  signal axi_araddr            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  signal axi_araddr_last       : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  signal axi_arlen             : unsigned(7 downto 0)                            := (others => '0');
  signal axi_arsize            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  signal axi_arburst           : std_logic_vector(1 downto 0)                    := (others => '0');
  signal axi_arwrap_en         : std_logic                                       := '0';
  signal axi_arwrap            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  -- Read data channel
  signal axi_rresp             : std_logic_vector(1 downto 0);
  signal axi_rlast             : std_logic                                       := '0';
  signal axi_rready            : std_logic                                       := '0';
  signal axi_rvalid            : std_logic                                       := '0';
  -- Write address channel
  signal axi_awid              : std_logic_vector(axi_id_width_g - 1 downto 0)   := (others => '0');
  signal axi_awaddr            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  signal axi_awlen             : unsigned(7 downto 0)                            := (others => '0');
  signal axi_awsize            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  signal axi_awburst           : std_logic_vector(1 downto 0)                    := (others => '0');
  signal axi_awwrap_en         : std_logic                                       := '0';
  signal axi_awwrap            : unsigned(axi_addr_width_g - 1 downto 0)         := (others => '0');
  -- Write data channel
  signal axi_wlast             : std_logic                                       := '0';
  signal axi_wready            : std_logic                                       := '0';
  -- Write response channel
  signal axi_bresp             : std_logic_vector(1 downto 0);
  -- Derived signals
  signal axi_raddr_sel         : std_logic                                       := '0';
  signal axi_waddr_sel         : std_logic                                       := '0';
  signal reg_rd                : std_logic_vector(num_reg_g - 1 downto 0)        := (others => '0');
  signal reg_wr                : std_logic_vector(num_reg_g - 1 downto 0)        := (others => '0');
  signal reg_rdata             : std_logic_vector(axi_data_width_g - 1 downto 0) := (others => '0');
  signal reg_rvalid            : std_logic                                       := '0';
  signal mem_rvalid            : std_logic                                       := '0';
  -- R-channel pipeline stage
  signal rpl_rready            : std_logic;
  signal rpl_rvalid            : std_logic;
  signal rpl_rid               : std_logic_vector(axi_id_width_g - 1 downto 0);
  signal rpl_rdata             : std_logic_vector(axi_data_width_g - 1 downto 0);
  signal rpl_rresp             : std_logic_vector(1 downto 0);
  signal rpl_rlast             : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Assertions
  -----------------------------------------------------------------------------
  assert isLog2(num_reg_g) report "###ERROR###: psi_common_axi_slave_ipif64: num_reg_g must be a power of two!" severity error;
  assert not (not use_mem_g and num_reg_g = 0) report "###ERROR###: psi_common_axi_slave_ipif64: num_reg_g must be > 0 if use_mem_g = true" severity error;

  -----------------------------------------------------------------------------
  -- AXI fsm
  -----------------------------------------------------------------------------
  axi_fsm_comb_proc : process(axi_fsm, axi_rlast, axi_wlast, s_axi_aresetn, s_axi_arvalid, s_axi_awvalid, s_axi_bready, rpl_rready, s_axi_wvalid)
  begin
    if (s_axi_aresetn = '0') then
      axi_fsm_comb <= axi_fsm_idle;
    else
      axi_fsm_comb <= axi_fsm;
      case axi_fsm is
        when axi_fsm_idle =>
          if (s_axi_arvalid = '1') then
            axi_fsm_comb <= axi_fsm_rd_data;
          elsif (s_axi_awvalid = '1') then
            axi_fsm_comb <= axi_fsm_wr_data;
          end if;
        when axi_fsm_rd_data =>
          if ((axi_rlast = '1') and (rpl_rready = '1')) then
            axi_fsm_comb <= axi_fsm_idle;
          end if;
        when axi_fsm_wr_data =>
          if ((axi_wlast = '1') and (s_axi_wvalid = '1')) then
            axi_fsm_comb <= axi_fsm_wr_resp_delay;
          end if;
        when axi_fsm_wr_resp_delay =>
          axi_fsm_comb <= axi_fsm_wr_done;
        when axi_fsm_wr_done =>
          if (s_axi_bready = '1') then
            axi_fsm_comb <= axi_fsm_idle;
          end if;
        when others =>
          axi_fsm_comb <= axi_fsm_idle;
      end case;
    end if;
  end process;

  axi_fsm_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      axi_fsm <= axi_fsm_comb;
    end if;
  end process axi_fsm_proc;

  -----------------------------------------------------------------------------
  -- AXI ARADDR
  -----------------------------------------------------------------------------
  axi_arwrap_en <= '1' when ((axi_araddr and axi_arwrap) = axi_arwrap) else '0';

  axi_araddr_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      case axi_fsm is
        when axi_fsm_idle =>
          axi_rresp <= RESP_OKAY_c;
          if (axi_fsm_comb = axi_fsm_rd_data) then
            axi_araddr      <= unsigned(s_axi_araddr);
            axi_araddr_last <= unsigned(s_axi_araddr);
            case (s_axi_arsize) is
              when "000" =>
                axi_arsize <= to_unsigned(1, axi_addr_width_g);
              when "001" =>
                axi_arsize <= to_unsigned(2, axi_addr_width_g);
              when "010" =>
                axi_arsize <= to_unsigned(4, axi_addr_width_g);
              when "011" =>
                axi_arsize <= to_unsigned(8, axi_addr_width_g);
              when others =>
                axi_arsize <= to_unsigned(1, axi_addr_width_g);
            end case;
            axi_arburst     <= s_axi_arburst;
            axi_arlen       <= unsigned(s_axi_arlen);
            if (s_axi_arburst = "10") then -- If wrapping burst
              case (s_axi_arlen) is
                when X"01" =>
                  case (s_axi_arsize) is
                    when "000" =>
                      axi_arwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_arwrap <= to_unsigned(2 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_arwrap <= to_unsigned(2 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_arwrap <= to_unsigned(2 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_arwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"03" =>
                  case (s_axi_arsize) is
                    when "000" =>
                      axi_arwrap <= to_unsigned(4 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_arwrap <= to_unsigned(4 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_arwrap <= to_unsigned(4 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_arwrap <= to_unsigned(4 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_arwrap <= to_unsigned(4 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"07" =>
                  case (s_axi_arsize) is
                    when "000" =>
                      axi_arwrap <= to_unsigned(8 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_arwrap <= to_unsigned(8 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_arwrap <= to_unsigned(8 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_arwrap <= to_unsigned(8 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_arwrap <= to_unsigned(8 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"0F" =>
                  case (s_axi_arsize) is
                    when "000" =>
                      axi_arwrap <= to_unsigned(16 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_arwrap <= to_unsigned(16 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_arwrap <= to_unsigned(16 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_arwrap <= to_unsigned(16 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_arwrap <= to_unsigned(16 * 1 - 1, axi_addr_width_g);
                  end case;
                when others =>
                  axi_arwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
              end case;
            end if;
          end if;
        when axi_fsm_rd_data =>
          -- Produce decoding error if memory is accessed but not enabled
          if unsigned(axi_araddr) >= (num_reg_g * 8) and not use_mem_g then
            axi_rresp <= RESP_DECERR_c;
          end if;
          -- Do access
          if (rpl_rready = '1') then
            case (axi_arburst) is
              when "00" =>              -- Fixed burst
                null;
              when "01" =>              -- Incremental burst
                axi_araddr <= axi_araddr + axi_arsize;
              when "10" =>              -- Wrapping burst
                if (axi_arwrap_en = '1') then
                  axi_araddr <= axi_araddr - axi_arwrap;
                else
                  axi_araddr <= axi_araddr + axi_arsize;
                end if;
              when others =>            -- Reserved
                null;
            end case;
            axi_araddr_last <= axi_araddr;
          else
            axi_araddr <= axi_araddr_last;
          end if;
          if (axi_rvalid = '1') then
            axi_arlen <= axi_arlen - 1;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process axi_araddr_proc;

  -----------------------------------------------------------------------------
  -- AXI RADDR denotes register or memory
  -----------------------------------------------------------------------------
  axi_raddr_sel <= '1' when ((axi_fsm = axi_fsm_rd_data) and (to_integer(unsigned(axi_araddr_last(axi_addr_width_g - 1 downto REG_ADDR_WIDTH))) /= 0)) else '0';

  -----------------------------------------------------------------------------
  -- AXI ARREADY
  -----------------------------------------------------------------------------
  s_axi_arready <= '1' when ((axi_fsm = axi_fsm_idle) and (axi_fsm_comb = axi_fsm_rd_data)) else '0';

  -----------------------------------------------------------------------------
  -- AXI RID
  -----------------------------------------------------------------------------
  axi_rid_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if (axi_fsm = axi_fsm_idle) then
        if (axi_fsm_comb = axi_fsm_rd_data) then
          axi_arid <= s_axi_arid;
        else
          axi_arid <= (others => '0');
        end if;
      end if;
    end if;
  end process axi_rid_proc;

  rpl_rid <= axi_arid;

  -----------------------------------------------------------------------------
  -- AXI RREADY
  -----------------------------------------------------------------------------
  axi_rready_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if (axi_fsm = axi_fsm_rd_data) then
        axi_rready <= rpl_rready;
      else
        axi_rready <= '0';
      end if;
    end if;
  end process axi_rready_proc;

  -----------------------------------------------------------------------------
  -- AXI RVALID
  -----------------------------------------------------------------------------
  axi_rvalid <= reg_rvalid or mem_rvalid;
  rpl_rvalid <= axi_rvalid;

  -----------------------------------------------------------------------------
  -- AXI RLAST
  -----------------------------------------------------------------------------
  axi_rlast <= '1' when (((mem_rvalid = '1') or (reg_rvalid = '1')) and (axi_arlen = X"00")) else '0';
  rpl_rlast <= axi_rlast;

  -----------------------------------------------------------------------------
  -- AXI RRESP
  -----------------------------------------------------------------------------
  rpl_rresp <= axi_rresp;

  -----------------------------------------------------------------------------
  -- AXI AWADDR
  -----------------------------------------------------------------------------
  axi_awwrap_en <= '1' when ((axi_awaddr and axi_awwrap) = axi_awwrap) else '0';

  axi_awaddr_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      case axi_fsm is
        when axi_fsm_idle =>
          axi_bresp <= RESP_OKAY_c;
          if (axi_fsm_comb = axi_fsm_wr_data) then
            axi_awaddr  <= unsigned(s_axi_awaddr);
            case (s_axi_awsize) is
              when "000" =>
                axi_awsize <= to_unsigned(1, axi_addr_width_g);
              when "001" =>
                axi_awsize <= to_unsigned(2, axi_addr_width_g);
              when "010" =>
                axi_awsize <= to_unsigned(4, axi_addr_width_g);
              when "011" =>
                axi_awsize <= to_unsigned(8, axi_addr_width_g);
              when others =>
                axi_awsize <= to_unsigned(1, axi_addr_width_g);
            end case;
            axi_awburst <= s_axi_awburst;
            axi_awlen   <= unsigned(s_axi_awlen);
            if (s_axi_awburst = "10") then -- If wrapping burst
              case (s_axi_awlen) is
                when X"01" =>
                  case (s_axi_awsize) is
                    when "000" =>
                      axi_awwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_awwrap <= to_unsigned(2 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_awwrap <= to_unsigned(2 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_awwrap <= to_unsigned(2 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_awwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"03" =>
                  case (s_axi_awsize) is
                    when "000" =>
                      axi_awwrap <= to_unsigned(4 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_awwrap <= to_unsigned(4 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_awwrap <= to_unsigned(4 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_awwrap <= to_unsigned(4 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_awwrap <= to_unsigned(4 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"07" =>
                  case (s_axi_awsize) is
                    when "000" =>
                      axi_awwrap <= to_unsigned(8 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_awwrap <= to_unsigned(8 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_awwrap <= to_unsigned(8 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_awwrap <= to_unsigned(8 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_awwrap <= to_unsigned(8 * 1 - 1, axi_addr_width_g);
                  end case;
                when X"0F" =>
                  case (s_axi_awsize) is
                    when "000" =>
                      axi_awwrap <= to_unsigned(16 * 1 - 1, axi_addr_width_g);
                    when "001" =>
                      axi_awwrap <= to_unsigned(16 * 2 - 1, axi_addr_width_g);
                    when "010" =>
                      axi_awwrap <= to_unsigned(16 * 4 - 1, axi_addr_width_g);
                    when "011" =>
                      axi_awwrap <= to_unsigned(16 * 8 - 1, axi_addr_width_g);
                    when others =>
                      axi_awwrap <= to_unsigned(16 * 1 - 1, axi_addr_width_g);
                  end case;
                when others =>
                  axi_awwrap <= to_unsigned(2 * 1 - 1, axi_addr_width_g);
              end case;
            end if;
          end if;
        when axi_fsm_wr_data =>
          -- Produce decoding error if memory is accessed but not enabled
          if unsigned(axi_awaddr) >= (num_reg_g * 8) and not use_mem_g then
            axi_bresp <= RESP_DECERR_c;
          end if;
          -- Do access
          if (s_axi_wvalid = '1') then
            case (axi_awburst) is
              when "00" =>              -- Fixed burst
                null;
              when "01" =>              -- Incremental burst
                axi_awaddr <= axi_awaddr + axi_awsize;
              when "10" =>              -- Wrapping burst
                if (axi_awwrap_en = '1') then
                  axi_awaddr <= axi_awaddr - axi_awwrap;
                else
                  axi_awaddr <= axi_awaddr + axi_awsize;
                end if;
              when others =>            -- Reserved
                null;
            end case;
          end if;
          if (axi_wready = '1') then
            axi_awlen <= axi_awlen - 1;
          end if;
        when others =>
          null;
      end case;
    end if;
  end process axi_awaddr_proc;

  -----------------------------------------------------------------------------
  -- AXI WADDR denotes register or memory
  -----------------------------------------------------------------------------
  axi_waddr_sel <= '1' when ((axi_fsm = axi_fsm_wr_data) and (to_integer(unsigned(axi_awaddr(axi_addr_width_g - 1 downto REG_ADDR_WIDTH))) /= 0)) else '0';

  -----------------------------------------------------------------------------
  -- AXI AWREADY
  -----------------------------------------------------------------------------
  s_axi_awready <= '1' when ((axi_fsm = axi_fsm_idle) and (axi_fsm_comb = axi_fsm_wr_data)) else '0';

  -----------------------------------------------------------------------------
  -- AXI WID
  -----------------------------------------------------------------------------
  axi_wid_proc : process(s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if (axi_fsm = axi_fsm_idle) then
        if (axi_fsm_comb = axi_fsm_wr_data) then
          axi_awid <= s_axi_awid;
        else
          axi_awid <= (others => '0');
        end if;
      end if;
    end if;
  end process axi_wid_proc;

  s_axi_bid <= axi_awid;

  -----------------------------------------------------------------------------
  -- AXI WREADY
  -----------------------------------------------------------------------------
  axi_wready   <= '1' when ((axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1')) else '0';
  s_axi_wready <= axi_wready;

  -----------------------------------------------------------------------------
  -- AXI WLAST
  -----------------------------------------------------------------------------
  axi_wlast <= '1' when ((axi_wready = '1') and (axi_awlen = X"00")) else '0';

  -----------------------------------------------------------------------------
  -- AXI BRESP
  -----------------------------------------------------------------------------
  s_axi_bresp <= axi_bresp;

  -----------------------------------------------------------------------------
  -- AXI BVALID
  -----------------------------------------------------------------------------
  s_axi_bvalid <= '1' when (axi_fsm = axi_fsm_wr_done) else '0';

  ---------------------------------------------------------------------------
  -- IP to Bus data
  ---------------------------------------------------------------------------
  rpl_rdata <= reg_rdata when (reg_rvalid = '1')
               else i_mem_rdata when (mem_rvalid = '1' and use_mem_g)
               else (others => '0');

  ---------------------------------------------------------------------------
  -- Register read
  ---------------------------------------------------------------------------
  reg_rvalid <= '1' when ((axi_raddr_sel = '0') and (axi_fsm = axi_fsm_rd_data) and (axi_rready = '1') and (rpl_rready = '1')) else '0';

  b_rdreg : block
    signal rd_data_ext : t_aslv64(0 to num_reg_g + 1) := (others => (others => '0'));
  begin
    rd_data_ext(0 to i_reg_rdata'high) <= i_reg_rdata; -- extend number of registers to prevent indexing errors
    reg_rdata_proc : process(s_axi_aclk) is
    begin
      if rising_edge(s_axi_aclk) then
        reg_rdata(axi_data_width_g - 1 downto 0) <= rd_data_ext(to_integer(unsigned(axi_araddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW))));
      end if;
    end process reg_rdata_proc;
  end block;

  reg_rd_proc : process(s_axi_aclk) is
  begin
    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        reg_rd <= (others => '0');
      else
        reg_rd <= (others => '0');
        if (reg_rvalid = '1') then
          reg_rd(to_integer(unsigned(axi_araddr_last(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW)))) <= '1';
        end if;
      end if;
    end if;
  end process reg_rd_proc;

  o_reg_rd <= reg_rd;

  ---------------------------------------------------------------------------
  -- Register write
  ---------------------------------------------------------------------------
  reg_wr_proc : process(s_axi_aclk) is
  begin
    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        reg_wr <= (others => '0');
      else
        reg_wr <= (others => '0');
        if ((axi_waddr_sel = '0') and (axi_wready = '1')) then
          reg_wr(to_integer(unsigned(axi_awaddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW)))) <= '1';
        end if;
      end if;
    end if;
  end process reg_wr_proc;

  o_reg_wr <= reg_wr;

  slv_reg_wr_proc : process(s_axi_aclk) is
  begin
    if rising_edge(s_axi_aclk) then
      if (s_axi_aresetn = '0') then
        o_reg_wdata                  <= (others => (others => '0'));
        o_reg_wdata(rst_val_g'range) <= rst_val_g;
      else
        for reg_byte_index in 0 to axi_byte_width_g - 1 loop
          if ((axi_waddr_sel = '0') and (axi_wready = '1') and (s_axi_wstrb(reg_byte_index) = '1')) then
            o_reg_wdata(to_integer(unsigned(axi_awaddr(REG_ADDR_INDEX_HIGH downto REG_ADDR_INDEX_LOW))))(reg_byte_index * 8 + 7 downto reg_byte_index * 8) <= s_axi_wdata(reg_byte_index * 8 + 7 downto reg_byte_index * 8);
          end if;
        end loop;
      end if;
    end if;
  end process slv_reg_wr_proc;

  -----------------------------------------------------------------------------
  -- Memory read/write
  -----------------------------------------------------------------------------
  mem_rvalid <= '1' when ((axi_raddr_sel = '1') and (axi_fsm = axi_fsm_rd_data) and (axi_rready = '1') and (rpl_rready = '1')) else '0';
  g_mem : if use_mem_g generate
    o_mem_addr  <= std_logic_vector(axi_awaddr - MEM_ADDR_START) when (axi_waddr_sel = '1') else std_logic_vector(axi_araddr - MEM_ADDR_START);
    g_o_mem_wr : for reg_byte_index in 0 to axi_byte_width_g - 1 generate
      o_mem_wr(reg_byte_index) <= '1' when ((axi_waddr_sel = '1') and (axi_fsm = axi_fsm_wr_data) and (s_axi_wvalid = '1') and (s_axi_wstrb(reg_byte_index) = '1')) else '0';
    end generate;
    o_mem_wdata <= s_axi_wdata;
  end generate;
  g_nmem : if not use_mem_g generate
    o_mem_wr    <= (others => '0');
    o_mem_wdata <= (others => '0');
    o_mem_addr  <= (others => '0');
  end generate;

  -----------------------------------------------------------------------------
  -- R-Channel Pipeline Stage
  -----------------------------------------------------------------------------
  -- The logic (ported legacy code) does only assert RVALID after RREADY is present. This violates the AXI specification.
  -- By using a pipeline stage to decouple the logic from the bus, this problem can be solved (the PL stage always asserts READY).
  b_rplstage : block
    signal pl_in_data  : std_logic_vector(axi_id_width_g + axi_data_width_g + 3 - 1 downto 0);
    signal pl_out_data : std_logic_vector(pl_in_data'range);
  begin
    pl_in_data(axi_data_width_g - 1 downto 0)                                         <= rpl_rdata;
    pl_in_data(axi_data_width_g + 2 - 1 downto axi_data_width_g)                      <= rpl_rresp;
    pl_in_data(axi_data_width_g + 2)                                                  <= rpl_rlast;
    pl_in_data(axi_id_width_g + axi_data_width_g + 3 - 1 downto axi_data_width_g + 3) <= rpl_rid;

    i_rplstage : entity work.psi_common_pl_stage
      generic map(
        width_g => axi_id_width_g + axi_data_width_g + 3,
        use_rdy_g => true,
        rst_pol_g => '0'
      )
      port map(
        clk_i => s_axi_aclk,
        rst_i => s_axi_aresetn,
        vld_i => rpl_rvalid,
        rdy_o => rpl_rready,
        dat_i => pl_in_data,
        -- Output
        vld_o => s_axi_rvalid,
        rdy_i => s_axi_rready,
        dat_o => pl_out_data
      );

    s_axi_rdata <= pl_out_data(axi_data_width_g - 1 downto 0);
    s_axi_rresp <= pl_out_data(axi_data_width_g + 2 - 1 downto axi_data_width_g);
    s_axi_rlast <= pl_out_data(axi_data_width_g + 2);
    s_axi_rid   <= pl_out_data(axi_id_width_g + axi_data_width_g + 3 - 1 downto axi_data_width_g + 3);
  end block;

end architecture;