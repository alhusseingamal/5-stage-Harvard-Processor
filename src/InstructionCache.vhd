LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

ENTITY InstructionCache IS
PORT(
	reset : IN STD_LOGIC;
	PC_address : out  std_logic_vector(31 DOWNTO 0);
	address : IN  std_logic_vector(IC_ADDRESS_WIDTH-1 DOWNTO 0);
	data_out : OUT std_logic_vector(INSTRUCTION_WIDTH-1 DOWNTO 0)
);
END ENTITY InstructionCache;

ARCHITECTURE behavioral OF InstructionCache IS	

TYPE memory_array_type IS ARRAY(0 TO IC_SIZE-1) OF std_logic_vector(INSTRUCTION_WIDTH - 1 DOWNTO 0);
SIGNAL memory_array : memory_array_type := (others => (others => '0'));
BEGIN
	-- handle reset if applicable
	-- process(reset)
	-- begin
	-- 	if reset = '1' then
	-- 		memory_array <= (others => (others => '0'));
	-- 	end if;
	-- end process;
	data_out <= memory_array(to_integer(unsigned(address)));
	PC_address <= memory_array(0) & memory_array(1);

END behavioral;
