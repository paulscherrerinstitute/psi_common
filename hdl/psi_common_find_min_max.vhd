------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoît Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This simple component extracts the min or the max from data input stream,
-- the RAZ signal allows to generate the min || max value prior this signal
-- is set to 1. Output is one clock cycle delayed with a strobe 

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--@formater:off
entity psi_common_find_min_max is
  generic(rst_pol_g : std_logic := '0';                            --rst pol select
          length_g  : natural   := 16;                             --data lenght
          signed_g  : boolean   := true;                           --signed/unsigned
          mode_g    : string    := "MIN");                         --mode select
  port(   clk_i     : in  std_logic;                               --clock
          rst_i     : in  std_logic;                               --sync reset
          str_i     : in  std_logic;                               --strobe in
          raz_i     : in  std_logic;                               --reset  output
          data_i    : in  std_logic_vector(length_g - 1 downto 0); --data input
          str_o     : out std_logic;                               --strobe output
          data_o    : out std_logic_vector(length_g - 1 downto 0)  --data output
      );
end entity;
--@formater:on
architecture rtl of psi_common_find_min_max is
  signal data_s    : std_logic_vector(length_g - 1 downto 0) := (others => '0');
  signal raz_dff_s : std_logic                               := '0';

begin

  proc_min_max : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        raz_dff_s <= '0';
        data_s    <= (others => '0');
        data_o    <= (others => '0');
      else

        raz_dff_s <= raz_i;

        if raz_i = '1' and raz_dff_s = '0' then
          data_o <= data_s;
          str_o  <= '1';
        else
          str_o <= '0';
        end if;

        --*** reset value edge detect ***
        if raz_i = '1' and raz_dff_s = '0' then
          data_s <= data_i;
        else
          if str_i = '1' then
            if mode_g = "MIN" and signed_g then
              if signed(data_i) <= signed(data_s) then
                data_s <= data_i;
              end if;
            elsif mode_g = "MIN" and signed_g = false then
              if unsigned(data_i) <= unsigned(data_s) then
                data_s <= data_i;
              end if;
            elsif mode_g = "MAX" and signed_g then
              if signed(data_i) >= signed(data_s) then
                data_s <= data_i;
              end if;
            else
              if unsigned(data_i) >= unsigned(data_s) then
                data_s <= data_i;
              end if;
            end if;
          end if;
        end if;

      end if;
    end if;
  end process;

end architecture;
