library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_axi_reader is
    port (
        clk_i             : in  std_logic;
        rst_i             : in  std_logic;
        vga_x_i           : in  std_logic_vector(9 downto 0);
        vga_y_i           : in  std_logic_vector(9 downto 0);
        vga_active_i      : in  std_logic;
        ping_pong_i       : in  std_logic;
        bram_we_o         : out std_logic;
        bram_addr_o       : out std_logic_vector(10 downto 0);
        bram_din_o        : out std_logic_vector(7 downto 0);
        image_ready_i     : in  std_logic;
        
        -- AXI4-Lite Master READ
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
        m_axi_rready      : out std_logic;
        
        -- AXI4-Lite Master WRITE 
        m_axi_awaddr      : out std_logic_vector(31 downto 0);
        m_axi_awvalid     : out std_logic;
        m_axi_awready     : in  std_logic;
        m_axi_wdata       : out std_logic_vector(31 downto 0);
        m_axi_wstrb       : out std_logic_vector(3 downto 0);
        m_axi_wvalid      : out std_logic;
        m_axi_wready      : in  std_logic;
        m_axi_bresp       : in  std_logic_vector(1 downto 0);
        m_axi_bvalid      : in  std_logic;
        m_axi_bready      : out std_logic
    );
end entity;

architecture Behavioral of vga_axi_reader is

    type state_type is (S_IDLE, S_SEND_ADDR, S_RECV_BURST, S_ERROR);
    signal state : state_type := S_IDLE;

    constant DDR3_BASE : unsigned(31 downto 0) := x"80010000";

    -- synchronize VGA signals from VGA clk domain to system clock 
    signal vga_y_s0, vga_y_s1           : std_logic_vector(9 downto 0) := (others => '0');
    signal vga_active_s0, vga_active_s1 : std_logic := '0';
    signal ping_pong_s0, ping_pong_s1   : std_logic := '0';

    signal load_line  : unsigned(9 downto 0) := (others => '0'); -- current line 
    signal load_col   : unsigned(9 downto 0) := (others => '0'); -- current column 
    signal last_line  : unsigned(9 downto 0) := (others => '1'); -- last loaded line 
    signal loading    : std_logic := '0';

    signal burst_num  : unsigned(2 downto 0) := (others => '0');
    
    -- current line base address 
    signal line_base  : unsigned(31 downto 0) := (others => '0');

begin
    -- unused AXI Write
    m_axi_awaddr  <= (others => '0');
    m_axi_awvalid <= '0';
    m_axi_wdata   <= (others => '0');
    m_axi_wstrb   <= (others => '0');
    m_axi_wvalid  <= '0';
    m_axi_bready  <= '0';

    -- burst 128 beats 
    m_axi_arlen   <= std_logic_vector(to_unsigned(127, 8));
    m_axi_arsize  <= "010"; -- 4 bytes per transfer, matches DDR3 data width
    m_axi_arburst <= "01"; -- mode INCR

    -- synch VGA -> AXI with double FF
    process(clk_i, rst_i)
    begin
        if rst_i = '1' then
            vga_y_s0      <= (others => '0');
            vga_y_s1      <= (others => '0');
            vga_active_s0 <= '0';
            vga_active_s1 <= '0';
            ping_pong_s0  <= '0';
            ping_pong_s1  <= '0';
        elsif rising_edge(clk_i) then
            vga_y_s0      <= vga_y_i;
            vga_y_s1      <= vga_y_s0;
            vga_active_s0 <= vga_active_i;
            vga_active_s1 <= vga_active_s0;
            ping_pong_s0  <= ping_pong_i;
            ping_pong_s1  <= ping_pong_s0;
        end if;
    end process;

    process(clk_i, rst_i)
        variable next_line   : unsigned(9 downto 0);
        variable pixel_index : unsigned(31 downto 0);
    begin
        if rst_i = '1' then
            state         <= S_IDLE;
            m_axi_arvalid <= '0';
            m_axi_rready  <= '0';
            m_axi_araddr  <= (others => '0');
            bram_we_o       <= '0';
            bram_addr_o     <= (others => '0');
            bram_din_o      <= (others => '0');
            load_col      <= (others => '0');
            last_line     <= (others => '1');
            loading       <= '0';
            burst_num     <= (others => '0');
            line_base     <= (others => '0');
        elsif rising_edge(clk_i) then
            bram_we_o <= '0';
            -- load the line that will be displayed NEXT (VGA_Y + 1)
            next_line := unsigned(vga_y_s1) + 1;
            case state is
                when S_IDLE =>
                    m_axi_rready <= '0';
                    -- launch burst if image ready AND VGA active AND next line valid AND not already loaded AND no burst in progress
                    if image_ready_i = '1' and vga_active_s1 = '1' and next_line < 480 and next_line /= last_line and loading = '0' then
                        load_line <= next_line;
                        load_col  <= (others => '0');
                        last_line <= next_line;
                        loading   <= '1';
                        burst_num <= (others => '0');

                        -- calculate base address of line in DDR3: line_base = DDR3_BASE + (next_line * 640 * 4)
                        pixel_index := resize(next_line * to_unsigned(640, 10), 32);
                        line_base <= DDR3_BASE + shift_left(pixel_index, 2);

                        -- launch first burst (pixels 0-127)
                        m_axi_araddr  <= std_logic_vector( DDR3_BASE + shift_left(pixel_index, 2));
                        m_axi_arvalid <= '1';
                        state         <= S_SEND_ADDR;
                    end if;

                when S_SEND_ADDR =>
                    -- wait for AXI handshake
                    if m_axi_arready = '1' then
                        m_axi_arvalid <= '0';
                        m_axi_rready  <= '1';
                        state         <= S_RECV_BURST;
                    end if;

                when S_RECV_BURST =>
                    if m_axi_rvalid = '1' then
                        if m_axi_rresp = "00" then
                            -- extract LS BYTE (pixel iteration count) and write to BRAM
                            bram_din_o <= m_axi_rdata(7 downto 0);
                            bram_we_o  <= '1';

                            if ping_pong_s1 = '0' then
                            -- ping-pong = 0: write to second buffer (addresses 640-1279)
                                bram_addr_o <= std_logic_vector(to_unsigned(640, 11) + load_col);
                            else
                            -- Ping-pong = 1: write to first buffer (addresses 0-639)
                                bram_addr_o <= std_logic_vector(resize(load_col, 11));
                            end if;
                            -- check if last beat of current burst
                            if m_axi_rlast = '1' then
                                m_axi_rready <= '0';
                                if burst_num = 4 then
                                    -- line complete
                                    loading   <= '0';
                                    state     <= S_IDLE;
                                else
                                    -- more burst to fetch 
                                    burst_num    <= burst_num + 1;
                                    m_axi_arvalid <= '1';
                                    state         <= S_SEND_ADDR;
                                        
                                    case burst_num is
                                         when "000" => m_axi_araddr <= std_logic_vector(line_base + to_unsigned(128*4, 32));
                                         when "001" => m_axi_araddr <= std_logic_vector(line_base + to_unsigned(256*4, 32));
                                         when "010" => m_axi_araddr <= std_logic_vector(line_base + to_unsigned(384*4, 32));
                                         when others => m_axi_araddr <= std_logic_vector(line_base + to_unsigned(512*4, 32));
                                    end case;
                                end if;
                            else
                                load_col <= load_col + 1;
                            end if;
                        else
                            state <= S_ERROR;
                        end if;
                    end if;

                when S_ERROR =>
                    state <= S_ERROR;

                when others =>
                    state <= S_IDLE;

            end case;
        end if;
    end process;

end architecture;