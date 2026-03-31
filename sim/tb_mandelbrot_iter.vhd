library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mandelbrot_iter is
end entity;

architecture sim of tb_mandelbrot_iter is
    constant CLK_PERIOD : time := 12 ns;
    constant F_BITS     : integer := 28;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal x_i, y_i   : signed(31 downto 0) := (others => '0');
    signal cr_i, ci_i : signed(31 downto 0) := (others => '0');
    signal x_next_o   : signed(31 downto 0);
    signal y_next_o   : signed(31 downto 0);
    signal escaped_o  : std_logic;

    -- real to Q4.28 signed
    function to_q28(r : real) return signed is
    begin
        return to_signed(integer(r * real(2**F_BITS)), 32);
    end function;

begin
    uut: entity work.mandelbrot_iter
        generic map (
            F_BITS => F_BITS
        )
        port map (
            clk        => clk,
            rst        => rst,
            x_i        => x_i,
            y_i        => y_i,
            cr_i       => cr_i,
            ci_i       => ci_i,
            x_next_o   => x_next_o,
            y_next_o   => y_next_o,
            escaped_o  => escaped_o
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        -- CASE 1: origin
        x_i  <= to_q28(0.0); y_i  <= to_q28(0.0);
        cr_i <= to_q28(0.0); ci_i <= to_q28(0.0);
        wait for 3*CLK_PERIOD;
        
        -- CASE 2: basic growth
        x_i  <= to_q28(0.5); y_i  <= to_q28(0.0);
        cr_i <= to_q28(0.1); ci_i <= to_q28(0.1);
        wait for 3*CLK_PERIOD;

        -- CASE 3: escape condition test
        x_i  <= to_q28(2.1); y_i  <= to_q28(0.0);
        cr_i <= to_q28(0.0); ci_i <= to_q28(0.0);
        wait for 3*CLK_PERIOD;
        
        -- CASE 4: negative numbers 
        x_i  <= to_q28(-0.5); y_i  <= to_q28(0.5);
        cr_i <= to_q28(-0.1); ci_i <= to_q28(-0.1);
        wait for 3*CLK_PERIOD;

        wait for 100 ns;
        assert false report "End of simulation" severity failure;
    end process;

end architecture;