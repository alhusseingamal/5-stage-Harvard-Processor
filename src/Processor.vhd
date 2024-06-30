LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.all;
use work.definitions.all;

Entity Processor is
Port(
    clk : in std_logic;
    reset : in std_logic;
    int : in std_logic := '0';
    INPUT_port_data : in std_logic_vector(DATA_WIDTH-1 DOWNTO 0) := (others => '0');
    OUTPUT_port_data : out std_logic_vector(DATA_WIDTH-1 DOWNTO 0) := (others => '0');
    exception_out: out std_logic
);
end Processor;

Architecture Behavioral of Processor is

    component InstructionCache is
    PORT(
        reset : in STD_LOGIC;
        PC_address : out std_logic_vector(31 DOWNTO 0);
        address : in std_logic_vector(IC_ADDRESS_WIDTH-1 DOWNTO 0);
        data_out : out std_logic_vector(INSTRUCTION_WIDTH-1 DOWNTO 0)
    );
    end component;

    component HazardDetectionUnit is
    port (
        EX_MemRead : in std_logic;
        EX_RegWrite1 : in std_logic;
        ID_IsBranch : in std_logic;
        ID_RegRead : in std_logic;
        EX_Rd : in std_logic_vector(2 downto 0);
        ID_Rt : in std_logic_vector(2 downto 0);
        ID_Rs : in std_logic_vector(2 downto 0);
        ID_Stall : out std_logic;
        DO_NOT_PREDICT : out std_logic
    );
    end Component;

    component PredictionUnit is
    Port(
         clk, rst: in std_logic;
         ID_EX_JMP_TYPE : IN std_logic;
         Prediction_is_wrong : IN std_logic;
         currentprediction : INOUT std_logic
    );
    end component;

    Component ProgramCounter is
        Port(
        clk : in std_logic;
        reset: in std_logic := '0';
        enable: in std_logic := '1';
        INT_STATE : in std_logic_vector(1 downto 0);
        RET_RTI_SIGNAL : in std_logic;
        RET_RTI_ADDRESS : in std_logic_vector(PC_BIT_COUNT - 1 downto 0);
        EXCEPTION_SIGNAL : in std_logic;
        EXCEPTION_HANDLED : in std_logic;
        EXCEPTION_RETURN_ADDRESS : in std_logic_vector(PC_BIT_COUNT - 1 downto 0);
        COUNT_IN : in std_logic_vector(PC_BIT_COUNT - 1 downto 0) := (others => '0');
        COUNT_OUT: out std_logic_vector(PC_BIT_COUNT - 1 downto 0) := (others => '0')
        );
    end Component;

    component InterruptUnit is
    port(
        clk : in std_logic;
        reset : in std_logic;
        interrupt : in std_logic;
        immediateOp : in std_logic;
        rtiOp : in std_logic;
        state : out std_logic_vector(1 downto 0);
        rtiPopCCR : out std_logic;
        rtiFlush : out std_logic;
        interrupt_on_imm : out std_logic
    );
    end component;

    component IF_ID_reg is
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
    end component;

    component signExtend is
        port(
            isUnsignedImmVal: in std_logic; 
            input_in : in std_logic_vector(15 downto 0);
            output_out : out std_logic_vector(31 downto 0)
        );
    end component;

    Component ControlUnit is
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
            type_of_operation: in std_logic_vector(1 downto 0);
            stackOp: out std_logic;
            pushPopOp: out std_logic;
            Rsrc2_mem_data: out std_logic; -- signal that will be used to select the data to be written to the memory
            savePC: out std_logic;
            saveCCR: out std_logic;
            STD_mem_data: out std_logic;
            is_imm: out std_logic;
            OutPort: out std_logic
        );
    end Component;

    component RegisterFile is
        generic (n : integer := 32);
        PORT(
            clk : in std_logic;
            reset : in std_logic;
            write_en1, write_en2  : in std_logic;
            write_address1, write_address2: in  std_logic_vector(2 DOWNTO 0);
            read_address1, read_address2  : in  std_logic_vector(2 DOWNTO 0);
            datain1,  datain2 : in  std_logic_vector(n-1 DOWNTO 0);
            dataout1, dataout2 : out std_logic_vector(n-1 DOWNTO 0)
        );
    end component;

    component ID_EX_reg is
        port (
            clk : in std_logic;
            reset, flush : in std_logic;
            WB_in : in std_logic_vector(1 downto 0);
            WB_out : out std_logic_vector(1 downto 0);
            RegRead_in : in std_logic_vector(1 downto 0);
            RegRead_out : out std_logic_vector(1 downto 0);
            is_imm_in: in std_logic;
            is_imm_out: out std_logic;
            MemtoReg_in : in std_logic;
            MemtoReg_out : out std_logic;
            MemWrite_in : in std_logic;
            MemWrite_out : out std_logic;
            MemRead_in : in std_logic;
            MemRead_out : out std_logic;
            AluSrc_in : in std_logic;
            AluSrc_out : out std_logic;
            ALUOp_in : in std_logic_vector(3 downto 0);
            ALUOp_out : out std_logic_vector(3 downto 0);
            Predicted_in : in std_logic;
            Predicted_out : out std_logic;
            branch_in : in std_logic;
            branch_out : out std_logic;
            jmp_in : in std_logic;
            jmp_out : out std_logic;
            Protect_in : in std_logic;
            Protect_out : out std_logic;
            Free_in : in std_logic;
            Free_out : out std_logic;
            i_RET : in std_logic;
            o_RET : out std_logic;
            i_RTI : in std_logic;
            o_RTI : out std_logic;
            i_popCCR : IN std_logic;
            o_popCCR : OUT std_logic;
            stack_op_in : in std_logic;
            stack_op_out : out std_logic;
            push_pop_in : in std_logic;
            push_pop_out : out std_logic;
            PC_data_mem_sel_in : in std_logic;
            PC_data_mem_sel_out : out std_logic;
            Rsrc2_data_mem_sel_in : in std_logic;
            Rsrc2_data_mem_sel_out : out std_logic;
            CCR_data_mem_sel_in : in std_logic;
            CCR_data_mem_sel_out : out std_logic;
            STD_data_mem_sel_in : in std_logic;
            STD_data_mem_sel_out : out std_logic;
            swap_in : in std_logic;
            swap_out : out std_logic;
            src1_in : in std_logic_vector(31 downto 0);
            src1_out : out std_logic_vector(31 downto 0);
            src2_in : in std_logic_vector(31 downto 0);
            src2_out : out std_logic_vector(31 downto 0);
            STD_in : in std_logic_vector(31 downto 0);
            STD_out : out std_logic_vector(31 downto 0);
            PC_in : in std_logic_vector(31 downto 0);
            PC_out : out std_logic_vector(31 downto 0);
            Rs_in : in std_logic_vector(2 downto 0);
            Rs_out : out std_logic_vector(2 downto 0);
            Rt_in : in std_logic_vector(2 downto 0);
            Rt_out : out std_logic_vector(2 downto 0);
            Rd_in : in std_logic_vector(2 downto 0);
            Rd_out : out std_logic_vector(2 downto 0);
            OutPortSignal_in : in std_logic;
            OutPortSignal_out : out std_logic 
        );
    end component;

    component BranchingUnit is
    port (
        clk : in std_logic;
        reset : in std_logic;
        -- BU in ID stage
        ID_PREDICTION : in std_logic; -- 1-BIT GLOBAL BRANCH PREDICTION OUTPUT (1 FOR TAKEN, 0 FOR NOT TAKEN)
        DO_NOT_PREDICT : in std_logic; -- ARE WE PREDICTING? (OUTPUT OF THE HDU)
        ID_BRANCH_TYPE : in std_logic; -- CONDITIONAL (1) OR UNCONDITIONAL (0)
        ID_IS_PREDICTED : out std_logic; -- IS THE BRANCH PREDICTED? (goes into the ID/EX pipeline register)

        -- RET operation
        retOp : in std_logic;
        retFlush : out std_logic;

        -- BU in EX stage
        ID_EX_IS_PREDICTED : in std_logic; -- IS THE BRANCH PREDICTED TAKEN? (comes from the ID/EX pipeline register)
        ID_EX_JMP_TYPE : in std_logic; -- 1 FOR UNCONDITIONAL JUMP, 0 FOR CONDITIONAL JUMP
        ID_EX_BRANCH : in std_logic; -- IS THE BRANCH TAKEN? (comes from control unit)
        CCR_ZF : in std_logic; -- ZERO FLAG (comes from the ALU)
        ret_or_rti : in std_logic;
        RTI_signal_in : in std_logic; -- RTI signal (comes from the control unit)
        PC_SELECT_1 : out std_logic;
        IS_WRONG_PREDICTION : out std_logic;
        FLUSH : out std_logic;
        EX_PC_MUX_SELECT : out std_logic_vector(1 downto 0);

        -- Branch Target Address forwarding for the case of interrupts with branching (jump) instructions
        INT_STATE : in std_logic_vector(1 downto 0);
        BTA_forwarding_selector : out std_logic_vector(1 downto 0)
    );
    end component;

    component ALU is
    Port ( 
        A, B : in  std_logic_vector(31 downto 0);
        Sel : in  std_logic_vector(3 downto 0);
        CCRIn : in  std_logic_vector(3 downto 0);
        F : out  std_logic_vector(31 downto 0);
        CCROut : out  std_logic_vector(3 downto 0)
    );
    end component;

    Component CCR is
        port (
            clk, rst, enable: in std_logic;
            i_ccr: in std_logic_vector(3 downto 0);
            o_ccr: out std_logic_vector(3 downto 0)
        );
    end Component;

    component ForwardingUnit is
        port (
        MEM_WB_RegWrite1 : in std_logic;
        EX_MEM_RegWrite1 : in std_logic;
        ID_EX_Rs : in std_logic_vector(2 downto 0);
        ID_EX_Rt : in std_logic_vector(2 downto 0);
        ID_EX_RsRead : in std_logic;
        ID_EX_RtRead : in std_logic;
        EX_MEM_Rd : in std_logic_vector(2 downto 0);
        MEM_WB_Rd : in std_logic_vector(2 downto 0);
        EX_MEM_Rt : in std_logic_vector(2 downto 0);
        MEM_WB_Rt : in std_logic_vector(2 downto 0);
        MEM_WB_RegWrite2 : in std_logic;
        EX_MEM_RegWrite2 : in std_logic;
        EX_MEM_SwapOp : in std_logic;
        MEM_WB_SwapOp : in std_logic;

        -- STD
        ID_EX_MemWrite : in std_logic;
        ID_EX_AluSrc : in std_logic;

        -- Outputs
        ForwardA : out std_logic_vector(2 downto 0);
        ForwardB : out std_logic_vector(2 downto 0);
        ForwardSTD : out std_logic_vector (1 downto 0)
        );
    end component;

    component EX_MEM_reg is
        port(
            clk : in std_logic;
            reset, flush : in std_logic;
            WB_in : in std_logic_vector(1 downto 0);
            WB_out : out std_logic_vector(1 downto 0);
            MemtoReg_in : in std_logic;
            MemtoReg_out : out std_logic;
            MemWrite_in : in std_logic;
            MemWrite_out : out std_logic;
            MemRead_in : in std_logic;
            MemRead_out : out std_logic;
            is_imm_in: in std_logic;
            is_imm_out: out std_logic;
            Protect_in : in std_logic;
            Protect_out : out std_logic;
            Free_in : in std_logic;
            Free_out : out std_logic;
            i_RET : in std_logic;
            o_RET : out std_logic;
            i_RTI : in std_logic;
            o_RTI : out std_logic;
            i_popCCR : IN std_logic;
            o_popCCR : OUT std_logic;
            stack_op_in : in std_logic;
            stack_op_out : out std_logic;
            push_pop_in : in std_logic;
            push_pop_out : out std_logic;
            PC_data_mem_sel_in : in std_logic;
            PC_data_mem_sel_out : out std_logic;
            Rsrc2_data_mem_sel_in : in std_logic;
            Rsrc2_data_mem_sel_out : out std_logic;
            CCR_data_mem_sel_in : in std_logic;
            CCR_data_mem_sel_out : out std_logic;
            STD_data_mem_sel_in : in std_logic;
            STD_data_mem_sel_out : out std_logic;
            swap_in : in std_logic;
            swap_out : out std_logic;
            ALU_OUTPUT_in : in std_logic_vector(31 downto 0);
            ALU_OUTPUT_out : out std_logic_vector(31 downto 0);
            src2_in : in std_logic_vector(31 downto 0);
            src2_out : out std_logic_vector(31 downto 0);
            STD_in : in std_logic_vector(31 downto 0);
            STD_out : out std_logic_vector(31 downto 0);
            PC_in : in std_logic_vector(31 downto 0);
            PC_out : out std_logic_vector(31 downto 0);
            FLAGS_in : in std_logic_vector(3 downto 0);
            FLAGS_out : out std_logic_vector(3 downto 0);
            Rt_in : in std_logic_vector(2 downto 0);
            Rt_out : out std_logic_vector(2 downto 0);
            Rd_in : in std_logic_vector(2 downto 0);
            Rd_out : out std_logic_vector(2 downto 0)
        );
    end component;

    component StackPointer is
        port(
        clk : in std_logic;
        reset : in std_logic;
        pushPopOp : in std_logic;
        stackOp: in std_logic;
        data_out : out std_logic_vector(31 downto 0)
    );
    end component;

    component DataMemory is
        port(
        clk : in std_logic;
        reset : in STD_LOGIC := '0';
        stackOp : in STD_LOGIC := '0';
        protect : in STD_LOGIC := '0';
        free : in STD_LOGIC := '0';
        MemRead : in STD_LOGIC;
        MemWrite : in STD_LOGIC;
        address: in STD_LOGIC_VECTOR(DM_ADDRESS_WIDTH-1 downto 0);
        data_in: in STD_LOGIC_VECTOR(31 DOWNTO 0);
        data_out: out STD_LOGIC_VECTOR(31 DOWNTO 0);
        exception : OUT STD_LOGIC
    );
    end component;

    component ExceptionUnit is
        PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        exception_vector : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        overflow_exception_pc : IN STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);
        protected_memory_exception_pc: IN STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0);
        exception_raised : OUT STD_LOGIC;
        exception_type : OUT STD_LOGIC;
        exception_handler_done : OUT STD_LOGIC;
        EPC : OUT STD_LOGIC_VECTOR(PC_BIT_COUNT-1 DOWNTO 0)
    );
    end component;

    component MEM_WB_reg is
        port(
            clk : in std_logic;
            reset, flush : in std_logic;
            MemtoReg_in : in std_logic;
            MemtoReg_out : out std_logic;
            is_imm_in: in std_logic;
            is_imm_out: out std_logic;
            WB_in : in std_logic_vector(1 downto 0);
            WB_out : out std_logic_vector(1 downto 0);
            swap_in : in std_logic;
            swap_out : out std_logic;
            i_RET : in std_logic;
            o_RET : out std_logic;
            i_RTI : in std_logic;
            o_RTI : out std_logic;
            i_popCCR : IN std_logic;
            o_popCCR : OUT std_logic;
            ALU_OUTPUT_in : in std_logic_vector(31 downto 0);
            ALU_OUTPUT_out : out std_logic_vector(31 downto 0);
            MEMORY_OUTPUT_in : in std_logic_vector(31 downto 0);
            MEMORY_OUTPUT_out : out std_logic_vector(31 downto 0);
            src2_in : in std_logic_vector(31 downto 0);
            src2_out : out std_logic_vector(31 downto 0);
            Rt_in : in std_logic_vector(2 downto 0);
            Rt_out : out std_logic_vector(2 downto 0);
            Rd_in : in std_logic_vector(2 downto 0);
            Rd_out : out std_logic_vector(2 downto 0)     
        );
    end component;

    Component MUX_2x1 is
        GENERIC (n : INTEGER := 8);
        Port (
            I0, I1 : in STD_LOGIC_VECTOR(n-1 downto 0);
            S : in STD_LOGIC;
            F : out STD_LOGIC_VECTOR(n-1 downto 0)
        );
    end Component;

    Component MUX_4x1 is
        GENERIC (n : INTEGER := 8);
        Port (
            I0, I1, I2, I3 : in STD_LOGIC_VECTOR(n-1 downto 0);
            S : in STD_LOGIC_VECTOR(1 downto 0);
            F : out STD_LOGIC_VECTOR(n-1 downto 0)
        );
    end Component;

    Component MUX_8x1 is
    GENERIC (n : INTEGER := 8);
    Port (
        I0, I1, I2, I3, I4, I5, I6, I7 : in STD_LOGIC_VECTOR(n-1 downto 0);
        S : in STD_LOGIC_VECTOR(2 downto 0);
        F : out STD_LOGIC_VECTOR(n-1 downto 0)
    );
    end component;

------------signal DECLARATION--------------
------------------- Interrupt signals--------------------
signal interrupt_fsm_state_IU, interrupt_fsm_state_IF_ID : std_logic_vector(1 downto 0);
signal rti_pop_ccr_state_IU, rti_flush_IU, ret_flush_BU, interrupt_on_imm_IU : std_logic;
signal HDU_stall_signal : std_logic := '0';
------------------- PC signals--------------------
signal ENABLE_PC : std_logic := '1';
signal pc_ret_rti_signal : std_logic := '0';
signal EXCEPTION_PC : std_logic := '0';
signal PC_MUX2_select : std_logic_vector(1 downto 0);
signal pc_branching_mux_selector : std_logic_vector(1 downto 0);
signal pc_branching_mux_output, PC_INPUT, pc_current, pc_next : std_logic_vector(PC_BIT_COUNT - 1 downto 0) := (others => '0');
------------------- INSTRUCTION CACHE Signals--------------------
signal ADDRESS_IC : std_logic_vector(IC_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal INSTRUCTION_IC, i_instruction_IF_ID, INSTRUCTION_IF_ID : std_logic_vector(INSTRUCTION_WIDTH-1 downto 0);
------------- IF_ID signals -------------
signal FLUSH_IF_ID : std_logic := '0';
signal WRITE_ENABLE_IF_ID : std_logic := '1';
signal pc_reset_address, pc_interrupt_address, pc_ret_rti_address, o_EPC : std_logic_vector(PC_BIT_COUNT-1 downto 0);
signal i_PC_IF_ID, PC_IF_ID, i_pc_ID_EX, i_pc_EX_MEM : std_logic_vector(PC_BIT_COUNT-1 downto 0);
signal INPortData_IF_ID : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
---------- RegisterFile signals ------------
signal RESET_GPRs : std_logic := '0';
signal RegWrite1_WB, RegWrite2_WB : std_logic;
signal Rs, Rt, Rd, Rd_2 : std_logic_vector(2 downto 0);
signal data_in1, data_in2, data_out1, data_out2 : std_logic_vector(DATA_WIDTH-1 downto 0);
---------- BranchingUnit signals ------------
signal PC_BRANCHING_MUX_SELECT_1, PREDICTION_IS_WRONG, flush_BU : std_logic;
signal branch_update_EX : std_logic_vector(PC_BIT_COUNT-1 downto 0);
signal EX_PC_MUX_SELECT_SIGNAL, BTA_forwarding_selector_BU : STD_LOGIC_VECTOR(1 DOWNTO 0);
---------- PREDICTOR signals ------------
signal PREDICTOR_OUTPUT, DO_NOT_PREDICT_HDU : std_logic;
--------------ControlUnit signals-------------
signal Opcode_CU : std_logic_vector(2 downto 0);
signal ALUOp_CU : std_logic_vector(3 downto 0);
signal RegDst_CU, RegWrite_CU, RegWrite2_CU, RegRead_CU, RegRead2_CU, ALUSrc_CU, PCSrc_CU, MemRead_CU, MemWrite_CU, MemToReg_CU : std_logic;
signal Branch_CU, Jump_CU, stackOp_CU, InOp_CU, pushPopOp_CU, RET_CU, RTI_CU : std_logic;
signal Rsrc2_data_mem_selector : std_logic;
signal STD_data_mem_selector : std_logic;
signal LDM_signal_CU, savePC_CU, saveCCR_CU, is_imm_CU, is_imm_ID_EX, is_imm_EX_MEM, is_imm_MEM_WB : std_logic;
signal OutportSignal_ID_EX, OutportSignal_EX_MEM : std_logic;

--- Other signals
signal signExtensionOutput: std_logic_vector(31 downto 0);
----------- ID_EX signals ------------
signal MemtoReg_ID_EX, MemWrite_ID_EX, MemRead_ID_EX, AluSrc_ID_EX : std_logic := '0';
signal i_RegRead_ID_EX, o_RegRead_ID_EX, i_WB_ID_EX, WB_ID_EX : std_logic_vector(1 downto 0) := (others => '0');
signal ALUOp_ID_EX : std_logic_vector(3 downto 0) := (others => '0');
signal FLUSH_ID_EX, Protect_CU, Protect_ID_EX, Free_CU, Free_ID_EX : std_logic := '0';

signal rtiPopCCR_ID_EX, ret_ID_EX, rti_ID_EX : std_logic := '0';
signal stackOp_ID_EX, pushPopOp_ID_EX : std_logic := '0';
signal savePC_ID_EX : std_logic := '0';
signal Rsrc2_data_mem_selector_OUTPUT_ID_EX : std_logic := '0';
signal saveCCR_ID_EX : std_logic := '0';
signal STD_data_mem_selector_OUTPUT_ID_EX : std_logic := '0';

signal SwapOp_CU, swapOp_ID_EX : std_logic := '0';
signal PC_ID_EX : std_logic_vector(PC_BIT_COUNT-1 downto 0) := (others => '0');
signal i_STD_ID_EX, o_STD_ID_EX, i_src1_ID_EX, o_src1_ID_EX, i_src2_ID_EX, o_src2_ID_EX : std_logic_vector(DATA_WIDTH-1 downto 0);
signal Rs_ID_EX, Rt_ID_EX, Rd_ID_EX : std_logic_vector(2 downto 0) := (others => '0');
signal IsPredictedTaken_BU_ID, IsPredictedTaken_ID_EX, IsBranch_ID_EX, JumpType_ID_EX : std_logic := '0';

------ ALU signals ------
signal A_ALU, B_ALU, F_ALU : std_logic_vector(DATA_WIDTH-1 downto 0);
signal SEL_ALU : std_logic_vector(3 downto 0);
------ Forwarding Unit signals ------
signal ForwardA, ForwardB : std_logic_vector(2 downto 0) := (others => '0'); -- ALU operands mux selectors
signal ForwardSTD : std_logic_vector(1 downto 0) := (others => '0'); -- STD instruction mux selector
------ CCR signals ------
signal i_ccr, o_ccr, o_FLAGS_ALU : std_logic_vector(3 downto 0) := (others => '0');
signal ENABLE_CCR : std_logic := '1';
------ EX_MEM signals ------------
signal MemtoReg_EX_MEM, MemWrite_EX_MEM, MemRead_EX_MEM, stackOp_EX_MEM, pushPopOp_EX_MEM : std_logic := '0';
signal WB_EX_MEM : std_logic_vector(1 downto 0) := (others => '0');
signal PC_data_mem_selector_INPUT_EX_MEM : std_logic := '0';
signal savePC_EX_MEM, saveCCR_EX_MEM : std_logic := '0';
signal Rsrc2_data_mem_selector_INPUT_EX_MEM : std_logic := '0';
signal Rsrc2_data_mem_selector_OUTPUT_EX_MEM : std_logic := '0';
signal CCR_data_mem_selector_INPUT_EX_MEM : std_logic := '0';
signal STD_data_mem_selector_INPUT_EX_MEM : std_logic := '0';
signal STD_data_mem_selector_OUTPUT_EX_MEM : std_logic := '0';

signal Protect_EX_MEM, Free_EX_MEM, rtiPopCCR_EX_MEM, ret_EX_MEM, swapOp_EX_MEM : std_logic := '0';
signal rti_EX_MEM, rti_MEM_WB, i_ret_or_rti_BU : std_logic := '0';
signal protected_memory_exception, o_exception_type_EU, o_exception_raised_EU, o_EXCEPTION_HANDLER_DONE : std_logic := '0';
signal i_exception_vector_EU : std_logic_vector(1 downto 0);

signal PC_EX_MEM : std_logic_vector(PC_BIT_COUNT-1 downto 0) := (others => '0');
signal STDOp_Data_STD_MUX : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal STDOp_Data_EX_MEM : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal FLAGS_EX_MEM : std_logic_vector(3 downto 0) := (others => '0');
signal src2_EX_MEM : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
signal Rt_EX_MEM, Rd_EX_MEM : std_logic_vector(2 downto 0) := (others => '0');
signal ALUOp_EX_MEM : std_logic_vector(3 downto 0) := (others => '0');
signal o_ALU_EX_MEM, o_ALU_MEM_WB : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

signal address_DM, address_SP : std_logic_vector(DM_ADDRESS_WIDTH-1 downto 0) := (others => '0');
signal i_DM, o_DM, o_DM_MEM_WB, data_WB : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

signal MemtoReg_MEM_WB, SwapOp_MEM_WB, RET_MEM_WB, rtiPopCCR_MEM_WB : std_logic := '0';
signal RegWrite_MEM_WB : std_logic_vector(1 downto 0) := (others => '0');
signal src2_MEM_WB : std_logic_vector(31 downto 0) := (others => '0');
signal Rt_MEM_WB, Rd_MEM_WB : std_logic_vector(2 downto 0) := (others => '0');
signal WB_MUX_SELECT : std_logic_vector(1 downto 0);
---------------------------
BEGIN
------------INSTANCE DECLARATION--------------

-- PC Connections --
-- pc_next <= std_logic_vector(unsigned(pc_current) + 1);
-- For the pop ccr state, we hardwire insert another RTI instruction into the pipeline, hence we need to keep the same PC
-- It is like the RTI is executed twice (once for the pop ccr and once for the pop pc)
pc_next <= pc_current when rti_pop_ccr_state_IU = '1' else std_logic_vector(unsigned(pc_current) + 1);

pc_branching_mux_selector <= PC_BRANCHING_MUX_SELECT_1 & IsPredictedTaken_BU_ID;
PC_BRANCHING_MUX : MUX_4x1
generic map(n => 32)
port map
(
    I0 => pc_next,                          -- PC + 1
    I1 => data_out1 ,                       -- Predicted PC from the ID stage
    I2 => branch_update_EX,                 -- 0 => Branch Target Address, 1 => PC of the instruction next to the instruction in the EX stage
    I3 => (others => '0'),                  -- garbage value, for now at least
    S => pc_branching_mux_selector,
    F => pc_branching_mux_output
);

PC_MUX2_select <= reset & interrupt_fsm_state_IU(1);
PC_MUX2 : MUX_4x1
generic map(n => 32)
port map
(
    I0 => pc_branching_mux_output,
    I1 => pc_interrupt_address,
    I2 => pc_reset_address,
    I3 => x"00000000",
    S => PC_MUX2_select,
    F => PC_INPUT
);

ENABLE_PC <= not HDU_stall_signal;
pc_ret_rti_address <= data_WB;
pc_ret_rti_signal <= (RET_MEM_WB or RTI_MEM_WB);-- and not rtiPopCCR_MEM_WB);
-- RET or RTI signal from but not an rti in the pop ccr state
-- This is a complete condition, but I believe the term (not rtiPopCCR_MEM_WB) could be removed without problems
-- since the in the pop ccr state, yes we will be a garbage value for pc_ret_rti_signal
-- but we are still flushing the IF/ID pipeline register, so this garbage value will not be used anyway

PC: ProgramCounter
    port map(
    clk => clk, reset => reset, enable => ENABLE_PC,
    INT_STATE => interrupt_fsm_state_IU,
    RET_RTI_SIGNAL => pc_ret_rti_signal, RET_RTI_ADDRESS => pc_ret_rti_address,
    EXCEPTION_SIGNAL => o_exception_raised_EU,
    EXCEPTION_HANDLED => o_EXCEPTION_HANDLER_DONE,
    EXCEPTION_RETURN_ADDRESS => o_EPC,
    COUNT_IN => PC_INPUT, COUNT_OUT => pc_current
);

IU: InterruptUnit
port map(
    clk => clk,
    reset => reset,
    interrupt => int,
    immediateOp => is_imm_CU,
    rtiOp => RTI_CU,
    state => interrupt_fsm_state_IU,
    rtiPopCCR => rti_pop_ccr_state_IU,
    rtiFlush => rti_flush_IU,
    interrupt_on_imm => interrupt_on_imm_IU
);
-- Based on the state of the interrupt FSM, the PC will be set to the interrupt handler address
-- The interrupt address is read on 2 cycles, the first cycle reads the least significant 16 bits
-- and the second cycle reads the most significant 16 bits
-- Remember that we are reading on two cycles because the address bus of the instruction cache is 16 bits only
-- It is specified in the specification that the interrupt handler address is 32 bits
pc_interrupt_address <=
    x"0000" & INSTRUCTION_IC when interrupt_fsm_state_IU = "10" else                               -- {Zeros, IC[3]}
    INSTRUCTION_IC & pc_interrupt_address(15 downto 0) when interrupt_fsm_state_IU = "11" else     -- {IC[2], IC[3]}
    (others => '0');

-- Instruction Memory Connections --
ADDRESS_IC <=
    -- x"300" when (o_exception_raised_EU = '1') else   -- I believe this should have been here to prioritize exceptions over interrupts
    x"003" when (interrupt_fsm_state_IU = "10") else   -- At push PC state, we read IC[3], the least significant 16 bits of the ISR
    x"002" when (interrupt_fsm_state_IU = "11") else   -- At push CCR state, we read IC[2], the most significant 16 bits of the ISR
    pc_current(IC_ADDRESS_WIDTH-1 downto 0);

-- Note for future: Relate this condition to the assigning of the COUNT_OUT signal in the PC module
-- Maybe they should be combines in order to avoid confusion and to achieve the correct behavior in complex conditions
-- i.e. interrupts with exceptions, interrupts with interrupts, interrupts with ret/rti, exceptions with ret/rti, etc.

IC : InstructionCache
    port map(
    reset => reset,
    PC_address => pc_reset_address,
    address => ADDRESS_IC,
    data_out => INSTRUCTION_IC
);

HDU : HazardDetectionUnit
port map(
    EX_MemRead => MemRead_ID_EX,
    EX_RegWrite1 => WB_ID_EX(1),
    ID_IsBranch => Branch_CU,
    ID_RegRead => RegRead_CU,
    EX_Rd => Rd_ID_EX, ID_Rt => Rt, ID_Rs => Rs,
    ID_Stall => HDU_stall_signal,
    DO_NOT_PREDICT => DO_NOT_PREDICT_HDU
);

-- IF_ID Connections --
-- In case of RTI signal (pop CCR state), we need to insert another RTI for POP PC state
i_instruction_IF_ID <= "1110000000000100" when rti_pop_ccr_state_IU = '1'
else INSTRUCTION_IC;

FLUSH_IF_ID <=
(is_imm_CU and not interrupt_on_imm_IU)
or o_exception_raised_EU
or flush_BU
or IsPredictedTaken_BU_ID
or ret_flush_BU
or (RTI_CU and not rti_pop_ccr_state_IU)
or rti_flush_IU;
-- Notes for future:

-- Note on first condition:
-- flush on immediate, if immediate and interrupt we need the interrupt_fsm_state_IU to pass the pipeline, so we don't flush.
-- Other signals are garbage; they shouldn't affect the program flow.

-- Note on RTI-related conditions:
-- The last two lines are about flushing on an RTI instruction.
-- The 1st of them is about flushing RTI instruction in the pop PC state,
-- but not in the pop CCR state because another RTI is inserted following it for POP PC state, hence we don't flush it.
-- The 2nd line - rti_Flush_IU signal - is about flushing when the RTI FSM is still in the wait state.
-- The wait state is a state when we are waiting for the PC to be popped from the stack and is available for the PC to start fetching
-- the instruction at that address in order to resume execution from where the interrupt signal stopped.
-- The two conditions may be combined into one in the InterruptUnit, but I saw it is better to keep them separate

WRITE_ENABLE_IF_ID <= '1' when HDU_stall_signal = '0' else '0';

-- ONLY AT THE CASE OF AN INTERRUPT (SPECIFICALLY AT PUSH PC STATE), WE WANT THE CURRENT PC TO BE PUSHED TO THE STACK
-- ELSE FOR AN INTERRUPT ON AN IMMEDIATE INSTRUCTION, WE FLUSH THE INSTRUCTION IN THE ID STAGE AS WELL.
-- HENCE, WE HAVE TO RETURN TO IT; ITS ADDRESS IS THE PREVIOUS ONE.
-- ELSE, WE PROPAGATE THE PC OF THE NEXT INSTRUCTION
i_PC_IF_ID <= A_ALU when BTA_forwarding_selector_BU = "11"
else PC_NEXT when (reset = '0' AND interrupt_fsm_state_IU(1) = '0')
else std_logic_vector(unsigned(pc_current) - 1) when interrupt_on_imm_IU = '1'
else pc_current;

-- IN THE FUTURE, CONSIDER ACTUALLY FLUSHING BOTH INSTRUCTIONS IN IF AND ID STAGES AND MODIFY THE ABOVE ASSIGNMENT ACCORDINGLY
-- FROM WHAT I HAVE READ, THIS IS WHAT HAPPENS IN MODERN ARHITECTURES(ARM, MIPS, ETC.)

IF_ID: IF_ID_reg
    port map(
    clk => clk, reset => reset, flush => FLUSH_IF_ID,
    operation_type_in => interrupt_fsm_state_IU, operation_type_out => interrupt_fsm_state_IF_ID,
    write_enable => WRITE_ENABLE_IF_ID,
    instruction => i_instruction_IF_ID, instruction_out => INSTRUCTION_IF_ID,
    PC => i_PC_IF_ID, PC_out => PC_IF_ID,
    input_port_data => input_port_data, input_port_data_out => INPortData_IF_ID
);

PU: PredictionUnit
port map(
clk => clk, rst => reset,
ID_EX_JMP_TYPE => JumpType_ID_EX,
Prediction_is_wrong => PREDICTION_IS_WRONG,
currentprediction => PREDICTOR_OUTPUT
);

i_ret_or_rti_BU <= RET_ID_EX or RTI_ID_EX;

BU: BranchingUnit
port map(
    clk => clk, reset => reset,
    ID_PREDICTION => PREDICTOR_OUTPUT,
    DO_NOT_PREDICT => DO_NOT_PREDICT_HDU,
    ID_BRANCH_TYPE => Jump_CU,
    ID_IS_PREDICTED => IsPredictedTaken_BU_ID,
    retOp => RET_CU,
    retFlush => ret_flush_BU,
    ID_EX_IS_PREDICTED => IsPredictedTaken_ID_EX,
    ID_EX_JMP_TYPE => JumpType_ID_EX,
    ID_EX_BRANCH => IsBranch_ID_EX,
    CCR_ZF => o_ccr(0),
    RTI_signal_in => rtiPopCCR_ID_EX,
    ret_or_rti => i_ret_or_rti_BU,
    PC_SELECT_1 => PC_BRANCHING_MUX_SELECT_1,
    IS_WRONG_PREDICTION => PREDICTION_IS_WRONG,
    FLUSH => flush_BU,
    EX_PC_MUX_SELECT => EX_PC_MUX_SELECT_SIGNAL,
    INT_STATE => interrupt_fsm_state_IU,
    BTA_forwarding_selector => BTA_forwarding_selector_BU
);

BRANCHING_MUX_EX : MUX_4x1
generic map(n => 32)
PORT MAP(
    I0 => A_ALU, -- THE RETURNED SELCTORS SHOULD HANDLE THAT THIS IS NOT SELECTED
    I1 => A_ALU,
    I2 => A_ALU, -- branch target address
    I3 => PC_ID_EX,
    S => EX_PC_MUX_SELECT_SIGNAL,
    F => branch_update_EX
);


-- ControlUnit Connections --
Opcode_CU <=
    INSTRUCTION_IF_ID(15 downto 13) when (HDU_stall_signal /= '1' and interrupt_fsm_state_IF_ID(1) = '0')
    else "000";
CU: ControlUnit
    port map(
    Opcode => Opcode_CU, Func => INSTRUCTION_IF_ID(2 downto 0),
    ALUOp => ALUOp_CU, RegDst => RegDst_CU,
    RegWrite => RegWrite_CU, RegWrite2 => RegWrite2_CU, RegRead => RegRead_CU, RegRead2 => RegRead2_CU,
    ALUSrc => ALUSrc_CU, PCSrc => PCSrc_CU,
    MemRead => MemRead_CU, MemWrite => MemWrite_CU, MemtoReg => MemToReg_CU,
    Branch => Branch_CU, Jump => Jump_CU,
    Protect_signal => Protect_CU, Free_signal => Free_CU,
    RET_signal => RET_CU, RTI_signal => RTI_CU,
    LDM_signal => LDM_signal_CU,
    stackOp => stackOp_CU, pushPopOp => pushPopOp_CU,
    type_of_operation => interrupt_fsm_state_IF_ID,
    Rsrc2_mem_data => Rsrc2_data_mem_selector,
    savePC => savePC_CU, saveCCR => saveCCR_CU,
    STD_mem_data => STD_data_mem_selector,
    is_imm => is_imm_CU, swapOp => SwapOp_CU, InOp => InOp_CU,
    OutPort => OutportSignal_ID_EX
);

-- Register File Connections --
data_in1 <= data_WB;
data_in2 <= o_ALU_MEM_WB;
Rs <= INSTRUCTION_IF_ID(12 downto 10);
Rt <= INSTRUCTION_IF_ID(9 downto 7);
Rd <= INSTRUCTION_IF_ID(6 downto 4);

GPR: RegisterFile
    port map(
    clk => clk, reset => reset,
    write_en1 => RegWrite_MEM_WB(1), write_en2 => RegWrite_MEM_WB(0),
    read_address1 => Rs, read_address2 => Rt, 
    write_address1 => Rd_MEM_WB, write_address2 => Rt_MEM_WB,
    datain1 => data_in1, datain2 => data_in2, dataout1 => data_out1, dataout2 => data_out2
);

i_WB_ID_EX <= RegWrite_CU & RegWrite2_CU;

src1_MUX_ID : MUX_2x1 generic map(n => 32) port map
(
I0 => data_out1,
I1 => INPortData_IF_ID,
S => InOp_CU,
F => i_src1_ID_EX
);

signExt: signExtend port map(
isUnsignedImmVal => LDM_signal_CU,
input_in => INSTRUCTION_IC,
output_out => signExtensionOutput
);
  
src2_MUX_ID : MUX_2x1 generic map(n => 32) port map
(
I0 => data_out2,
I1 => signExtensionOutput,
S => ALUSrc_CU,
F => i_src2_ID_EX
);

i_STD_ID_EX <= data_out2;
i_RegRead_ID_EX <= RegRead_CU & RegRead2_CU;
FLUSH_ID_EX <= flush_BU or o_exception_raised_EU or ((ret_EX_MEM or rti_EX_MEM) and not rtiPopCCR_EX_MEM) or interrupt_on_imm_IU;

-- Forwarding Branch Target address to be saved (as the PC) in case of an interrupt arrives during the execution of a branch instruction
i_pc_ID_EX <= A_ALU when BTA_forwarding_selector_BU = "10"
else PC_IF_ID;
ID_EX: ID_EX_reg
    port map(
    clk => clk, reset => reset, flush => FLUSH_ID_EX,
    is_imm_in => is_imm_CU, is_imm_out => is_imm_ID_EX,
    WB_in => i_WB_ID_EX, WB_out => WB_ID_EX,
    RegRead_in => i_RegRead_ID_EX, RegRead_out => o_RegRead_ID_EX,
    MemtoReg_in => MemToReg_CU, MemtoReg_out => MemtoReg_ID_EX,
    MemWrite_in => MemWrite_CU, MemWrite_out => MemWrite_ID_EX,
    MemRead_in => MemRead_CU, MemRead_out => MemRead_ID_EX,
    AluSrc_in => ALUSrc_CU, AluSrc_out => AluSrc_ID_EX,
    ALUOp_in => ALUOp_CU, ALUOp_out => ALUOp_ID_EX,
    Predicted_in => IsPredictedTaken_BU_ID, Predicted_out => IsPredictedTaken_ID_EX,
    branch_in => Branch_CU, branch_out => IsBranch_ID_EX,
    jmp_in => Jump_CU, jmp_out => JumpType_ID_EX,
    Protect_in => Protect_CU, Protect_out => Protect_ID_EX,
    Free_in => Free_CU, Free_out => Free_ID_EX,
    i_RET => RET_CU, o_RET => ret_ID_EX,
    i_RTI => RTI_CU, o_RTI => rti_ID_EX,
    i_popCCR => rti_pop_ccr_state_IU, o_popCCR => rtiPopCCR_ID_EX,
    stack_op_in => stackOp_CU, stack_op_out => stackOp_ID_EX,
    push_pop_in => pushPopOp_CU, push_pop_out => pushPopOp_ID_EX,
    PC_data_mem_sel_in => savePC_CU, PC_data_mem_sel_out => savePC_ID_EX,
    Rsrc2_data_mem_sel_in => Rsrc2_data_mem_selector, Rsrc2_data_mem_sel_out => Rsrc2_data_mem_selector_OUTPUT_ID_EX,
    CCR_data_mem_sel_in => saveCCR_CU, CCR_data_mem_sel_out => saveCCR_ID_EX,
    STD_data_mem_sel_in => STD_data_mem_selector, STD_data_mem_sel_out => STD_data_mem_selector_OUTPUT_ID_EX,
    swap_in => SwapOp_CU, swap_out => swapOp_ID_EX,
    src1_in => i_src1_ID_EX, src1_out => o_src1_ID_EX,
    src2_in => i_src2_ID_EX, src2_out => o_src2_ID_EX,
    STD_in => i_STD_ID_EX, STD_out => o_STD_ID_EX,
    PC_in => i_pc_ID_EX, PC_out => PC_ID_EX,
    Rs_in => Rs, Rs_out => Rs_ID_EX,
    Rt_in => Rt, Rt_out => Rt_ID_EX,
    Rd_in => Rd, Rd_out => Rd_ID_EX,
    OutPortSignal_in => OutportSignal_ID_EX, OutPortSignal_out => OutportSignal_EX_MEM
);

FU: ForwardingUnit
port map(
    MEM_WB_RegWrite1 => RegWrite_MEM_WB(1), EX_MEM_RegWrite1 => WB_EX_MEM(1),
    ID_EX_Rs => Rs_ID_EX, ID_EX_Rt => Rt_ID_EX,
    ID_EX_RsRead => o_RegRead_ID_EX(1), ID_EX_RtRead => o_RegRead_ID_EX(0),
    EX_MEM_Rd => Rd_EX_MEM, MEM_WB_Rd => Rd_MEM_WB, EX_MEM_Rt => Rt_EX_MEM, MEM_WB_Rt => Rt_MEM_WB,
    MEM_WB_RegWrite2 => RegWrite_MEM_WB(0), EX_MEM_RegWrite2 => WB_EX_MEM(0),
    EX_MEM_SwapOp => swapOp_EX_MEM, MEM_WB_SwapOp => SwapOp_MEM_WB,
    ID_EX_MemWrite => MemWrite_ID_EX, ID_EX_AluSrc => AluSrc_ID_EX,
    ForwardA => ForwardA, ForwardB => ForwardB, ForwardSTD => ForwardSTD
);

STD_MUX : MUX_4x1
generic map(n => 32)
port map(
    I0 => o_STD_ID_EX,
    I1 => data_WB,
    I2 => o_ALU_EX_MEM,
    I3 => o_STD_ID_EX,
    S => ForwardSTD,
    F => STDOp_Data_STD_MUX
);

OperandA_MUX : MUX_8x1
generic map(n => 32)
port map(
    I0 => o_src1_ID_EX,
    I1 => data_WB,
    I2 => o_ALU_EX_MEM,
    I3 => (others => '0'),
    I4 => (others => '0'),
    I5 => o_ALU_MEM_WB,
    I6 => src2_EX_MEM,
    I7 => (others => '0'),
    S => ForwardA,
    F => A_ALU
);

OperandB_MUX : MUX_8x1
generic map(n => 32)
port map(
    I0 => o_src2_ID_EX,
    I1 => data_WB,
    I2 => o_ALU_EX_MEM,
    I3 => (others => '0'),
    I4 => (others => '0'),
    I5 => o_ALU_MEM_WB,
    I6 => src2_EX_MEM,
    I7 => (others => '0'),
    S => ForwardB,
    F => B_ALU
);

SEL_ALU <= ALUOp_ID_EX;
ALU_Unit: ALU
    port map(
    A => A_ALU,
    B => B_ALU,
    Sel => SEL_ALU,
    CCRIn => o_ccr,     -- In case of operations not affecting a flag(s), we feed this back as it is to the CCR (as if we are latching it)
    F => F_ALU,
    CCROut => o_FLAGS_ALU
);

OUTPUT_port_data <= A_ALU when OutportSignal_EX_MEM = '1' else (others => '0');

-- CCR Connections --

-- When should we be able to write to the CCR?
-- At any operation that uses the ALU (SEL_ALU /= "1111" and SEL_ALU /= "0100")
-- And when we are not in the RTI pop CCR state, regardless of the operation in the EX stage
ENABLE_CCR <= '0' when (SEL_ALU = "1111" or SEL_ALU = "0100") and (rtiPopCCR_MEM_WB = '0') else '1';
i_ccr <= o_DM_MEM_WB(3 downto 0) when rtiPopCCR_MEM_WB = '1' else o_FLAGS_ALU;

CCR_Unit: CCR port map(clk => clk, rst => reset, enable => ENABLE_CCR, i_ccr => i_ccr, o_ccr => o_ccr);

-- Forwarding Branch Target address to be saved (as the PC) in case of an interrupt arrives during the execution of a branch instruction
i_pc_EX_MEM <= A_ALU when BTA_forwarding_selector_BU = "01"
else PC_ID_EX;

EX_MEM: EX_MEM_reg
port map(
clk => clk,
reset => reset,
flush => o_exception_raised_EU,
is_imm_in => is_imm_ID_EX, is_imm_out => is_imm_EX_MEM,
WB_in => WB_ID_EX, WB_out => WB_EX_MEM,
MemtoReg_in => MemtoReg_ID_EX, MemtoReg_out => MemtoReg_EX_MEM,
MemWrite_in => MemWrite_ID_EX, MemWrite_out => MemWrite_EX_MEM,
MemRead_in => MemRead_ID_EX, MemRead_out => MemRead_EX_MEM,
Protect_in => Protect_ID_EX, Protect_out => Protect_EX_MEM,
Free_in => Free_ID_EX, Free_out => Free_EX_MEM,
i_RET => ret_ID_EX, o_RET => ret_EX_MEM,
i_RTI => rti_ID_EX, o_RTI => rti_EX_MEM,
i_popCCR => rtiPopCCR_ID_EX, o_popCCR => rtiPopCCR_EX_MEM,
stack_op_in => stackOp_ID_EX, stack_op_out => stackOp_EX_MEM,
push_pop_in => pushPopOp_ID_EX, push_pop_out => pushPopOp_EX_MEM,
PC_data_mem_sel_in => savePC_ID_EX, PC_data_mem_sel_out => savePC_EX_MEM,
Rsrc2_data_mem_sel_in => Rsrc2_data_mem_selector_OUTPUT_ID_EX, Rsrc2_data_mem_sel_out => Rsrc2_data_mem_selector_OUTPUT_EX_MEM,
CCR_data_mem_sel_in => saveCCR_ID_EX, CCR_data_mem_sel_out => saveCCR_EX_MEM,
STD_data_mem_sel_in => STD_data_mem_selector_OUTPUT_ID_EX, STD_data_mem_sel_out => STD_data_mem_selector_OUTPUT_EX_MEM,
FLAGS_in => o_ccr, FLAGS_out => FLAGS_EX_MEM,
swap_in => swapOp_ID_EX, swap_out => swapOp_EX_MEM,
ALU_OUTPUT_in => F_ALU, ALU_OUTPUT_out => o_ALU_EX_MEM,
src2_in => B_ALU, src2_out => src2_EX_MEM,
STD_in => STDOp_Data_STD_MUX, STD_out => STDOp_Data_EX_MEM,
PC_in => i_pc_EX_MEM,  PC_out => PC_EX_MEM,
Rt_in => Rt_ID_EX,  Rt_out => Rt_EX_MEM,
Rd_in => Rd_ID_EX,  Rd_out => Rd_EX_MEM
);

SP: StackPointer
port map(
clk => clk,
reset => reset,
pushPopOp => pushPopOp_EX_MEM,
stackOp => stackOp_EX_MEM,
data_out => address_SP
);

address_DM <= address_SP when stackOp_EX_MEM = '1' else o_ALU_EX_MEM;

-- DM Input Selector --
i_DM <=
    src2_EX_MEM when Rsrc2_data_mem_selector_OUTPUT_EX_MEM = '1' else
    PC_EX_MEM when savePC_EX_MEM = '1' else
    ("0000000000000000000000000000" & FLAGS_EX_MEM) when saveCCR_EX_MEM = '1' else
    STDOp_Data_EX_MEM when STD_data_mem_selector_OUTPUT_EX_MEM = '1' else
    (others => '0');

DM : DataMemory
port map(
clk => clk, reset => reset,
protect => Protect_EX_MEM, free => Free_EX_MEM,
stackOp => stackOp_EX_MEM,
MemRead => MemRead_EX_MEM, MemWrite => MemWrite_EX_MEM,
address => address_DM,
data_in => i_DM, data_out => o_DM,
exception => protected_memory_exception
);

i_exception_vector_EU <= protected_memory_exception & (o_FLAGS_ALU(1) and o_FLAGS_ALU(0)); -- Protected memory exception and the Overflow flag
EU: ExceptionUnit
port map(
clk => clk, reset => reset,
exception_vector => i_exception_vector_EU,
overflow_exception_pc => PC_ID_EX,
protected_memory_exception_pc => PC_EX_MEM,
exception_raised => o_exception_raised_EU,
exception_type => o_exception_type_EU,
exception_handler_done => o_EXCEPTION_HANDLER_DONE,
EPC => o_EPC
);

exception_out <= o_exception_raised_EU;

MEM_WB: MEM_WB_reg
port map(
clk => clk, reset => reset,
flush => o_exception_type_EU,    -- only flushed in case of a memory exception
is_imm_in => is_imm_EX_MEM, is_imm_out => is_imm_MEM_WB,
MemtoReg_in => MemtoReg_EX_MEM, MemtoReg_out => MemtoReg_MEM_WB,
WB_in => WB_EX_MEM, WB_out => RegWrite_MEM_WB,
swap_in => swapOp_EX_MEM, swap_out => SwapOp_MEM_WB,
ALU_OUTPUT_in => o_ALU_EX_MEM, ALU_OUTPUT_out => o_ALU_MEM_WB,
MEMORY_OUTPUT_in => o_DM, MEMORY_OUTPUT_out => o_DM_MEM_WB,
i_RET => ret_EX_MEM, o_RET => RET_MEM_WB,
i_RTI => rti_EX_MEM, o_RTI => rti_MEM_WB,
i_popCCR => rtiPopCCR_EX_MEM, o_popCCR => rtiPopCCR_MEM_WB,
src2_in => src2_EX_MEM, src2_out => src2_MEM_WB,
Rt_in => Rt_EX_MEM, Rt_out => Rt_MEM_WB, Rd_in => Rd_EX_MEM, Rd_out => Rd_MEM_WB
);

WB_MUX_SELECT <= (MemtoReg_MEM_WB & (SwapOp_MEM_WB or is_imm_MEM_WB));
WB_MUX : MUX_4x1
generic map(n => 32)
port map
(
    I0 => o_ALU_MEM_WB,
    I1 => src2_MEM_WB,
    I2 => o_DM_MEM_WB,
    I3 => (others => '0'), -- for now at least
    S => WB_MUX_SELECT,
    F => data_WB
);

END Behavioral;