# 🔄 MIPS vs RISC-V en este proyecto

## Contexto histórico

El proyecto arrancó implementando MIPS y se migró a RISC-V.

> *La versión MIPS quedó en la rama `TP_MIPS` del repositorio.*


**El hardware actual, en `RISCV/`, decodifica RISC-V (RV32I) real**. 

Los programas se arman con el ensamblador propio, `Ensamblador/ensamblador_riscv.py` (ver su README).

Referencia que estamos usando para RV32I: [riscv-isadoc (msyksphinz)](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#rv32i-rv64i-instructions).

## Comparación

| | MIPS (fase anterior) | RISC-V en `RISCV/` |
|---|---|---|
| Opcode | 6 bits, en `instruccion[31:26]` | 7 bits, en `instruccion[6:0]` |
| Campos de registro | `rs`, `rt`, `rd` contiguos después del opcode | `rs1=[19:15]`, `rs2=[24:20]`, `rd=[11:7]` |
| Discriminador de tipo de instrucción | opcode (+ `funct` en R-type) | `opcode` + `func3` (+ `func7` en R-type) |
| Inmediatos | un solo esquema de 16 bits para todos los I-type | 5 formatos (I/S/B/U/J), cada uno arma los bits distinto (`ID/pc_jump.v`) |

## 🪧 ¿Dónde el diseño se aparta del RV32I estándar?

- **PC por palabra:** incrementa de a 1 y la memoria de instrucciones tiene 32 palabras (ver `02-IF.md`).
- **Offsets de branch/JAL:** se codifican en bytes, como pide la ISA, y el diseño los divide por 4 para convertirlos a índice de palabra.
- **Link de `jal`/`jalr`:** se guarda `(pc+1)*4`, la dirección de retorno en bytes. Así el programa trabaja con direcciones en bytes, como en RV32I, y `jalr` las vuelve a convertir a índice de palabra (`(rs1 + imm)/4`).

## 🪧 ¿Qué decodifica el hardware?

Esto es lo que cubre `ID/control.v` + `EX/aluControl.v`, y por lo tanto lo que tiene que poder generar un ensamblador RV32I:

- **R-type** (`opcode 0110011`): AND, OR, ADD, XOR, SLL, SRL, SRA, SLTU, SUB, SLT.
- **I-type aritmético** (`opcode 0010011`): ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI.
- **Loads** (`opcode 0000011`): LB, LH, LW, LBU, LHU.
- **JALR** (`opcode 1100111`).
- **Stores** (`opcode 0100011`): SB, SH, SW.
- **Branches** (`opcode 1100011`): BEQ, BNE (`control.v` solo distingue `func3==000` como "igual"; el resto cae al caso "no igual" — BLT/BGE/BLTU/BGEU no están soportados, se ejecutarían como BNE).
- **JAL** (`opcode 1101111`).
- **LUI** (`opcode 0110111`).

> Para cargar un programa en la placa, `Ensamblador/ensamblador_riscv.py` genera la secuencia de bytes lista para la UART (LSB primero, con el `ffffffff` final), y la GUI `UartPython/UartGIUCargaArchivo.py` la envía.
