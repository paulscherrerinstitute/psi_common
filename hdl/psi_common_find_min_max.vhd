------------------------------------------------------------------------------
--  Copyright (c) 2021 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This simple component extracts the min or the max from data input stream,
-- the RAZ signal allows to generate the min || max value prior this signal
-- is set to 1. Output is one clock cycle delayed with a strobe 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--@formatter:off
entity psi_common_find_min_max is
  generic(rst_pol_g : std_logic := '0';                            --rst pol select
          length_g  : natural   := 16;                             --data lenght
          signed_g  : boolean   := true;                           --signed/unsigned
          mode_g    : string    := "MIN");                         --mode select
  port(   clk_i     : in  std_logic;                               --clock
          rst_i     : in  std_logic;                               --sync reset
          str_i     : in  std_logic;                               --strobe in
          raz_i     : in  std_logic;                               --reset  output
          dat_i     : in  std_logic_vector(length_g - 1 downto 0); --data input
          str_o     : out std_logic;                               --strobe output
          dat_o     : out std_logic_vector(length_g - 1 downto 0); --data output
          run_dat_o : out std_logic_vector(length_g - 1 downto 0); --data output running
          run_str_o : out std_logic
      );
end entity;
--@formatter:on
architecture rtl of psi_common_find_min_max is
  signal data_s    : std_logic_vector(length_g - 1 downto 0) := (others => '0');
  signal raz_dff_s : std_logic                               := '0';
  signal str_s     : std_logic;
begin

  proc_min_max : process(clk_i)
  begin
    if rising_edge(clk_i) then
      if rst_i = rst_pol_g then
        raz_dff_s <= '0';
        data_s    <= (others => '0');
        dat_o    <= (others => '0');
      else
        str_s<= str_i;
        raz_dff_s <= raz_i;

        if raz_i = '1' and raz_dff_s = '0' then
          dat_o <= data_s;
          str_o  <= '1';
        else
          str_o <= '0';
        end if;

        --*** reset value edge detect ***
        if raz_i = '1' and raz_dff_s = '0' then
          data_s <= dat_i;
        else
          if str_i = '1' then
            if mode_g = "MIN" and signed_g then
              if signed(dat_i) <= signed(data_s) then
                data_s <= dat_i;
              end if;
            elsif mode_g = "MIN" and signed_g = false then
              if unsigned(dat_i) <= unsigned(data_s) then
                data_s <= dat_i;
              end if;
            elsif mode_g = "MAX" and signed_g then
              if signed(dat_i) >= signed(data_s) then
                data_s <= dat_i;
              end if;
            else
              if unsigned(dat_i) >= unsigned(data_s) then
                data_s <= dat_i;
              end if;
            end if;
          end if;
        end if;
        
        --*** running output ***
        run_dat_o <= data_s ;
        run_str_o <= str_s;

      end if;
    end if;
  end process;

end architecture;