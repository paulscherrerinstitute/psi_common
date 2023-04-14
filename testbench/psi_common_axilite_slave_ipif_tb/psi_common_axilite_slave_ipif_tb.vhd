------------------------------------------------------------
-- Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
-- Copyright (c) 2020 by Enclustra GmbH, Switzerland
-- All rights reserved.
------------------------------------------------------------

------------------------------------------------------------
-- Testbench generated by TbGen.py
------------------------------------------------------------
-- see Library/Python/TbGenerator

-- NOTE: The testbench is not very detailed since the code tested
--       is legacy code that worked on hardware for years and hence
--       functionality seems to be generally correct.

------------------------------------------------------------
-- Libraries
------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.psi_common_array_pkg.all;
    use work.psi_common_math_pkg.all;
    use work.psi_common_logic_pkg.all;

library work;
    use work.psi_tb_txt_util.all;
    use work.psi_tb_compare_pkg.all;
    use work.psi_tb_activity_pkg.all;
    use work.psi_tb_axi_pkg.all;

------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------
entity psi_common_axilite_slave_ipif_tb is
    generic (
        num_reg_g : positive := 32;
        use_mem_g : boolean := true
    );
end entity;

------------------------------------------------------------
-- Architecture
------------------------------------------------------------
architecture sim of psi_common_axilite_slave_ipif_tb is
    -- *** Fixed Generics ***
    constant rst_val_g : t_aslv32 := (X"0001ABCD", X"00021234");
    
    -- *** Not Assigned Generics (default values) ***
    constant AxiIdWidth_g : integer := 1 ;
    constant axi_addr_width_g : integer := 8;
    
    -------------------------------------------------------------------------
    -- AXI Definition
    -------------------------------------------------------------------------
    constant ID_WIDTH       : integer   := AxiIdWidth_g;
    constant ADDR_WIDTH     : integer   := axi_addr_width_g;
    constant USER_WIDTH     : integer   := 1;
    constant DATA_WIDTH     : integer   := 32;
    constant BYTE_WIDTH     : integer   := DATA_WIDTH/8;
    
    subtype ID_RANGE is natural range ID_WIDTH-1 downto 0;
    subtype ADDR_RANGE is natural range ADDR_WIDTH-1 downto 0;
    subtype USER_RANGE is natural range USER_WIDTH-1 downto 0;
    subtype DATA_RANGE is natural range DATA_WIDTH-1 downto 0;
    subtype BYTE_RANGE is natural range BYTE_WIDTH-1 downto 0;
    
    signal axi_ms : axi_ms_r (  arid(ID_RANGE), awid(ID_RANGE),
                                araddr(ADDR_RANGE), awaddr(ADDR_RANGE),
                                aruser(USER_RANGE), awuser(USER_RANGE), wuser(USER_RANGE),
                                wdata(DATA_RANGE),
                                wstrb(BYTE_RANGE));
    
    signal axi_sm : axi_sm_r (  rid(ID_RANGE), bid(ID_RANGE),
                                ruser(USER_RANGE), buser(USER_RANGE),
                                rdata(DATA_RANGE));     
    
    -- *** TB Control ***
    signal TbRunning : boolean := True;
    signal NextCase : integer := -1;
    signal ProcessDone : std_logic_vector(0 to 1) := (others => '0');
    constant AllProcessesDone_c : std_logic_vector(0 to 1) := (others => '1');
    constant TbProcNr_axi_c : integer := 0;
    constant TbProcNr_ip_c : integer := 1;
    signal TestCase : integer := -1;
    signal CaseDone : integer := -1;    
    
    -- *** DUT Signals ***
    signal s_axi_aclk : std_logic := '1';
    signal s_axi_aresetn : std_logic := '0';
    signal o_reg_rd : std_logic_vector(num_reg_g-1 downto 0) := (others => '0');
    signal i_reg_rdata : t_aslv32(0 to num_reg_g-1) := (others => (others => '0'));
    signal o_reg_wr : std_logic_vector(num_reg_g-1 downto 0) := (others => '0');
    signal o_reg_wdata : t_aslv32(0 to num_reg_g-1) := (others => (others => '0'));
    signal o_mem_addr : std_logic_vector(axi_addr_width_g - 1 downto 0) := (others => '0');
    signal o_mem_wr : std_logic_vector(3 downto 0) := (others => '0');
    signal o_mem_wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal i_mem_rdata : std_logic_vector(31 downto 0) := (others => '0');
    
    procedure WaitCase(nr : integer) is
    begin
        while TestCase /= nr loop
            wait until rising_edge(s_axi_aclk);
        end loop;
    end procedure;
    
    procedure WaitDone(nr : integer) is
    begin
        while CaseDone /= nr loop
            wait until rising_edge(s_axi_aclk);
        end loop;
    end procedure;  
    
begin
    ------------------------------------------------------------
    -- DUT Instantiation
    ------------------------------------------------------------
    
    -- Hardwire AXI signals that are not present in axilite
    axi_sm.rlast <= '1';
    
    i_dut : entity work.psi_common_axilite_slave_ipif
        generic map (
            num_reg_g => num_reg_g,
            use_mem_g => use_mem_g,
            rst_val_g => rst_val_g
        )
        port map (
            s_axilite_aclk => s_axi_aclk,
            s_axilite_aresetn => s_axi_aresetn,
            s_axilite_araddr => axi_ms.araddr,
            s_axilite_arvalid => axi_ms.arvalid,
            s_axilite_arready => axi_sm.arready,
            s_axilite_rdata => axi_sm.rdata,
            s_axilite_rresp => axi_sm.rresp,
            s_axilite_rvalid => axi_sm.rvalid,
            s_axilite_rready => axi_ms.rready,
            s_axilite_awaddr => axi_ms.awaddr,
            s_axilite_awvalid => axi_ms.awvalid,
            s_axilite_awready => axi_sm.awready,
            s_axilite_wdata => axi_ms.wdata,
            s_axilite_wstrb => axi_ms.wstrb,
            s_axilite_wvalid => axi_ms.wvalid,
            s_axilite_wready => axi_sm.wready,
            s_axilite_bresp => axi_sm.bresp,
            s_axilite_bvalid => axi_sm.bvalid,
            s_axilite_bready => axi_ms.bready,
            o_reg_rd => o_reg_rd,
            i_reg_rdata => i_reg_rdata,
            o_reg_wr => o_reg_wr,
            o_reg_wdata => o_reg_wdata,
            o_mem_addr => o_mem_addr,
            o_mem_wr => o_mem_wr,
            o_mem_wdata => o_mem_wdata,
            i_mem_rdata => i_mem_rdata
        );
    
    ------------------------------------------------------------
    -- Testbench Control !DO NOT EDIT!
    ------------------------------------------------------------
    p_tb_control : process
    begin
        wait until s_axi_aresetn = '1';
        wait until ProcessDone = AllProcessesDone_c;
        TbRunning <= false;
        wait;
    end process;
    
    ------------------------------------------------------------
    -- Clocks !DO NOT EDIT!
    ------------------------------------------------------------
    p_clock_s_axi_aclk : process
        constant Frequency_c : real := real(100e6);
    begin
        while TbRunning loop
            wait for 0.5*(1 sec)/Frequency_c;
            s_axi_aclk <= not s_axi_aclk;
        end loop;
        wait;
    end process;
    
    
    ------------------------------------------------------------
    -- Resets
    ------------------------------------------------------------
    p_rst_s_axi_aresetn : process
    begin
        wait for 1 us;
        -- Wait for two clk edges to ensure reset is active for at least one edge
        wait until rising_edge(s_axi_aclk);
        wait until rising_edge(s_axi_aclk);
        s_axi_aresetn <= '1';
        wait;
    end process;
    
    
    ------------------------------------------------------------
    -- Processes
    ------------------------------------------------------------
    -- *** axi ***
    p_axi : process
    begin
        axi_master_init(axi_ms);
        
        -- start of process !DO NOT EDIT
        wait until s_axi_aresetn = '1';
        
        -- *** Test Reset Behavior ***
        print(">> Reset Behavior");
        TestCase <= 0;
        WaitDone(0);
        
        -- *** Test Single Read/Write to Registers ***
        if num_reg_g > 0 then
            print(">> Single Read/Write to Registers");
            TestCase <= 1;
            -- write
            axi_single_write(4*1, 16#1234ABCD#, axi_ms, axi_sm, s_axi_aclk);
            -- read
            axi_single_expect(4*1, 16#66665555#, axi_ms, axi_sm, s_axi_aclk);
            WaitDone(1);
        end if;

        -- *** Test Single Read/Write to Memory ***
        print(">> Single Read/Write to Memory");    
        TestCase <= 2;      
        if use_mem_g then            
            -- write
            axi_single_write(4*(num_reg_g+1), 16#11112222#, axi_ms, axi_sm, s_axi_aclk);
            -- read
            axi_single_expect(4*(num_reg_g+3), 16#33334444#, axi_ms, axi_sm, s_axi_aclk);
        else
            -- write
            axi_apply_aw(4*(num_reg_g+1), AxSIZE_4_c, 1-1, xBURST_INCR_c, axi_ms, axi_sm, s_axi_aclk);
            axi_apply_wd_single(X"ABCD1234", X"F", axi_ms, axi_sm, s_axi_aclk);
            axi_expect_bresp(xRESP_DECERR_c, axi_ms, axi_sm, s_axi_aclk);
            -- read 
            axi_apply_ar(4*(num_reg_g+1), AxSIZE_4_c, 1-1, xBURST_INCR_c, axi_ms, axi_sm, s_axi_aclk);
            axi_expect_rresp_single(X"00000000", xRESP_DECERR_c, axi_ms, axi_sm, s_axi_aclk, IgnoreData=>true);
        end if;
        WaitDone(2);
        
        -- end of process !DO NOT EDIT!
        ProcessDone(TbProcNr_axi_c) <= '1';
        wait;
    end process;
    
    -- *** ip ***
    p_ip : process
        variable StartTime_v : time;
        variable RecWords_v  : std_logic_vector(3 downto 0);
        variable MemWord_v   : integer;
    begin
        -- start of process !DO NOT EDIT
        wait until s_axi_aresetn = '1';
        
        -- *** Test Reset Behavior ***      
        WaitCase(0);
        if num_reg_g > 0 then
            StdlvCompareStdlv(X"0001ABCD", o_reg_wdata(0), "Wrong reset data [0]");
            StdlvCompareStdlv(X"00021234", o_reg_wdata(1), "Wrong reset data [1]");
            StdlvCompareStdlv(X"00000000", o_reg_wdata(2), "Wrong reset data [2]");
            StdlvCompareStdlv(X"00000000", o_reg_wdata(3), "Wrong reset data [3]");
        end if;
        if use_mem_g then
            StdlvCompareStdlv("0000", o_mem_wr, "Wrong reset o_mem_wr");
        end if;
        CaseDone <= 0;
        
        -- *** Test Single Read/Write to Registers ***
        if num_reg_g > 0 then
            WaitCase(1);
            i_reg_rdata(1) <= X"66665555";
            WaitForValueStdl(o_reg_wr(1), '1', 1 us, "Write did not arrive");
            StdlvCompareStdlv(X"1234ABCD", o_reg_wdata(1), "Wrong reset data [1]");
            WaitForValueStdl(o_reg_rd(1), '1', 1 us, "Read did not arrive");
            CaseDone <= 1;
        end if;
        
        -- *** Test Single Read/Write to Memory ***     
        WaitCase(2);
        if use_mem_g then
            wait until rising_edge(s_axi_aclk) and o_mem_wr = "1111" for 1 us;
            StdlvCompareStdlv("1111", o_mem_wr, "Write did not arrive");
            StdlvCompareStdlv(X"11112222", o_mem_wdata, "Received wrong data");
            StdlvCompareInt(1*4, o_mem_addr, "Wrong write address");
            wait until rising_edge(s_axi_aclk) and unsigned(o_mem_addr) = 3*4 for 1 us;
            wait until falling_edge(s_axi_aclk);
            i_mem_rdata <= X"33334444";
            wait until rising_edge(s_axi_aclk);
            i_mem_rdata <= (others => '0');
        end if;
        CaseDone <= 2;      
        
        -- end of process !DO NOT EDIT!
        ProcessDone(TbProcNr_ip_c) <= '1';
        wait;
    end process;
    
    
end;
