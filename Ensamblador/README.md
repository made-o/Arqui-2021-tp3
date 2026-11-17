# Ensamblador RISC-V (RV32I) para la Basys 3

Traduce assembler RISC-V a palabras de 32 bits para cargarlas por UART en el procesador
segmentado (`RISCV/`). Solo usa la biblioteca estándar de Python 3; la GUI
además necesita `pyserial` y Tk (`sudo apt install python3-tk`).

## Uso

**Por línea de comandos** — genera un listado `.txt`:

```bash
python3 ensamblador_riscv.py ejemplos/ejemplo.asm
```

```
# addr  hex       binario (32 bits)                 bytes UART   fuente
0x00  00500093  00000000010100000000000010010011  93 00 50 00  addi x1, x0, 5
0x04  00000113  00000000000000000000000100010011  13 01 00 00  addi x2, x0, 0
0x08  00110133  00000000000100010000000100110011  33 01 11 00  add  x2, x2, x1
0x0C  FFF08093  11111111111100001000000010010011  93 80 F0 FF  addi x1, x1, -1
0x10  FE009CE3  11111110000000001001110011100011  E3 9C 00 FE  bne  x1, x0, loop
0x14  00202423  00000000001000000010010000100011  23 24 20 00  sw   x2, 8(x0)
0x18  00802183  00000000100000000010000110000011  83 21 80 00  lw   x3, 8(x0)
0x1C  FFFFFFFF  11111111111111111111111111111111  FF FF FF FF  halt

# Secuencia completa para la UART (bytes ya invertidos, incluye el halt):
9300500013010000330111009380F0FFE39C00FE2324200083218000FFFFFFFF
```

- `addr` está en bytes (`índice × 4`); el PC del hardware es `addr / 4`.
- `bytes UART` es el orden de envío, **LSB primero** (`002081B3` → `B3 81 20 00`).
- La última línea es el programa completo ya listo para pegar en "Hex" de la GUI.

| Opción | Efecto |
|---|---|
| `-o salida.txt` | Archivo de salida (por defecto, el `.asm` con extensión `.txt`). |
| `--sin-halt` | No agrega el `halt` final. |
| `--max-instr N` | Tamaño de la memoria de instrucciones (por defecto 32). |

Si hay errores se listan con su número de línea, no se genera el archivo y el programa
termina con código 1.

**Desde la GUI** (`UartPython/UartGIUCargaArchivo.py`), que ensambla y envía a la placa:

```bash
cd UartPython
python3 UartGIUCargaArchivo.py [../Ensamblador/ejemplos/ejemplo.asm]
```

1. **Abrir puerto** (baudios por defecto: 115200).
2. **Abrir archivo...**: un `.asm` (se ensambla al momento) o un `.txt` del ensamblador.
   Los errores aparecen en el listado y bloquean el envío.
3. Apretar el botón de inicio de la placa (**T18**).
4. **1. Enviar programa** (manda las instrucciones y el `FFFFFFFF`).
5. Elegir modo: **2a. Paso (1E)** (un ciclo por clic) o **2b. Continuo (0E)** (hasta el `halt`).

"Enviar programa" relee el archivo cada vez: se puede editar, guardar y reenviar sin reabrirlo.

---

## Sintaxis

```asm
# comentario (también //)
inicio:                     # label en su propia línea
loop:   add  x2, x2, x1     # o junto a la instrucción
        lw   t0, -4(sp)     # offset(registro)
        beq  x1, x0, inicio
        halt
```

- Una instrucción por línea, mayúsculas o minúsculas. Operandos separados por coma o espacios.
- Inmediatos en decimal, hex (`0x7FF`) o binario (`0b1010`).
- Destinos de branch/`jal`: un label o un offset en **bytes** múltiplo de 4.
- `.word 0x12345678` inserta una palabra cruda. `.text`, `.globl`, `.section` y `.align`
  se ignoran; cualquier otra directiva (`.data`, ...) da error.
- Registros: `x0`–`x31` o nombres ABI (`zero ra sp gp tp t0-t6 s0/fp s1-s11 a0-a7`).

### Instrucciones

| Tipo | Instrucciones | Formato |
|---|---|---|
| R | `add sub sll slt sltu xor srl sra or and` | `add rd, rs1, rs2` |
| I | `addi slti sltiu xori ori andi` | `addi rd, rs1, imm` (−2048..2047) |
| Shift | `slli srli srai` | `slli rd, rs1, shamt` (0..31) |
| Load | `lb lh lw lbu lhu` | `lw rd, off(rs1)` |
| Store | `sb sh sw` | `sw rs2, off(rs1)` |
| Branch | `beq bne blt bge bltu bgeu` | `beq rs1, rs2, label` |
| Saltos | `jal`, `jalr` | `jal rd, label` / `jalr rd, off(rs1)` |
| U | `lui` | `lui rd, imm20` (0..0xFFFFF) |

No implementadas en el hardware (dan error): `auipc`, `ecall`, `ebreak`, `fence`, `csr*`.

### Pseudo-instrucciones

| Pseudo | Equivale a |
|---|---|
| `nop` | `addi x0, x0, 0` |
| `mv rd, rs` | `addi rd, rs, 0` |
| `li rd, imm` | `addi rd, x0, imm` (solo −2048..2047; si no, `lui` + `addi`) |
| `not rd, rs` / `neg rd, rs` | `xori rd, rs, -1` / `sub rd, x0, rs` |
| `j label` / `jal label` | `jal x0, label` / `jal ra, label` |
| `jr rs` / `ret` | `jalr x0, 0(rs)` / `jalr x0, 0(ra)` |
| `beqz rs, label` / `bnez rs, label` | `beq rs, x0, label` / `bne rs, x0, label` |
| `halt` | `FFFFFFFF` |

---

## Límites del hardware

- **Máximo 32 palabras, contando el `halt`** (`DATA_DEPTH` de `IF/intruction_mem.v`). El
  `halt` es obligatorio (el `Debug_Manager` deja de cargar al recibir `FFFFFFFF`); si falta,
  el ensamblador lo agrega.
- Un `halt` en el medio corta la carga: lo que sigue no se carga (hay advertencia).
- Memoria de datos: direcciones en bytes, palabras en múltiplos de 4 (`sw x1, 8(x0)` es la
  palabra 2).

### Advertencias

El encoding siempre es RV32I estándar, pero en estos casos el hardware no se comporta como
el ISA. El ensamblador lo avisa sin frenar:

| Caso | Qué pasa en el hardware |
|---|---|
| `blt`, `bge`, `bltu`, `bgeu` | `control.v` solo distingue `beq`; el resto se ejecuta como `bne`. |
| `jalr` / `ret` / `jr` | `jal` guarda `PC+1` (en palabras), pero `jalr` usa `(rs1+imm)/4` (`ID/pc_jump.v`): el retorno de subrutina no cae donde debería. |
| Branch o `jal` que es destino de otro salto | Recibe un PC viejo en ID (`IF/pc.v`) y calcula mal su destino. Solución: poner un `nop` antes, en el destino. |
