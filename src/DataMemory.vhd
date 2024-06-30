LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
USE work.definitions.all;

entity DataMemory is
    port(
        clk : IN std_logic;
        reset : IN STD_LOGIC := '0';
        stackOp : IN STD_LOGIC := '0';
        protect : IN STD_LOGIC := '0';
        free : IN STD_LOGIC := '0';
        MemRead : IN STD_LOGIC;
        MemWrite : IN STD_LOGIC;
        address: IN STD_LOGIC_VECTOR(DM_ADDRESS_WIDTH-1 downto 0);
        data_in: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_out: OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        exception : OUT STD_LOGIC
    );
end entity DataMemory;

ARCHITECTURE Behavioral OF DataMemory IS

    TYPE memory_array IS ARRAY(0 TO DM_SIZE-1) OF std_logic_vector(DM_DATA_WIDTH-1 DOWNTO 0);
    SIGNAL MEM : memory_array := (others => (others => '0'));

    TYPE protection_array IS ARRAY(0 to DM_SIZE-1) OF std_logic;
    SIGNAL PROTECTION_MEM : protection_array := (others => '0');
    SIGNAL internal_data_out : std_logic_vector(31 DOWNTO 0) := (others => '0');

    BEGIN
        PROCESS(clk, reset) IS
            BEGIN
                IF(reset = '1') THEN
                    MEM <= (others => (others => '0'));
                    PROTECTION_MEM <= (others => '0');
                    internal_data_out <= (others => '0');
                    exception <= '0';
                ELSIF rising_edge(clk) THEN  
                    IF MemWrite = '1' AND (protect = '0' and free = '0')THEN
                        IF PROTECTION_MEM(to_integer(unsigned(address))) = '0' THEN -- We need to add exception for else
                            IF stackOp = '1' THEN -- push operation
                                MEM(to_integer(unsigned(address))) <= data_in(15 downto 0); -- synchronous write
                                MEM(to_integer(unsigned(address))-1) <= data_in(31 downto 16); -- synchronous write
                            ELSE -- pop operation
                                MEM(to_integer(unsigned(address))) <= data_in(15 downto 0); -- synchronous write
                                MEM(to_integer(unsigned(address))+1) <= data_in(31 downto 16); -- synchronous write
                            END IF;
                        ELSE
                            exception <= '1';
                        END IF;   
                    END IF;
                    IF protect = '1' THEN
                        PROTECTION_MEM(to_integer(unsigned(address))) <= '1';
                    END IF;
                    IF free = '1' THEN
                        PROTECTION_MEM(to_integer(unsigned(address))) <= '0';   -- free the memory
                        MEM(to_integer(unsigned(address))) <= (others => '0');  -- reset the memory
                    END IF;
                    IF MemRead = '1' AND stackOp = '1' THEN
                        internal_data_out(31 downto 16) <= MEM(to_integer(unsigned(address))+1);
                        internal_data_out(15 downto 0) <= MEM(to_integer(unsigned(address))+2);
                    ELSIF MemRead = '1' THEN
                        internal_data_out(31 downto 16) <= MEM(to_integer(unsigned(address)));
                        internal_data_out(15 downto 0) <= MEM(to_integer(unsigned(address))+1);
                    END IF;
                END IF;
        END PROCESS;
        data_out <= internal_data_out;
END Behavioral;