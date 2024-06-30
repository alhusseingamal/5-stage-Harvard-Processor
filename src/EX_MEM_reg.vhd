LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;

entity EX_MEM_reg is
    port(
        clk : IN std_logic;
        reset, flush : IN std_logic;
        WB_in : IN std_logic_vector(1 downto 0);
        WB_out : OUT std_logic_vector(1 downto 0);
        MemtoReg_in : IN std_logic;
        MemtoReg_out : OUT std_logic;
        MemWrite_in : IN std_logic;
        MemWrite_out : OUT std_logic;
        MemRead_in : IN std_logic;
        MemRead_out : OUT std_logic;
        is_imm_in: IN std_logic;
        is_imm_out: OUT std_logic;
        Protect_in : IN std_logic;
        Protect_out : OUT std_logic;
        Free_in : IN std_logic;
        Free_out : OUT std_logic;
        i_RET : IN std_logic;
        o_RET : OUT std_logic;
        i_RTI : IN std_logic;
        o_RTI : OUT std_logic;
        i_popCCR : IN std_logic;
        o_popCCR : OUT std_logic;
        stack_op_in : IN std_logic;
        stack_op_out : OUT std_logic;
        push_pop_in : IN std_logic;
        push_pop_out : OUT std_logic;
        PC_data_mem_sel_in : IN std_logic;
        PC_data_mem_sel_out : OUT std_logic;
        Rsrc2_data_mem_sel_in : IN std_logic;
        Rsrc2_data_mem_sel_out : OUT std_logic;
        CCR_data_mem_sel_in : IN std_logic;
        CCR_data_mem_sel_out : OUT std_logic;
        STD_data_mem_sel_in : IN std_logic;
        STD_data_mem_sel_out : OUT std_logic;
        swap_in : IN std_logic;
        swap_out : OUT std_logic;
        ALU_OUTPUT_in : IN std_logic_vector(31 downto 0);
        ALU_OUTPUT_out : OUT std_logic_vector(31 downto 0);
        src2_in : IN std_logic_vector(31 downto 0);
        src2_out : OUT std_logic_vector(31 downto 0);
        STD_in : IN std_logic_vector(31 downto 0);
        STD_out : OUT std_logic_vector(31 downto 0);
        PC_in : IN std_logic_vector(31 downto 0);
        PC_out : OUT std_logic_vector(31 downto 0);
        FLAGS_in : IN std_logic_vector(3 downto 0);
        FLAGS_out : OUT std_logic_vector(3 downto 0);
        Rt_in : IN std_logic_vector(2 downto 0);
        Rt_out : OUT std_logic_vector(2 downto 0);
        Rd_in : IN std_logic_vector(2 downto 0);
        Rd_out : OUT std_logic_vector(2 downto 0)
    );
end EX_MEM_reg;

architecture behavioral of EX_MEM_reg is

begin

    process(clk, reset)
    begin
        if reset = '1' then
            WB_out <= (others => '0');
            is_imm_out <='0';
            MemtoReg_out <= '0';
            MemWrite_out <= '0';
            MemRead_out <= '0';
            o_RET <= '0';
            o_RTI <= '0';
            o_popCCR <= '0';
            stack_op_out <= '0';
            push_pop_out <= '0';
            PC_data_mem_sel_out <= '0';
            Rsrc2_data_mem_sel_out <= '0';
            CCR_data_mem_sel_out <= '0';
            STD_data_mem_sel_out <= '0';
            swap_out <= '0';
            ALU_OUTPUT_out <= (others => '0');
            src2_out <= (others => '0');
            STD_out <= (others => '0');
            PC_out <= (others => '0');
            Rt_out <= (others => '0');
            Rd_out <= (others => '0');
            FLAGS_out <= (others => '0');
            Protect_out <= '0';
            Free_out <= '0';
        elsif falling_edge(clk) then
            if flush = '1' then
                WB_out <= (others => '0');
                is_imm_out <='0';
                MemtoReg_out <= '0';
                MemWrite_out <= '0';
                MemRead_out <= '0';
                o_RET <= '0';
                o_RTI <= '0';
                o_popCCR <= '0';
                stack_op_out <= '0';
                push_pop_out <= '0';
                PC_data_mem_sel_out <= '0';
                Rsrc2_data_mem_sel_out <= '0';
                CCR_data_mem_sel_out <= '0';
                STD_data_mem_sel_out <= '0';
                swap_out <= '0';
                ALU_OUTPUT_out <= (others => '0');
                src2_out <= (others => '0');
                STD_out <= (others => '0');
                PC_out <= (others => '0');
                Rt_out <= (others => '0');
                Rd_out <= (others => '0');
                FLAGS_out <= (others => '0');
                Protect_out <= '0';
                Free_out <= '0';
            else
                WB_out <= WB_in;
                is_imm_out <= is_imm_in;
                MemtoReg_out <= MemtoReg_in;
                MemWrite_out <= MemWrite_in;
                MemRead_out <= MemRead_in;
                Protect_out <= Protect_in;
                Free_out <= Free_in;
                o_RET <= i_RET;
                o_RTI <= i_RTI;
                o_popCCR <= i_popCCR;
                stack_op_out <= stack_op_in;
                push_pop_out <= push_pop_in;
                PC_data_mem_sel_out <= PC_data_mem_sel_in;
                Rsrc2_data_mem_sel_out <= Rsrc2_data_mem_sel_in;
                CCR_data_mem_sel_out <= CCR_data_mem_sel_in;
                STD_data_mem_sel_out <= STD_data_mem_sel_in;
                swap_out <= swap_in;
                ALU_OUTPUT_out <= ALU_OUTPUT_in;
                src2_out <= src2_in;
                STD_out <= STD_in;
                PC_out <= PC_in;
                Rt_out <= Rt_in;
                Rd_out <= Rd_in;
                FLAGS_out <= FLAGS_in;
            end if;
        end if;
    end process;

end behavioral;