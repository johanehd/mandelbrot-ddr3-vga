library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_buffer_bram is
    port (
        clk_a     : in  std_logic; -- 83,33 MHz AXI reader
        we_a_i    : in  std_logic;
        addr_a_i  : in  std_logic_vector(10 downto 0); -- 0-1279 (2�640)
        din_a_i   : in  std_logic_vector(7 downto 0);

        clk_b     : in  std_logic; -- 25 MHz VGA 
        addr_b_i  : in  std_logic_vector(10 downto 0);
        dout_b_o  : out std_logic_vector(7 downto 0)
    );
end entity;

architecture Behavioral of line_buffer_bram is

    type bram_type is array (0 to 1279) of std_logic_vector(7 downto 0);
    signal mem : bram_type := (others => (others => '0'));

begin
    process(clk_a)
    begin
        if rising_edge(clk_a) then
            if we_a_i = '1' then
                mem(to_integer(unsigned(addr_a_i))) <= din_a_i;
            end if;
        end if;
    end process;

    process(clk_b)
    begin
        if rising_edge(clk_b) then
            dout_b_o <= mem(to_integer(unsigned(addr_b_i)));
        end if;
    end process;

end architecture;
