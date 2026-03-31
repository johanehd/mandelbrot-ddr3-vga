library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mandelbrot_master is
end tb_mandelbrot_master;

architecture sim of tb_mandelbrot_master is
    constant CLK_PERIOD : time := 12 ns;
    signal clk           : std_logic := '0';
    signal rst           : std_logic := '0';
    signal start_image   : std_logic := '0';

    signal m_axi_awaddr  : std_logic_vector(31 downto 0);
    signal m_axi_awprot  : std_logic_vector(2 downto 0);
    signal m_axi_awvalid : std_logic;
    signal m_axi_awready : std_logic := '0';
    signal m_axi_wdata   : std_logic_vector(31 downto 0);
    signal m_axi_wstrb   : std_logic_vector(3 downto 0);
    signal m_axi_wvalid  : std_logic;
    signal m_axi_wready  : std_logic := '0';
    signal m_axi_bvalid  : std_logic := '0';
    signal m_axi_bready  : std_logic;
    signal m_axi_bresp   : std_logic_vector(1 downto 0) := "00";

    signal m_axi_araddr  : std_logic_vector(31 downto 0);
    signal m_axi_arprot  : std_logic_vector(2 downto 0);
    signal m_axi_arvalid : std_logic;
    signal m_axi_arready : std_logic := '0';
    signal m_axi_rdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_rresp   : std_logic_vector(1 downto 0) := "00";
    signal m_axi_rvalid  : std_logic := '0';
    signal m_axi_rready  : std_logic;

    signal seq_start     : std_logic;
    signal seq_cr        : signed(31 downto 0);
    signal seq_ci        : signed(31 downto 0);
    signal seq_ready     : std_logic := '0';
    signal seq_iter      : unsigned(7 downto 0) := (others => '0');

    signal busy          : std_logic;
    signal done_image    : std_logic;
    signal error_out     : std_logic;

begin

    clk <= not clk after CLK_PERIOD/2; 

    UUT: entity work.mandelbrot_master
        port map (
            clk             => clk,
            rst             => rst,
            start_image_i   => start_image,
            seq_start_o     => seq_start,
            seq_cr_o        => seq_cr,
            seq_ci_o        => seq_ci,
            seq_ready_i     => seq_ready,
            seq_iter_i      => seq_iter,
            m_axi_awaddr    => m_axi_awaddr,
            m_axi_awprot    => m_axi_awprot,
            m_axi_awvalid   => m_axi_awvalid,
            m_axi_awready   => m_axi_awready,
            m_axi_wdata     => m_axi_wdata,
            m_axi_wstrb     => m_axi_wstrb,
            m_axi_wvalid    => m_axi_wvalid,
            m_axi_wready    => m_axi_wready,
            m_axi_bvalid    => m_axi_bvalid,
            m_axi_bready    => m_axi_bready,
            m_axi_bresp     => m_axi_bresp,
            m_axi_araddr    => m_axi_araddr,
            m_axi_arprot    => m_axi_arprot,
            m_axi_arvalid   => m_axi_arvalid,
            m_axi_arready   => m_axi_arready,
            m_axi_rdata     => m_axi_rdata,
            m_axi_rresp     => m_axi_rresp,
            m_axi_rvalid    => m_axi_rvalid,
            m_axi_rready    => m_axi_rready,
            busy_o          => busy,
            done_image_o    => done_image,
            error_out       => error_out
        );

    stim_proc: process
        variable mode_desync : std_logic := '0';
    begin
        rst <= '1';
        wait for 45 ns;
        rst <= '0';
        wait until rising_edge(clk);

        start_image <= '1';
        wait until rising_edge(clk);
        start_image <= '0';

        for i in 0 to 700 loop

            -- PHASE 1 : wait for sequencer request
            wait until seq_start = '1';
            wait until rising_edge(clk);

            -- simulate 3 cycles of computation
            wait for 30 ns;
            seq_iter  <= to_unsigned(i mod 256, 8);
            seq_ready <= '1';
            wait until rising_edge(clk);
            seq_ready <= '0';

            -- PHASE 2 : AXI write handshake
            wait until (m_axi_awvalid = '1' and m_axi_wvalid = '1');
            wait until rising_edge(clk);

            if mode_desync = '0' then
                -- TC01 : synchronous mode 
                m_axi_awready <= '1';
                m_axi_wready  <= '1';
                wait until rising_edge(clk);
                m_axi_awready <= '0';
                m_axi_wready  <= '0';
            else
                -- TC02 : desynchronized mode (AW before W)
                m_axi_awready <= '1';
                wait until rising_edge(clk);
                m_axi_awready <= '0';
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                wait until rising_edge(clk);
                m_axi_wready <= '1';
                wait until rising_edge(clk);
                m_axi_wready <= '0';
            end if;

            -- PHASE 3 : write response
            wait for 20 ns;
            m_axi_bvalid <= '1';
            wait until rising_edge(clk);
            m_axi_bvalid <= '0';

            wait until rising_edge(clk);
        end loop;

        report "Simulation completed successfully" severity note;
        wait;
    end process;

end sim;