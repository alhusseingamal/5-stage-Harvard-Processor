library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity RegisterFile is
port(
    clk : in std_logic;
    reset : in std_logic;
    write_en1, write_en2  : in std_logic;
    write_address1, write_address2: in  std_logic_vector(2 DOWNTO 0);
    read_address1, read_address2  : in  std_logic_vector(2 DOWNTO 0);
    datain1,  datain2 : in  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
    dataout1, dataout2 : out std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
);
end entity RegisterFile;

architecture behavioral of RegisterFile is

-- declare any components used
component DFF_pos_nbit is
GENERIC (n : integer := DATA_WIDTH);
PORT(
	D : IN std_logic_vector(n-1 DOWNTO 0);
	clk : IN std_logic;
    en : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic_vector(n-1 DOWNTO 0)
);
end component;

Component MUX_8x1 is
GENERIC (n : INTEGER := DATA_WIDTH);
Port (
    I0, I1, I2, I3, I4, I5, I6, I7 : in STD_LOGIC_VECTOR(n-1 downto 0);
    S : in STD_LOGIC_VECTOR(2 downto 0);
    F : out STD_LOGIC_VECTOR(n-1 downto 0)
);
end component;

-- declare any Intermediate signals
signal write_enable: std_logic_vector(REGISTER_COUNT-1 downto 0);
signal in0, in1, in2, in3, in4, in5, in6, in7: std_logic_vector(DATA_WIDTH-1 downto 0);
signal R0, R1, R2, R3, R4, R5, R6, R7: std_logic_vector(DATA_WIDTH-1 downto 0);

begin

enable_loop1:
for i in 0 to (REGISTER_COUNT - 1) GENERATE
    write_enable(i) <= '1' when (((to_integer(unsigned(write_address1)) = i) and write_en1 = '1') or
    ((to_integer(unsigned(write_address2)) = i) and write_en2 = '1'))
    else '0';
end GENERATE;

Register0: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in0, clk => clk, en => write_enable(0), reset => reset, Q => R0);
Register1: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in1, clk => clk, en => write_enable(1), reset => reset, Q => R1);
Register2: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in2, clk => clk, en => write_enable(2), reset => reset, Q => R2);
Register3: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in3, clk => clk, en => write_enable(3), reset => reset, Q => R3);
Register4: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in4, clk => clk, en => write_enable(4), reset => reset, Q => R4);
Register5: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in5, clk => clk, en => write_enable(5), reset => reset, Q => R5);
Register6: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in6, clk => clk, en => write_enable(6), reset => reset, Q => R6);
Register7: DFF_pos_nbit generic map(n => DATA_WIDTH) port map (D => in7, clk => clk, en => write_enable(7), reset => reset, Q => R7);

MUX_1 : MUX_8x1 generic map(n => DATA_WIDTH) port map 
(I0 => R0, I1 => R1, I2 => R2, I3 => R3, I4 => R4, I5 => R5, I6 => R6, I7 => R7, S => read_address1, F => dataout1);

MUX_2 : MUX_8x1 generic map(n => DATA_WIDTH) port map
(I0 => R0, I1 => R1, I2 => R2, I3 => R3, I4 => R4, I5 => R5, I6 => R6, I7 => R7, S => read_address2, F => dataout2);

in0 <= datain1 when (to_integer(unsigned(write_address1)) = 0 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 0 and write_en2 = '1')
else (others => '0');

in1 <= datain1 when (to_integer(unsigned(write_address1)) = 1 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 1 and write_en2 = '1')
else (others => '0');

in2 <= datain1 when (to_integer(unsigned(write_address1)) = 2 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 2 and write_en2 = '1')
else (others => '0');

in3 <= datain1 when (to_integer(unsigned(write_address1)) = 3 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 3 and write_en2 = '1')
else (others => '0');

in4 <= datain1 when (to_integer(unsigned(write_address1)) = 4 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 4 and write_en2 = '1')
else (others => '0');

in5 <= datain1 when (to_integer(unsigned(write_address1)) = 5 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 5 and write_en2 = '1')
else (others => '0');

in6 <= datain1 when (to_integer(unsigned(write_address1)) = 6 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 6 and write_en2 = '1')
else (others => '0');

in7 <= datain1 when (to_integer(unsigned(write_address1)) = 7 and write_en1 = '1')
else datain2 when (to_integer(unsigned(write_address2)) = 7 and write_en2 = '1')
else (others => '0');

end architecture behavioral;