library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_sequencer is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        start_i        : in  std_logic; 
        cr_i, ci_i     : in  signed(31 downto 0);     
        pixel_ready_o  : out std_logic;
        iter_count_o   : out unsigned(7 downto 0) 
    );
end entity;

architecture Behavioral of mandelbrot_sequencer is
    type state_type is (S_IDLE, S_COMPUTE, S_WAIT_PIPE, S_FINISH);
    signal state : state_type := S_IDLE;

    signal x_reg, y_reg   : signed(31 downto 0);
    signal x_next, y_next : signed(31 downto 0);
    signal escaped        : std_logic;

    signal count          : unsigned(7 downto 0);
    constant MAX_ITER     : unsigned(7 downto 0) := x"FF";

    signal delay_cnt      : integer range 0 to 2;

begin

    -- instantiate the iterator 
    iter_inst : entity work.mandelbrot_iter
        port map (
            clk   => clk,
            rst   => rst,
            x_i     => x_reg,
            y_i     => y_reg,
            cr_i    => cr_i,
            ci_i    => ci_i,
            x_next_o  => x_next,
            y_next_o  => y_next,
            escaped_o => escaped
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= S_IDLE;
                pixel_ready_o <= '0';
                count <= (others => '0');
                delay_cnt <= 0;
            else
                case state is
                    when S_IDLE =>
                        pixel_ready_o <= '0';
                        x_reg     <= (others => '0'); -- Z0 = 0
                        y_reg     <= (others => '0');
                        count     <= (others => '0');
                        delay_cnt <= 0;
                        if start_i = '1' then
                            state <= S_WAIT_PIPE; 
                        end if;

                    -- for the sequential mode of iter 
                    when S_WAIT_PIPE =>
                        if delay_cnt < 2 then
                            delay_cnt <= delay_cnt + 1;
                        else
                            delay_cnt <= 0;
                            state     <= S_COMPUTE;
                        end if;

                    when S_COMPUTE =>
                        x_reg <= x_next; 
                        y_reg <= y_next;
                    
                        if escaped = '1' or count = MAX_ITER then
                            -- stop and send count to output
                            iter_count_o <= count;
                            state <= S_FINISH;
                        else
                            -- continue iterating 
                            count <= count + 1;
                            state <= S_WAIT_PIPE; 
                        end if;

                    -- pulse pixel_ready signal for one cycle
                    when S_FINISH =>
                        pixel_ready_o <= '1';
                        state        <= S_IDLE;

                    when others =>
                        state <= S_IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture;


--architecture Behavioral of mandelbrot_sequencer is
--    type state_type is (IDLE, COMPUTE, FINISH);
--    signal state : state_type := IDLE;

--    signal x_reg, y_reg   : signed(31 downto 0);
--    signal x_next, y_next : signed(31 downto 0);
--    signal escaped        : std_logic;
    
--    signal count          : unsigned(7 downto 0);
--    constant MAX_ITER     : unsigned(7 downto 0) := x"FF";

--begin

--    iter_inst : entity work.mandelbrot_iter
--        generic map ( F_BITS => 28 )
--        port map (
--            x_i       => x_reg,
--            y_i       => y_reg,
--            cr_i      => cr_i,
--            ci_i      => ci_i,
--            x_next_o  => x_next,
--            y_next_o  => y_next,
--            escaped_o => escaped
--        );

--    process(clk)
--    begin
--        if rising_edge(clk) then
--            if rst = '1' then
--                state <= IDLE;
--                pixel_ready_o <= '0';
--                count <= (others => '0');
--                x_reg <= (others => '0');
--                y_reg <= (others => '0');
--            else
--                case state is
                    
--                    when IDLE =>
--                        pixel_ready_o <= '0';
--                        if start_i = '1' then
--                            x_reg <= (others => '0'); -- Z0 = 0
--                            y_reg <= (others => '0');
--                            count <= (others => '0');
--                            state <= COMPUTE;
--                        end if;

--                    when COMPUTE =>
--                        if escaped = '1' or count = MAX_ITER then
--                            iter_count_o <= count;
--                            state       <= FINISH;
--                        else
--                            x_reg <= x_next;
--                            y_reg <= y_next;
--                            count <= count + 1;
--                        end if;

--                    when FINISH =>
--                        pixel_ready_o <= '1';
--                        state        <= IDLE;

--                    when others =>
--                        state <= IDLE;
--                end case;
--            end if;
--        end if;
--    end process;

--end architecture;