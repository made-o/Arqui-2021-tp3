"""
GUI para cargar un programa RISC-V en la Basys 3 por UART y depurarlo.

Junta dos cosas:
  - carga de programa: ensambla un .asm (o lee un listado .txt) y lo manda a la placa;
  - visualizador del pipeline: decodifica el volcado que manda el Debug Manager en
    cada paso (IF, ID, EX, MEM, WB, memoria de datos y registros), con historial
    navegable de pasos.

Uso:
    python3 UartGIUCargaArchivo.py [programa.asm|listado.txt] [--demo]

--demo carga tramas inventadas en el historial para probar la interfaz sin placa.
"""
import os
import struct
import sys
import tkinter as tk
from tkinter import ttk, scrolledtext, filedialog
from tkinter import font as tkfont

import serial
import serial.tools.list_ports

# El ensamblador vive en ../Ensamblador
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Ensamblador"))
from ensamblador_riscv import ensamblar, formatear_listado, leer_listado  # noqa: E402

# Bytes de modo que espera el Debug_Manager en WAIT_CMD (Debug_Manager.v)
MODO_PASO_A_PASO = 0x1E
MODO_CONTINUO = 0x0E
HALT = 0xFFFFFFFF

# Zoom de los textos, en porcentaje
ZOOM_MIN, ZOOM_MAX, ZOOM_PASO = 60, 200, 10

# ---------------------------------------------------------------------------
# Formato de la trama (debug_manager/interface_tx.v)
#
# Por cada volcado la placa manda, en este orden, palabras de 32 bits LSB primero:
#   IF 2, ID 5, EX 3, MEM 3, WB 2, memoria de datos N_MEM, registros N_REG.
# N_MEM y N_REG tienen que coincidir con MEM_DATA_COUNT y MEM_REG_COUNT del RTL
# (hoy 5 y 5; si se suben a 128 y 32, cambiar solo estas dos constantes).
# ---------------------------------------------------------------------------
N_MEM = 128
N_REG = 32
PALABRAS_ETAPAS = 15
PALABRAS_TRAMA = PALABRAS_ETAPAS + N_MEM + N_REG
BYTES_TRAMA = PALABRAS_TRAMA * 4

# El orden de las señales dentro de cada bus de control sale de Risc_top.v
# (w_control_bits_ID / _EX / _MEM).
# Campos de las palabras empaquetadas: (nombre, bit menos significativo, ancho, formato)
# formato: "x" = numero de registro, "b" = binario, "h" = hexadecimal
CAMPOS_ID = [  # {3'b0, rs1, 3'b0, rd, control[9:0], flush, rs2}
    ("rs1", 24, 5, "x"), ("rs2", 0, 5, "x"), ("rd", 16, 5, "x"), ("flush", 5, 1, "b"),
    ("RegWrite", 15, 1, "b"), ("MemToReg", 14, 1, "b"), ("MemWrite", 13, 1, "b"),
    ("MemRead", 12, 1, "b"), ("Branch", 10, 2, "b"), ("ALUOp", 8, 2, "b"), ("ALUSrc", 6, 2, "b"),
]
CAMPOS_EX = [  # {3'b0, rd, 8'b0, control[5:0], 2'b0, cero, 7'b0}
    ("rd", 24, 5, "x"), ("cero", 7, 1, "b"),
    ("RegWrite", 15, 1, "b"), ("MemToReg", 14, 1, "b"), ("MemWrite", 13, 1, "b"),
    ("MemRead", 12, 1, "b"), ("Branch", 10, 2, "b"),
]
CAMPOS_MEM = [  # {3'b0, rd, 8'b0, control[1:0], 14'b0}
    ("rd", 24, 5, "x"), ("RegWrite", 15, 1, "b"), ("MemToReg", 14, 1, "b"),
]
CAMPOS_WB = [  # {3'b0, rd, 8'b0, regWrite, 15'b0}
    ("rd", 24, 5, "x"), ("RegWrite", 15, 1, "b"),
]

# Dato 1/Dato 2 = datos leídos del banco de registros; Inmed. = inmediato extendido;
# Salto = dirección de salto; Dato mem = dato leído de la memoria de datos.
# Etapas: (clave, titulo, [(etiqueta, indice de palabra en la trama)], indice de la
# palabra empaquetada, campos de esa palabra)
ETAPAS = [
    ("IF", "IF", [("PC", 0), ("Instr.", 1)], None, []),
    ("ID", "ID", [("Dato 1", 3), ("Dato 2", 4), ("Inmed.", 5), ("Salto", 6)],
     2, CAMPOS_ID),
    ("EX", "EX", [("ALU", 7), ("Dato 2", 8)], 9, CAMPOS_EX),
    ("MEM", "MEM", [("ALU", 10), ("Dato mem", 11)], 12, CAMPOS_MEM),
    ("WB", "WB", [("Dato", 13)], 14, CAMPOS_WB),
]


def extraer_campos(palabra, campos):
    """Devuelve {nombre: texto} con los campos de una palabra empaquetada."""
    salida = {}
    for nombre, lsb, ancho, fmt in campos:
        valor = (palabra >> lsb) & ((1 << ancho) - 1)
        if fmt == "x":
            salida[nombre] = f"x{valor}"
        elif fmt == "b":
            salida[nombre] = f"{valor:0{ancho}b}"
        else:
            salida[nombre] = f"0x{valor:x}"
    return salida


def decodificar_trama(palabras):
    """
    Convierte las PALABRAS_TRAMA palabras de un volcado en un dict plano
    {clave: texto} listo para mostrar. Claves: "IF.PC", "ID.rs1", "MEM.3", "REG.1", ...
    """
    if len(palabras) != PALABRAS_TRAMA:
        raise ValueError(f"la trama tiene {len(palabras)} palabras, se esperaban {PALABRAS_TRAMA}")
    d = {}
    for clave, _, datos, idx_ctrl, campos in ETAPAS:
        for etiqueta, idx in datos:
            d[f"{clave}.{etiqueta}"] = f"{palabras[idx]:08x}"
        if idx_ctrl is not None:
            for nombre, texto in extraer_campos(palabras[idx_ctrl], campos).items():
                d[f"{clave}.{nombre}"] = texto
    for i in range(N_MEM):
        d[f"DMEM.{i}"] = f"{palabras[PALABRAS_ETAPAS + i]:08x}"
    for i in range(N_REG):
        d[f"REG.{i}"] = f"{palabras[PALABRAS_ETAPAS + N_MEM + i]:08x}"
    return d


def tramas_demo():
    """Tramas inventadas (no salen de una simulación) para probar la GUI sin placa."""
    tramas = []
    for paso in range(6):
        t = [0] * PALABRAS_TRAMA
        t[0], t[1] = paso, [0x00500093, 0x00000113, 0x00110133, 0xFFF08093, 0xFE009CE3, HALT][paso]
        t[2] = (paso << 24) | ((paso + 1) << 16) | (0b1000001001 << 6) | (paso & 1) << 5 | 2
        t[3], t[4], t[5], t[6] = paso * 3, paso * 5, 5, paso + 4
        t[7], t[8], t[9] = paso * 8, paso * 5, (paso << 24) | (0b100000 << 10) | ((paso & 1) << 7)
        t[10], t[11], t[12] = paso * 7, 0, (paso << 24) | (0b10 << 14)
        t[13], t[14] = paso * 6, (paso << 24) | (1 << 15)
        for i in range(N_MEM):
            t[PALABRAS_ETAPAS + i] = i * paso
        for i in range(N_REG):
            t[PALABRAS_ETAPAS + N_MEM + i] = i * (paso + 1)
        tramas.append(t)
    return tramas


class PanelCampos(ttk.LabelFrame):
    """Grupo de campos de solo lectura. Resalta los que cambiaron respecto del paso anterior."""

    COLOR_NORMAL = "#f0f0f0"
    COLOR_CAMBIO = "#ffe08a"

    def __init__(self, parent, titulo, alto_scroll=None):
        """alto_scroll: si se indica, los campos van en un área desplazable de ese alto (px)."""
        super().__init__(parent, text=titulo)
        self.entradas = {}
        self.fila = 0
        self.cuerpo = self  # donde se crean los campos
        if alto_scroll:
            lienzo = tk.Canvas(self, height=alto_scroll, highlightthickness=0)
            barra = ttk.Scrollbar(self, orient="vertical", command=lienzo.yview)
            lienzo.configure(yscrollcommand=barra.set)
            barra.pack(side="right", fill="y")
            lienzo.pack(side="left", fill="both", expand=True)
            self.cuerpo = tk.Frame(lienzo)
            lienzo.create_window(0, 0, window=self.cuerpo, anchor="nw")
            # El ancho sigue al contenido (cambia con el zoom); el alto queda fijo
            self.cuerpo.bind("<Configure>", lambda e: lienzo.configure(
                width=e.width, scrollregion=(0, 0, e.width, e.height)))
            rueda = lambda e: lienzo.yview_scroll(-1 if (e.num == 4 or e.delta > 0) else 1, "units")
            for evento in ("<MouseWheel>", "<Button-4>", "<Button-5>"):
                lienzo.bind(evento, rueda)
                self.cuerpo.bind(evento, rueda)
            self.rueda = rueda

    def agregar(self, clave, etiqueta, ancho=10, fila=None, columna=0):
        if fila is None:
            fila = self.fila
            self.fila += 1
        r = tk.Label(self.cuerpo, text=etiqueta, font="GuiMono")
        r.grid(row=fila, column=columna * 2, sticky="e", padx=(6, 2), pady=1)
        e = tk.Entry(self.cuerpo, width=ancho, font="GuiMono", justify="right",
                     state="readonly", readonlybackground=self.COLOR_NORMAL)
        e.grid(row=fila, column=columna * 2 + 1, sticky="w", padx=(0, 6), pady=1)
        self.entradas[clave] = e
        if self.cuerpo is not self:
            for w in (r, e):
                for evento in ("<MouseWheel>", "<Button-4>", "<Button-5>"):
                    w.bind(evento, self.rueda)

    def separador(self, texto):
        tk.Label(self.cuerpo, text=texto, font="GuiMonoChico", fg="gray").grid(
            row=self.fila, column=0, columnspan=2, sticky="w", padx=6, pady=(6, 0))
        self.fila += 1

    def mostrar(self, valores, anteriores=None):
        for clave, e in self.entradas.items():
            texto = valores.get(clave, "")
            e.config(state="normal")
            e.delete(0, tk.END)
            e.insert(0, texto)
            cambio = anteriores is not None and anteriores.get(clave) != texto
            e.config(state="readonly",
                     readonlybackground=self.COLOR_CAMBIO if cambio else self.COLOR_NORMAL)


class UARTApp:
    def __init__(self, root, archivo_inicial=None, demo=False):
        self.root = root
        self.root.title("RISC-V Basys 3 - carga de programa y pipeline")
        self.ser = None
        self.running = False  # Controla el bucle de recepción
        self.archivo = None
        self.palabras = []
        self.lineas_listado = {}  # indice de instrucción -> nro de línea en listado_text
        self.buffer_rx = bytearray()
        self.ticks_sin_datos = 0
        self.aviso_resto = False
        self.historial = []  # una lista de PALABRAS_TRAMA palabras por volcado recibido
        self.indice = -1
        self.after_id = None

        self.parity_map = {"N": serial.PARITY_NONE, "O": serial.PARITY_ODD, "E": serial.PARITY_EVEN}
        self.stopbits_map = {1: serial.STOPBITS_ONE, 2: serial.STOPBITS_TWO}

        self._crear_fuentes()
        self._crear_conexion()
        cuerpo = ttk.Frame(root)
        cuerpo.pack(fill="both", expand=True, padx=10)
        izquierda = ttk.Frame(cuerpo)
        izquierda.pack(side="left", fill="both", expand=True)
        derecha = ttk.Frame(cuerpo)
        derecha.pack(side="left", fill="both", padx=(10, 0))
        self._crear_programa(izquierda)
        self._crear_inferior(izquierda)
        self._crear_navegacion(derecha)
        self._crear_pipeline(derecha)

        root.protocol("WM_DELETE_WINDOW", self.cerrar)

        if archivo_inicial:
            self.cargar_archivo(archivo_inicial)
        if demo:
            for t in tramas_demo():
                self.historial.append(t)
            self.escribir_log("Modo demo: tramas inventadas cargadas en el historial")
            self.navegar(len(self.historial) - 1)

    # ------------------------------------------------------------------
    # Construcción de la ventana
    # ------------------------------------------------------------------
    def _crear_fuentes(self):
        """Fuentes con nombre: todos los textos las usan, así el zoom las cambia de una vez."""
        self.zoom = 100
        self.fuentes = [  # (fuente, tamaño al 100 %)
            (tkfont.Font(root=self.root, name="GuiMono", family="Courier", size=9), 9),
            (tkfont.Font(root=self.root, name="GuiMonoChico", family="Courier", size=8), 8),
            (tkfont.Font(root=self.root, name="GuiTitulo", family="Helvetica", size=10, weight="bold"), 10),
        ]
        # Fuentes por defecto de Tk (botones, etiquetas, pestañas, log)
        for nombre in ("TkDefaultFont", "TkTextFont", "TkFixedFont", "TkMenuFont", "TkHeadingFont"):
            f = tkfont.nametofont(nombre, root=self.root)
            self.fuentes.append((f, f.cget("size")))

    def cambiar_zoom(self, delta):
        """delta en puntos porcentuales; 0 vuelve al 100 %."""
        self.zoom = 100 if delta == 0 else max(ZOOM_MIN, min(ZOOM_MAX, self.zoom + delta))
        for fuente, base in self.fuentes:
            # Tk usa tamaños negativos para píxeles: se conserva el signo
            tam = max(1, round(abs(base) * self.zoom / 100))
            fuente.configure(size=tam if base >= 0 else -tam)
        self.lbl_zoom.config(text=f"{self.zoom}%")

    def _crear_conexion(self):
        f = ttk.LabelFrame(self.root, text="Configuración UART")
        f.pack(padx=10, pady=5, fill="x")

        ttk.Label(f, text="Puerto:").pack(side="left", padx=(5, 2), pady=5)
        self.port_var = tk.StringVar()
        self.port_combo = ttk.Combobox(f, textvariable=self.port_var, width=16,
                                       postcommand=self.refrescar_puertos)
        self.port_combo.pack(side="left", padx=2)
        self.refrescar_puertos()
        if self.port_combo["values"]:
            self.port_combo.current(0)

        ttk.Label(f, text="Baudios:").pack(side="left", padx=(10, 2))
        self.baud_var = tk.StringVar(value="115200")
        ttk.Entry(f, textvariable=self.baud_var, width=8).pack(side="left", padx=2)

        ttk.Label(f, text="Bits:").pack(side="left", padx=(10, 2))
        self.databits_var = tk.IntVar(value=8)
        ttk.Combobox(f, textvariable=self.databits_var, values=[5, 6, 7, 8], width=2,
                     state="readonly").pack(side="left", padx=2)

        ttk.Label(f, text="Paridad:").pack(side="left", padx=(10, 2))
        self.parity_var = tk.StringVar(value="None")
        ttk.Combobox(f, textvariable=self.parity_var, values=["None", "Odd", "Even"], width=5,
                     state="readonly").pack(side="left", padx=2)

        ttk.Label(f, text="Parada:").pack(side="left", padx=(10, 2))
        self.stopbits_var = tk.IntVar(value=1)
        ttk.Combobox(f, textvariable=self.stopbits_var, values=[1, 2], width=2,
                     state="readonly").pack(side="left", padx=2)

        self.open_btn = ttk.Button(f, text="Abrir puerto", command=self.open_port)
        self.open_btn.pack(side="left", padx=(15, 2))
        self.close_btn = ttk.Button(f, text="Cerrar puerto", command=self.close_port, state="disabled")
        self.close_btn.pack(side="left", padx=2)

        # Zoom de los textos; clic en el porcentaje vuelve al 100 %
        ttk.Label(f, text="Zoom:").pack(side="left", padx=(20, 2))
        ttk.Button(f, text="A-", width=3, command=lambda: self.cambiar_zoom(-ZOOM_PASO)).pack(side="left", padx=2)
        self.lbl_zoom = ttk.Label(f, text="100%", width=5, anchor="center")
        self.lbl_zoom.pack(side="left")
        self.lbl_zoom.bind("<Button-1>", lambda e: self.cambiar_zoom(0))
        ttk.Button(f, text="A+", width=3, command=lambda: self.cambiar_zoom(ZOOM_PASO)).pack(side="left", padx=2)

    def _crear_programa(self, parent):
        f = ttk.LabelFrame(parent, text="Programa (.asm o listado .txt del ensamblador)")
        f.pack(pady=5, fill="both", expand=True)
        fila = ttk.Frame(f)
        fila.pack(fill="x")
        ttk.Button(fila, text="Abrir archivo...", command=self.elegir_archivo).pack(side="left", padx=5, pady=5)
        self.archivo_var = tk.StringVar(value="(ningún archivo)")
        ttk.Label(fila, textvariable=self.archivo_var).pack(side="left", padx=5)

        fila = ttk.Frame(f)
        fila.pack(fill="x")
        ttk.Button(fila, text="1. Enviar programa", command=self.enviar_programa).pack(side="left", padx=5, pady=5)
        ttk.Button(fila, text="2a. Paso (1E)",
                   command=lambda: self.enviar_modo(MODO_PASO_A_PASO)).pack(side="left", padx=5)
        ttk.Button(fila, text="2b. Continuo (0E)",
                   command=lambda: self.enviar_modo(MODO_CONTINUO)).pack(side="left", padx=5)
        ttk.Label(f, text="Antes de enviar el programa, apretar el botón de inicio de la placa (T18).\n"
                          "En paso a paso, cada clic en 1E devuelve un volcado y avanza un ciclo.",
                  foreground="gray").pack(anchor="w", padx=5, pady=2)
        barra_h = ttk.Scrollbar(f, orient="horizontal")
        barra_h.pack(side="bottom", fill="x", padx=5, pady=(0, 5))
        self.listado_text = scrolledtext.ScrolledText(f, height=12, width=72, font="GuiMono",
                                                      wrap="none", xscrollcommand=barra_h.set)
        self.listado_text.pack(padx=5, pady=(5, 0), fill="both", expand=True)
        barra_h.config(command=self.listado_text.xview)
        self.listado_text.tag_configure("pc", background="#ffe08a")

    def _crear_inferior(self, parent):
        f = ttk.LabelFrame(parent, text="Enviar datos a mano")
        f.pack(pady=5, fill="x")
        ttk.Label(f, text="Hex:").pack(side="left", padx=5, pady=5)
        self.send_var = tk.StringVar()
        entrada = ttk.Entry(f, textvariable=self.send_var)
        entrada.pack(side="left", fill="x", expand=True, padx=5)
        entrada.bind("<Return>", lambda e: self.send_data())
        ttk.Button(f, text="Enviar", command=self.send_data).pack(side="left", padx=5)

        pestanas = ttk.Notebook(parent)
        pestanas.pack(pady=5, fill="both", expand=True)
        self.log = scrolledtext.ScrolledText(pestanas, height=7, width=40)
        pestanas.add(self.log, text="Log")
        self.receive_text = scrolledtext.ScrolledText(pestanas, height=7, width=40, font="GuiMono")
        pestanas.add(self.receive_text, text="Recibido (hex crudo)")

    def _crear_navegacion(self, parent):
        f = ttk.LabelFrame(parent, text="Navegación de pasos")
        f.pack(fill="x", pady=5)
        self.lbl_paso = tk.Label(f, text="Paso: 0/0", font="GuiTitulo", width=12)
        self.lbl_paso.pack(side="left", padx=10, pady=5)
        ttk.Button(f, text="|<", width=4, command=lambda: self.navegar(0)).pack(side="left", padx=2)
        ttk.Button(f, text="< Ant", width=6, command=lambda: self.navegar(self.indice - 1)).pack(side="left", padx=2)
        ttk.Button(f, text="Sig >", width=6, command=lambda: self.navegar(self.indice + 1)).pack(side="left", padx=2)
        ttk.Button(f, text=">|", width=4, command=lambda: self.navegar(len(self.historial) - 1)).pack(side="left", padx=2)
        ttk.Button(f, text="Limpiar", command=self.limpiar_historial).pack(side="right", padx=5)

    def _crear_pipeline(self, parent):
        self.paneles = []
        fila_etapas = ttk.Frame(parent)
        fila_etapas.pack(fill="x", pady=5)
        for clave, titulo, datos, idx_ctrl, campos in ETAPAS:
            p = PanelCampos(fila_etapas, titulo)
            p.pack(side="left", fill="y", padx=2, anchor="n")
            for etiqueta, _ in datos:
                p.agregar(f"{clave}.{etiqueta}", etiqueta)
            if campos:
                p.separador("reg. / control")
                for nombre, _, _, _ in campos:
                    p.agregar(f"{clave}.{nombre}", nombre, ancho=4)
            self.paneles.append(p)

        fila_mem = ttk.Frame(parent)
        fila_mem.pack(fill="x", pady=5)
        for prefijo, titulo, cantidad, nombre in (
                ("REG", "Registros", N_REG, lambda i: f"x{i}"),
                ("DMEM", "Memoria de datos", N_MEM, lambda i: f"M[{i}]")):
            # Hasta 32 valores: columnas de 8. Más que eso: 2 por fila con barra de desplazamiento
            con_scroll = cantidad > 32
            p = PanelCampos(fila_mem, titulo, alto_scroll=190 if con_scroll else None)
            p.pack(side="left", fill="y", padx=2, anchor="n")
            filas = min(cantidad, 8)
            for i in range(cantidad):
                if con_scroll:
                    p.agregar(f"{prefijo}.{i}", nombre(i), fila=i // 2, columna=i % 2)
                else:
                    p.agregar(f"{prefijo}.{i}", nombre(i), fila=i % filas, columna=i // filas)
            self.paneles.append(p)

    # ------------------------------------------------------------------
    # Puerto
    # ------------------------------------------------------------------
    def escribir_log(self, mensaje):
        self.log.insert(tk.END, mensaje + "\n")
        self.log.see(tk.END)

    def refrescar_puertos(self):
        self.port_combo["values"] = [p.device for p in serial.tools.list_ports.comports()]

    def puerto_abierto(self):
        if self.ser and self.ser.is_open:
            return True
        self.escribir_log("Error: Puerto no abierto")
        return False

    def open_port(self):
        if self.ser and self.ser.is_open:
            self.escribir_log("El puerto ya está abierto")
            return
        try:
            self.ser = serial.Serial(
                port=self.port_var.get(),
                baudrate=int(self.baud_var.get()),
                bytesize=self.databits_var.get(),
                parity=self.parity_map[self.parity_var.get()[0]],
                stopbits=self.stopbits_map[self.stopbits_var.get()],
                timeout=0  # Timeout 0 para recepción no bloqueante
            )
        except Exception as e:  # SerialException, baudios no numéricos, termios.error, ...
            self.escribir_log(f"Error al abrir puerto: {e}")
            return
        self.buffer_rx.clear()
        self.escribir_log(f"Puerto {self.port_var.get()} abierto")
        self.open_btn.config(state="disabled")
        self.close_btn.config(state="normal")
        if not self.running:
            self.running = True
            self.receive_data()  # Iniciar recepción continua

    def close_port(self):
        if self.ser and self.ser.is_open:
            self.detener_recepcion()
            self.ser.close()
            self.escribir_log(f"Puerto {self.port_var.get()} cerrado")
            self.open_btn.config(state="normal")
            self.close_btn.config(state="disabled")
        else:
            self.escribir_log("El puerto no está abierto")

    def detener_recepcion(self):
        self.running = False
        if self.after_id:
            self.root.after_cancel(self.after_id)
            self.after_id = None

    def cerrar(self):
        self.detener_recepcion()
        if self.ser and self.ser.is_open:
            self.ser.close()
        self.root.destroy()

    # ------------------------------------------------------------------
    # Programa
    # ------------------------------------------------------------------
    def elegir_archivo(self):
        ruta = filedialog.askopenfilename(
            title="Elegir programa",
            filetypes=[("Assembler RISC-V", "*.asm *.s"), ("Listado del ensamblador", "*.txt"),
                       ("Todos", "*.*")])
        if ruta:
            self.cargar_archivo(ruta)

    def cargar_archivo(self, ruta):
        """Ensambla un .asm, o lee las palabras de un listado .txt. Devuelve True si quedó listo."""
        self.archivo = ruta
        self.palabras = []
        self.archivo_var.set(os.path.basename(ruta))
        self.listado_text.delete("1.0", tk.END)
        try:
            with open(ruta, encoding="utf-8") as f:
                texto = f.read()
        except OSError as e:
            self.escribir_log(f"Error al leer {ruta}: {e}")
            return False

        if ruta.lower().endswith(".txt"):
            self.palabras = leer_listado(texto)
            self.listado_text.insert(tk.END, texto)
            if not self.palabras:
                self.escribir_log("El .txt no tiene palabras; ¿es un listado del ensamblador?")
                return False
            if self.palabras[-1] != HALT:
                self.escribir_log("Advertencia: el listado no termina en FFFFFFFF (halt)")
        else:
            resultado = ensamblar(texto)
            for adv in resultado["advertencias"]:
                self.listado_text.insert(tk.END, f"ADVERTENCIA {adv}\n")
            if resultado["errores"]:
                for err in resultado["errores"]:
                    self.listado_text.insert(tk.END, f"ERROR {err}\n")
                self.escribir_log(f"{len(resultado['errores'])} error(es) al ensamblar; no se puede enviar")
                return False
            self.palabras = resultado["palabras"]
            self.listado_text.insert(tk.END, formatear_listado(resultado, os.path.basename(ruta)))

        self.indexar_listado()
        self.resaltar_pc()
        self.escribir_log(f"Programa listo: {len(self.palabras)} palabras ({os.path.basename(ruta)})")
        return True

    def indexar_listado(self):
        """Ubica en el texto del listado la línea de cada instrucción (las que empiezan con 0x..)."""
        self.lineas_listado = {}
        lineas = self.listado_text.get("1.0", tk.END).splitlines()
        for nro, linea in enumerate(lineas, start=1):
            if linea[:2].lower() == "0x" and len(linea.split()) >= 2:
                self.lineas_listado[len(self.lineas_listado)] = nro

    def resaltar_pc(self):
        """Marca en el listado la instrucción que está en IF en el paso que se está viendo."""
        self.listado_text.tag_remove("pc", "1.0", tk.END)
        if not (0 <= self.indice < len(self.historial)) or not self.palabras:
            return
        pc, instr = self.historial[self.indice][0], self.historial[self.indice][1]
        # El PC del RTL cuenta palabras; se acepta también en bytes. La instrucción desempata.
        for idx in (pc, pc // 4):
            if idx < len(self.palabras) and self.palabras[idx] == instr and idx in self.lineas_listado:
                nro = self.lineas_listado[idx]
                self.listado_text.tag_add("pc", f"{nro}.0", f"{nro}.end")
                self.listado_text.see(f"{nro}.0")
                return

    def enviar_programa(self):
        if not self.puerto_abierto():
            return
        if not self.archivo:
            self.escribir_log("Error: primero abrir un archivo")
            return
        # Se vuelve a leer el archivo para tomar cambios hechos en el editor
        if not self.cargar_archivo(self.archivo):
            return

        try:
            # Programa nuevo: se descarta lo que hubiera quedado de la corrida anterior
            self.ser.reset_input_buffer()
            self.limpiar_historial()
            # Cada palabra va LSB primero (Debug_Manager arma instruccion_temp[7:0] con el 1er byte)
            datos = b"".join(struct.pack("<I", p) for p in self.palabras)
            self.ser.write(datos)
            self.ser.flush()
            self.escribir_log(f"Programa enviado: {len(self.palabras)} palabras, {len(datos)} bytes")
            self.escribir_log("Ahora elegir el modo: 1E (paso a paso) o 0E (continuo)")
        except serial.SerialException as e:
            self.escribir_log(f"Error al enviar: {e}")

    def enviar_modo(self, modo):
        if not self.puerto_abierto():
            return
        try:
            self.ser.write(bytes([modo]))
            self.escribir_log(f"Enviado modo: {modo:02x}")
        except serial.SerialException as e:
            self.escribir_log(f"Error al enviar: {e}")

    def send_data(self):
        if not self.puerto_abierto():
            return
        try:
            # Convertir entrada hexadecimal a binario
            hex_data = self.send_var.get().replace(" ", "")
            datos_a_enviar = bytes.fromhex(hex_data)
            self.ser.write(datos_a_enviar)
            self.escribir_log(f"Enviado: {datos_a_enviar.hex()}")
            self.send_var.set("")  # Limpiar entrada
        except ValueError:
            self.escribir_log("Error: Datos deben ser hexadecimal (ej. AA 55)")
        except serial.SerialException as e:
            self.escribir_log(f"Error al enviar: {e}")

    # ------------------------------------------------------------------
    # Recepción e historial
    # ------------------------------------------------------------------
    def receive_data(self):
        if not self.running:
            return
        if self.ser and self.ser.is_open:
            try:
                nuevos = self.ser.read(self.ser.in_waiting or 0)
            except (serial.SerialException, OSError) as e:
                self.escribir_log(f"Error al recibir: {e}")
                nuevos = b""
            self.procesar_bytes(nuevos)
        self.after_id = self.root.after(50, self.receive_data)

    def procesar_bytes(self, nuevos):
        """Acumula bytes y arma un paso del historial por cada BYTES_TRAMA completos."""
        if nuevos:
            self.buffer_rx.extend(nuevos)
            self.ticks_sin_datos = 0
            self.aviso_resto = False
        else:
            self.ticks_sin_datos += 1

        llegaron = 0
        while len(self.buffer_rx) >= BYTES_TRAMA:
            crudo = bytes(self.buffer_rx[:BYTES_TRAMA])
            del self.buffer_rx[:BYTES_TRAMA]
            # '<I': Little Endian, la FPGA manda primero el LSB
            palabras = list(struct.unpack(f"<{PALABRAS_TRAMA}I", crudo))
            self.historial.append(palabras)
            llegaron += 1
            self.receive_text.insert(
                tk.END, f"--- paso {len(self.historial)} ---\n"
                + " ".join(f"{p:08x}" for p in palabras) + "\n")
        if llegaron:
            self.receive_text.see(tk.END)
            self.navegar(len(self.historial) - 1)

        # Bytes sueltos que no completan una trama durante ~1 s: avisar una sola vez
        if self.buffer_rx and self.ticks_sin_datos == 20 and not self.aviso_resto:
            self.aviso_resto = True
            self.escribir_log(
                f"Advertencia: quedaron {len(self.buffer_rx)} bytes que no completan una trama de "
                f"{BYTES_TRAMA} ({self.buffer_rx.hex(' ')}). ¿N_MEM/N_REG coinciden con el RTL?")

    def limpiar_historial(self):
        self.historial = []
        self.indice = -1
        self.buffer_rx.clear()
        self.receive_text.delete("1.0", tk.END)
        self.lbl_paso.config(text="Paso: 0/0")
        for p in self.paneles:
            p.mostrar({})
        self.resaltar_pc()

    def navegar(self, idx):
        if 0 <= idx < len(self.historial):
            self.indice = idx
            self.actualizar_vista()

    def actualizar_vista(self):
        valores = decodificar_trama(self.historial[self.indice])
        anteriores = decodificar_trama(self.historial[self.indice - 1]) if self.indice > 0 else None
        self.lbl_paso.config(text=f"Paso: {self.indice + 1}/{len(self.historial)}")
        for p in self.paneles:
            p.mostrar(valores, anteriores)
        self.resaltar_pc()

    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if a != "--demo"]
    root = tk.Tk()
    app = UARTApp(root, args[0] if args else None, demo="--demo" in sys.argv[1:])
    app.run()
