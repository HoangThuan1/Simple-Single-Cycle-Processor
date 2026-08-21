# Simple 16-bit Single-Cycle Processor

A small educational **16-bit single-cycle CPU** written in **SystemVerilog**. The processor implements a complete fetch → decode → execute → memory → write-back datapath in which every instruction is completed within one clock cycle.

The design is intentionally compact and is intended for learning basic CPU organization, datapath construction, instruction decoding, register-file operation, ALU control, and memory access.

## Architecture Overview

The processor contains the following main blocks:

- **Program Counter (`ProgramCounter`)** — holds the byte address of the current instruction.
- **Instruction Memory (`InstructionMemory`)** — stores 16-bit instructions.
- **Control Unit (`ControlUnit`)** — decodes the 4-bit opcode and generates datapath control signals.
- **Register File (`Regfile`)** — 16 general-purpose 16-bit registers.
- **ALU (`ALU`)** — performs arithmetic, logic, and shift operations.
- **Data Memory (`DataMemory`)** — 256 × 16-bit data memory.
- **ALU-input multiplexer** — selects either register operand `rt` or a sign-extended 4-bit immediate.
- **Write-back multiplexer** — selects either the ALU result or data-memory output for register write-back.

The top-level integration is implemented in `top_module.sv`.

## Single-Cycle Datapath

For each clock cycle, the processor performs:

```text
PC
 │
 ▼
Instruction Memory
 │
 ▼
Instruction Decode
 │
 ├──────────────► Control Unit
 │
 ▼
Register File
 │
 ▼
ALU / Address Calculation
 │
 ├──────────────► Data Memory
 │
 ▼
Write-back MUX
 │
 ▼
Register File
```

There is no pipelining. The combinational datapath between clocked state elements must settle within one clock period.

## Program Counter and Instruction Fetch

The PC is 16 bits wide and advances by **2 bytes per clock cycle**:

```text
PC_next = PC + 2
```

This matches the 16-bit instruction width.

Instruction memory is word-organized internally but accessed from a byte-addressed PC:

```systemverilog
instr = rom[pc[15:1]];
```

The current implementation provides space for **64 instructions**.

Reset is asynchronous and sets the PC to `0x0000`.

## Instruction Format

All instructions are 16 bits wide:

```text
15          12 11           8 7            4 3            0
+--------------+--------------+--------------+--------------+
|    opcode    |      rd      |      rs      |   rt / imm   |
+--------------+--------------+--------------+--------------+
     4 bits         4 bits         4 bits         4 bits
```

Fields:

| Field | Bits | Description |
|---|---:|---|
| `opcode` | `[15:12]` | Selects the instruction |
| `rd` | `[11:8]` | Destination register |
| `rs` | `[7:4]` | First source/base register |
| `rt / imm` | `[3:0]` | Second source register or 4-bit immediate |

The low four bits are interpreted according to the instruction being executed.

## Instruction Set

The control unit currently decodes nine opcodes.

| Opcode | Mnemonic | Operation | Main control behaviour |
|---|---|---|---|
| `0001` | `ADD` | `R[rd] = R[rs] + R[rt]` | register write, ALU add |
| `0010` | `SUB` | `R[rd] = R[rs] - R[rt]` | register write, ALU subtract |
| `0011` | `AND` | `R[rd] = R[rs] & R[rt]` | register write, ALU AND |
| `0100` | `OR` | `R[rd] = R[rs] \| R[rt]` | register write, ALU OR |
| `0101` | `SHL` | `R[rd] = R[rs] << imm[3:0]` | immediate ALU operand, register write |
| `0110` | `SHR` | `R[rd] = R[rs] >> imm[3:0]` | immediate ALU operand, register write |
| `0111` | `LOADI` | conventionally `R[rd] = imm` with `rs = R0` | immediate add, register write |
| `1000` | `STORE` | store register data to memory | address add, memory write |
| `1001` | `LOAD` | load memory data into `rd` | address add, memory read, register write |

All other opcodes currently leave the control signals at their default inactive values.

## ALU Operations

The ALU is controlled by the 3-bit `aluctrl` signal:

| `aluctrl` | Operation |
|---|---|
| `000` | `A + B` |
| `001` | `A - B` |
| `010` | `A & B` |
| `011` | `A \| B` |
| `100` | `A << B[3:0]` |
| `101` | `A >> B[3:0]` |
| other | result = `0` |

The ALU also generates a `zero` flag:

```text
zero = 1 when result == 0
```

The current top-level datapath does not use this flag for branching.

## Immediate Handling

For instructions using an immediate operand, the 4-bit field `instr[3:0]` is sign-extended to 16 bits:

```systemverilog
imm_ext = {{12{instr[3]}}, instr[3:0]};
```

The ALU-input multiplexer then selects:

```text
ALU_B = alusrc ? imm_ext : R[rt]
```

Therefore the immediate range for arithmetic/address generation is:

```text
-8 ... +7
```

For `SHL` and `SHR`, the ALU uses only `B[3:0]` as the shift amount.

## Register File

The processor contains:

- **16 registers**: `R0`–`R15`
- **16 bits per register**
- two asynchronous read ports
- one synchronous write port

Register reads are selected by `rs` and `rt`.

Writes occur on the rising clock edge when `regwrite = 1`.

`R0` is protected from writes:

```systemverilog
if (regwrite && rd != 4'd0)
    regs[rd] <= writedata;
```

After reset, all registers are cleared to zero. This allows `R0` to act as a constant-zero register.

## LOADI Behaviour

`LOADI` uses the ALU add path rather than a dedicated immediate path:

```text
R[rd] = R[rs] + sign_extend(imm4)
```

The intended encoding convention is to set `rs = 0`, making `R0 = 0` and therefore:

```text
R[rd] = imm
```

Example:

```text
LOADI R1, #5
```

is encoded as:

```text
0111 0001 0000 0101
^^^^ ^^^^ ^^^^ ^^^^
op   rd   rs   imm
```

## Data Memory

`DataMemory` contains **256 words × 16 bits**.

Memory is indexed using:

```systemverilog
mem[addr[15:1]]
```

so the ALU produces a byte-style address while bit 0 is ignored for word access.

Memory behaviour:

- writes are synchronous on the rising clock edge;
- reads are combinational when `memread = 1`;
- when `memread = 0`, `readdata` is `0`.

### LOAD

For a load instruction:

```text
address = R[rs] + sign_extend(imm4)
R[rd]   = MEM[address]
```

The write-back multiplexer selects memory data because `memtoreg = 1`.

### STORE

For a store instruction, the current RTL computes:

```text
address = R[rs] + sign_extend(instr[3:0])
MEM[address] = R[rt]
```

There is an important implementation detail: **`rt` and `imm4` are the same physical field, `instr[3:0]`.** Therefore, in the current encoding, the same four bits simultaneously:

1. select the register whose value is written to memory; and
2. provide the signed address offset.

This is a limitation of the present instruction format/datapath and should be considered when extending the ISA.

## Control Signals

The control unit generates the following signals:

| Signal | Purpose |
|---|---|
| `regwrite` | enables register-file write-back |
| `alusrc` | selects immediate instead of `R[rt]` as ALU operand B |
| `memread` | enables data-memory read |
| `memwrite` | enables data-memory write |
| `memtoreg` | selects memory data for register write-back |
| `aluctrl[2:0]` | selects ALU operation |

Simplified control table:

| Instruction | RegWrite | ALUSrc | MemRead | MemWrite | MemToReg | ALUCtrl |
|---|---:|---:|---:|---:|---:|---|
| ADD | 1 | 0 | 0 | 0 | 0 | `000` |
| SUB | 1 | 0 | 0 | 0 | 0 | `001` |
| AND | 1 | 0 | 0 | 0 | 0 | `010` |
| OR | 1 | 0 | 0 | 0 | 0 | `011` |
| SHL | 1 | 1 | 0 | 0 | 0 | `100` |
| SHR | 1 | 1 | 0 | 0 | 0 | `101` |
| LOADI | 1 | 1 | 0 | 0 | 0 | `000` |
| STORE | 0 | 1 | 0 | 1 | 0 | `000` |
| LOAD | 1 | 1 | 1 | 0 | 1 | `000` |

## Example Program

`InstructionMemory.sv` currently initializes the first six ROM locations with a small demonstration program:

```text
LOADI R1, #5
LOADI R2, #3
ADD   R3, R1, R2
SUB   R4, R1, R2
AND   R5, R1, R2
OR    R6, R1, R2
```

Expected arithmetic results after execution are:

```text
R1 = 5
R2 = 3
R3 = 8
R4 = 2
R5 = 1
R6 = 7
```

The PC advances through the program at addresses `0, 2, 4, 6, ...`.

## Source Files

| File | Role |
|---|---|
| `top_module.sv` | connects the complete processor datapath |
| `ProgramCounter.sv` | program counter and sequential PC update |
| `InstructionMemory.sv` | 64-word instruction ROM and example program |
| `ControlUnit.sv` | opcode decoder and control-signal generation |
| `Regfile.sv` | 16 × 16-bit register file |
| `ALU.sv` | arithmetic, logic, shift operations, and zero flag |
| `DataMemory.sv` | 256 × 16-bit data memory |
| `IM.sv` | currently empty/unused |

## Datapath by Instruction Class

### Register-register ALU instructions

```text
Instruction → rs, rt → Register File → ALU → rd
```

Used by `ADD`, `SUB`, `AND`, and `OR`.

### Immediate ALU instructions

```text
Instruction → rs
            → imm4 → sign extension
                    ↓
Register File ────► ALU → rd
```

Used by `SHL`, `SHR`, and `LOADI`.

### LOAD

```text
R[rs] + imm4 → ALU address → Data Memory → Write-back MUX → R[rd]
```

### STORE

```text
R[rs] + imm4 → ALU address → Data Memory
R[rt] ----------------------► Data Memory write data
```

## Timing Model

State changes occur on the rising clock edge:

- PC update
- register-file write
- data-memory write

Instruction decode, register reads, ALU computation, memory read, and write-back selection are combinational.

Because the processor is single-cycle, the clock period must accommodate the longest combinational path, typically a load-style path such as:

```text
PC → Instruction Memory → Register File → ALU → Data Memory → Write-back MUX → Register File input
```

## Current Limitations

This project is intentionally minimal. The current RTL does **not** include:

- pipelining;
- branch or jump instructions;
- branch use of the ALU `zero` flag;
- forwarding or hazard detection;
- interrupts or exceptions;
- cache hierarchy;
- separate instruction formats for register and immediate operations;
- a dedicated assembler;
- a complete verification/testbench environment in the repository.

The shared `rt / imm` field also restricts the flexibility of `STORE`, as described above.

## Possible Extensions

Natural next steps for the design include:

- adding `BEQ`, `BNE`, and jump instructions;
- separating R-type and I-type instruction formats;
- improving LOAD/STORE addressing;
- adding a dedicated immediate datapath;
- adding testbenches and automated simulation;
- supporting instruction loading from a hex/binary file;
- adding waveform examples;
- synthesizing the design for an FPGA;
- evolving the datapath into a multi-cycle or pipelined processor.

## Purpose

This repository is primarily an educational CPU-design exercise demonstrating how a small instruction set can be mapped onto a complete RTL datapath in SystemVerilog.
