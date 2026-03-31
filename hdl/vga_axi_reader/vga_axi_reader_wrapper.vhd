library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_axi_reader_wrapper is
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        vga_x_i           : in  std_logic_vector(9 downto 0);
        vga_y_i           : in  std_logic_vector(9 downto 0);
        vga_active_i      : in  std_logic;
        image_ready_i     : in  std_logic;
        ping_pong_i       : in  std_logic;
        
        bram_we_o         : out std_logic;
        bram_addr_o       : out std_logic_vector(10 downto 0);
        bram_din_o        : out std_logic_vector(7 downto 0);
        
        -- AXI Write (tie-off)
        m_axi_awaddr      : out std_logic_vector(31 downto 0);
        m_axi_awvalid     : out std_logic;
        m_axi_awready     : in  std_logic;
        m_axi_wdata       : out std_logic_vector(31 downto 0);
        m_axi_wstrb       : out std_logic_vector(3 downto 0);
        m_axi_wvalid      : out std_logic;
        m_axi_wready      : in  std_logic;
        m_axi_bresp       : in  std_logic_vector(1 downto 0);
        m_axi_bvalid      : in  std_logic;
        m_axi_bready      : out std_logic;
        
        -- AXI Read (burst)
        m_axi_araddr      : out std_logic_vector(31 downto 0);
        m_axi_arvalid     : out std_logic;
        m_axi_arready     : in  std_logic;
        m_axi_arlen       : out std_logic_vector(7 downto 0);
        m_axi_arsize      : out std_logic_vector(2 downto 0);
        m_axi_arburst     : out std_logic_vector(1 downto 0);
        m_axi_rlast       : in  std_logic;
        m_axi_rdata       : in  std_logic_vector(31 downto 0);
        m_axi_rresp       : in  std_logic_vector(1 downto 0);
        m_axi_rvalid      : in  std_logic;
        m_axi_rready      : out std_logic
    );
end entity;

architecture wrapper of vga_axi_reader_wrapper is
begin
    i_core : entity work.vga_axi_reader
        port map (
            clk_i            => clk,
            rst_i            => rst,
            
            vga_x_i          => vga_x_i,
            vga_y_i          => vga_y_i,
            vga_active_i     => vga_active_i,
            image_ready_i    => image_ready_i,
            ping_pong_i      => ping_pong_i,
            
            bram_we_o        => bram_we_o,
            bram_addr_o      => bram_addr_o,
            bram_din_o       => bram_din_o,
            
            m_axi_awaddr     => m_axi_awaddr,
            m_axi_awvalid    => m_axi_awvalid,
            m_axi_awready    => m_axi_awready,
            m_axi_wdata      => m_axi_wdata,
            m_axi_wstrb      => m_axi_wstrb,
            m_axi_wvalid     => m_axi_wvalid,
            m_axi_wready     => m_axi_wready,
            m_axi_bresp      => m_axi_bresp,
            m_axi_bvalid     => m_axi_bvalid,
            m_axi_bready     => m_axi_bready,
            
            m_axi_araddr     => m_axi_araddr,
            m_axi_arvalid    => m_axi_arvalid,
            m_axi_arready    => m_axi_arready,
            m_axi_arlen      => m_axi_arlen,
            m_axi_arsize     => m_axi_arsize,
            m_axi_arburst    => m_axi_arburst,
            m_axi_rlast      => m_axi_rlast,
            m_axi_rdata      => m_axi_rdata,
            m_axi_rresp      => m_axi_rresp,
            m_axi_rvalid     => m_axi_rvalid,
            m_axi_rready     => m_axi_rready
        );
end architecture;