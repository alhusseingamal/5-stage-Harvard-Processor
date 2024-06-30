LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity IF_ID_reg is
    port(
        clk : in std_logic;
        reset : in std_logic;
        flush : in std_logic;
        write_enable : in std_logic;

        operation_type_in : in std_logic_vector(1 downto 0); -- 0 for push pc, 1 for push ccr this signal is used in case of interrupt the ouptut from the FSM 
        operation_type_out : out std_logic_vector(1 downto 0);

        instruction : in std_logic_vector(15 downto 0);
        instruction_out : out std_logic_vector(15 downto 0);

        PC : in std_logic_vector(31 downto 0);
        PC_out : out std_logic_vector(31 downto 0);

        input_port_data : in std_logic_vector(31 downto 0);
        input_port_data_out : out std_logic_vector(31 downto 0)
    );
end IF_ID_reg;

architecture Behavioral of IF_ID_reg is
begin 
    process(clk, reset)
    begin
        if reset = '1'then
            instruction_out <= (others => '0');
            PC_out <= (others => '0');
            input_port_data_out <= (others => '0');
            operation_type_out <= (others => '0');
        elsif falling_edge(clk) then
            if flush = '1' then
                instruction_out <= (others => '0');
                PC_out <= (others => '0');
                input_port_data_out <= (others => '0');
                operation_type_out <= (others => '0');
            elsif write_enable = '1' then
                instruction_out <= instruction;
                PC_out <= PC;
                input_port_data_out <= input_port_data;
                operation_type_out <= operation_type_in;
            end if;
        end if;
    end process;
end Behavioral;
    
