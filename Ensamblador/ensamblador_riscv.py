#!/usr/bin/env python3
"""
Ensamblador RISC-V (RV32I) para el procesador segmentado de la Basys 3.

Traduce un programa en assembler RISC-V estandar a palabras de 32 bits y
genera un listado (.txt) con direccion, hex, binario, bytes UART y fuente.

Uso:
    python3 ensamblador_riscv.py programa.asm [-o salida.txt] [--sin-halt]

Tambien se puede importar (lo usa UartPython/UartGIUCargaArchivo.py):
    from ensamblador_riscv import ensamblar
    resultado = ensamblar(texto)
"""

import argparse
import os
import re
import sys

# Palabra de HALT: el Debug_Manager deja de cargar al recibirla y la memoria de
# instrucciones levanta o_haltSignal al leerla (Debug_Manager.v, intruction_mem.v).
HALT = 0xFFFFFFFF

# DATA_DEPTH de IF/intruction_mem.v (= MAX_INSTRUCTIONS del Debug_Manager).
# El halt ocupa una de estas posiciones.
MAX_INSTRUCCIONES = 32

# ---------------------------------------------------------------------------
# Registros
# ---------------------------------------------------------------------------
REGISTROS = {f"x{i}": i for i in range(32)}
REGISTROS.update({
    "zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
    "t0": 5, "t1": 6, "t2": 7,
    "s0": 8, "fp": 8, "s1": 9,
    "a0": 10, "a1": 11, "a2": 12, "a3": 13, "a4": 14, "a5": 15, "a6": 16, "a7": 17,
    "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "s8": 24, "s9": 25, "s10": 26, "s11": 27,
    "t3": 28, "t4": 29, "t5": 30, "t6": 31,
})

# ---------------------------------------------------------------------------
# Tabla de instrucciones: mnemonico -> (formato, opcode, funct3, funct7)
# ---------------------------------------------------------------------------
INSTRUCCIONES = {
    # Tipo R
    "add":  ("R", 0b0110011, 0b000, 0b0000000),
    "sub":  ("R", 0b0110011, 0b000, 0b0100000),
    "sll":  ("R", 0b0110011, 0b001, 0b0000000),
    "slt":  ("R", 0b0110011, 0b010, 0b0000000),
    "sltu": ("R", 0b0110011, 0b011, 0b0000000),
    "xor":  ("R", 0b0110011, 0b100, 0b0000000),
    "srl":  ("R", 0b0110011, 0b101, 0b0000000),
    "sra":  ("R", 0b0110011, 0b101, 0b0100000),
    "or":   ("R", 0b0110011, 0b110, 0b0000000),
    "and":  ("R", 0b0110011, 0b111, 0b0000000),
    # Tipo I aritmeticas
    "addi":  ("I", 0b0010011, 0b000, None),
    "slti":  ("I", 0b0010011, 0b010, None),
    "sltiu": ("I", 0b0010011, 0b011, None),
    "xori":  ("I", 0b0010011, 0b100, None),
    "ori":   ("I", 0b0010011, 0b110, None),
    "andi":  ("I", 0b0010011, 0b111, None),
    # Shifts con inmediato (funct7 va en imm[11:5])
    "slli": ("SH", 0b0010011, 0b001, 0b0000000),
    "srli": ("SH", 0b0010011, 0b101, 0b0000000),
    "srai": ("SH", 0b0010011, 0b101, 0b0100000),
    # Loads
    "lb":  ("L", 0b0000011, 0b000, None),
    "lh":  ("L", 0b0000011, 0b001, None),
    "lw":  ("L", 0b0000011, 0b010, None),
    "lbu": ("L", 0b0000011, 0b100, None),
    "lhu": ("L", 0b0000011, 0b101, None),
    # Stores
    "sb": ("S", 0b0100011, 0b000, None),
    "sh": ("S", 0b0100011, 0b001, None),
    "sw": ("S", 0b0100011, 0b010, None),
    # Branches
    "beq":  ("B", 0b1100011, 0b000, None),
    "bne":  ("B", 0b1100011, 0b001, None),
    "blt":  ("B", 0b1100011, 0b100, None),
    "bge":  ("B", 0b1100011, 0b101, None),
    "bltu": ("B", 0b1100011, 0b110, None),
    "bgeu": ("B", 0b1100011, 0b111, None),
    # Saltos y LUI
    "jal":  ("J",    0b1101111, None,  None),
    "jalr": ("JALR", 0b1100111, 0b000, None),
    "lui":  ("U",    0b0110111, None,  None),
}

# Instrucciones RV32I validas que el hardware no implementa.
NO_SOPORTADAS = {"auipc", "ecall", "ebreak", "fence", "fence.i",
                 "csrrw", "csrrs", "csrrc", "csrrwi", "csrrsi", "csrrci"}

# Advertencias sobre como el RTL actual ejecuta algunas instrucciones.
ADVERTENCIAS_HW = {
    "blt":  "el hardware solo distingue BEQ; blt se ejecuta como bne (control.v)",
    "bge":  "el hardware solo distingue BEQ; bge se ejecuta como bne (control.v)",
    "bltu": "el hardware solo distingue BEQ; bltu se ejecuta como bne (control.v)",
    "bgeu": "el hardware solo distingue BEQ; bgeu se ejecuta como bne (control.v)",
    "jalr": "JAL guarda PC+1 en palabras pero JALR calcula (rs1+imm)/4 (pc_jump.v); "
            "el retorno de subrutina no cae en la direccion esperada",
}


class ErrorAsm(Exception):
    pass


# ---------------------------------------------------------------------------
# Parseo de operandos
# ---------------------------------------------------------------------------
def reg(token):
    nombre = token.strip().lower()
    if nombre not in REGISTROS:
        raise ErrorAsm(f"registro desconocido '{token}'")
    return REGISTROS[nombre]


def numero(token):
    t = token.strip().lower().replace("_", "")
    try:
        return int(t, 0)  # acepta 10, -4, 0x1f, 0b101
    except ValueError:
        raise ErrorAsm(f"inmediato invalido '{token}'")


def rango(valor, bits, con_signo, que):
    if con_signo:
        lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    else:
        lo, hi = 0, (1 << bits) - 1
    if not lo <= valor <= hi:
        raise ErrorAsm(f"{que} {valor} fuera de rango [{lo}, {hi}]")
    return valor & ((1 << bits) - 1)


def offset_base(token):
    """'8(x2)' -> (8, 2).  '(x2)' -> (0, 2)."""
    m = re.fullmatch(r"\s*([^()]*)\(\s*([^()\s]+)\s*\)\s*", token)
    if not m:
        raise ErrorAsm(f"se esperaba offset(registro), se encontro '{token}'")
    off = numero(m.group(1)) if m.group(1).strip() else 0
    return off, reg(m.group(2))


def destino(token, labels, pc):
    """Offset en bytes desde pc hasta un label o un offset numerico literal."""
    t = token.strip()
    if t.lower() in labels:
        return labels[t.lower()] - pc
    if re.fullmatch(r"[A-Za-z_.][\w.]*", t):
        raise ErrorAsm(f"label no definido '{t}'")
    return numero(t)


def cantidad(ops, n, mnem):
    if len(ops) != n:
        raise ErrorAsm(f"'{mnem}' espera {n} operandos, se encontraron {len(ops)}")


# ---------------------------------------------------------------------------
# Codificacion por formato
# ---------------------------------------------------------------------------
def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    return (imm << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3, op):
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) \
        | ((imm & 0x1F) << 7) | op


def enc_b(imm, rs2, rs1, f3, op):
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) \
        | (rs1 << 15) | (f3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def enc_u(imm20, rd, op):
    return (imm20 << 12) | (rd << 7) | op


def enc_j(imm, rd, op):
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) \
        | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | op


def salto(off, bits, que):
    if off % 4:
        raise ErrorAsm(f"offset de {que} {off} no es multiplo de 4")
    return rango(off, bits, True, f"offset de {que}")


def codificar(mnem, ops, labels, pc):
    fmt, op, f3, f7 = INSTRUCCIONES[mnem]

    if fmt == "R":
        cantidad(ops, 3, mnem)
        return enc_r(f7, reg(ops[2]), reg(ops[1]), f3, reg(ops[0]), op)

    if fmt == "I":
        cantidad(ops, 3, mnem)
        imm = rango(numero(ops[2]), 12, True, "inmediato")
        return enc_i(imm, reg(ops[1]), f3, reg(ops[0]), op)

    if fmt == "SH":
        cantidad(ops, 3, mnem)
        shamt = rango(numero(ops[2]), 5, False, "shamt")
        return enc_i((f7 << 5) | shamt, reg(ops[1]), f3, reg(ops[0]), op)

    if fmt == "L":
        cantidad(ops, 2, mnem)
        off, base = offset_base(ops[1])
        return enc_i(rango(off, 12, True, "offset"), base, f3, reg(ops[0]), op)

    if fmt == "S":
        cantidad(ops, 2, mnem)
        off, base = offset_base(ops[1])
        return enc_s(rango(off, 12, True, "offset"), reg(ops[0]), base, f3, op)

    if fmt == "B":
        cantidad(ops, 3, mnem)
        imm = salto(destino(ops[2], labels, pc), 13, "branch")
        return enc_b(imm, reg(ops[1]), reg(ops[0]), f3, op)

    if fmt == "J":
        if len(ops) == 1:              # jal label  ==  jal ra, label
            ops = ["ra"] + ops
        cantidad(ops, 2, mnem)
        imm = salto(destino(ops[1], labels, pc), 21, "jal")
        return enc_j(imm, reg(ops[0]), op)

    if fmt == "JALR":
        if len(ops) == 1 and "(" not in ops[0]:   # jalr rs1
            rd, rs1, off = 1, reg(ops[0]), 0
        elif len(ops) == 2:                       # jalr rd, off(rs1)
            rd = reg(ops[0])
            off, rs1 = offset_base(ops[1])
        else:                                     # jalr rd, rs1, off
            cantidad(ops, 3, mnem)
            rd, rs1, off = reg(ops[0]), reg(ops[1]), numero(ops[2])
        return enc_i(rango(off, 12, True, "offset"), rs1, f3, rd, op)

    if fmt == "U":
        cantidad(ops, 2, mnem)
        return enc_u(rango(numero(ops[1]), 20, False, "inmediato de lui"), reg(ops[0]), op)

    raise ErrorAsm(f"formato interno desconocido para '{mnem}'")


def offset_salto(palabra):
    """Offset en bytes de un branch o jal ya codificado; None si no es un salto."""
    if palabra == HALT:
        return None
    op = palabra & 0x7F
    if op == 0b1100011:
        imm = (((palabra >> 31) & 1) << 12) | (((palabra >> 7) & 1) << 11) \
            | (((palabra >> 25) & 0x3F) << 5) | (((palabra >> 8) & 0xF) << 1)
        return imm - (1 << 13) if imm & (1 << 12) else imm
    if op == 0b1101111:
        imm = (((palabra >> 31) & 1) << 20) | (((palabra >> 12) & 0xFF) << 12) \
            | (((palabra >> 20) & 1) << 11) | (((palabra >> 21) & 0x3FF) << 1)
        return imm - (1 << 21) if imm & (1 << 20) else imm
    return None


# ---------------------------------------------------------------------------
# Pseudo-instrucciones (todas ocupan exactamente 1 palabra)
# ---------------------------------------------------------------------------
def expandir_pseudo(mnem, ops):
    if mnem == "nop":
        return "addi", ["x0", "x0", "0"]
    if mnem == "mv":
        return "addi", [ops[0], ops[1], "0"] if len(ops) == 2 else ops
    if mnem == "li":
        if len(ops) == 2 and not -2048 <= numero(ops[1]) <= 2047:
            raise ErrorAsm("li solo admite inmediatos de 12 bits [-2048, 2047]; "
                           "usar lui + addi")
        return "addi", [ops[0], "x0", ops[1]] if len(ops) == 2 else ops
    if mnem == "not":
        return "xori", [ops[0], ops[1], "-1"] if len(ops) == 2 else ops
    if mnem == "neg":
        return "sub", [ops[0], "x0", ops[1]] if len(ops) == 2 else ops
    if mnem == "j":
        return "jal", ["x0"] + ops
    if mnem == "jr":
        return "jalr", ["x0", f"0({ops[0]})"] if len(ops) == 1 else ops
    if mnem == "ret":
        return "jalr", ["x0", "0(ra)"]
    if mnem == "beqz":
        return "beq", [ops[0], "x0", ops[1]] if len(ops) == 2 else ops
    if mnem == "bnez":
        return "bne", [ops[0], "x0", ops[1]] if len(ops) == 2 else ops
    return mnem, ops


# ---------------------------------------------------------------------------
# Ensamblado
# ---------------------------------------------------------------------------
def limpiar(linea):
    linea = linea.split("#")[0].split("//")[0]
    return linea.strip()


def separar_operandos(resto):
    resto = resto.strip()
    if not resto:
        return []
    # separa por comas o espacios, respetando 'off(reg)'
    return [t for t in re.split(r"\s*,\s*|\s+(?![^()]*\))", resto) if t]


def ensamblar(texto, agregar_halt=True, max_instr=MAX_INSTRUCCIONES):
    """
    Devuelve un dict con:
      palabras:     lista de enteros de 32 bits (incluye el halt)
      listado:      lista de (direccion_bytes, palabra, fuente, nro_linea)
      errores:      lista de strings "linea N: mensaje"
      advertencias: lista de strings
    """
    errores, advertencias = [], []

    # Pasada 1: labels e instrucciones (direccion en bytes = indice * 4)
    labels, items = {}, []
    for nro, cruda in enumerate(texto.splitlines(), start=1):
        linea = limpiar(cruda)
        while True:
            m = re.match(r"([A-Za-z_.][\w.]*)\s*:\s*(.*)$", linea)
            if not m:
                break
            nombre = m.group(1).lower()
            if nombre in labels:
                errores.append(f"linea {nro}: label duplicado '{m.group(1)}'")
            labels[nombre] = len(items) * 4
            linea = m.group(2).strip()
        if not linea:
            continue
        if linea.startswith("."):
            directiva = linea.split()[0].lower()
            if directiva == ".word":
                for v in separar_operandos(linea[len(directiva):]):
                    items.append((nro, ".word", [v], linea))
            elif directiva not in (".text", ".globl", ".global", ".section", ".align"):
                errores.append(f"linea {nro}: directiva no soportada '{directiva}'")
            continue
        partes = linea.split(None, 1)
        items.append((nro, partes[0].lower(),
                      separar_operandos(partes[1] if len(partes) > 1 else ""), linea))

    # Pasada 2: codificacion
    listado = []
    for idx, (nro, mnem, ops, fuente) in enumerate(items):
        pc = idx * 4
        try:
            if mnem == ".word":
                palabra = numero(ops[0]) & 0xFFFFFFFF
            elif mnem == "halt":
                palabra = HALT
            else:
                real, real_ops = expandir_pseudo(mnem, ops)
                if real in NO_SOPORTADAS:
                    raise ErrorAsm(f"'{real}' no esta implementada en el procesador")
                if real not in INSTRUCCIONES:
                    raise ErrorAsm(f"instruccion desconocida '{mnem}'")
                palabra = codificar(real, real_ops, labels, pc)
                if real in ADVERTENCIAS_HW:
                    advertencias.append(f"linea {nro}: {ADVERTENCIAS_HW[real]}")
            listado.append((pc, palabra, fuente, nro))
        except (ErrorAsm, IndexError) as e:
            msg = str(e) if isinstance(e, ErrorAsm) else f"faltan operandos en '{fuente}'"
            errores.append(f"linea {nro}: {msg}")

    if agregar_halt and (not listado or listado[-1][1] != HALT):
        listado.append((len(listado) * 4, HALT, "halt  (agregado automaticamente)", None))

    # La instruccion que cae en el destino de un salto ve en ID un pc_out viejo
    # (pc_current no se actualiza al destino, ver IF/pc.v), asi que si es otro
    # branch/jal calcula mal su destino o su direccion de retorno.
    destinos = {pc + offset_salto(p) for pc, p, _, _ in listado if offset_salto(p) is not None}
    for pc, palabra, fuente, nro in listado:
        if pc in destinos and offset_salto(palabra) is not None:
            advertencias.append(f"linea {nro}: '{fuente}' es destino de un salto y a la vez "
                                "es un branch/jal; el hardware le pasa un PC incorrecto. "
                                "Poner una instruccion (ej. nop) antes en el destino")

    # Un HALT en el medio corta la carga del Debug_Manager: lo que sigue no se carga.
    for pc, palabra, _, nro in listado[:-1]:
        if palabra == HALT:
            advertencias.append(f"linea {nro}: halt en el medio del programa; el "
                                "Debug_Manager deja de cargar ahi y no carga lo que sigue")
            break

    if len(listado) > max_instr:
        errores.append(f"el programa ocupa {len(listado)} palabras y la memoria "
                       f"de instrucciones tiene {max_instr} (el halt cuenta)")

    errores.sort(key=lambda e: int(re.match(r"linea (\d+)", e).group(1))
                 if e.startswith("linea ") else 10**9)
    return {
        "palabras": [p for _, p, _, _ in listado],
        "listado": listado,
        "errores": errores,
        "advertencias": advertencias,
    }


# ---------------------------------------------------------------------------
# Formato de salida
# ---------------------------------------------------------------------------
def bytes_uart(palabra):
    """Bytes en el orden en que se envian por UART (LSB primero)."""
    return palabra.to_bytes(4, "little")


def formatear_listado(resultado, nombre_fuente=""):
    lineas = [
        f"# Ensamblado de {nombre_fuente}" if nombre_fuente else "# Programa ensamblado",
        "# addr  hex       binario (32 bits)                 bytes UART   fuente",
    ]
    for pc, palabra, fuente, _ in resultado["listado"]:
        lineas.append(f"0x{pc:02X}  {palabra:08X}  {palabra:032b}  "
                      f"{bytes_uart(palabra).hex(' ').upper()}  {fuente}")
    secuencia = "".join(bytes_uart(p).hex() for p in resultado["palabras"]).upper()
    lineas += ["", "# Secuencia completa para la UART (bytes ya invertidos, incluye el halt):",
               secuencia, ""]
    return "\n".join(lineas)


def leer_listado(texto):
    """Lee las palabras de un listado .txt generado por este ensamblador."""
    palabras = []
    for linea in texto.splitlines():
        t = linea.split()
        if len(t) >= 2 and t[0].lower().startswith("0x") and re.fullmatch(r"[0-9A-Fa-f]{8}", t[1]):
            palabras.append(int(t[1], 16))
    return palabras


def main():
    ap = argparse.ArgumentParser(description="Ensamblador RISC-V RV32I para la Basys 3")
    ap.add_argument("entrada", help="archivo .asm")
    ap.add_argument("-o", "--salida", help="archivo de salida (por defecto <entrada>.txt)")
    ap.add_argument("--sin-halt", action="store_true",
                    help="no agregar el halt (FFFFFFFF) al final")
    ap.add_argument("--max-instr", type=int, default=MAX_INSTRUCCIONES,
                    help=f"tamano de la memoria de instrucciones (por defecto {MAX_INSTRUCCIONES})")
    args = ap.parse_args()

    with open(args.entrada, encoding="utf-8") as f:
        resultado = ensamblar(f.read(), agregar_halt=not args.sin_halt,
                              max_instr=args.max_instr)

    for a in resultado["advertencias"]:
        print(f"{args.entrada}: ADVERTENCIA {a}", file=sys.stderr)
    if resultado["errores"]:
        for e in resultado["errores"]:
            print(f"{args.entrada}: ERROR {e}", file=sys.stderr)
        print(f"{len(resultado['errores'])} error(es); no se genero salida.", file=sys.stderr)
        sys.exit(1)

    salida = args.salida or os.path.splitext(args.entrada)[0] + ".txt"
    texto = formatear_listado(resultado, os.path.basename(args.entrada))
    with open(salida, "w", encoding="utf-8") as f:
        f.write(texto)
    print(texto)
    print(f"-> {salida} ({len(resultado['palabras'])} palabras)")


if __name__ == "__main__":
    main()
