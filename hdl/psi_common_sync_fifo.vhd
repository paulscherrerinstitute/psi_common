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

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.psi_common_math_pkg.all;

------------------------------------------------------------------------------
-- Entity Declaration
------------------------------------------------------------------------------
entity psi_common_sync_fifo is
  generic(
    Width_g         : positive  := 16;
    Depth_g         : positive  := 32;
    AlmFullOn_g     : boolean   := false;
    AlmFullLevel_g  : natural   := 28;
    AlmEmptyOn_g    : boolean   := false;
    AlmEmptyLevel_g : natural   := 4;
    RamStyle_g      : string    := "auto";
    RamBehavior_g   : string    := "RBW"; -- "RBW" = read-before-write, "WBR" = write-before-read
    RdyRstState_g   : std_logic := '1'  -- Use '1' for minimal logic on Rdy path
  );
  port(
    -- Control Ports
    Clk      : in  std_logic;
    Rst      : in  std_logic;
    -- Input Data
    InData   : in  std_logic_vector(Width_g - 1 downto 0);
    InVld    : in  std_logic;
    InRdy    : out std_logic;           -- not full

    -- Output Data
    OutData  : out std_logic_vector(Width_g - 1 downto 0);
    OutVld   : out std_logic;           -- not empty
    OutRdy   : in  std_logic;
    -- Input Status
    Full     : out std_logic;
    AlmFull  : out std_logic;
    InLevel  : out std_logic_vector(log2ceil(Depth_g + 1) - 1 downto 0);
    -- Output Status
    Empty    : out std_logic;
    AlmEmpty : out std_logic;
    OutLevel : out std_logic_vector(log2ceil(Depth_g + 1) - 1 downto 0);
  );
end entity;

------------------------------------------------------------------------------
-- Architecture Declaration
------------------------------------------------------------------------------
architecture rtl of psi_common_sync_fifo is

  type two_process_r is record
    WrLevel : std_logic_vector(InLevel'range);
    RdLevel : std_logic_vector(OutLevel'range);
    RdUp    : std_logic;
    WrDown  : std_logic;
    WrAddr  : std_logic_vector(log2ceil(Depth_g) - 1 downto 0);
    RdAddr  : std_logic_vector(log2ceil(Depth_g) - 1 downto 0);
  end record;

  signal r, r_next : two_process_r;

  signal RamWr     : std_logic;
  signal RamRdAddr : std_logic_vector(log2ceil(Depth_g) - 1 downto 0);

begin

  --------------------------------------------------------------------------
  -- Combinatorial Process
  --------------------------------------------------------------------------
  p_comb : process(InVld, OutRdy, Rst, r)
    variable v : two_process_r;
  begin
    -- hold variables stable
    v := r;

    -- Write side
    v.RdUp := '0';
    RamWr  <= '0';
    if unsigned(r.WrLevel) /= Depth_g and InVld = '1' then
      if unsigned(r.WrAddr) /= Depth_g - 1 then
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
    if unsigned(r.WrLevel) = Depth_g then
      InRdy <= '0';
      Full  <= '1';
    else
      InRdy <= '1';
      Full  <= '0';
    end if;
    -- Artificially keep InRdy low during reset if required
    if (RdyRstState_g = '0') and (Rst = '1') then
      InRdy <= '0';
    end if;

    if AlmFullOn_g and unsigned(r.WrLevel) >= AlmFullLevel_g then
      AlmFull <= '1';
    else
      AlmFull <= '0';
    end if;

    -- Read side
    v.WrDown  := '0';
    if unsigned(r.RdLevel) /= 0 and OutRdy = '1' then
      if unsigned(r.RdAddr) /= Depth_g - 1 then
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
    if unsigned(r.RdLevel) = 0 then
      OutVld <= '0';
      Empty  <= '1';
    else
      OutVld <= '1';
      Empty  <= '0';
    end if;

    if AlmEmptyOn_g and unsigned(r.RdLevel) <= AlmEmptyLevel_g then
      AlmEmpty <= '1';
    else
      AlmEmpty <= '0';
    end if;

    -- Assign signal
    r_next <= v;

  end process;

  -- Synchronous Outputs
  OutLevel <= r.RdLevel;
  InLevel  <= r.WrLevel;

  --------------------------------------------------------------------------
  -- Sequential
  --------------------------------------------------------------------------
  p_seq : process(Clk)
  begin
    if rising_edge(Clk) then
      r <= r_next;
      if Rst = '1' then
        r.WrLevel <= (others => '0');
        r.RdLevel <= (others => '0');
        r.RdUp    <= '0';
        r.WrDown  <= '0';
        r.WrAddr  <= (others => '0');
        r.RdAddr  <= (others => '0');
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- Component Instantiations
  --------------------------------------------------------------------------
  i_ram : entity work.psi_common_sdp_ram
    generic map(
      Depth_g    => Depth_g,
      Width_g    => Width_g,
      RamStyle_g => RamStyle_g,
      Behavior_g => RamBehavior_g
    )
    port map(
      Clk    => Clk,
      WrAddr => r.WrAddr,
      Wr     => RamWr,
      WrData => InData,
      RdAddr => RamRdAddr,
      RdData => OutData
    );

end;

