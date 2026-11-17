# ==============================================================================
# Programa de prueba para procesador RV32I en FPGA
# Registros usados:
#   x1 (ra)  : contador del bucle (0 -> 3)
#   x2 (sp)  : límite del bucle (3)
#   x3 (gp)  : primer valor de prueba (0x000000AA)
#   x4 (tp)  : segundo valor de prueba (0x00000055)
#   x5 (t0)  : dirección base de memoria de datos (0x00000000)
# ==============================================================================
    addi x1, x0, 0          # [PC=0] Inicializa contador x1 = 0
    addi x2, x0, 3          # [PC=1] Límite del bucle x2 = 3
    addi x1, x1, 1          # [PC=2] Incrementa contador: x1 = x1 + 1
    bne  x1, x2, -4         # [PC=3] Si x1 != 3, salta a loop (offset = -4 bytes -> PC - 1 = 2)
    jal  x0, 8              # [PC=4] Cuando x1 == 3, salta a mem_swap (offset = +8 bytes -> PC + 2 = 6)
    addi x0, x0, 0          # [PC=5] NOP (instrucción en sombra de salto / relleno)
    addi x3, x0, 0xAA       # [PC=6] Carga valor A en x3 (x3 = 0x000000AA)
    addi x4, x0, 0x55       # [PC=7] Carga valor B en x4 (x4 = 0x00000055)
    addi x5, x0, 0          # [PC=8] Dirección base de dataMemory x5 = 0
    sw   x3, 0(x5)          # [PC=9]  Guarda x3 (0xAA) en memData[0] (dirección byte 0)
    sw   x4, 4(x5)          # [PC=10] Guarda x4 (0x55) en memData[1] (dirección byte 4)
    lw   x3, 4(x5)          # [PC=11] Lee memData[1] (0x55) en x3 (orden inverso)
    lw   x4, 0(x5)          # [PC=12] Lee memData[0] (0xAA) en x4 (orden inverso)
    HALT                    # [PC=13] Instrucción HALT para detener el pipeline y enviar por UART
