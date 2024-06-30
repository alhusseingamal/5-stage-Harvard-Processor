LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity StackPointer is
    port(
        clk : in std_logic;
        reset : in std_logic;
        pushPopOp : in std_logic;
        stackOp: in std_logic;
        data_out : out std_logic_vector(31 downto 0)
    );
end StackPointer;

architecture Behavioral of StackPointer is
    signal SPValue : std_logic_vector(31 downto 0);
begin
    process(clk, reset)
    begin
        if reset = '1' then
            SPValue <= "00000000000000000000111111111111"; -- initial address of stack pointer = 2^12 - 1
        elsif falling_edge(clk) then
            if stackOp = '1' then
                if pushPopOp = '1' then
                    SPValue <= std_logic_vector(unsigned(SPValue) - 2);  -- push
                else
                    SPValue <= std_logic_vector(unsigned(SPValue) + 2);  -- pop
                end if;
            end if;
        end if;
    end process;
    data_out <= SPValue;
end architecture Behavioral;