LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY DFF_neg_nbit IS
GENERIC (n : integer := 16);
PORT(
	D : IN std_logic_vector(n-1 DOWNTO 0);
	clk : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic_vector(n-1 DOWNTO 0)
);
END DFF_neg_nbit;

ARCHITECTURE behavioral OF DFF_neg_nbit IS
COMPONENT DFF_neg IS
PORT(
	D: IN std_logic;
	clk : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic
);
END COMPONENT;
BEGIN
loop1:
FOR i IN 0 TO n-1 GENERATE
	fx: DFF_neg PORT MAP(D => D(i), clk => clk, reset => reset, Q => Q(i));
END GENERATE;

END architecture behavioral;
