------------------------------------------------------------------------------
--	Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
--	All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a simple data-width conversion. The output width
-- must be an integer multiple of the input width (Wo = n*Wi)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.psi_common_math_pkg.all;
use work.psi_common_logic_pkg.all;

-- @formatter:off
entity psi_common_wconv_n2xn is
  generic( width_in_g  : natural;                                         -- input length vector
           width_out_g : natural;                                         -- output length vector
           rst_pol_g   : std_logic := '1');                               -- '1' active high, '0' active low
  port   ( clk_i       : in  std_logic;                                     -- system clock
           rst_i       : in  std_logic;                                     -- system reset
           vld_i       : in  std_logic;                                     -- AXI-S handshaking valid signal
           rdy_o       : out std_logic;                                     -- AXI-S handshaking ready signal output to push back stream
           dat_i       : in  std_logic_vector(width_in_g - 1 downto 0);     -- data input
           last_i      : in  std_logic := '0';                              -- AXI-S handshaking last signal
           vld_o       : out std_logic;                                     -- AXI-S handshaking valid signal
           rdy_i       : in  std_logic := '1';                              -- AXI-S handshaking ready signal input from next block
           dat_o       : out std_logic_vector(width_out_g - 1 downto 0);    -- data output
           last_o      : out std_logic;                                     -- AXI-S handshaking last signal
           we_o        : out std_logic_vector(width_out_g / width_in_g - 1 downto 0)); -- Output word-enable. Works like byte-enable but with one bit per input-word. All bits in this signal are set, exept for with conversion results flushed  out by *last_i='1'*. In this case, the *we_o* bits indicate wich *dat_o* bits contain valid data.
end entity;
-- @formatter:on

architecture rtl of psi_common_wconv_n2xn is

  -- *** Constants ***
  constant RatioReal_c : real    := real(width_out_g) / real(width_in_g);
  constant RatioInt_c  : integer := integer(RatioReal_c);

  -- *** Two Process Method ***
  type two_process_r is record
    DataVld  : std_logic_vector(RatioInt_c - 1 downto 0);
    Data     : std_logic_vector(width_out_g - 1 downto 0);
    DataLast : std_logic;
    vld_o    : std_logic;
    dat_o    : std_logic_vector(width_out_g - 1 downto 0);
    last_o   : std_logic;
    we_o     : std_logic_vector(RatioInt_c - 1 downto 0);
    Cnt      : integer range 0 to RatioInt_c;
  end record;
  signal r, r_next : two_process_r;

begin
  assert floor(RatioReal_c) = ceil(RatioReal_c) report "psi_common_wconv_n2xn: Ratio width_out_g/width_in_g must be an integer number" severity error;

  p_comb : process(r, vld_i, dat_i, rdy_i, last_i)
    variable v           : two_process_r;
    variable IsStuck_v   : std_logic;
    variable ShiftDone_v : boolean;
  begin
    -- *** hold variables stable ***
    v := r;

    -- Halt detection
    ShiftDone_v := (r.DataVld(r.DataVld'high) = '1') or (r.DataLast = '1');
    if ShiftDone_v and (r.vld_o = '1') and (rdy_i = '0') then
      IsStuck_v := '1';
    else
      IsStuck_v := '0';
    end if;

    -- Reset OutVld when transfer occured
    if (r.vld_o = '1') and (rdy_i = '1') then
      v.vld_o := '0';
    end if;

    -- Data Deserialization
    if ShiftDone_v and ((r.vld_o = '0') or (rdy_i = '1')) then
      v.vld_o    := '1';
      v.dat_o    := r.Data;
      v.last_o   := r.DataLast;
      v.we_o     := r.DataVld;
      v.DataVld  := (others => '0');
      v.DataLast := '0';
    end if;
    if vld_i = '1' and IsStuck_v = '0' then
      v.Data((r.Cnt + 1) * width_in_g - 1 downto r.Cnt * width_in_g) := dat_i;
      v.DataVld(r.Cnt)                                               := '1';
      if last_i = '1' then
        v.DataLast := '1';
      end if;
      if (r.Cnt = RatioInt_c - 1) or (last_i = '1') then
        v.Cnt := 0;
      else
        v.Cnt := r.Cnt + 1;
      end if;
    end if;

    -- Outputs
    rdy_o <= not IsStuck_v;
    vld_o    <= r.vld_o;
    dat_o    <= r.dat_o;
    last_o   <= r.last_o;
    we_o     <= r.we_o;

    -- *** assign signal ***
    r_next <= v;
  end process;

  p_seq : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= r_next;
      if rst_i = rst_pol_g then
        r.DataVld  <= (others => '0');
        r.vld_o    <= '0';
        r.Cnt      <= 0;
        r.DataLast <= '0';
      end if;
    end if;
  end process;

end architecture;
