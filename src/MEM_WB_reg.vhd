LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

entity MEM_WB_reg is
    port(
        clk : in std_logic;
        reset, flush : in std_logic;

        MemtoReg_in : IN std_logic;
        MemtoReg_out : OUT std_logic;

        is_imm_in: IN std_logic;
        is_imm_out: OUT std_logic;

        WB_in : IN std_logic_vector(1 downto 0);
        WB_out : OUT std_logic_vector(1 downto 0);

        swap_in : IN std_logic;
        swap_out : OUT std_logic;

        i_RET : IN std_logic;
        o_RET : OUT std_logic;

        i_RTI : IN std_logic;
        o_RTI : OUT std_logic;

        i_popCCR : IN std_logic;
        o_popCCR : OUT std_logic;

        ALU_OUTPUT_in : IN std_logic_vector(31 downto 0);
        ALU_OUTPUT_out : OUT std_logic_vector(31 downto 0);

        MEMORY_OUTPUT_in : IN std_logic_vector(31 downto 0);
        MEMORY_OUTPUT_out : OUT std_logic_vector(31 downto 0);

        src2_in : IN std_logic_vector(31 downto 0);
        src2_out : OUT std_logic_vector(31 downto 0);

        Rt_in : IN std_logic_vector(2 downto 0);
        Rt_out : OUT std_logic_vector(2 downto 0);

        Rd_in : IN std_logic_vector(2 downto 0);
        Rd_out : OUT std_logic_vector(2 downto 0)     
    );
end entity;

architecture behavioral of MEM_WB_reg is

signal WB1 : std_logic_vector(1 downto 0);
signal WB2 : std_logic_vector(1 downto 0);

begin
    process(clk, reset)
    begin
        if reset = '1' then
            MemtoReg_out <= '0';
            is_imm_out <= '0';
            WB_out <= (others => '0');
            swap_out <= '0';
            ALU_OUTPUT_out <= (others => '0');
            MEMORY_OUTPUT_out <= (others => '0');
            src2_out <= (others => '0');
            Rt_out <= (others => '0');
            Rd_out <= (others => '0');
            o_RET <= '0';
            o_RTI <= '0';
            o_popCCR <= '0';
        elsif falling_edge(clk) then
            if flush = '1' then
                MemtoReg_out <= '0';
                is_imm_out <= '0';
                WB_out <= (others => '0');
                swap_out <= '0';
                ALU_OUTPUT_out <= (others => '0');
                MEMORY_OUTPUT_out <= (others => '0');
                src2_out <= (others => '0');
                Rt_out <= (others => '0');
                Rd_out <= (others => '0');
                o_RET <= '0';
                o_RTI <= '0';
                o_popCCR <= '0';
            else
                MemtoReg_out <= MemtoReg_in;
                is_imm_out <= is_imm_in;
                WB_out <= WB_in;
                swap_out <= swap_in;
                ALU_OUTPUT_out <= ALU_OUTPUT_in;
                MEMORY_OUTPUT_out <= MEMORY_OUTPUT_in;
                src2_out <= src2_in;
                Rt_out <= Rt_in;
                Rd_out <= Rd_in;
                o_RET <= i_RET;
                o_RTI <= i_RTI;
                o_popCCR <= i_popCCR;
            end if;
        end if;
    end process;
end architecture;