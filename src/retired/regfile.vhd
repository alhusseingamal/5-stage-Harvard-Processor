library ieee;
use ieee.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.definitions.all;
entity RegisterFile is
    generic (n : integer := 32);
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		write_en1, write_en2  : IN std_logic;
		write_address1, write_address2: IN  std_logic_vector(2 DOWNTO 0);
		read_address1, read_address2  : IN  std_logic_vector(2 DOWNTO 0);
		datain1,  datain2 : IN  std_logic_vector(n-1 DOWNTO 0);
		dataout1, dataout2 : OUT std_logic_vector(n-1 DOWNTO 0));
end entity RegisterFile;

-- input: 16-bit instruction

architecture behavioral of RegisterFile is

    TYPE ram_type IS ARRAY(0 TO 7) OF std_logic_vector(n-1 DOWNTO 0);
	SIGNAL ram : ram_type ;
	
	BEGIN
		PROCESS(clk, reset) IS
			BEGIN
				IF (reset = '1') then
					ram <= (others => (others => '0'));
				ELSIF rising_edge(clk) THEN  
					IF write_en1 = '1' THEN
						ram(to_integer(unsigned(write_address1))) <= datain1;	
					END IF;
					IF write_en2 = '1' THEN
						ram(to_integer(unsigned(write_address2))) <= datain2;	
					END IF;
				END IF;
		END PROCESS;
		dataout1 <= ram(to_integer(unsigned(read_address1)));
		dataout2 <= ram(to_integer(unsigned(read_address2)));

end architecture behavioral;
