# Single-Cycle 16-bit CPU (Verilog)

## Overview
Simple 16-bit **single-cycle processor** where each instruction executes in one clock cycle.

## Components
- Program Counter (PC)
- Instruction Memory (IM)
- Control Unit (CU)
- Register File (RF)
- ALU
- Data Memory (DM)
- Multiplexers

## Datapath Flow
Fetch → Decode → Execute → Memory → Write-back (single cycle)

## Instruction Format
[15:12] opcode
[11:8] rd
[7:4] rs
[3:0] rt / imm

## Control Signals
- `aluctrl`
- `alusrc`
- `memread`
- `memwrite`
- `memtoreg`
- `regwrite`

## Purpose
Basic implementation of a CPU datapath for learning computer architecture and Verilog design.
