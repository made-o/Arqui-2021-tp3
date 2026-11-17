# Ejemplo: suma 5 + 4 + 3 + 2 + 1 con un loop y guarda el resultado en memoria.
# Resultado esperado al terminar:
#   x1 = 0 (contador), x2 = 15 (suma), x3 = 15 (leido de memoria)
#   memoria de datos, direccion 8 (palabra 2) = 15

        addi x1, x0, 5          # x1 = contador
        addi x2, x0, 0          # x2 = suma
loop:
        add  x2, x2, x1         # suma += contador
        addi x1, x1, -1         # contador--
        bne  x1, x0, loop       # repetir mientras contador != 0
        sw   x2, 8(x0)          # mem[8] = suma
        lw   x3, 8(x0)          # x3 = mem[8]
        halt
