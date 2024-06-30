LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BranchingUnit is
    port (
        clk : in std_logic;
        reset : in std_logic;
        -- BU in ID stage
        ID_PREDICTION : in std_logic; -- 1-BIT GLOBAL BRANCH PREDICTION OUTPUT (1 FOR TAKEN, 0 FOR NOT TAKEN)
        DO_NOT_PREDICT : in std_logic; -- ARE WE PREDICTING? (OUTPUT OF THE HDU)
        ID_BRANCH_TYPE : in std_logic; -- CONDITIONAL (1) OR UNCONDITIONAL (0)
        ID_IS_PREDICTED : out std_logic; -- IS THE BRANCH PREDICTED? (goes into the ID/EX pipeline register)

        retOp : in std_logic;
        retFlush : out std_logic;

        -- BU in EX stage
        ID_EX_IS_PREDICTED : in std_logic;      -- IS THE BRANCH PREDICTED TAKEN? (comes from the ID/EX pipeline register)
        ID_EX_JMP_TYPE : in std_logic;          -- 1 FOR CONDITIONAL JUMP, 0 FOR UNCONDITIONAL JUMP
        ID_EX_BRANCH : in std_logic;            -- IS IT A BRANCH INSTRUCTION? (comes from the ID/EX pipeline register)
        CCR_ZF : in std_logic;                  -- ZERO FLAG (comes from the ALU)
        ret_or_rti : in std_logic;              -- NOT RET OR RTI SIGNAL (comes from the control unit)
        RTI_signal_in : in std_logic;           -- RTI SIGNAL (comes from the control unit)
        PC_SELECT_1 : out std_logic;
        IS_WRONG_PREDICTION : out std_logic;
        FLUSH : out std_logic;
        EX_PC_MUX_SELECT : out std_logic_vector(1 downto 0);

        INT_STATE : in std_logic_vector(1 downto 0);
        BTA_forwarding_selector : out std_logic_vector(1 downto 0)
    );
end entity BranchingUnit;

architecture behavioral of BranchingUnit is
-- BU ID STAGE SIGNALS
signal BRANCHING : STD_LOGIC;

-- RET FSM signals
type ret_fsm_state_type is (ret_idle, ret_wait);
signal ret_fsm_internal_state : ret_fsm_state_type := ret_idle;
signal ret_fsm_counter : unsigned(3 downto 0) := (others => '0');

-- BU EX STAGE SIGNALS
signal ARE_WE_BRANCHING : STD_LOGIC;
signal IS_WRONG_PREDICTION_SIGNAL : STD_LOGIC;

begin

-- BU ID STAGE
ID_IS_PREDICTED <= ID_PREDICTION and (not DO_NOT_PREDICT) and ID_BRANCH_TYPE;

-- BU EX STAGE

-- WE BRANCH IF WE HAVE A (BRANCH INSTRUCTION) AND (THE JUMP IS UNCONDITIONAL OR THE ZERO FLAG IS SET)
ARE_WE_BRANCHING <= ID_EX_BRANCH AND (NOT ID_EX_JMP_TYPE OR CCR_ZF) AND (NOT ret_or_rti);
-- NOTE: THE TERM EXCLUDING THE CASES OF RET AND RTI IS UNNECESSARY, BUT IT IS INCLUDED FOR CLARITY AND FUTURE PROOFING

PC_SELECT_1 <= ARE_WE_BRANCHING XOR ID_EX_IS_PREDICTED; -- XOR GATE OUTPUT

-- WE ARE WRONG IF WE A HAVE A CONDTIONAL BRANCH, THE BRANCH DECISION IS DIFFERENT THAN THE PREDICTION (AND WE ARE NOT RETURNING FROM INTERRUPT?!)
IS_WRONG_PREDICTION_SIGNAL <= (ID_EX_JMP_TYPE) AND (ARE_WE_BRANCHING XOR ID_EX_IS_PREDICTED) AND (NOT RTI_signal_in);
IS_WRONG_PREDICTION <= IS_WRONG_PREDICTION_SIGNAL;

-- WE FLUSH IF WE ARE A BRANCHING INSTRUCTION AND (THE PREDICTION IS WRONG OR IF THE BRANCH IS UNCONDITIONAL)
FLUSH <= ID_EX_BRANCH AND (IS_WRONG_PREDICTION_SIGNAL OR (NOT ID_EX_JMP_TYPE)) AND (NOT ret_or_rti);


-- EX STAGE BRANCH TARGET ADDRESS MUX SELECTION
EX_PC_MUX_SELECT <= ID_EX_JMP_TYPE & ID_EX_IS_PREDICTED;
-- THE FOLLOWING ASSIGNMENT IS A PREVIOUS (AND PROBABLY INCORRECT) VERSION OF IT, IT IS LEFT FOR FUTURE REFERENCE
-- EX_PC_MUX_SELECT <= 
-- ((ARE_WE_BRANCHING XOR ID_EX_IS_PREDICTED) AND
-- ID_EX_IS_PREDICTED) OR (ID_EX_JMP_TYPE);


-- RET FSM
process(clk, reset)
    begin
        if reset = '1' then
            ret_fsm_internal_state <= ret_idle;
        elsif falling_edge(clk) then
            if (retOp = '1' or ret_fsm_internal_state = ret_wait) then
                case (ret_fsm_internal_state) is
                    when ret_idle =>
                        ret_fsm_internal_state <= ret_wait;
                    when ret_wait =>
                        if (ret_fsm_counter = 2) then
                            ret_fsm_internal_state <= ret_idle;
                            ret_fsm_counter <= (others => '0');
                        else
                            ret_fsm_internal_state <= ret_wait;
                            ret_fsm_counter <= ret_fsm_counter + 1;
                        end if;
                    when others =>
                        ret_fsm_internal_state <= ret_idle;
                end case;
            end if;
        end if;
    end process;

    retFlush <= '1' when retOp = '1' or ret_fsm_internal_state = ret_wait else '0';

    -- Branch Address Forwarding
    BTA_forwarding_selector <= "01" when INT_STATE = "01" and ARE_WE_BRANCHING = '1' else   -- Forward BTA to EX stage
                               "10" when INT_STATE = "10" and ARE_WE_BRANCHING = '1' else   -- Forward BTA to ID stage
                               "11" when INT_STATE = "11" and ARE_WE_BRANCHING = '1' else   -- Forward BTA to IF stage
                               "00";

    -- A special scenario to be handled is when an interrupt is raised while a branching instruction is in the pipeline (IF, ID, EX)
    -- In this scenario, we cannot just take the pc of the instruction that would be executed had a branch instruction not been there
    -- This is because the branching instruction itself may change the address of the instruction to be executed
    -- If we are branching, and an interrupt is raised, we forward the branch target address in place of the address of the next instruction
    -- to be pushed onto the stack, that is the PUSH PC state of the interrupt signal is performed where the PC is the branch target address

    -- We wait until the branch decision is made (EX stage); when we know whether we are branching or not to the branch target address
    -- Thus, we need a signal to tell us when a branch instruction is in the EX stage
    -- We need to know if the branch was taken or not -> Both information are provided by the ARE_WE_BRANCHING signal

    -- 3 cases:
    -- 1] Interrupt at jump instruction in IF stage
    -- JUMP, <INT SIGNAL>        F   D   E   M   W
    -- <INT SEQUENCE: PUSH PC>       F   D   E   M   W
    -- -> Branch target address is forwarded to EX stage

    -- 2] Interrupt at jump instruction in ID stage
    -- JUMP                     F   D   E   M   W
    -- ADD, <INT SIGNAL>            F   D   E   M   W
    -- <INT SEQUENCE: PUSH PC>          F   D   E   M   W
    -- -> Branch target address is forwarded to ID stage

    -- 3] Interrupt at jump instruction in EX stage
    -- JUMP                     F   D   E   M   W
    -- ADD                          F   D   E   M   W
    -- ADD, <INT SIGNAL>                F   D   E   M   W
    -- <INT SEQUENCE: PUSH PC>              F   D   E   M   W
    -- -> Branch target address is forwarded to IF stage

    -- We need to be able to determine where was this instruction when the interrupt was raised
    -- We can determine that from the state of the interrupt at the time when the instruction is in the EX stage
    -- If int_fsm_internal_state = int_halt, then the instruction was in the IF stage when the interrupt was raised
    -- If int_fsm_internal_state = int_pushPC, then the instruction was in the ID stage when the interrupt was raised
    -- If int_fsm_internal_state = int_pushCCR, then the instruction was in the EX stage when the interrupt was raised
    
end architecture behavioral;