library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller is
  port (
    clk_25 : in std_logic;
    rst    : in std_logic;
    -- vga_axi_reader
    pixel_data_i : in std_logic_vector(11 downto 0);
    pixel_x_o    : out std_logic_vector(9 downto 0);
    pixel_y_o    : out std_logic_vector(9 downto 0);
    zone_on_o    : out std_logic;
    ping_pong_o  : out std_logic;
    -- line_buffer_bram (port b)
    bram_rd_addr_o : out std_logic_vector(10 downto 0);
    -- VGA
    vga_hs_o : out std_logic;
    vga_vs_o : out std_logic;
    vga_r_o  : out std_logic_vector(3 downto 0);
    vga_g_o  : out std_logic_vector(3 downto 0);
    vga_b_o  : out std_logic_vector(3 downto 0)
  );
end vga_controller;

architecture Behavioral of vga_controller is

  constant H_VISIBLE : integer := 640;
  constant H_FP      : integer := 16;
  constant H_SYNC    : integer := 96;
  constant H_BP      : integer := 48;
  constant H_TOTAL   : integer := 800; -- H_VISIBLE + H_FP + H_SYNC + H_BP
  constant V_VISIBLE : integer := 480;
  constant V_FP      : integer := 10;
  constant V_SYNC    : integer := 2;
  constant V_BP      : integer := 33;
  constant V_TOTAL   : integer := 525; -- V_VISIBLE + V_FP + V_SYNC + V_BP

  signal h_cnt  : unsigned(9 downto 0) := (others => '0'); -- 0 to H_TOTAL
  signal v_cnt  : unsigned(9 downto 0) := (others => '0'); -- 0 to V_TOTAL
  signal active : std_logic; -- high when h_cnt and v_cnt are both in the visible area

  signal ping_pong_reg : std_logic := '0';

begin
  process (clk_25, rst)
  begin
    if rst = '1' then
      h_cnt         <= (others => '0');
      v_cnt         <= (others => '0');
      ping_pong_reg <= '0';
    elsif rising_edge(clk_25) then
      if h_cnt = H_TOTAL - 1 then
        -- end of line
        h_cnt <= (others => '0');
        if v_cnt = V_TOTAL - 1 then
          -- end of frame
          v_cnt <= (others => '0');
        else
          v_cnt <= v_cnt + 1;
        end if;
        -- toggle ping-pong at end of each visible line only
        if v_cnt < V_VISIBLE then
          ping_pong_reg <= not ping_pong_reg;
        end if;
      else
        h_cnt <= h_cnt + 1;
      end if;
    end if;
  end process;

  -- horizontal sync: active low during SYNC pulse (h_cnt in [656, 751])
  vga_hs_o <= '0' when (h_cnt >= (H_VISIBLE + H_FP)) and (h_cnt < (H_VISIBLE + H_FP + H_SYNC)) else
    '1';
  -- vertical sync: active low during SYNC pulse (v_cnt in [490, 491])
  vga_vs_o <= '0' when (v_cnt >= (V_VISIBLE + V_FP)) and (v_cnt < (V_VISIBLE + V_FP + V_SYNC)) else
    '1';

  -- high when both h and v counters are in the visible area
  active <= '1' when (h_cnt < H_VISIBLE) and (v_cnt < V_VISIBLE) else
    '0';

  -- expose active zone for other modules
  zone_on_o <= active;

  pixel_x_o <= std_logic_vector(h_cnt) when active = '1' else
    (others => '0');
  pixel_y_o <= std_logic_vector(v_cnt) when active = '1' else
    (others => '0');

  process (clk_25)
  begin
    if rising_edge(clk_25) then
      if active = '1' then
        if h_cnt < H_VISIBLE - 1 then
          if ping_pong_reg = '0' then
            -- VGA reads buffer 0 : addresses 0 to 639
            bram_rd_addr_o <= std_logic_vector(resize(h_cnt + 1, 11));
          else
            -- VGA reads buffer 1 : addresses 640 to 1279
            bram_rd_addr_o <= std_logic_vector(to_unsigned(640, 11) + resize(h_cnt + 1, 11));
          end if;
        else
          if ping_pong_reg = '0' then
            bram_rd_addr_o <= (others => '0');
          else
            bram_rd_addr_o <= std_logic_vector(to_unsigned(640, 11));
          end if;
        end if; -- bram_rd_addr <= std_logic_vector(resize(h_cnt + 1, 11));
      end if;
    end if;
  end process;

  ping_pong_o <= ping_pong_reg;

  -- RGB outputs only in active zone, black elsewhere
  vga_r_o <= pixel_data_i(11 downto 8) when active = '1' else
    (others => '0');
  vga_g_o <= pixel_data_i(7 downto 4) when active = '1' else
    (others => '0');
  vga_b_o <= pixel_data_i(3 downto 0) when active = '1' else
    (others => '0');

end architecture;