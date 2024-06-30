LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY DFF_pos IS
PORT(
	D: IN std_logic;
	clk : IN std_logic;
	en : IN std_logic;
	reset : IN std_logic;
	Q : OUT std_logic
);
END DFF_pos;

ARCHITECTURE behavioral OF DFF_pos IS
BEGIN
	PROCESS(clk, reset)
	BEGIN
		IF(reset = '1') THEN
			Q <= '0';
		ELSIF rising_edge(clk) THEN
			IF en = '1' THEN
				Q <= D;
			END IF;
		END IF;
	END PROCESS;
END architecture behavioral;
