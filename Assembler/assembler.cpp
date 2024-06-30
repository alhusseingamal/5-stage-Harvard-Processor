#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>
#include <bitset>
#include <algorithm>
#include <cctype>

std::string intToBinaryString(int num, int length) {
    return std::bitset<16>(num).to_string().substr(16 - length);
}


std::vector<std::string> split(const std::string &s) {
    std::string s_copy = s;
    std::replace(s_copy.begin(), s_copy.end(), '(', ' ');
    std::replace(s_copy.begin(), s_copy.end(), ')', ' ');
    std::replace(s_copy.begin(), s_copy.end(), ',', ' ');

    std::stringstream ss(s_copy);
    std::vector<std::string> tokens;
    std::string token;
    while (std::getline(ss, token, ' ')) {
        if (!token.empty()) {
            tokens.push_back(token);
        }
    }
    return tokens;
}

bool isReservedLocation(int location) {
    return location == 0 || location == 1 || location == 2 || location == 3;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " input_file.asm\n";
        return 1;
    }

    std::string inputFileName = argv[1];
    std::ifstream inputFile(inputFileName);
    if (!inputFile.is_open()) {
        std::cerr << "Error: Unable to open input file.\n";
        return 1;
    }

    std::string outputFileName = inputFileName.substr(0, inputFileName.find_last_of('.')) + ".mem";
    std::ofstream outputFile(outputFileName);
    if (!outputFile.is_open()) {
        std::cerr << "Error: Unable to create output file.\n";
        return 1;
    }

    outputFile << "// memory data file (do not edit the following line - required for mem load use)\n// instance=/processor/InstructionCahce/memory_array\n// format=mti addressradix=d dataradix=s version=1.0 wordsperline=1" << std::endl;

    std::map<std::string, std::string> opcodes = {
        {"NOP", "000"},

        {"NOT", "001"},
        {"NEG", "001"},
        {"INC", "001"},
        {"DEC", "001"},

        {"OUT", "010"},
        {"IN", "010"},

        {"MOV", "011"},
        {"SWAP", "011"},
        {"ADD", "011"},
        {"SUB", "011"},
        {"AND", "011"},
        {"OR", "011"},
        {"XOR", "011"},
        {"CMP", "011"},

        {"ADDI", "100"},
        {"SUBI", "100"},
        {"LDM", "100"},
        {"LDD", "100"},
        {"STD", "100"},

        {"PUSH", "101"},
        {"POP", "101"},
        {"PROTECT", "101"},
        {"FREE", "101"},
        
        {"JZ", "110"},

        {"JMP", "111"},
        {"CALL", "111"},
        {"RET", "111"},
        {"RTI", "111"},
    };

    std::map<std::string, std::string> identifiers = {
        {"NOP", "0000"},

        {"NOT", "0000"},
        {"NEG", "0001"},
        {"INC", "0010"},
        {"DEC", "0100"},

        {"OUT", "0000"},
        {"IN", "0001"},

        {"MOV", "0000"},
        {"SWAP", "0001"},
        {"ADD", "0010"},
        {"SUB", "0011"},
        {"AND", "0100"},
        {"OR", "0101"},
        {"XOR", "0110"},
        {"CMP", "0111"},

        {"ADDI", "1000"},
        {"SUBI", "1001"},
        {"LDM", "1010"},
        {"LDD", "1011"},
        {"STD", "1100"},

        {"PUSH", "0000"},
        {"POP", "0001"},
        {"PROTECT", "0010"},
        {"FREE", "0100"},
        
        {"JZ", "0000"},

        {"JMP", "0000"},
        {"CALL", "0001"},
        {"RET", "0010"},
        {"RTI", "0100"},
    };

    std::string line;
    int currentMemoryLocation = 4;
    int lastMemoryLocation = 4;
    bool orgFlag = false;

    while (std::getline(inputFile, line)) {
        std::transform(line.begin(), line.end(), line.begin(), ::toupper);
        line.erase(line.begin(), std::find_if(line.begin(), line.end(), [](unsigned char ch) {
            return !std::isspace(ch);
        }));

        size_t hashPos = line.find('#');
        // If '#' is found, get the substring from the start of the line to just before '#'
        if (hashPos != std::string::npos) {
            line = line.substr(0, hashPos);
        }

        if (line.empty() || line[0] == '#')
            continue;

        if (line.substr(0, 4) == ".org" || line.substr(0, 4) == ".ORG"){
            lastMemoryLocation = currentMemoryLocation;
            currentMemoryLocation = std::stoi(line.substr(5,6), nullptr, 16);
            if (isReservedLocation(currentMemoryLocation)) {
                orgFlag = true;
            } else {
                orgFlag = false;
            }
            continue;
        }

        std::vector<std::string> tokens = split(line);
        std::string opcode = tokens[0];

        tokens.erase(std::remove_if(tokens.begin(), tokens.end(), [](const std::string& token) {
            return std::all_of(token.begin(), token.end(), [](char c) {
                return std::isspace(static_cast<unsigned char>(c));
            });
        }), tokens.end());

        std::string opcodeBinary = opcodes[opcode];
        
        std::string binaryInstruction;

        binaryInstruction += opcodeBinary;
        
        int numOperands = tokens.size() - 1;
        
        if (numOperands == 0) {
            if (opcode == "NOP"){
                binaryInstruction += "000000000";
            }
            else if (opcode == "RET" || opcode == "RTI"){
                binaryInstruction += "000";
                binaryInstruction += "000";
                binaryInstruction += "000";
            } else {
                int value = std::stoi(tokens[0], nullptr, 16);
                binaryInstruction += intToBinaryString(value, 16);
                outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;

                currentMemoryLocation++;
                if(currentMemoryLocation > 4){
                    orgFlag = false;
                }
                continue;
            }

        } else {
            if (orgFlag) {
                if (currentMemoryLocation < 4) {
                    currentMemoryLocation = 4;
                }
                else {
                    currentMemoryLocation = lastMemoryLocation;
                }
                orgFlag = false;
            }
        }
        if (numOperands == 1) {
            if (opcodeBinary == "001") {
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                binaryInstruction += "000";
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
            } else if (opcodeBinary == "010" || opcodeBinary == "101") {
                if (opcode == "OUT" ) {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += "000";
                    binaryInstruction += "000";
                } else if (opcode == "PUSH") {
                    binaryInstruction += "000";
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += "000";
                }
                 else if (opcode == "IN" || opcode == "POP") {
                    binaryInstruction += "000";
                    binaryInstruction += "000";
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                } else if (opcode == "PROTECT" || opcode == "FREE") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += "000";
                    binaryInstruction += "000";
                }
            } else if (opcodeBinary == "110" || opcodeBinary == "111") {
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                binaryInstruction += "000";
                binaryInstruction += "000";
            }
        }
        else if (numOperands == 2) {
            if (opcodeBinary == "100") {
                if (opcode == "LDM") {
                    binaryInstruction += "000";
                    binaryInstruction += "000";
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += identifiers[opcode];
                    outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;

                    int immediateValue = std::stoi(tokens[2], nullptr, 16);
                    std::string immediateBinary = intToBinaryString(immediateValue, 16);
                    outputFile << currentMemoryLocation + 1 << ": " << immediateBinary << std::endl;

                    currentMemoryLocation += 2;
                    continue;
                }
            } else if (opcodeBinary == "011") {
                if (opcode == "SWAP") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                }
                else if (opcode == "MOV") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                    binaryInstruction += "000";
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                } else if (opcode == "CMP") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                    binaryInstruction += "000";
                }
            } else {
                binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                binaryInstruction += "000";
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
            }
        }
        else if (numOperands == 3) {
            if (opcodeBinary == "100"){
                if (opcode == "LDD") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[3].substr(1)), 3);
                    binaryInstruction += "000";
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += identifiers[opcode];

                    outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;
            
                    int immediateValue = std::stoi(tokens[2], nullptr, 16);
                    std::string immediateBinary = intToBinaryString(immediateValue, 16);
                   
                    outputFile << currentMemoryLocation + 1 << ": " << immediateBinary << std::endl;

                    currentMemoryLocation += 2;
                    continue;

                } else if (opcode == "STD") {
                    binaryInstruction += intToBinaryString(std::stoi(tokens[3].substr(1)), 3);
                    binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                    binaryInstruction += "000";
                    binaryInstruction += identifiers[opcode];

                    outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;
            
                    int immediateValue = std::stoi(tokens[2], nullptr, 16);
                    std::string immediateBinary = intToBinaryString(immediateValue, 16);
                   
                    outputFile << currentMemoryLocation + 1 << ": " << immediateBinary << std::endl;

                    currentMemoryLocation += 2;
                    continue;
                }
                else if (opcode == "ADDI" || opcode == "SUBI"){
                binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                binaryInstruction += "000";
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
                binaryInstruction += identifiers[opcode];
                outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;

                int immediateValue = std::stoi(tokens[3], nullptr, 16);
                std::string immediateBinary = intToBinaryString(immediateValue, 16);
                outputFile << currentMemoryLocation + 1 << ": " << immediateBinary << std::endl;

                currentMemoryLocation += 2;
                continue;
                }
            }  else {
                binaryInstruction += intToBinaryString(std::stoi(tokens[2].substr(1)), 3);
                binaryInstruction += intToBinaryString(std::stoi(tokens[3].substr(1)), 3);
                binaryInstruction += intToBinaryString(std::stoi(tokens[1].substr(1)), 3);
            }
        }

        binaryInstruction += identifiers[opcode];

        outputFile << currentMemoryLocation << ": " << binaryInstruction << std::endl;

        currentMemoryLocation++;
    }

    std::cout << "Assembly file assembled successfully.\n";
    inputFile.close();
    outputFile.close();
    return 0;
}
