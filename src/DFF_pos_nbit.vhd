LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY DFF_pos_nbit IS
GENERIC (n : integer := 16);
PORT(
	D : IN std_logic_vector(n-1 DOWNTO 0);
	clk : IN std_logic;
	en : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic_vector(n-1 DOWNTO 0)
);
END DFF_pos_nbit;

ARCHITECTURE behavioral OF DFF_pos_nbit IS
COMPONENT DFF_pos IS
PORT(
	D: IN std_logic;
	clk : IN std_logic;
	en : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic
);
END COMPONENT;
BEGIN
loop1:
FOR i IN 0 TO n-1 GENERATE
	fx: DFF_pos PORT MAP(D => D(i), clk => clk, en => en, reset => reset, Q => Q(i));
END GENERATE;

END architecture behavioral;

