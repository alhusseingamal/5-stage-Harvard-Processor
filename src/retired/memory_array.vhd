LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

ENTITY memory_array IS
generic(DATA_WIDTH: integer := 16; MEMORY_SIZE: integer := 4096; ADDRESS_WIDTH: integer := 12);
PORT(
clk : IN std_logic;
write_en  : IN std_logic;
reset : IN std_logic;
READ_ADD : IN  std_logic_vector(ADDRESS_WIDTH-1 DOWNTO 0);
WRITE_ADD : IN  std_logic_vector(ADDRESS_WIDTH-1 DOWNTO 0);
data_in   : IN  std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
data_out : OUT std_logic_vector(DATA_WIDTH-1 DOWNTO 0)
);
END ENTITY memory_array;

ARCHITECTURE memory_array_arch OF memory_array IS

	TYPE memory_array_type IS ARRAY(0 TO MEMORY_SIZE-1) OF std_logic_vector(DATA_WIDTH - 1 DOWNTO 0);
	SIGNAL memory_array : memory_array_type := (others => (others => '0'));
	
	BEGIN
		PROCESS(clk, reset) IS
			BEGIN
				IF(reset = '1') THEN
					memory_array <= (others => (others => '0'));
				ELSIF rising_edge(clk) THEN  
					IF write_en = '1' THEN
						memory_array(to_integer(unsigned(WRITE_ADD))) <= data_in; -- synchronous write
					END IF;
				END IF;
		END PROCESS;
		data_out <= memory_array(to_integer(unsigned(READ_ADD)));
END memory_array_arch;
