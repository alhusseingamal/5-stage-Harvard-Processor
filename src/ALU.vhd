library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity ALU is
    Port ( 
        A, B : in  std_logic_vector(31 downto 0);
        Sel : in  std_logic_vector(3 downto 0);
        CCRIn : in  std_logic_vector(3 downto 0);
        F : out  std_logic_vector(31 downto 0);
        CCROut : out  std_logic_vector(3 downto 0)
    );
end ALU;

architecture Behavioral of ALU is
    signal F_internal : std_logic_vector(31 downto 0);
    signal zeroFlag, negativeFlag, carryFlag, overflowFlag : std_logic;
    signal tempF : std_logic_vector(32 downto 0);
    signal tempCin : std_logic;

begin
    with Sel select
        F_internal <=
	    (not A) when "0000", 							-- NOT
	    (not A) + "1" when "0001", 						-- NEG
	    A + "1" when "0010", 							-- INC
	    A - "1" when "0011", 							-- DEC
	    A when "0100", 									-- IN, MOV, SWAP
	    A + B when "0101" | "1011" | "1101" | "1110", 	-- ADD, ADDI, LDD, STD
	    A - B when "0110" | "1100" | "1010", 			-- SUB, SUBI, CMP
	    A and B when "0111", 							-- AND
	    A or B when "1000", 							-- OR
	    A xor B when "1001", 							-- XOR
	    (others => '0') when others; 					-- NOP, OUT, PUSH, POP, LDM, PROTECT, FREE, JZ, JMP, CALL, RET, RTI

    F <= F_internal;

    -- Zero Flag
    zeroFlag <= 
	'1' when (F_internal = "00000000000000000000000000000000") and 
   	    (Sel = "0000" or Sel = "0001" or Sel = "0010" or Sel = "0011" or Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100" or Sel = "0111" or Sel = "1000" or Sel = "1001" or Sel = "1010") else 
     	'0' when (F_internal /= "00000000000000000000000000000000") and 
   	    (Sel = "0000" or Sel = "0001" or Sel = "0010" or Sel = "0011" or Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100" or Sel = "0111" or Sel = "1000" or Sel = "1001" or Sel = "1010") else
	CCRIn(0);

    -- Carry Flag
    tempF <= 
	(("0" & A) + ("1")) when (Sel = "0010") else
	(("0" & A) - ("1")) when (Sel = "0011") else
	(("0" & A) + ("0" & B)) when (Sel = "0101" or Sel = "1011") else
	(("0" & A) - ("0" & B)) when (Sel = "0110" or Sel = "1100");

    carryFlag <= 
	tempF(32) when (Sel = "0010" or Sel = "0011" or Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100") else
	CCRIn(1);

    -- Overflow Flag
    tempCin <= 
	A(31) xor F_internal(31) when (Sel = "0010" or Sel = "0011") else
	A(31) xor B(31) xor F_internal(31) when (Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100");

    overflowFlag <= 
	tempCin xor carryFlag when (Sel = "0010" or Sel = "0011" or Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100") else
	CCRIn(2);

    -- Negative Flag
    negativeFlag <= 
	F_internal(31) when (Sel = "0000" or Sel = "0001" or Sel = "0010" or Sel = "0011" or Sel = "0101" or Sel = "1011" or Sel = "0110" or Sel = "1100" or Sel = "0111" or Sel = "1000" or Sel = "1001" or Sel = "1010") else
	CCRIn(3);

    CCROut <= (negativeFlag & overflowFlag & carryFlag & zeroFlag) when (Sel /= "1111" and Sel /= "0100") else "0000";
    
end Behavioral;