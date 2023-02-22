------------------------------------------------------------------------------
--  Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This is a very basic clock crossing that allows passing of static-data
-- (i.e. data that is not sample based) from one clock domain to another. This
-- entity ensures that the data is passed correctly at some point of time but
-- it does not specify an exact sample point.
-- The main use cause of this entity is to pass status information or configuration
-- register values between clock domains.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_status_cc is
  generic(
    data_width_g : positive := 16
  );
  port(
    -- Clock Domain A
    a_clk_i    : in  std_logic;
    a_rst_i  : in  std_logic;
    a_rst_o : out std_logic;
    a_dat_i   : in  std_logic_vector(data_width_g - 1 downto 0);
    -- Clock Domain B
    b_clk_i    : in  std_logic;
    b_rst_i  : in  std_logic;
    b_rst_o : out std_logic;
    b_dat_o   : out std_logic_vector(data_width_g - 1 downto 0)
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_status_cc is
  signal RstIntA       : std_logic;
  signal RstIntB       : std_logic;
  signal Started       : std_logic;
  signal RstIntBSync   : std_logic_vector(1 downto 0);
  signal VldA          : std_logic;
  signal RecToggle     : std_logic;
  signal VldB          : std_logic;
  signal RecToggleSync : std_logic_vector(2 downto 0);

  attribute syn_srlstyle : string;
  attribute syn_srlstyle of RstIntBSync : signal is "registers";
  attribute syn_srlstyle of RecToggle : signal is "registers";
  attribute syn_srlstyle of RecToggleSync : signal is "registers";

  attribute shreg_extract : string;
  attribute shreg_extract of RstIntBSync : signal is "no";
  attribute shreg_extract of RecToggle : signal is "no";
  attribute shreg_extract of RecToggleSync : signal is "no";

  attribute ASYNC_REG : string;
  attribute ASYNC_REG of RstIntBSync : signal is "TRUE";
  attribute ASYNC_REG of RecToggle : signal is "TRUE";
  attribute ASYNC_REG of RecToggleSync : signal is "TRUE";

begin

  -- Valid pulse generation
  i_vldgen : process(a_clk_i)
  begin
    if rising_edge(a_clk_i) then
      if RstIntA = '1' then
        RstIntBSync   <= (others => '1');
        Started       <= '0';
        VldA          <= '0';
        RecToggleSync <= (others => '0');
      else
        -- default values
        VldA          <= '0';
        -- Synchronize signals of clock domain B
        RstIntBSync   <= RstIntBSync(RstIntBSync'left - 1 downto 0) & RstIntB;
        RecToggleSync <= RecToggleSync(RecToggleSync'left - 1 downto 0) & RecToggle;
        -- Generation of first vld pulse
        if (Started = '0') and (RstIntBSync(RstIntBSync'left) = '0') then
          VldA    <= '1';
          Started <= '1';
        end if;
        -- Send next value because other clockdomain received last data
        if RecToggleSync(RecToggleSync'left) /= RecToggleSync(RecToggleSync'left - 1) then
          VldA <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Reception detection
  i_recdet : process(b_clk_i)
  begin
    if rising_edge(b_clk_i) then
      if RstIntB = '1' then
        RecToggle <= '0';
      else
        if VldB = '1' then
          RecToggle <= not RecToggle;
        end if;
      end if;
    end if;
  end process;

  -- instantiation of simple CC
  i_scc : entity work.psi_common_simple_cc
    generic map(
      data_width_g => data_width_g
    )
    port map(
      a_clk_i    => a_clk_i,
      a_rst_i  => a_rst_i,
      a_rst_o => RstIntA,
      a_dat_i   => a_dat_i,
      a_vld_i    => VldA,
      b_clk_i    => b_clk_i,
      b_rst_i  => b_rst_i,
      b_rst_o => RstIntB,
      b_dat_o   => b_dat_o,
      b_vld_o    => VldB
    );
  a_rst_o <= RstIntA;
  b_rst_o <= RstIntB;

end;

