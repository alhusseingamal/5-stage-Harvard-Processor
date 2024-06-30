LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY DFF_neg IS
PORT(
	D: IN std_logic;
	clk : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic
);
END DFF_neg;

ARCHITECTURE behavioral OF DFF_neg IS
BEGIN
	PROCESS(clk, reset)
	BEGIN
		IF(reset = '1') THEN
			Q <= '0';
		ELSIF falling_edge(clk) THEN
			Q <= D;
		END IF;
	END PROCESS;
END architecture behavioral;
