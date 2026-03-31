library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_master is
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        start_image_i   : in  std_logic;
        
        -- interface with the sequencer
        seq_start_o     : out std_logic;
        seq_cr_o        : out signed(31 downto 0);
        seq_ci_o        : out signed(31 downto 0);
        seq_ready_i     : in  std_logic;
        seq_iter_i      : in  unsigned(7 downto 0);

        -- AXI4-Lite Master WRITE
        m_axi_awaddr    : out std_logic_vector(31 downto 0);
        m_axi_awprot    : out std_logic_vector(2 downto 0);
        m_axi_awvalid   : out std_logic;
        m_axi_awready   : in  std_logic;
             
        m_axi_wdata     : out std_logic_vector(31 downto 0);
        m_axi_wstrb     : out std_logic_vector(3 downto 0);
        m_axi_wvalid    : out std_logic;
        m_axi_wready    : in  std_logic;
        
        m_axi_bvalid    : in  std_logic;
        m_axi_bready    : out std_logic;
        m_axi_bresp     : in  std_logic_vector(1 downto 0);

        -- AXI4-Lite Master READ
        m_axi_araddr    : out std_logic_vector(31 downto 0);
        m_axi_arprot    : out std_logic_vector(2 downto 0);
        m_axi_arvalid   : out std_logic;
        m_axi_arready   : in  std_logic;
        m_axi_rdata     : in  std_logic_vector(31 downto 0);
        m_axi_rresp     : in  std_logic_vector(1 downto 0);
        m_axi_rvalid    : in  std_logic;
        m_axi_rready    : out std_logic;

        -- status et debug
        busy_o            : out std_logic;
        done_image_o      : out std_logic;
        error_out       : out std_logic
    );
end entity;

architecture Behavioral of mandelbrot_master is
    type state_type is (S_IDLE, S_INIT_PIXEL, S_WAIT_PIXEL, S_AXI_WRITE, S_AXI_WAIT_RESP, S_NEXT_PIXEL, S_FINISH, S_ERROR);
    signal state : state_type := S_IDLE;
    
    -- pixel coordinates (VGA 640x480)
    signal x_px : unsigned(9 downto 0) := (others => '0');
    signal y_px : unsigned(8 downto 0) := (others => '0');
    
    -- Mandelbrot complexe plane coordinates
    signal current_cr : signed(31 downto 0);
    signal current_ci : signed(31 downto 0);
    
    -- AXI write handshake
    signal aw_done : std_logic := '0'; -- address accepted
    signal w_done  : std_logic := '0'; -- data accepted

    -- Mandelbrot parameters
    constant X_START_VAL : signed(31 downto 0) := x"E0000000"; -- -2.0
    constant Y_START_VAL : signed(31 downto 0) := x"ECCCCD00"; -- -1.2
    constant X_STEP      : signed(31 downto 0) := x"00134000"; 
    constant Y_STEP      : signed(31 downto 0) := x"00147AE1";
    
    -- DDR3 base address 
    constant DDR3_BASE   : unsigned(31 downto 0) := x"80010000";

begin
    seq_cr_o <= current_cr;
    seq_ci_o <= current_ci;

    -- tie off unused AXI read channel
    m_axi_awprot  <= "000";
    m_axi_arprot  <= "000";
    m_axi_araddr  <= (others => '0');
    m_axi_arvalid <= '0';
    m_axi_rready  <= '0';

    process(clk)
        variable pixel_index : unsigned(31 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state         <= S_IDLE;
                seq_start_o     <= '0';
                busy_o          <= '0';
                done_image_o    <= '0';
                error_out     <= '0';
                x_px          <= (others => '0');
                y_px          <= (others => '0');
                m_axi_awvalid <= '0';
                m_axi_wvalid  <= '0';
                m_axi_bready  <= '0';
                aw_done       <= '0';
                w_done        <= '0';
            else
                case state is
                    when S_IDLE =>
                        -- done_image <= '0';
                        -- wait for start signal
                        if start_image_i = '1' then
                            x_px       <= (others => '0');
                            y_px       <= (others => '0');
                            current_cr <= X_START_VAL;
                            current_ci <= Y_START_VAL;
                            busy_o       <= '1';
                            state      <= S_INIT_PIXEL;
                        end if;

                    when S_INIT_PIXEL =>
                        -- pulse the sequencer start signal 
                        seq_start_o <= '1';
                        state     <= S_WAIT_PIXEL;

                    when S_WAIT_PIXEL =>
                        -- wait for sequencer to finish 
                        if seq_ready_i = '1' then
                            seq_start_o <= '0';
                            
                            -- calculate pixel memory  index : (y_px * 640) + x_px
                            -- 2^9 = 512, 2^7 = 128, 512 + 128 = 640
                            -- (y_px � 2^9) + (y_px � 2^7) + x_px 
                            pixel_index := shift_left(resize(y_px, 32), 9) + shift_left(resize(y_px, 32), 7) + resize(x_px, 32);
                            
                            -- AXI address: base + (index * 4) for 32-bit words
                            m_axi_awaddr <= std_logic_vector(DDR3_BASE + shift_left(pixel_index, 2));
                            
                            -- padding + pixel value provided by sequencer, range 0 to 255 
                            m_axi_wdata  <= x"000000" & std_logic_vector(seq_iter_i);
                            m_axi_wstrb  <= "1111";
                            
                            -- initiate AXI write
                            m_axi_awvalid <= '1';
                            m_axi_wvalid  <= '1';
                            m_axi_bready  <= '1';
                            aw_done       <= '0';
                            w_done        <= '0';
                            state         <= S_AXI_WRITE;
                        end if;
                    when S_AXI_WRITE =>
                        -- handshake @
                        if m_axi_awready = '1' then
                            m_axi_awvalid <= '0';
                            aw_done       <= '1';
                        end if;
                        -- handshake data
                        if m_axi_wready = '1' then
                            m_axi_wvalid <= '0';
                            w_done       <= '1';
                        end if;
                        
                        -- when both channel done wait for write response
                        if (aw_done = '1' or m_axi_awready = '1') and (w_done  = '1' or m_axi_wready  = '1') then
                            state <= S_AXI_WAIT_RESP;
                        end if;
                    
                    when S_AXI_WAIT_RESP =>
                        if m_axi_bvalid = '1' then
                            m_axi_bready <= '0';
                            if m_axi_bresp = "00" then -- OKAY
                                state <= S_NEXT_PIXEL;
                            else
                                state <= S_ERROR;
                            end if;
                        end if;

                    when S_NEXT_PIXEL =>
                        if x_px < 639 then
                            -- move to next pixel in current row
                            x_px       <= x_px + 1;
                            current_cr <= current_cr + X_STEP;
                            state      <= S_INIT_PIXEL;
                        else
                            -- move to next row 
                            x_px       <= (others => '0');
                            current_cr <= X_START_VAL;
                            if y_px < 479 then
                                y_px       <= y_px + 1;
                                current_ci <= current_ci + Y_STEP;
                                state      <= S_INIT_PIXEL;
                            else
                                -- image done (640x480)
                                state <= S_FINISH;
                            end if;
                        end if;

                    when S_FINISH =>
                        busy_o       <= '0';
                        done_image_o <= '1';
                        state      <= S_IDLE;

                    when S_ERROR =>
                        error_out <= '1';
                        busy_o      <= '0';
                        state     <= S_ERROR; -- stay in error state

                    when others =>
                        state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;
end architecture;