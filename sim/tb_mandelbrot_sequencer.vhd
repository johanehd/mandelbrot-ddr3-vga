library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mandelbrot_sequencer is
end entity;

architecture sim of tb_mandelbrot_sequencer is
    constant CLK_PERIOD : time := 12 ns;
    
    signal clk       : std_logic := '0';
    signal rst       : std_logic := '0';
    signal start_i     : std_logic := '0';
    signal cr_i, ci_i  : signed(31 downto 0) := (others => '0');
    signal pixel_ready_o : std_logic;
    signal iter_count_o  : unsigned(7 downto 0);

    function to_q28(r : real) return signed is
    begin
        return to_signed(integer(r * real(2**28)), 32);
    end function;

begin
    uut: entity work.mandelbrot_sequencer
        port map (
            clk         => clk,
            rst         => rst,
            start_i       => start_i,
            cr_i          => cr_i,
            ci_i          => ci_i,
            pixel_ready_o => pixel_ready_o,
            iter_count_o  => iter_count_o
        );

    -- Clock generation
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- Case 1: fast escaping point
        report "Starting Test 1: Fast escaping point";
        cr_i <= to_q28(1.0);
        ci_i <= to_q28(1.0);
        start_i <= '1';
        wait for CLK_PERIOD;
        start_i <= '0';

        wait until pixel_ready_o = '1';
        report "Test 1 finished. Iterations: " & integer'image(to_integer(iter_count_o));

        wait for 50 ns;

        -- CASE 2: stable point
        report "Starting Test 2: Stable point (should reach 255)";
        cr_i <= to_q28(0.1);
        ci_i <= to_q28(0.1);
        start_i <= '1';
        wait for CLK_PERIOD;
        start_i <= '0';

        wait until pixel_ready_o = '1';
        report "Test 2 finished. Iterations: " & integer'image(to_integer(iter_count_o));

        wait for 100 ns;
        assert false report "End of simulation" severity failure;
    end process;
end architecture;