LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
USE work.definitions.all;

ENTITY ExceptionUnit IS
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        exception_vector : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- protected memory access & overflow
        overflow_exception_pc : IN STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);
        protected_memory_exception_pc: IN STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);
        exception_raised : OUT STD_LOGIC;
        exception_type : OUT STD_LOGIC;                     -- 0 = overflow, 1 = protected memory access
        exception_handler_done : OUT STD_LOGIC;
        EPC : OUT STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0)
    );
END ENTITY ExceptionUnit;

ARCHITECTURE BEHAVIORAL OF ExceptionUnit IS

    -- ECU SIGNALS
    SIGNAL exception_raised_internal : STD_LOGIC;
    SIGNAL exception_type_internal : STD_LOGIC;
    -- EPC SIGNALS
    SIGNAL EPC_internal : STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);

    -- EXCEPTION HANDLER SIGNALS
    SIGNAL exception_handler_done_internal : STD_LOGIC;
    SIGNAL exception_handler_pc : STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);
    signal exception_handler_counter : unsigned(3 downto 0) := (others => '0');
BEGIN

    -- ECU
    exception_raised_internal <= '0' when reset = '1' else (exception_vector(1) OR exception_vector(0));
    exception_raised <= exception_raised_internal;
    exception_type_internal <= '0' when reset = '1' else exception_vector(1);
    exception_type <= exception_type_internal;

    -- EPC
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            EPC_internal <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF exception_raised_internal = '1' THEN
                IF exception_type_internal = '0' THEN
                    EPC_internal <= overflow_exception_pc;
                ELSE
                    EPC_internal <= protected_memory_exception_pc;
                END IF;
            ELSIF exception_handler_done_internal = '1' THEN          -- IN CASE THE EXCEPTION HANDLER MODIFIED THE EPC, WE CAPTURE THAT VALUE
                EPC_internal <= exception_handler_pc;
            ELSE
                EPC_internal <= EPC_internal;
            END IF;
        END IF;
    END PROCESS;
    EPC <= EPC_internal;

    -- EXCEPTION HANDLER : This is a dummy implementation, it could be anything you want
    -- IT OPERATES AT THE SAME CLOCK EDGE AS THE PIPELINE REGISTERS
    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            exception_handler_counter <= (others => '0');
            exception_handler_done_internal <= '0';
            exception_handler_pc <= (OTHERS => '0');
        ELSIF falling_edge(clk) THEN
            IF (exception_raised_internal = '1' OR exception_handler_counter > 0)THEN
                IF(exception_handler_counter = 3) THEN
                    exception_handler_counter <= (others => '0');
                    exception_handler_done_internal <= '1';
                    -- exception_handler_pc <= std_logic_vector(unsigned(EPC_internal) + 1); -- we would like ADD 1 in order to get the pc of the next instruction, but we already have it, so no need to add 1 
                    exception_handler_pc <= EPC_internal; -- This is made temporary until we modify our pipeline to pass the PC of current instruction
                ELSE
                    exception_handler_counter <= exception_handler_counter + 1;
                    exception_handler_done_internal <= '0';
                    exception_handler_pc <= (OTHERS => '0');
                END IF;
            ELSE
                exception_handler_counter <= (others => '0');
                exception_handler_done_internal <= '0';
                exception_handler_pc <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;
    exception_handler_done <= exception_handler_done_internal;

END BEHAVIORAL;