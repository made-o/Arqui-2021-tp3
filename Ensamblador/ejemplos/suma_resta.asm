# Ejemplo simple: suma y resta dos constantes, guarda los resultados en memoria
# y vuelve a leer uno. Sin saltos: cada instruccion pasa una sola vez por el pipeline.
# Resultado esperado al terminar:
#   x1 = 7, x2 = 3, x3 = 10 (suma), x4 = 10 (leido de memoria)
#   memoria de datos, direccion 0 (palabra 0) = 10
#   memoria de datos, direccion 4 (palabra 1) = 4

        addi x1, x0, 7          # x1 = 7
        addi x2, x0, 3          # x2 = 3
        add  x3, x1, x2         # x3 = 7 + 3 = 10
        sub  x4, x1, x2         # x4 = 7 - 3 = 4
        sw   x3, 0(x0)          # mem[0] = 10
        sw   x4, 4(x0)          # mem[4] = 4
        lw   x4, 0(x0)          # x4 = mem[0] = 10 (pisa el 4)
        halt
