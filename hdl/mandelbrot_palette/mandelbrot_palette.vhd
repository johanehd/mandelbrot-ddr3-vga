library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_palette is
    port (
        iter_count_i : in  unsigned(7 downto 0);
        rgb_out    : out std_logic_vector(11 downto 0)
    );
end entity;

architecture Behavioral of mandelbrot_palette is
    signal i : integer range 0 to 255;
begin
    i <= to_integer(iter_count_i);

    process(i)
    begin
        if iter_count_i = x"FF" then rgb_out <= x"000"; 
        elsif i < 1  then rgb_out <= x"001";
        elsif i < 2  then rgb_out <= x"002";
        elsif i < 3  then rgb_out <= x"003";
        elsif i < 4  then rgb_out <= x"004";
        elsif i < 5  then rgb_out <= x"005";
        elsif i < 6  then rgb_out <= x"006";
        elsif i < 7  then rgb_out <= x"007";
        elsif i < 8  then rgb_out <= x"008";
        elsif i < 9  then rgb_out <= x"009";
        elsif i < 10 then rgb_out <= x"00A";
        elsif i < 11 then rgb_out <= x"00B";
        elsif i < 12 then rgb_out <= x"00C";
        elsif i < 13 then rgb_out <= x"00D";
        elsif i < 14 then rgb_out <= x"00E";
        elsif i < 16 then rgb_out <= x"00F"; 

        elsif i < 20 then rgb_out <= x"11F";
        elsif i < 24 then rgb_out <= x"22F";
        elsif i < 28 then rgb_out <= x"33F";
        elsif i < 32 then rgb_out <= x"44F";
        elsif i < 36 then rgb_out <= x"55F";
        elsif i < 40 then rgb_out <= x"66F";
        elsif i < 44 then rgb_out <= x"77F";
        elsif i < 48 then rgb_out <= x"88F";
        elsif i < 52 then rgb_out <= x"99F";
        elsif i < 56 then rgb_out <= x"AAF";
        elsif i < 60 then rgb_out <= x"BBF";
        elsif i < 64 then rgb_out <= x"CCF";
        elsif i < 68 then rgb_out <= x"DDF";
        elsif i < 72 then rgb_out <= x"EEF";

        elsif i < 90  then rgb_out <= x"FFF"; 
        elsif i < 110 then rgb_out <= x"FFE"; 
        elsif i < 130 then rgb_out <= x"FFD"; 
        elsif i < 150 then rgb_out <= x"FFC"; 
        elsif i < 170 then rgb_out <= x"FFB"; 
        elsif i < 190 then rgb_out <= x"FFA"; 
        elsif i < 210 then rgb_out <= x"FF9"; 
        elsif i < 230 then rgb_out <= x"FF8"; 
        else  rgb_out <= x"FF7"; 

        end if;
    end process;
end architecture;
