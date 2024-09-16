library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity psi_common_sample_rate_converter_tb is
end entity psi_common_sample_rate_converter_tb;

architecture tb of psi_common_sample_rate_converter_tb is

  -- Constants
  constant CLK_PERIOD_c        : time                                    := 4 ns; -- 250 MHz clock period
  constant SAMPLE_RATE_c       : real                                    := 250.0e6; -- 250 MHz sample rate
  constant SIGNAL_FREQ_c       : real                                    := 1.0e6; -- 1 MHz sine wave frequency
  constant DOWNSAMPLE_RATE_c   : integer                                 := 512; -- Downsampling rate
  constant UP_SAMPLING_RATE_c  : integer                                 := 8;
  constant NUM_INPUT_SAMPLES_c : integer                                 := 10000; -- Number of input samples
  constant LENGTH_c            : integer                                 := 16; -- slv size
  -- Testbench signals
  signal clk_i                 : std_logic                               := '0';
  signal rst_i                 : std_logic                               := '0';
  signal vld_i                 : std_logic                               := '0';
  signal dat_i                 : std_logic_vector(LENGTH_c - 1 downto 0) := (others => '0');
  signal dat_o                 : std_logic_vector(LENGTH_c - 1 downto 0) := (others => 'L');
  signal vld_o                 : std_logic                               := 'L';

  -- Variables for sine wave generation and self-test
  signal sine_wave      : real    := 0.0;
  signal sample_count   : integer := 0;
  signal valid_count    : integer := 0; -- To count valid input samples
  signal validup_count  : integer := 0;
  signal expected_count : integer := 0;
  signal count_ok       : boolean := true;
  signal countup_ok     : boolean := true;
  signal datup_o        : std_logic_vector(LENGTH_c - 1 downto 0);
  signal vldup_o        : std_logic;
  signal tb_run         : boolean := true;
begin

  -- Clock generation process
  clk_proc : process
  begin
    while tb_run loop
      clk_i <= '0';
      wait for CLK_PERIOD_c / 2;
      clk_i <= '1';
      wait for CLK_PERIOD_c / 2;
    end loop;
    wait;
  end process;

  -- Sine wave generation and signal application
  stim_proc : process
    variable t : real := 0.0;           -- Time variable in seconds
  begin
    rst_i <= '1';
    wait for 10 * CLK_PERIOD_c;
    rst_i <= '0';

    vld_i <= '1';
    wait for CLK_PERIOD_c;

    while sample_count < 10000 loop     -- Generate 10000 samples
      t            := real(sample_count + 1) / SAMPLE_RATE_c;
      sine_wave    <= sin(2.0 * math_pi * SIGNAL_FREQ_c * t);
      dat_i        <= std_logic_vector(to_signed(integer(2.0**(LENGTH_c - 1) * sine_wave), LENGTH_c)); -- 16-bit signed output
      wait for CLK_PERIOD_c;
      sample_count <= sample_count + 1;
    end loop;

    -- Finish simulation
    wait for 100 * CLK_PERIOD_c;
    tb_run <= false;
    report "###INFO: End of simulation";
    wait;
  end process;

  -- Instantiate the SampleRateConverter
  dut_dw_inst : entity work.psi_common_sample_rate_converter
    generic map(
      RATE_g               => DOWNSAMPLE_RATE_c, -- Downsampling rate
      MODE_g               => "DOWN",   -- Downsampling mode
      length_g             => LENGTH_c,
      clk_to_vld_ratio_g => 1)
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      vld_i => vld_i,
      dat_i => dat_i,
      dat_o => dat_o,
      vld_o => vld_o
    );

  dut_up_inst : entity work.psi_common_sample_rate_converter
    generic map(
      RATE_g               => UP_SAMPLING_RATE_c, -- UP sample rate
      MODE_g               => "UP",     --Upsampling mode
      length_g             => LENGTH_c,
      clk_to_vld_ratio_g => DOWNSAMPLE_RATE_c
    )
    port map(
      clk_i => clk_i,
      rst_i => rst_i,
      vld_i => vld_o,
      dat_i => dat_o,
      dat_o => datup_o,
      vld_o => vldup_o
    );

  -- Count the number of valid input samples between valid output samples
  count_valid_dw_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      assert count_ok report "###ERROR### :Test DW Failed: Number of valid input samples between valid outputs does not match the downsampling ratio." severity error;
      if rst_i = '1' then
        valid_count <= 0;
        count_ok    <= true;            -- Reset status
      elsif vld_i = '1' then
        valid_count <= valid_count + 1; -- Count valid input samples
        if vld_o = '1' then
          -- When a valid output is produced, check the count of valid inputs
          if valid_count < (DOWNSAMPLE_RATE_c - 1) or valid_count > (DOWNSAMPLE_RATE_c + 1) then
            count_ok <= false;          -- Flag an error if the count does not match
          else
            count_ok <= true;
          end if;
          valid_count <= 0;             -- Reset count for the next segment
        end if;
      end if;
    end if;
  end process;

  -- Count the number of valid input samples between valid output samples
  count_valid_up_proc : process(clk_i)
  begin
    if rising_edge(clk_i) then
      assert countup_ok report "###ERROR### :Test UP Failed: Number of valid input samples between valid outputs does not match the upsampling ratio." severity error;
      if rst_i = '1' then
        validup_count <= 0;
        -- Reset status
        countup_ok    <= true;
      elsif vld_o = '1' then
        -- Count valid input samples
        validup_count <= validup_count + 1;
        if vldup_o = '1' then
          -- When a valid output is produced, check the count of valid inputs
          if validup_count < (UP_SAMPLING_RATE_c-1) or validup_count > (UP_SAMPLING_RATE_c+1) then
            -- Flag an error if the count does not match
            countup_ok <= false;
          else
            countup_ok <= true;
          end if;
          -- Reset count for the next segment
          validup_count <= 0;
        end if;
      end if;
    end if;
  end process;

end architecture;
