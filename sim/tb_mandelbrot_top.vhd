library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_mandelbrot_top is
end tb_mandelbrot_top;

architecture sim of tb_mandelbrot_top is

    component ddr3_model is
        port (
            rst_n   : in    std_logic;
            ck      : in    std_logic;
            ck_n    : in    std_logic;
            cke     : in    std_logic;
            cs_n    : in    std_logic;
            ras_n   : in    std_logic;
            cas_n   : in    std_logic;
            we_n    : in    std_logic;
            dm_tdqs : inout std_logic_vector(1 downto 0);
            ba      : in    std_logic_vector(2 downto 0);
            addr    : in    std_logic_vector(13 downto 0);
            dq      : inout std_logic_vector(15 downto 0);
            dqs     : inout std_logic_vector(1 downto 0);
            dqs_n   : inout std_logic_vector(1 downto 0);
            tdqs_n  : out   std_logic_vector(1 downto 0);
            odt     : in    std_logic
        );
    end component;

    signal clk_in1_0             : std_logic := '0';
    signal ext_reset_in_0        : std_logic := '0';
    signal start_image_i_0       : std_logic := '0';
    signal busy_o_0              : std_logic;
    signal done_image_o_0        : std_logic;
    signal error_out_0           : std_logic;
    signal init_calib_complete_0 : std_logic;

    signal ddr3_addr    : std_logic_vector(13 downto 0);
    signal ddr3_ba      : std_logic_vector(2 downto 0);
    signal ddr3_cas_n   : std_logic;
    signal ddr3_ck_n    : std_logic_vector(0 downto 0);
    signal ddr3_ck_p    : std_logic_vector(0 downto 0);
    signal ddr3_cke     : std_logic_vector(0 downto 0);
    signal ddr3_cs_n    : std_logic_vector(0 downto 0);
    signal ddr3_dm      : std_logic_vector(1 downto 0);
    signal ddr3_dq      : std_logic_vector(15 downto 0);
    signal ddr3_dqs_n   : std_logic_vector(1 downto 0);
    signal ddr3_dqs_p   : std_logic_vector(1 downto 0);
    signal ddr3_odt     : std_logic_vector(0 downto 0);
    signal ddr3_ras_n   : std_logic;
    signal ddr3_reset_n : std_logic;
    signal ddr3_we_n    : std_logic;

    signal vga_r        : std_logic_vector(3 downto 0);
    signal vga_g        : std_logic_vector(3 downto 0);
    signal vga_b        : std_logic_vector(3 downto 0);
    signal vga_hs       : std_logic;
    signal vga_vs       : std_logic;

    constant CLK_PERIOD : time := 10 ns;

begin

    clk_in1_0 <= not clk_in1_0 after CLK_PERIOD / 2;

    uut : entity work.mandebrot_vga_top_wrapper
        port map (
            DDR3_0_addr           => ddr3_addr,
            DDR3_0_ba             => ddr3_ba,
            DDR3_0_cas_n          => ddr3_cas_n,
            DDR3_0_ck_n           => ddr3_ck_n,
            DDR3_0_ck_p           => ddr3_ck_p,
            DDR3_0_cke            => ddr3_cke,
            DDR3_0_cs_n           => ddr3_cs_n,
            DDR3_0_dm             => ddr3_dm,
            DDR3_0_dq             => ddr3_dq,
            DDR3_0_dqs_n          => ddr3_dqs_n,
            DDR3_0_dqs_p          => ddr3_dqs_p,
            DDR3_0_odt            => ddr3_odt,
            DDR3_0_ras_n          => ddr3_ras_n,
            DDR3_0_reset_n        => ddr3_reset_n,
            DDR3_0_we_n           => ddr3_we_n,
            busy_o_0              => busy_o_0,
            clk_in1_0             => clk_in1_0,
            done_image_o_0        => done_image_o_0,
            error_out_0           => error_out_0,
            ext_reset_in_0        => ext_reset_in_0,
            init_calib_complete_0 => init_calib_complete_0,
            start_image_i_0       => start_image_i_0,
            vga_r_o_0             => vga_r,
            vga_g_o_0             => vga_g,
            vga_b_o_0             => vga_b,
            vga_hs_o_0            => vga_hs,
            vga_vs_o_0            => vga_vs
        );

    mem_model : ddr3_model
        port map (
            rst_n   => ddr3_reset_n,
            ck      => ddr3_ck_p(0),
            ck_n    => ddr3_ck_n(0),
            cke     => ddr3_cke(0),
            cs_n    => ddr3_cs_n(0),
            ras_n   => ddr3_ras_n,
            cas_n   => ddr3_cas_n,
            we_n    => ddr3_we_n,
            dm_tdqs => ddr3_dm,
            ba      => ddr3_ba,
            addr    => ddr3_addr,
            dq      => ddr3_dq,
            dqs     => ddr3_dqs_p,
            dqs_n   => ddr3_dqs_n,
            tdqs_n  => open,
            odt     => ddr3_odt(0)
        );

    ddr3_dq    <= (others => 'H');
    ddr3_dqs_p <= (others => 'H');
    ddr3_dqs_n <= (others => 'L');

    process
    begin
        ext_reset_in_0 <= '1'; wait for 200 ns;
        ext_reset_in_0 <= '0'; 
        
        wait until init_calib_complete_0 = '1';
        wait for 1 us;

        start_image_i_0 <= '1'; wait for 100 ns;
        start_image_i_0 <= '0';

        wait until done_image_o_0 = '1';

        wait;
    end process;

end sim;