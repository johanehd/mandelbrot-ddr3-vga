library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_iter is
    generic (
        F_BITS : integer := 28 -- Q4.28
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        x_i, y_i   : in  signed(31 downto 0); -- z = x + i*y
        cr_i, ci_i : in  signed(31 downto 0); -- c = cr + i*ci
        x_next_o, y_next_o : out signed(31 downto 0); -- z_next = x_next + i*y_next
        escaped_o  : out std_logic            -- '1' if x^2 + y^2 > 4
    );
end entity;

architecture Behavioral of mandelbrot_iter is
    signal x2, y2, xy : signed(63 downto 0);
    signal lenght2 : signed(63 downto 0); -- x^2 + y^2
begin
    process(clk)
    begin
       if rising_edge(clk) then
           if rst = '1' then
                x2      <= (others => '0');
                y2      <= (others => '0');
                xy      <= (others => '0');
                x_next_o  <= (others => '0');
                y_next_o  <= (others => '0');
                lenght2 <= (others => '0');
                escaped_o <= '0';
            else
                x2 <= x_i * x_i;
                y2 <= y_i * y_i;
                xy <= x_i * y_i;
                
                -- z^2 = (x + i*y)^2 = x^2 - y^2 + 2*i*x*y
                -- x_net = x^2 - y^2 + cr
                -- y_next = 2*x*y + ci  
                x_next_o <= resize(shift_right(x2 - y2, F_BITS), 32) + cr_i;
                y_next_o <= resize(shift_right(xy, F_BITS-1), 32) + ci_i; -- shift F_BITS-1  => * 2
    
                lenght2 <= x2 + y2;
                
                if lenght2 > shift_left(to_signed(4, 64), 56) then -- threshold 4 in Q8.56 format (28 * 2 bits fractional)
                    escaped_o <= '1';
                else
                    escaped_o <= '0';
                end if;
             end if;
        end if;
    end process;
end architecture;

-- NOTE on combinational Architecture:
-- This combinational version cannot be used at 83.3 MHz (12 ns clock period).
-- The critical path (32-bit Multipliers -> 64-bit Subtractors -> 32-bit Adders) 
-- is approximately 14.2 ns, which exceeds the 12 ns limit.
-- This results in a negative Slack of -2.2 ns, causing timing violations.
-- To run at this frequency, a sequential version is required 
-- to break the logic into smaller stages.


--architecture Behavioral of mandelbrot_iter is

--    signal x2, y2, xy : signed(63 downto 0);
--    signal length2    : signed(63 downto 0); 
--begin

--    x2 <= x_i * x_i;
--    y2 <= y_i * y_i;
--    xy <= x_i * y_i;

--    -- z^2 = (x + i*y)^2 = x^2 - y^2 + 2*i*x*y
--    -- x_next = x^2 - y^2 + cr
--    -- y_next = 2*x*y + ci
--    x_next_o <= resize(shift_right(x2 - y2, F_BITS), 32) + cr_i;
--    y_next_o <= resize(shift_right(xy, F_BITS-1), 32) + ci_i; 

--    length2 <= x2 + y2;
    
--    escaped_o <= '1' when length2 > shift_left(to_signed(4, 64), F_BITS*2) else '0';

--end architecture;