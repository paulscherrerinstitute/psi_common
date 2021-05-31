------------------------------------------------------------------------------
--  Copyright (c) 2020 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Benoit Stef
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This block allows to generate single pulses which are triggered by inputs
-- ramp cmd and according to the incmrenet that is fed at its input will rise 
-- within the "time specified" to its target level. The output will stay high
-- until a new ramp cmd occurs (pulse) and then it will go low accordingly. 
-- increment should be fed at the input.
-- A small state machine allows knowing in which state the pulse is see below:
--          
--  init   ____________     flat     init
--        /|          |\           |
--       / |          | \          |
-- _____/  |          |  \_________| 
--   00 |01|    11    |10| 11      | 00

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity psi_common_ramp_gene is
  generic(width_g   : natural   := 16;                          -- accumulator width
          is_sign_g : boolean   := false;                       -- sign / unsign
          rst_pol_g : std_logic := '1');                        -- polarity reset	
  port(clk_i      : in  std_logic;                              -- system clock
       rst_i      : in  std_logic;                              -- sync reset
       ---------------------------------------------------------
       str_i      : in  std_logic;                              -- strobe input
       tgt_lvl_i  : in  std_logic_vector(width_g - 1 downto 0); -- Target pulse level
       ramp_inc_i : in  std_logic_vector(width_g - 1 downto 0); -- steepness of the ramp (positive, also for ramping down)
       ramp_cmd_i : in  std_logic;                              -- start ramping
       init_cmd_i : in  std_logic;                              -- go to init whatever state
       ---------------------------------------------------------
       sts_o      : out std_logic_vector(1 downto 0);           -- FSM status
       str_o      : out std_logic;                              -- Pulse strobe output
       puls_o     : out std_logic_vector(width_g - 1 downto 0)  -- Pulse value
      );
end entity;

architecture rtl of psi_common_ramp_gene is
  --*** internal declaration ***
  type fsm_t is (zero, up, flat, dw);
  attribute enum_encoding : string;
  attribute enum_encoding of fsm_t : type is "00 01 11 10";
  -- record
  type two_process_t is record
    fsm_state : fsm_t;
    status    : std_logic_vector(1 downto 0);
    pulse     : unsigned(width_g downto 0);
    spulse    : signed(width_g downto 0);
    str_s     : std_logic;
  end record;
  --signals
  signal r, rin           : two_process_t;

begin

  proc_comb : process(r, ramp_inc_i, ramp_cmd_i, init_cmd_i, str_i, tgt_lvl_i)
    variable v : two_process_t;
  begin
    v := r;

    case r.fsm_state is

      when zero =>
        v.status := "00";
        -- *** pulse set to 0 ***
        v.pulse  := (others => '0');
        -- *** decision maker ::  states change ***
        if ramp_cmd_i = '1' and init_cmd_i = '0' then
          v.fsm_state := up;
        end if;

      when up =>
        v.status := "01";
        -- *** increase pulse :: accu ***
        if str_i = '1' then
          if not is_sign_g then
            v.pulse := r.pulse + resize(unsigned(ramp_inc_i), width_g + 1);
            if r.pulse(width_g downto 0) >= resize(unsigned(tgt_lvl_i) - unsigned(ramp_inc_i), width_g + 1) or
               (unsigned(tgt_lvl_i) <= unsigned(ramp_inc_i)) then
              v.fsm_state := flat;
              v.pulse     := resize(unsigned(tgt_lvl_i), width_g + 1);
            end if;
          else
            -- *** signed ***
             v.spulse := r.spulse + resize(signed(ramp_inc_i), width_g + 1);
            if r.spulse(width_g downto 0) >= resize(signed(tgt_lvl_i) - signed(ramp_inc_i), width_g + 1) or
               (signed(tgt_lvl_i) <= signed(ramp_inc_i)) then
              v.fsm_state := flat;
              v.spulse     := resize(signed(tgt_lvl_i), width_g + 1);
            end if;
          end if;
        end if;
        -- *** decision maker :: states change ***
        if init_cmd_i = '1' then
          v.fsm_state := zero;
        end if;

      when flat =>
        v.status := "11";
        -- *** decision maker :: states change ***
        if init_cmd_i = '1' then
          v.fsm_state := zero;
        elsif ramp_cmd_i = '1' then
          if not is_sign_g then
            if unsigned(tgt_lvl_i) > r.pulse then
              v.fsm_state := up;
            else
              v.fsm_state := dw;
            end if;
          else
            if signed(tgt_lvl_i) > r.spulse then
              v.fsm_state := up;
            else
              v.fsm_state := dw;
            end if;
          end if;
        end if;

      when dw =>
        v.status := "10";
        -- *** decrease pulse :: accu ***
        if str_i = '1' then
          if not is_sign_g then
            v.pulse := r.pulse - resize(unsigned(ramp_inc_i), width_g + 1);
            if r.pulse(width_g downto 0) <= resize((unsigned(tgt_lvl_i) + unsigned(ramp_inc_i)), width_g + 1) then
              v.fsm_state := flat;
              v.pulse     := resize(unsigned(tgt_lvl_i), width_g + 1);
            end if;
          else
            --*** is signed ***
           v.spulse := r.spulse - resize(signed(ramp_inc_i), width_g + 1);
            if r.spulse(width_g downto 0) <= resize((signed(tgt_lvl_i) + signed(ramp_inc_i)), width_g + 1) then
              v.fsm_state := flat;
              v.spulse    := resize(signed(tgt_lvl_i), width_g + 1);
            end if;
          end if;
        end if;
        -- *** decision maker :: states change ***
        if init_cmd_i = '1' then
          v.fsm_state := zero;
        end if;
    end case;

    --*** clock latency strobe *** 
    v.str_s := str_i;

    --*** v to r ***
    rin <= v;
  end process;

  proc_regs : process(clk_i)
  begin
    if rising_edge(clk_i) then
      r <= rin;
      --*** sync reset ***
      if rst_i = rst_pol_g then
        r.fsm_state <= zero;
        r.pulse     <= (others => '0');
        r.spulse    <= (others => '0');
        r.status    <= "00";
        r.str_s     <= '0';
      end if;
    end if;
  end process;

  --*** out mapping ***--
  str_o  <= r.str_s;
  sts_o  <= r.status;
  
  gen_output_usign : if not is_sign_g generate 
  begin
   puls_o <= std_logic_vector(r.pulse(width_g - 1 downto 0));
  end generate;

  gen_output_sign : if is_sign_g generate 
  begin
   puls_o <= std_logic_vector(r.spulse(width_g - 1 downto 0));
 end generate;
 
end architecture;
