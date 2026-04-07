library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_vga_axi_reader is
end entity;

architecture sim of tb_vga_axi_reader is

    constant CLK_PERIOD : time := 12 ns;

    signal clk_i          : std_logic := '0';
    signal rst_i          : std_logic := '1';
    signal vga_x_i        : std_logic_vector(9 downto 0)  := (others => '0');
    signal vga_y_gray_i        : std_logic_vector(9 downto 0)  := (others => '0');
    signal vga_active_i   : std_logic := '0';
    signal ping_pong_i    : std_logic := '0';
    signal image_ready_i  : std_logic := '0';
    signal bram_we_o      : std_logic;
    signal bram_addr_o    : std_logic_vector(10 downto 0);
    signal bram_din_o     : std_logic_vector(7 downto 0);
    signal m_axi_araddr   : std_logic_vector(31 downto 0);
    signal m_axi_arvalid  : std_logic;
    signal m_axi_arready  : std_logic := '0';
    signal m_axi_arlen    : std_logic_vector(7 downto 0);
    signal m_axi_arsize   : std_logic_vector(2 downto 0);
    signal m_axi_arburst  : std_logic_vector(1 downto 0);
    signal m_axi_rdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal m_axi_rresp    : std_logic_vector(1 downto 0)  := "00";
    signal m_axi_rvalid   : std_logic := '0';
    signal m_axi_rready   : std_logic;
    signal m_axi_rlast    : std_logic := '0';
    signal m_axi_awaddr   : std_logic_vector(31 downto 0);
    signal m_axi_awvalid  : std_logic;
    signal m_axi_awready  : std_logic := '0';
    signal m_axi_wdata    : std_logic_vector(31 downto 0);
    signal m_axi_wstrb    : std_logic_vector(3 downto 0);
    signal m_axi_wvalid   : std_logic;
    signal m_axi_wready   : std_logic := '0';
    signal m_axi_bresp    : std_logic_vector(1 downto 0)  := "00";
    signal m_axi_bvalid   : std_logic := '0';
    signal m_axi_bready   : std_logic;

begin

    clk_i <= not clk_i after CLK_PERIOD / 2;

    dut : entity work.vga_axi_reader
        port map (
            clk_i         => clk_i,
            rst_i         => rst_i,
            vga_x_i       => vga_x_i,
            vga_y_gray_i       => vga_y_gray_i,
            vga_active_i  => vga_active_i,
            ping_pong_i   => ping_pong_i,
            image_ready_i => image_ready_i,
            bram_we_o     => bram_we_o,
            bram_addr_o   => bram_addr_o,
            bram_din_o    => bram_din_o,
            m_axi_araddr  => m_axi_araddr,
            m_axi_arvalid => m_axi_arvalid,
            m_axi_arready => m_axi_arready,
            m_axi_arlen   => m_axi_arlen,
            m_axi_arsize  => m_axi_arsize,
            m_axi_arburst => m_axi_arburst,
            m_axi_rdata   => m_axi_rdata,
            m_axi_rresp   => m_axi_rresp,
            m_axi_rvalid  => m_axi_rvalid,
            m_axi_rready  => m_axi_rready,
            m_axi_rlast   => m_axi_rlast,
            m_axi_awaddr  => m_axi_awaddr,
            m_axi_awvalid => m_axi_awvalid,
            m_axi_awready => m_axi_awready,
            m_axi_wdata   => m_axi_wdata,
            m_axi_wstrb   => m_axi_wstrb,
            m_axi_wvalid  => m_axi_wvalid,
            m_axi_wready  => m_axi_wready,
            m_axi_bresp   => m_axi_bresp,
            m_axi_bvalid  => m_axi_bvalid,
            m_axi_bready  => m_axi_bready
        );

    stim_proc: process
    begin
        -- reset
        rst_i <= '1';
        wait for 50 ns;
        rst_i <= '0';
        wait for 20 ns;

        -- TC01: load line 1, ping_pong=0
        -- BRAM written to buffer 1 (addresses 640-1279)
        report "TC01: load line 1, ping_pong=0";
        image_ready_i <= '1';
        vga_active_i  <= '1';
        vga_y_gray_i       <= std_logic_vector(to_unsigned(0, 10));
        ping_pong_i   <= '0';

        for b in 0 to 4 loop
            wait until m_axi_arvalid = '1';
            wait until rising_edge(clk_i);
            m_axi_arready <= '1';
            wait until rising_edge(clk_i);
            m_axi_arready <= '0';
            for beat in 0 to 127 loop
                m_axi_rdata  <= std_logic_vector(to_unsigned(beat, 32));
                m_axi_rvalid <= '1';
                if beat = 127 then
                    m_axi_rlast <= '1';
                end if;
                wait until rising_edge(clk_i) and m_axi_rready = '1';
            end loop;
            m_axi_rvalid <= '0';
            m_axi_rlast  <= '0';
        end loop;

        report "TC01 PASS" severity note;
        wait for 10 * CLK_PERIOD;

        -- TC02: image_ready=0 no burst should be launched
        report "TC02: image_ready=0, no burst expected";
        image_ready_i <= '0';
        vga_active_i  <= '1';
        vga_y_gray_i       <= std_logic_vector(to_unsigned(10, 10));
        wait for 100 * CLK_PERIOD;
        assert m_axi_arvalid = '0'
            report "TC02 FAIL: burst launched while image_ready=0" severity error;
        report "TC02 PASS" severity note;

        report "Simulation completed" severity note;
        wait;
    end process;

end sim;