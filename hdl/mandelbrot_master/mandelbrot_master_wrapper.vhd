library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_master_wrapper is
    port (
        clk               : in  std_logic;
        rst               : in  std_logic;
        start_image_i     : in  std_logic;
        
        -- Sequencer Interface
        seq_start_o       : out std_logic;
        seq_cr_o          : out std_logic_vector(31 downto 0);
        seq_ci_o          : out std_logic_vector(31 downto 0);
        seq_ready_i       : in  std_logic;
        seq_iter_i        : in  std_logic_vector(7 downto 0);
        
        -- AXI4-Lite Master Write
        m_axi_awaddr      : out std_logic_vector(31 downto 0);
        m_axi_awprot      : out std_logic_vector(2 downto 0);
        m_axi_awvalid     : out std_logic;
        m_axi_awready     : in  std_logic;
        
        m_axi_wdata       : out std_logic_vector(31 downto 0);
        m_axi_wstrb       : out std_logic_vector(3 downto 0);
        m_axi_wvalid      : out std_logic;
        m_axi_wready      : in  std_logic;
        
        m_axi_bvalid      : in  std_logic;
        m_axi_bready      : out std_logic;
        m_axi_bresp       : in  std_logic_vector(1 downto 0);
        
        -- AXI4-Lite Master Read (tie-off)
        m_axi_araddr      : out std_logic_vector(31 downto 0);
        m_axi_arprot      : out std_logic_vector(2 downto 0);
        m_axi_arvalid     : out std_logic;
        m_axi_arready     : in  std_logic;
        m_axi_rdata       : in  std_logic_vector(31 downto 0);
        m_axi_rresp       : in  std_logic_vector(1 downto 0);
        m_axi_rvalid      : in  std_logic;
        m_axi_rready      : out std_logic;
        
        -- Status & Debug
        busy_o            : out std_logic;
        done_image_o      : out std_logic;
        error_out           : out std_logic
    );
end entity;

architecture wrapper of mandelbrot_master_wrapper is
    signal s_seq_cr   : signed(31 downto 0);
    signal s_seq_ci   : signed(31 downto 0);
    signal s_seq_iter : unsigned(7 downto 0);
begin
    seq_cr_o     <= std_logic_vector(s_seq_cr);
    seq_ci_o     <= std_logic_vector(s_seq_ci);
    s_seq_iter   <= unsigned(seq_iter_i);
    
    i_core : entity work.mandelbrot_master
        port map (
            clk           => clk,
            rst           => rst,
            start_image_i   => start_image_i,
            
            seq_start_o     => seq_start_o,
            seq_cr_o        => s_seq_cr,
            seq_ci_o        => s_seq_ci,
            seq_ready_i     => seq_ready_i,
            seq_iter_i      => s_seq_iter,
            
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
            
            busy_o          => busy_o,
            done_image_o    => done_image_o,
            error_out         => error_out
        );
end architecture;