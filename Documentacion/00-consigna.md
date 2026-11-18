# Consigna del TP


## Objetivos

1. Implementar el **pipeline** del procesador RISC-V.
2. Implementar una **Debug Unit** que envía y recibe información del procesador por **UART**.
3. Armar una **interfaz** para visualizar esos datos e interactuar con la Debug Unit (CLI, GUI y/o TUI).

## Instrucciones a implementar (32 en total)

| Tipo | Instrucciones |
|---|---|
| R-type (registro-registro) | `add, sub, sll, srl, sra, and, or, xor, slt, sltu` |
| I-type (inmediato/carga) | `lb, lh, lw, lbu, lhu, addi, andi, ori, xori, slti, sltiu, slli, srli, srai, jalr` |
| J-type (salto incondicional) | `jal` |
| S-type (almacenamiento) | `sb, sh, sw` |
| B-type (rama condicional) | `beq, bne` |
| U-type (inmediato superior) | `lui` |


## Requerimientos duros

- El **clock no debe intervenirse** en ninguna parte del proyecto.
- El procesador debe poder **programarse y reprogramarse dinámicamente** por UART, **sin resintetizar**.
- Decisiones de diseño que queden a criterio propio deben **documentarse con su porqué**.

## Debug Unit — qué exponer por UART

- Contenido de los 32 registros.
- Contenido de los latches intermedios (pipeline).
- Contenido de la memoria de datos usada.

## Carga de programa

- El programa se escribe en assembler, se traduce a lenguaje máquina y se envía por UART.
- Debe incluir una instrucción **HALT**/stop.
- Preguntas que la consigna pide responder explícitamente: ¿hace falta vaciar la memoria? ¿y los registros? ¿hace falta vaciar el pipeline? ¿y la memoria de programa?
- Todo esto sin resintetizar el procesador.

## Modos de operación

- **Continuo**: un comando por UART arranca la ejecución hasta el final del programa; ahí se muestran todos los valores.
- **Paso a paso**: cada comando por UART ejecuta un ciclo de clock, mostrando el estado en cada paso.
- En ambos casos, el pipeline debe quedar **vacío** al terminar la ejecución.
- Pregunta a responder: ¿qué pasa si no hay instrucción de parada en memoria?

## Clock

Al integrar, hay que identificar el camino crítico del sistema y si genera *skew*. Si lo hay: encontrar la frecuencia óptima de funcionamiento, medirla con las herramientas de Vivado, y aplicarla.

## Bibliografía citada en la consigna

- [RISC-V instruction set](https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html#rv32i-rv64i-instructions)
- *Computer Organization and Design (RISC-V Edition)* — Patterson & Hennessy
