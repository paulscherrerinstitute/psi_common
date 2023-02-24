----------------------------------------------------------------------------------
-- Copyright (c) 2018 by Paul Scherrer Institute, Switzerland
-- All rights reserved.
-- Authors: Rafael Basso
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Description: 
----------------------------------------------------------------------------------
-- A generic pseudo random binary sequence based on a linear-feedback shifter
-- register.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity psi_common_prbs is
  generic(width_g   : natural range 2 to 32 := 8; -- I/O data width
          rst_pol_g : std_logic             := '1' -- Reset polarity
         );
  port(rst_i  : in  std_logic;          -- Input reset
       clk_i  : in  std_logic;          -- Input clock
       strb_i : in  std_logic;          -- Input strobe
       seed_i : in  std_logic_vector((width_g - 1) downto 0); -- Input seed
       strb_o : out std_logic;          -- Output strobe
       data_o : out std_logic_vector((width_g - 1) downto 0) -- Output data
      );
end psi_common_prbs;

architecture behav of psi_common_prbs is
  type poly_t is array (2 to 32) of std_logic_vector(31 downto 0);
  -- MASK 
  constant poly_c   : poly_t                                   := (
    x"00000003",                        --PRBS2 	00000000000000000000000000000011
    x"00000006",                        --PRBS3 	00000000000000000000000000000110
    x"0000000C",                        --PRBS4 	00000000000000000000000000001100
    x"00000014",                        --PRBS5 	00000000000000000000000000010100
    x"00000030",                        --PRBS6 	00000000000000000000000000110000
    x"00000060",                        --PRBS7 	00000000000000000000000001100000
    x"000000B8",                        --PRBS8 	00000000000000000000000010111000
    x"00000110",                        --PRBS9 	00000000000000000000000100010000
    x"00000240",                        --PRBS10	00000000000000000000001001000000
    x"00000500",                        --PRBS11	00000000000000000000010100000000
    x"00000829",                        --PRBS12	00000000000000000000100000101001
    x"0000100D",                        --PRBS13	00000000000000000001000000001101
    x"00002015",                        --PRBS14	00000000000000000010000000010101
    x"00006000",                        --PRBS15	00000000000000000110000000000000
    x"0000D008",                        --PRBS16	00000000000000001101000000001000
    x"00012000",                        --PRBS17	00000000000000010010000000000000
    x"00020400",                        --PRBS18	00000000000000100000010000000000
    x"00040023",                        --PRBS19	00000000000001000000000000100011
    x"00090000",                        --PRBS20	00000000000010010000000000000000
    x"00140000",                        --PRBS21	00000000000101000000000000000000
    x"00300000",                        --PRBS22	00000000001100000000000000000000
    x"00420000",                        --PRBS23	00000000010000100000000000000000
    x"00E10000",                        --PRBS24	00000000111000010000000000000000
    x"01200000",                        --PRBS25	00000001001000000000000000000000
    x"02000023",                        --PRBS26	00000010000000000000000000100011
    x"04000013",                        --PRBS27	00000100000000000000000000010011
    x"09000000",                        --PRBS28	00001001000000000000000000000000
    x"14000000",                        --PRBS29	00010100000000000000000000000000
    x"20000029",                        --PRBS30	00100000000000000000000000101001
    x"48000000",                        --PRBS31	01001000000000000000000000000000
    x"80200003"                         --PRBS32	10000000001000000000000000000011
  );
  -- Constants
  constant mask_c   : std_logic_vector((width_g - 1) downto 0) := poly_c(width_g)((width_g - 1) downto 0);
  -- Signals
  signal d0_s       : std_logic                                := '0';
  signal q_s        : std_logic_vector((width_g - 1) downto 0) := (others => '0');
  signal q_masked_s : std_logic_vector((width_g - 1) downto 0) := (others => '0');
begin

  data_o <= q_s;

  q_masked_s <= mask_c and q_s;
  d0_s       <= xor q_masked_s;         -- 2008 syntax

  p_lfsr : process(clk_i)
  begin
    if (rising_edge(clk_i)) then
      if (rst_i = rst_pol_g) then
        q_s    <= seed_i;
        strb_o <= '0';
      else
        if (strb_i = '1') then
          q_s <= q_s((width_g - 2) downto 0) & d0_s;
        end if;
        strb_o <= strb_i;
      end if;
    end if;
  end process;

end architecture;
