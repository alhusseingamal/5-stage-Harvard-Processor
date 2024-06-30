LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

Entity ControlUnit is
    Port(
        Opcode : in std_logic_vector(2 downto 0);
        Func : in std_logic_vector(2 downto 0);
        ALUOp : out std_logic_vector(3 downto 0);
        RegDst: out std_logic;
        RegWrite: out std_logic;
        RegWrite2: out std_logic;
        RegRead : out std_logic;
        RegRead2 : out std_logic;
        ALUSrc: out std_logic;
        PCSrc: out std_logic;
        MemRead: out std_logic;
        MemWrite: out std_logic;
        MemtoReg: out std_logic;
        Branch: out std_logic;
        Jump: out std_logic;
        swapOp : out std_logic;
        InOp : out std_logic;
        Protect_signal: out std_logic;
        Free_signal: out std_logic;
        RET_signal : out std_logic;
        RTI_signal: out std_logic;
        LDM_signal: out std_logic;
        type_of_operation: in std_logic_vector(1 downto 0); --  '1' in "10" or "11" for letting the ControlUnit this operation is for the intterrupt 10 for push pc, 11 for push ccr this signal will be used to select the data to be written to the memory in case of INT signal
        stackOp: out std_logic;
        pushPopOp: out std_logic;
        Rsrc2_mem_data: out std_logic; -- signal that will be used to select the data to be written to the memory
        savePC: out std_logic;
        saveCCR: out std_logic;
        STD_mem_data: out std_logic;
        is_imm: out std_logic;
        OutPort: out std_logic
    );
end ControlUnit;

Architecture Behavioral of ControlUnit is
    begin
        
        -- for now
        RegRead <= '0' when
        Opcode = "000" or -- NOP
        (Opcode = "010" and Func = "001") or                    -- IN operation
        (Opcode = "101" and (Func = "000" or Func = "001")) or  -- push and pop operations
        (Opcode = "100" and Func = "010") or                    -- LDM operation
        (Opcode = "111" and (Func = "010" or Func = "100"))     -- ret and rti operations
        else '1';

        RegRead2 <= '1' when
        (Opcode = "011" and Func /= "000") or -- Two Operands except for MOV operation
        (Opcode = "101" and Func = "000") or -- push operation
        (Opcode  = "100" and Func = "100") -- STD operation
        else '0';

        InOp <= '1' when Opcode = "010" and Func = "001" else '0';

        RegDst <= '1' when Opcode /= "000"; 

        OutPort <= '1' when Opcode = "010" and Func = "000" else '0';

        ALUSrc <= '1'when Opcode = "100" else '0'; -- 1 if immediate, 0 if register

        PCSrc <= '0';

        Protect_signal <= '1' when Opcode = "101" and Func = "010" else '0';

        Free_signal <= '1' when Opcode = "101" and Func = "100" else '0';

        RET_signal <= '1' when Opcode = "111" and Func = "010" else '0';
        RTI_signal <= '1' when Opcode = "111" and Func = "100" else '0';

        swapOp <= '1' when Opcode = "011" and Func = "001" else '0';

        stackOp <= '1' when
        (Opcode = "101" and (Func = "000" or Func = "001")) or                  -- push and pop operations
        (Opcode = "111" and (Func = "001" or Func = "010" or Func = "100")) or  -- call, ret, rti operations
        (type_of_operation(1) = '1') or                                         -- interrupt signal (pushPC or pushCCR states)
        (Opcode = "111" and Func = "111") -- What is this?
        else '0';
        
        pushPopOp <= '1' when                -- 1 for any operation/signal that will push to the stack
        (Opcode = "101" and Func = "000") or -- in case of PUSH operation
        (Opcode = "111" and Func = "001") or -- in case of CALL operation
        (type_of_operation(1) = '1')         -- in case of INT signal
        else '0';                            -- 0 for pop operations : ret (pop PC), rti (pop CCR, pop PC)

        Rsrc2_mem_data <= '1'
        when (Opcode = "101" and Func = "000")
        else '0'; -- in case of push
        
        savePC <= '1' when
        (Opcode = "111" and Func = "001") or    -- in case of CALL operation
        (type_of_operation = "10")              -- in case of INT signal (pushPC state)
        else '0';
        
        saveCCR <= '1' when
        (type_of_operation = "11")              -- in case of INT signal (pushCCR state)
        else '0';
        
        STD_mem_data <= '1' when (Opcode = "100" and Func = "100") else '0'; -- in case of STD
        
        is_imm <= '1' when Opcode = "100" else '0';
        
        RegWrite <= '1' when
        Opcode = "001" or -- all single operand operations : NOT, NEG, INC, DEC (opcode = 001)
        (Opcode = "011" and Func /= "111") or -- all two operands operations except for CMP
        (Opcode = "100" and Func /= "100") or -- all immediate operations except for STD
        (Opcode = "101" and Func = "001") or -- pop operation
        (Opcode = "010" and Func = "001") -- IN operation
        else '0';
        
        RegWrite2 <= '1' when Opcode = "011" and Func = "001" else '0';
        
        MemRead <= '1' when
        (Opcode = "101" and Func = "001") or -- pop operation
        (Opcode = "100" and Func = "011") or -- LDD operation
        (Opcode = "111" and (Func = "010" or Func = "100" or Func = "111")) -- ret and reti operations, but what is the last one?
        else '0';
        
        MemWrite <= '1' when
        (Opcode = "101" and Func /= "001") or   -- all operations with opcode = 101, except pop, write to memory (push, protect, free)
        (Opcode = "100" and Func = "100") or    -- STD operation
        (Opcode = "111" and Func = "001") or    -- call operation : write the PC + 1 to the memory
        (type_of_operation(1) = '1')            -- in case of interrupt we will push the PC and CCR to the memory
        else '0';
        
        MemtoReg <= '1' when
        (Opcode = "101" and Func = "001") or -- pop operation
        (Opcode = "100" and Func = "011") or -- LDD operation
        (Opcode = "111" and (Func = "010" or Func = "100")) -- ret and reti operations (probably not true, check this)
        else '0';
        
        LDM_signal <= '1' when Opcode = "100" and Func = "010" else '0';

        Branch <= '1' when Opcode = "111" or Opcode = "110" else '0'; -- 1 if branch instruction, 0 if not
        
        Jump <= '1' when Opcode = "110" else '0'; -- 1 if conditional branch, 0 if not conditional branch

        --One Operand   
        ALUOp <= "0000" when Opcode = "001" and Func = "000"
        else "0001" when Opcode = "001" and Func = "001"
        else "0010" when Opcode = "001" and Func = "010"
        else "0011" when Opcode = "001" and Func = "100"
        else "0100" when Opcode = "010" and Func = "001" -- IN operation
        else "0100" when Opcode = "101" and Func = "010"
        else "0100" when Opcode = "101" and Func = "100"
        --Two Operands
        else "0100" when Opcode = "011" and Func = "000"
        else "0100" when Opcode = "011" and Func = "001"
        else "0101" when Opcode = "011" and Func = "010"
        else "0110" when Opcode = "011" and Func = "011"
        else "0111" when Opcode = "011" and Func = "100"
        else "1000" when Opcode = "011" and Func = "101"
        else "1001" when Opcode = "011" and Func = "110"
        else "1010" when Opcode = "011" and Func = "111"
        --Immediate 
        else "1011" when Opcode = "100" and Func = "000"
        else "1100" when Opcode = "100" and Func = "001"
        else "1101" when Opcode = "100" and Func = "011"
        else "1110" when Opcode = "100" and Func = "100"
        else "1111";

end Behavioral;