# Five-Stage, Harvard Architecture, RISC-ISA Processor  

<div align="center"><img src="https://github.com/alhusseingamal/5-stage-Harvard-Processor/blob/main/media/Processor.gif" alt="Processor GIF"></img></div>

This project implements a five-stage, pipelined, Harvard processor with a RISC ISA in VHDL. The code structure is self-documenting, easy to follow, and prioritizes clarity, maintainability and extensibility. Each submodule in the Processor is self-contained. This makes modifications easier and within a limited scope.  

## Processor Design
![Processor Design Diagram](https://github.com/alhusseingamal/5-stage-Harvard-Processor/blob/main/media/Processor.png)  

## Summary  

### The processor has 5 stages:  
- Fetch  
- Decode  
- Execute  
- Memory  
- Write Back  

## Submodules  

### Pipeline Registers  
Four registers (IF/ID, ID/EX, EX/MEM, MEM/WB) work at the falling clock edge, passing necessary signals to subsequent stages.  

### Program Counter  
Responsible for holding the address of the next instruction to be fetched.  

### Instruction Cache  
Stores the instructions to be executed by the processor.  

### Control Unit (CU)
Generates Control Signal.  

### Arithmetic Logic Unit (ALU)
An ALU that performs arithmetic, logical, and Shift Operations.

### Condition Code Register (CCR)
A Flag register for ALU Flags. It is responsible for storing the flags in cases of instructions that are not supposed to modify the flags.  

### Branching Unit (BU)  
The branching unit is divided into three parts:  

#### Branching Unit in ID Stage (BU_ID)  
Facilitates early branching in the ID stage for non-conditional branches or predicted taken branches.  

#### Branching Unit in EX Stage (BU_EX)  
Facilitates branching in the EX stage after the branch decision is made. It corrects wrong branching decisions taken in the ID stage or facilitates a branch in the EX stage if the branch decision is taken.  

#### Function Call Branching (RET_FSM)  
Handles branches from function calls, ensuring the correct return address and pipeline states (Flags, Signals, etc.).  

The BU also forwards the Branch Target Address in case of an interrupt interfering with the branching of a Jump instruction.  

### Prediction Unit (PU)  
Provides an interface for integrating a prediction unit with the BU. A 1-bit Global Branch Predictor is implemented, but a more complex prediction scheme can be easily integrated.  

### Forwarding Unit (FU)  
A full-forwarding unit responsible for forwarding data to ALU Operands or Memory Operands. It also handles double forwarding in case of SWAP operation.  

### Interrupt Unit (IU)  
Divided into two main parts:  

#### Interrupt Latch (INT_FSM)  
Executes a sequence that pushes the PC of the interrupted instruction and the Flag Register into the stack to restore them later. It fetches the address of the Interrupt Handler for execution.  

#### RTI_FSM  
A FSM with a sequence that correctly restores the instruction address and the Flag Register.  

### Exception Unit (EU)  
Captures raised exceptions, reports them, and starts the Exception Handler code. A dummy hardware exception handler is implemented for completeness to demonstrate program flow after an exception is raised.  

Two exceptions can be reported: Arithmetic Overflow exception in the EX stage and Accessing Protected Memory location in the MEM stage.  

### Stack Pointer (SP)  
Pushes and pops data into the stack memory, keeping track of the address of the top of the stack.  

### Data Memory (DM)  
16-bit wide data memory with 1 protection bit. The data memory controller selects the input to the data memory, the access address, and handles raising exceptions.  

### Input Port  
A port to which data can be written through I/O operations.  

### Output Port
A port through data can be read through I/O operations.  


### More
#### I used the following textbook throughout the project to learn more about processor design:  
Computer Organization and Design - Fifth Edition - David A. Patterson & John L. Hennessy

#### Find the project Requriement [here](https://github.com/alhusseingamal/5-stage-Harvard-Processor/blob/main/Project%20CMP301%20Spring24.pdf)

#### Find the ISA design and control signals [here](https://docs.google.com/spreadsheets/d/1zjyA8mo_xPZetTjjhiIkFmT95-MTbjqX930M286H9xo/edit?gid=0#gid=0) or [here](https://github.com/alhusseingamal/5-stage-Harvard-Processor/blob/main/Harvard%20Processor-%20Instructions%20Design.xlsx)
