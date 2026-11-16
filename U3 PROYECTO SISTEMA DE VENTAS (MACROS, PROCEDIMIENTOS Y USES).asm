; =============================================================================
; TECNOLOGICO NACIONAL DE MEXICO - CAMPUS CULIACAN
; MATERIA: Lenguajes de Interfaz (Unidad 3: Macros, Procedimientos y USES)
; DOCENTE: Dr. Jose Luis Medina Jimenez
; ALUMNO:  Jesus Guadalupe Flores Beltran
; PROYECTO: Sistema de Ventas e Inventario (Tienda de Videojuegos)
; =============================================================================

INCLUDE Irvine32.inc

; -----------------------------------------------------------------------------
; DEFINICION DE MACROS (UNIDAD 3)
; -----------------------------------------------------------------------------

; 1. mMostrarTexto: Imprime una cadena en consola preservando EDX
mMostrarTexto MACRO bufferTxt:REQ
    push edx
    mov edx, OFFSET bufferTxt
    call WriteString
    pop edx
ENDM

; 2. mCapturarCadena: Muestra un prompt y lee una cadena en bufEntrada
;    Deja en EAX la longitud de caracteres leidos por ReadString.
mCapturarCadena MACRO promptTxt:REQ
    mov edx, OFFSET promptTxt
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, SIZEOF bufEntrada - 1
    call ReadString
ENDM

; 3. mImprimirMonedaLinea: Imprime etiqueta + monto en MXN + salto de linea
mImprimirMonedaLinea MACRO etiquetaTxt:REQ, valorCentavos:REQ
    mMostrarTexto etiquetaTxt
    mov eax, valorCentavos
    call ImprimirMonedaMXN
    call Crlf
ENDM

; 4. mImprimirEnteroLinea: Imprime etiqueta + entero + salto de linea
mImprimirEnteroLinea MACRO etiquetaTxt:REQ, valorEntero:REQ
    mMostrarTexto etiquetaTxt
    mov eax, valorEntero
    call ImprimirEntero
    call Crlf
ENDM

; 5. mRellenarEspacios: Rellena con espacios hasta completar 'anchoMax' chars.
;    Usa LOCAL para evitar colision de etiquetas al expandirse varias veces.
mRellenarEspacios MACRO ptrCadena:REQ, anchoMax:REQ
    LOCAL ContarLargo, Rellenar, CicloPad, FinPad
    push eax
    push ecx
    push edi

    mov edi, ptrCadena
    xor ecx, ecx
ContarLargo:
    cmp BYTE PTR [edi], 0
    je Rellenar
    inc edi
    inc ecx
    jmp ContarLargo
Rellenar:
    mov eax, anchoMax
    sub eax, ecx
    mov ecx, eax
    mov al, ' '
CicloPad:
    cmp ecx, 0
    jle FinPad
    call WriteChar
    dec ecx
    jmp CicloPad
FinPad:
    pop edi
    pop ecx
    pop eax
ENDM

; -----------------------------------------------------------------------------
; DEFINICION DE ESTRUCTURA Y CONSTANTES
; -----------------------------------------------------------------------------
PRODUCTO STRUCT
    codigo      BYTE 8 DUP(0)       ; 7 chars (ABC-123) + 1 nulo (Offset 0)
    nombre      BYTE 26 DUP(0)      ; 1 a 25 chars + 1 nulo      (Offset 8)
    align_pad   BYTE 2 DUP(0)       ; Padding para alinear DWORD (Offset 34)
    precio      DWORD 0             ; En centavos: 1 a 999999    (Offset 36)
    existencia  DWORD 0             ; De 0 a 100 unidades        (Offset 40)
    vendidos    DWORD 0             ; Acumulado de ventas        (Offset 44)
PRODUCTO ENDS                       ; Tamano exacto = 48 bytes

MAX_PROD        EQU 10
TAM_PROD        EQU TYPE PRODUCTO   ; 48 bytes
ARCHIVO_BYTES   EQU 484             ; 4 bytes (contador) + 480 bytes (10 productos)

.data
; --- Almacenamiento Principal del Catalogo ---
numProductos    DWORD 0
catalogo        PRODUCTO MAX_PROD DUP(<>)

; --- Buffer Temporal para Validacion de Carga de Archivo ---
tempNumProd     DWORD 0
tempCatalogo    PRODUCTO MAX_PROD DUP(<>)

; --- Variables de Estado de la Sesion ---
ingresosSesion  DWORD 0             ; Acumulado en centavos
cambiosSinG     DWORD 0             ; Bandera: 0 = guardado, 1 = cambios pendientes
nombreArchivo   BYTE "inventario.dat", 0
manejadorArch   DWORD ?

; --- Buffers de Captura y Conversion Propia ---
bufEntrada      BYTE 64 DUP(0)
bufNumero       BYTE 32 DUP(0)
bufMoneda       BYTE 32 DUP(0)

; --- Variables Auxiliares de Trabajo ---
auxCodigo       BYTE 8 DUP(0)
auxNombre       BYTE 26 DUP(0)
auxPrecio       DWORD 0
auxExistencia   DWORD 0
auxCantidad     DWORD 0

; --- Textos de Interfaz y Menus ---
strTitulo       BYTE 0Dh, 0Ah, "==========================================================", 0Dh, 0Ah
                BYTE "     SISTEMA DE VENTAS E INVENTARIO - VIDEOJUEGOS         ", 0Dh, 0Ah
                BYTE "==========================================================", 0Dh, 0Ah, 0
strMenu         BYTE "1. Registrar nuevo producto", 0Dh, 0Ah
                BYTE "2. Mostrar inventario completo", 0Dh, 0Ah
                BYTE "3. Buscar producto por codigo", 0Dh, 0Ah
                BYTE "4. Recibir mercancia (Entradas)", 0Dh, 0Ah
                BYTE "5. Realizar venta", 0Dh, 0Ah
                BYTE "6. Mostrar resumen y Regla de Negocio", 0Dh, 0Ah
                BYTE "7. Guardar catalogo en archivo", 0Dh, 0Ah
                BYTE "8. Cargar catalogo desde archivo", 0Dh, 0Ah
                BYTE "9. Salir", 0Dh, 0Ah
                BYTE "Seleccione una opcion (1-9): ", 0

; --- Mensajes de Solicitud (Prompts) ---
msgPedirCod     BYTE "Ingrese codigo (Formato ABC-123): ", 0
msgPedirNom     BYTE "Ingrese nombre del videojuego (1-25 caracteres): ", 0
msgPedirPre     BYTE "Ingrese precio en pesos (0.01 a 9999.99): ", 0
msgPedirExi     BYTE "Ingrese existencia inicial (0 a 100): ", 0
msgPedirCantE   BYTE "Ingrese cantidad a recibir (> 0): ", 0
msgPedirCantV   BYTE "Ingrese cantidad a vender (> 0): ", 0
msgAvisoSalir   BYTE 0Dh, 0Ah, "ADVERTENCIA: Hay cambios sin guardar en el catalogo.", 0Dh, 0Ah
                BYTE "Desea salir de todas formas? (S/N): ", 0

; --- Mensajes de Error y Validacion ---
errOpcion       BYTE ">> ERROR: Opcion invalida. Intente de nuevo.", 0Dh, 0Ah, 0
errLleno        BYTE ">> ERROR: El catalogo ya alcanzo el limite de 10 productos.", 0Dh, 0Ah, 0
errCodFormato   BYTE ">> ERROR: Formato invalido. Use 3 mayusculas, guion y 3 digitos (ej. JUE-001).", 0Dh, 0Ah, 0
errCodDuplicado BYTE ">> ERROR: El codigo ingresado ya existe en el catalogo.", 0Dh, 0Ah, 0
errNoEncontrado BYTE ">> ERROR: Producto no encontrado en el catalogo.", 0Dh, 0Ah, 0
errNomVacio     BYTE ">> ERROR: El nombre debe tener entre 1 y 25 caracteres.", 0Dh, 0Ah, 0
errPrecio       BYTE ">> ERROR: Precio invalido. Rango: 0.01 a 9999.99 (sin simbolos ni comas).", 0Dh, 0Ah, 0
errExistencia   BYTE ">> ERROR: La existencia debe ser un entero entre 0 y 100.", 0Dh, 0Ah, 0
errCantidad     BYTE ">> ERROR: La cantidad debe ser un entero mayor que 0.", 0Dh, 0Ah, 0
errExcesoStock  BYTE ">> ERROR: La entrada supera el limite maximo de 100 unidades.", 0Dh, 0Ah, 0
errSinStock     BYTE ">> ERROR: Existencias insuficientes para realizar la venta.", 0Dh, 0Ah, 0
errArchivoG     BYTE ">> ERROR: No se pudo crear o escribir el archivo de inventario.", 0Dh, 0Ah, 0
errArchivoC     BYTE ">> ERROR: Archivo inexistente, tamano incorrecto o datos corruptos.", 0Dh, 0Ah, 0

; --- Mensajes de Exito y Formatos de Salida ---
okAlta          BYTE ">> Producto registrado exitosamente.", 0Dh, 0Ah, 0
okEntrada       BYTE ">> Mercancia recibida. Nueva existencia: ", 0
okGuardado      BYTE ">> Catalogo guardado correctamente en 'inventario.dat'.", 0Dh, 0Ah, 0
okCargado       BYTE ">> Catalogo verificado y cargado exitosamente.", 0Dh, 0Ah, 0
msgVacio        BYTE ">> El inventario se encuentra vacio actualmente.", 0Dh, 0Ah, 0

lblCabecera     BYTE 0Dh, 0Ah, "CODIGO  | NOMBRE                    | PRECIO          | STOCK | VENDIDOS", 0Dh, 0Ah
                BYTE "------------------------------------------------------------------------", 0Dh, 0Ah, 0
lblSep          BYTE " | ", 0
lblMXN          BYTE " MXN", 0

; --- Textos de Ticket de Venta y Resumen ---
lblTicket       BYTE 0Dh, 0Ah, "--- DETALLE DE VENTA ---", 0Dh, 0Ah, 0
lblSubtotal     BYTE "Importe Base:      $", 0
lblDescuento    BYTE "Descuento (10%):  -$", 0
lblTotalVenta   BYTE "Total a Pagar:     $", 0
lblStockRest    BYTE "Stock Restante:     ", 0

lblResTitulo    BYTE 0Dh, 0Ah, "=== RESUMEN DEL SISTEMA Y REGLA DE NEGOCIO ===", 0Dh, 0Ah, 0
lblResUnidades  BYTE "Total Unidades Disponibles:  ", 0
lblResValor     BYTE "Valor Total del Inventario:  $", 0
lblResIngresos  BYTE "Ingresos de la Sesion:       $", 0
lblResRegla1    BYTE 0Dh, 0Ah, "[REGLA DE NEGOCIO ACTIVA]:", 0Dh, 0Ah
                BYTE "1. Mayoreo: 10% de descuento en ventas de 5 o mas unidades (sin fracciones de centavo).", 0Dh, 0Ah
                BYTE "2. Alerta de Stock Critico (menos de 5 unidades) y Producto Mas Vendido:", 0Dh, 0Ah, 0
lblMasVendido   BYTE "   -> Producto mas vendido: ", 0
lblSinVentas    BYTE "   -> Aun no se registran ventas en el catalogo.", 0Dh, 0Ah, 0
lblAlertaStock  BYTE "   -> [ALERTA STOCK BAJO]: ", 0
lblUnidades     BYTE " unidades", 0Dh, 0Ah, 0

.code
; =============================================================================
; PROCEDIMIENTO PRINCIPAL (main)
; =============================================================================
main PROC
CicloMenu:
    mMostrarTexto strTitulo
    mCapturarCadena strMenu

    cmp eax, 1
    jne OpcionInvalida
    mov al, bufEntrada[0]
    cmp al, '1'
    jb OpcionInvalida
    cmp al, '9'
    ja OpcionInvalida

    call Crlf

    cmp al, '1'
    je OpRegistrar
    cmp al, '2'
    je OpMostrar
    cmp al, '3'
    je OpBuscar
    cmp al, '4'
    je OpRecibir
    cmp al, '5'
    je OpVender
    cmp al, '6'
    je OpResumen
    cmp al, '7'
    je OpGuardar
    cmp al, '8'
    je OpCargar
    cmp al, '9'
    je OpSalir

OpcionInvalida:
    mMostrarTexto errOpcion
    jmp CicloMenu

OpRegistrar:
    call RegistrarProducto
    jmp CicloMenu
OpMostrar:
    call MostrarInventario
    jmp CicloMenu
OpBuscar:
    call ConsultarPorCodigo
    jmp CicloMenu
OpRecibir:
    call RecibirMercancia
    jmp CicloMenu
OpVender:
    call RealizarVenta
    jmp CicloMenu
OpResumen:
    call MostrarResumen
    jmp CicloMenu
OpGuardar:
    call GuardarArchivo
    jmp CicloMenu
OpCargar:
    call CargarArchivo
    jmp CicloMenu

OpSalir:
    cmp cambiosSinG, 0
    je FinPrograma
PedirConfirmacion:
    mCapturarCadena msgAvisoSalir
    cmp eax, 1
    jne PedirConfirmacion
    mov al, bufEntrada[0]
    cmp al, 'S'
    je FinPrograma
    cmp al, 's'
    je FinPrograma
    cmp al, 'N'
    je CicloMenu
    cmp al, 'n'
    je CicloMenu
    jmp PedirConfirmacion

FinPrograma:
    exit
main ENDP

; =============================================================================
; 1. PROCEDIMIENTOS DE CONVERSION Y VALIDACION CON DIRECTIVA 'USES'
; =============================================================================

; -----------------------------------------------------------------------------
; ValidarFormatoCodigo
; Verifica que una cadena cumpla exactamente el patron ABC-123 (7 caracteres).
; Entradas: EDX = Offset de la cadena a evaluar.
; Salidas:  EAX = 1 si es valido, 0 si es invalido (EAX queda fuera de USES).
; Registros conservados con USES: ESI, ECX.
; -----------------------------------------------------------------------------
ValidarFormatoCodigo PROC USES esi ecx
    mov esi, edx

    mov ecx, 3
RevLetras:
    mov al, [esi]
    cmp al, 'A'
    jb FormatoInvalido
    cmp al, 'Z'
    ja FormatoInvalido
    inc esi
    loop RevLetras

    mov al, [esi]
    cmp al, '-'
    jne FormatoInvalido
    inc esi

    mov ecx, 3
RevDigitos:
    mov al, [esi]
    cmp al, '0'
    jb FormatoInvalido
    cmp al, '9'
    ja FormatoInvalido
    inc esi
    loop RevDigitos

    cmp BYTE PTR [esi], 0
    jne FormatoInvalido

    mov eax, 1
    ret

FormatoInvalido:
    xor eax, eax
    ret
ValidarFormatoCodigo ENDP

; -----------------------------------------------------------------------------
; CadenaAEntero
; Convierte una cadena ASCII de digitos en un entero sin signo de 32 bits.
; Entradas: EDX = Offset de la cadena terminada en 0.
; Salidas:  EAX = Valor convertido, EBX = 1 si exito, 0 si error.
;           (EAX y EBX quedan fuera de USES por ser registros de retorno).
; Registros conservados con USES: ESI, ECX, EDX.
; -----------------------------------------------------------------------------
CadenaAEntero PROC USES esi ecx edx
    mov esi, edx
    xor eax, eax
    cmp BYTE PTR [esi], 0
    je ErrorEntero

CicloEntero:
    movzx ecx, BYTE PTR [esi]
    cmp cl, 0
    je ExitoEntero
    cmp cl, '0'
    jb ErrorEntero
    cmp cl, '9'
    ja ErrorEntero

    sub cl, '0'
    mov edx, 10
    mul edx
    jc ErrorEntero
    add eax, ecx
    jc ErrorEntero
    cmp eax, 100000
    ja ErrorEntero

    inc esi
    jmp CicloEntero

ExitoEntero:
    mov ebx, 1
    ret
ErrorEntero:
    xor eax, eax
    xor ebx, ebx
    ret
CadenaAEntero ENDP

; -----------------------------------------------------------------------------
; CadenaAPrecioCentavos
; Convierte una cadena en formato "185", "185.5" o "185.50" a centavos enteros.
; Entradas: EDX = Offset de la cadena.
; Salidas:  EAX = Precio en centavos, EBX = 1 si valido, 0 si error.
; Registros conservados con USES: ESI, ECX, EDX, EDI.
; -----------------------------------------------------------------------------
CadenaAPrecioCentavos PROC USES esi ecx edx edi
    mov esi, edx
    xor eax, eax
    xor edi, edi

    cmp BYTE PTR [esi], 0
    je PrecioInvalido

CicloPesos:
    movzx ecx, BYTE PTR [esi]
    cmp cl, 0
    je SinDecimales
    cmp cl, '.'
    je ProcesarPunto
    cmp cl, '0'
    jb PrecioInvalido
    cmp cl, '9'
    ja PrecioInvalido

    inc edi
    cmp edi, 4
    ja PrecioInvalido

    sub cl, '0'
    mov edx, 10
    mul edx
    add eax, ecx
    inc esi
    jmp CicloPesos

SinDecimales:
    cmp edi, 0
    je PrecioInvalido
    mov edx, 100
    mul edx
    jmp VerificarRangoPrecio

ProcesarPunto:
    cmp edi, 0
    je PrecioInvalido
    inc esi

    movzx ecx, BYTE PTR [esi]
    cmp cl, '0'
    jb PrecioInvalido
    cmp cl, '9'
    ja PrecioInvalido
    sub cl, '0'
    mov edi, ecx
    inc esi

    movzx ecx, BYTE PTR [esi]
    cmp cl, 0
    je UnSoloDecimal
    cmp cl, '0'
    jb PrecioInvalido
    cmp cl, '9'
    ja PrecioInvalido
    sub cl, '0'
    inc esi

    cmp BYTE PTR [esi], 0
    jne PrecioInvalido

    mov edx, 100
    mul edx
    imul edi, 10
    add eax, edi
    add eax, ecx
    jmp VerificarRangoPrecio

UnSoloDecimal:
    mov edx, 100
    mul edx
    imul edi, 10
    add eax, edi

VerificarRangoPrecio:
    cmp eax, 1
    jb PrecioInvalido
    cmp eax, 999999
    ja PrecioInvalido

    mov ebx, 1
    ret

PrecioInvalido:
    xor eax, eax
    xor ebx, ebx
    ret
CadenaAPrecioCentavos ENDP

; -----------------------------------------------------------------------------
; ImprimirEntero
; Convierte un entero sin signo en EAX a cadena ASCII e imprime con WriteString.
; Entradas: EAX = Numero entero a mostrar.
; Salidas:  Impresion en consola.
; Registros conservados con USES: EAX, EBX, EDX, EDI.
; -----------------------------------------------------------------------------
ImprimirEntero PROC USES eax ebx edx edi
    mov edi, OFFSET bufNumero + 30
    mov BYTE PTR [edi], 0
    mov ebx, 10

    cmp eax, 0
    jne CicloDivEnt
    dec edi
    mov BYTE PTR [edi], '0'
    jmp MostrarEnt

CicloDivEnt:
    cmp eax, 0
    je MostrarEnt
    xor edx, edx
    div ebx
    add dl, '0'
    dec edi
    mov [edi], dl
    jmp CicloDivEnt

MostrarEnt:
    mov edx, edi
    call WriteString
    ret
ImprimirEntero ENDP

; -----------------------------------------------------------------------------
; ImprimirMonedaMXN
; Recibe un monto en centavos en EAX y lo muestra con formato "XXXX.XX MXN".
; Entradas: EAX = Importe en centavos enteros.
; Salidas:  Impresion formateada en pantalla.
; Registros conservados con USES: EAX, EBX, EDX.
; -----------------------------------------------------------------------------
ImprimirMonedaMXN PROC USES eax ebx edx
    xor edx, edx
    mov ebx, 100
    div ebx

    push edx
    call ImprimirEntero

    pop eax
    xor edx, edx
    mov ebx, 10
    div ebx

    add al, '0'
    add dl, '0'
    mov bufMoneda[0], '.'
    mov bufMoneda[1], al
    mov bufMoneda[2], dl
    mov bufMoneda[3], 0

    mMostrarTexto bufMoneda
    mMostrarTexto lblMXN
    ret
ImprimirMonedaMXN ENDP

; =============================================================================
; 2. PROCEDIMIENTOS DE BUSQUEDA, RECORRIDO Y REUTILIZACION (UNIDAD 3)
; =============================================================================

; -----------------------------------------------------------------------------
; CompararCadenas
; Compara dos cadenas terminadas en nulo caracter por caracter.
; Entradas: ESI = Cadena 1, EDI = Cadena 2.
; Salidas:  EAX = 1 si son identicas, 0 si son diferentes (EAX fuera de USES).
; Registros conservados con USES: ESI, EDI, EBX.
; -----------------------------------------------------------------------------
CompararCadenas PROC USES esi edi ebx
CicloComp:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne CadDiferentes
    cmp al, 0
    je CadIguales
    inc esi
    inc edi
    jmp CicloComp
CadIguales:
    mov eax, 1
    ret
CadDiferentes:
    xor eax, eax
    ret
CompararCadenas ENDP

; -----------------------------------------------------------------------------
; CopiarCadena
; Copia una cadena terminada en nulo de ESI hacia EDI.
; Entradas: ESI = Origen, EDI = Destino.
; Salidas:  Memoria destino actualizada.
; Registros conservados con USES: ESI, EDI, EAX.
; -----------------------------------------------------------------------------
CopiarCadena PROC USES esi edi eax
CicloCopia:
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je FinCopia
    inc esi
    inc edi
    jmp CicloCopia
FinCopia:
    ret
CopiarCadena ENDP

; -----------------------------------------------------------------------------
; BuscarProductoPorCodigo
; Recorre el catalogo utilizando ESI para localizar un producto por su codigo.
; Entradas: EDX = Offset del codigo buscado.
; Salidas:  EAX = 1 si lo encontro (ESI apunta al producto), 0 si no existe.
;           (EAX y ESI quedan fuera de USES porque entregan el resultado).
; Registros conservados con USES: ECX, EDI.
; -----------------------------------------------------------------------------
BuscarProductoPorCodigo PROC USES ecx edi
    mov ecx, numProductos
    cmp ecx, 0
    je NoEncontrado

    mov esi, OFFSET catalogo
    mov edi, edx

CicloBusquedaESI:
    call CompararCadenas
    cmp eax, 1
    je Encontrado
    add esi, TAM_PROD
    loop CicloBusquedaESI

NoEncontrado:
    xor eax, eax
    ret
Encontrado:
    mov eax, 1
    ret
BuscarProductoPorCodigo ENDP

; -----------------------------------------------------------------------------
; CapturarYBuscarProducto (NUEVO PROCEDIMIENTO REUTILIZADO - UNIDAD 3)
; Verifica si hay productos en el catalogo, solicita el codigo repetidamente
; hasta que cumpla el formato ABC-123 y lo busca en el catalogo.
; Entradas: Ninguna.
; Salidas:  EAX = 1 si el producto fue localizado (ESI apunta al registro),
;           EAX = 0 si el inventario esta vacio o el codigo no existe.
; Registros conservados con USES: ECX, EDX (EAX y ESI devuelven resultados).
; -----------------------------------------------------------------------------
CapturarYBuscarProducto PROC USES ecx edx
    cmp numProductos, 0
    jne CicloPedirCod
    mMostrarTexto msgVacio
    xor eax, eax
    ret

CicloPedirCod:
    mCapturarCadena msgPedirCod
    mov edx, OFFSET bufEntrada
    call ValidarFormatoCodigo
    cmp eax, 1
    je BuscarEnCatalogo
    mMostrarTexto errCodFormato
    jmp CicloPedirCod

BuscarEnCatalogo:
    mov edx, OFFSET bufEntrada
    call BuscarProductoPorCodigo
    cmp eax, 1
    je ProdLocalizado
    mMostrarTexto errNoEncontrado
    xor eax, eax
    ret

ProdLocalizado:
    mov eax, 1
    ret
CapturarYBuscarProducto ENDP

; -----------------------------------------------------------------------------
; CapturarEnteroRango (NUEVO PROCEDIMIENTO REUTILIZADO - UNIDAD 3)
; Solicita un numero entero al usuario, lo convierte y valida que se encuentre
; dentro del rango [EBX..EDI]. Repite la captura mostrando el error en ESI.
; Entradas: EDX = Offset del prompt, ESI = Offset mensaje error,
;           EBX = Valor minimo permitido, EDI = Valor maximo permitido.
; Salidas:  EAX = Valor entero validado (EAX queda fuera de USES).
; Registros conservados con USES: EBX, ECX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
CapturarEnteroRango PROC USES ebx ecx edx esi edi
    mov ecx, edx                ; Guardar prompt en ECX
CicloCapRango:
    mov edx, ecx
    call WriteString
    mov edx, OFFSET bufEntrada
    push ecx
    mov ecx, SIZEOF bufEntrada - 1
    call ReadString
    pop ecx

    push ebx                    ; Guardar limite minimo
    mov edx, OFFSET bufEntrada
    call CadenaAEntero          ; EAX = valor, EBX = 1 si exito
    mov edx, ebx                ; EDX = bandera de exito
    pop ebx                     ; Recuperar limite minimo

    cmp edx, 1
    jne MostrarErrRango
    cmp eax, ebx
    jb MostrarErrRango
    cmp eax, edi
    ja MostrarErrRango
    ret

MostrarErrRango:
    mov edx, esi
    call WriteString
    jmp CicloCapRango
CapturarEnteroRango ENDP

; -----------------------------------------------------------------------------
; ImprimirFilaProducto
; Muestra en consola los datos del producto apuntado por ESI.
; Entradas: ESI = Direccion del registro PRODUCTO.
; Salidas:  Impresion en consola.
; Registros conservados con USES: EAX, EDX.
; -----------------------------------------------------------------------------
ImprimirFilaProducto PROC USES eax edx
    mov edx, esi
    call WriteString
    mMostrarTexto lblSep

    lea edx, [esi + PRODUCTO.nombre]
    call WriteString
    mRellenarEspacios edx, 25
    mMostrarTexto lblSep

    mov eax, [esi + PRODUCTO.precio]
    call ImprimirMonedaMXN
    mMostrarTexto lblSep

    mov eax, [esi + PRODUCTO.existencia]
    call ImprimirEntero
    mMostrarTexto lblSep

    mov eax, [esi + PRODUCTO.vendidos]
    call ImprimirEntero
    call Crlf
    ret
ImprimirFilaProducto ENDP

; =============================================================================
; 3. FUNCIONES OBLIGATORIAS DEL NEGOCIO (REFACTORIZADAS CON MACROS Y USES)
; =============================================================================

; -----------------------------------------------------------------------------
; 1A. RegistrarProducto
; Captura y valida codigo unico, nombre, precio y existencia inicial.
; Registros conservados con USES: EAX, EBX, ECX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
RegistrarProducto PROC USES eax ebx ecx edx esi edi
    mov eax, numProductos
    cmp eax, MAX_PROD
    jb PedirDatosCodigo
    mMostrarTexto errLleno
    ret

PedirDatosCodigo:
    mCapturarCadena msgPedirCod
    mov edx, OFFSET bufEntrada
    call ValidarFormatoCodigo
    cmp eax, 1
    je RevisarDuplicado
    mMostrarTexto errCodFormato
    jmp PedirDatosCodigo

RevisarDuplicado:
    mov edx, OFFSET bufEntrada
    call BuscarProductoPorCodigo
    cmp eax, 0
    je GuardarCodigoTemp
    mMostrarTexto errCodDuplicado
    jmp PedirDatosCodigo

GuardarCodigoTemp:
    mov esi, OFFSET bufEntrada
    mov edi, OFFSET auxCodigo
    call CopiarCadena

PedirDatosNombre:
    mCapturarCadena msgPedirNom
    cmp eax, 1
    jb ErrorNom
    cmp eax, 25
    ja ErrorNom
    cmp BYTE PTR bufEntrada[0], ' '
    je ErrorNom

    mov esi, OFFSET bufEntrada
    mov edi, OFFSET auxNombre
    call CopiarCadena
    jmp PedirDatosPrecio

ErrorNom:
    mMostrarTexto errNomVacio
    jmp PedirDatosNombre

PedirDatosPrecio:
    mCapturarCadena msgPedirPre
    mov edx, OFFSET bufEntrada
    call CadenaAPrecioCentavos
    cmp ebx, 1
    je GuardarPrecioTemp
    mMostrarTexto errPrecio
    jmp PedirDatosPrecio

GuardarPrecioTemp:
    mov auxPrecio, eax

    ; Reutilizacion de CapturarEnteroRango para Existencia Inicial [0..100]
    mov edx, OFFSET msgPedirExi
    mov esi, OFFSET errExistencia
    mov ebx, 0
    mov edi, 100
    call CapturarEnteroRango
    mov auxExistencia, eax

    ; Guardar en el arreglo usando ESI
    mov eax, numProductos
    mov ebx, TAM_PROD
    mul ebx
    mov esi, OFFSET catalogo
    add esi, eax

    mov edi, esi
    push esi
    mov esi, OFFSET auxCodigo
    call CopiarCadena
    pop esi

    lea edi, [esi + PRODUCTO.nombre]
    push esi
    mov esi, OFFSET auxNombre
    call CopiarCadena
    pop esi

    mov eax, auxPrecio
    mov [esi + PRODUCTO.precio], eax
    mov eax, auxExistencia
    mov [esi + PRODUCTO.existencia], eax
    mov DWORD PTR [esi + PRODUCTO.vendidos], 0

    inc numProductos
    mov cambiosSinG, 1
    mMostrarTexto okAlta
    ret
RegistrarProducto ENDP

; -----------------------------------------------------------------------------
; 1B. MostrarInventario
; Recorre el catalogo con ESI e imprime todos los productos registrados.
; Registros conservados con USES: ECX, ESI.
; -----------------------------------------------------------------------------
MostrarInventario PROC USES ecx esi
    mov ecx, numProductos
    cmp ecx, 0
    jne ImprimirTabla
    mMostrarTexto msgVacio
    ret

ImprimirTabla:
    mMostrarTexto lblCabecera
    mov esi, OFFSET catalogo

CicloMostrarESI:
    call ImprimirFilaProducto
    add esi, TAM_PROD
    loop CicloMostrarESI
    ret
MostrarInventario ENDP

; -----------------------------------------------------------------------------
; 1C. ConsultarPorCodigo
; Utiliza CapturarYBuscarProducto para localizar e imprimir un producto.
; Registros conservados con USES: EAX, ESI.
; -----------------------------------------------------------------------------
ConsultarPorCodigo PROC USES eax esi
    call CapturarYBuscarProducto
    cmp eax, 1
    jne FinConsulta

    mMostrarTexto lblCabecera
    call ImprimirFilaProducto
FinConsulta:
    ret
ConsultarPorCodigo ENDP

; -----------------------------------------------------------------------------
; 2. RecibirMercancia
; Utiliza CapturarYBuscarProducto y CapturarEnteroRango para sumar stock.
; Registros conservados con USES: EAX, EBX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
RecibirMercancia PROC USES eax ebx edx esi edi
    call CapturarYBuscarProducto
    cmp eax, 1
    jne FinRecibir

    mov ecx, esi                ; Preservar puntero ESI del producto en ECX
CapturarCantEntrada:
    mov edx, OFFSET msgPedirCantE
    mov esi, OFFSET errCantidad
    mov ebx, 1
    mov edi, 100000
    call CapturarEnteroRango    ; EAX = cantidad > 0

    mov esi, ecx                ; Restaurar puntero del producto en ESI
    mov ebx, [esi + PRODUCTO.existencia]
    add ebx, eax
    cmp ebx, 100
    ja ErrorTope100

    mov [esi + PRODUCTO.existencia], ebx
    mov cambiosSinG, 1
    mImprimirEnteroLinea okEntrada, ebx
    ret

ErrorTope100:
    mMostrarTexto errExcesoStock
    jmp CapturarCantEntrada

FinRecibir:
    ret
RecibirMercancia ENDP

; -----------------------------------------------------------------------------
; 3. RealizarVenta
; Verifica existencias, calcula importe, aplica descuento y muestra ticket.
; Registros conservados con USES: EAX, EBX, ECX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
RealizarVenta PROC USES eax ebx ecx edx esi edi
    call CapturarYBuscarProducto
    cmp eax, 1
    jne FinVenta

    cmp DWORD PTR [esi + PRODUCTO.existencia], 0
    jne IniciarCapturaVenta
    mMostrarTexto errSinStock
    ret

IniciarCapturaVenta:
    mov ecx, esi                ; Guardar puntero del producto en ECX
CapturarCantVenta:
    mov edx, OFFSET msgPedirCantV
    mov esi, OFFSET errCantidad
    mov ebx, 1
    mov edi, 100000
    call CapturarEnteroRango

    mov esi, ecx                ; Recuperar puntero del producto en ESI
    mov ebx, [esi + PRODUCTO.existencia]
    cmp eax, ebx
    ja ErrorStockInsuficiente

    mov auxCantidad, eax

    ; Calculo de Importe Base (precio * cantidad)
    mov eax, [esi + PRODUCTO.precio]
    mul auxCantidad
    mov ebx, eax                ; EBX = Importe base
    xor ecx, ecx                ; ECX = Descuento

    ; Regla de Negocio: 10% de descuento si cantidad >= 5
    cmp auxCantidad, 5
    jb CalcularTotalFinal
    mov eax, ebx
    xor edx, edx
    mov edi, 10
    div edi
    mov ecx, eax

CalcularTotalFinal:
    mov edi, ebx
    sub edi, ecx                ; EDI = Total a pagar

    ; Actualizar Inventario e Ingresos
    mov eax, auxCantidad
    sub [esi + PRODUCTO.existencia], eax
    add [esi + PRODUCTO.vendidos], eax
    add ingresosSesion, edi
    mov cambiosSinG, 1

    ; Imprimir Ticket usando Macros de la Unidad 3
    mMostrarTexto lblTicket
    mImprimirMonedaLinea lblSubtotal, ebx
    mImprimirMonedaLinea lblDescuento, ecx
    mImprimirMonedaLinea lblTotalVenta, edi
    mImprimirEnteroLinea lblStockRest, [esi + PRODUCTO.existencia]
    ret

ErrorStockInsuficiente:
    mMostrarTexto errSinStock
    jmp CapturarCantVenta

FinVenta:
    ret
RealizarVenta ENDP

; -----------------------------------------------------------------------------
; 4 y 6. MostrarResumen
; Recorre el catalogo con ESI y muestra totales, mas vendido y alertas.
; Registros conservados con USES: EAX, EBX, ECX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
MostrarResumen PROC USES eax ebx ecx edx esi edi
    xor ebx, ebx
    xor edi, edi

    mov ecx, numProductos
    cmp ecx, 0
    je ImprimirDatosResumen

    mov esi, OFFSET catalogo
CicloResumenESI:
    mov eax, [esi + PRODUCTO.existencia]
    add ebx, eax
    mov edx, [esi + PRODUCTO.precio]
    mul edx
    add edi, eax
    add esi, TAM_PROD
    loop CicloResumenESI

ImprimirDatosResumen:
    mMostrarTexto lblResTitulo
    mImprimirEnteroLinea lblResUnidades, ebx
    mImprimirMonedaLinea lblResValor, edi
    mImprimirMonedaLinea lblResIngresos, ingresosSesion
    mMostrarTexto lblResRegla1

    cmp numProductos, 0
    je FinResumen

    mov ecx, numProductos
    mov esi, OFFSET catalogo
    xor ebx, ebx
    xor edi, edi

CicloMasVendidoESI:
    mov eax, [esi + PRODUCTO.vendidos]
    cmp eax, ebx
    jbe SiguienteMasVendido
    mov ebx, eax
    mov edi, esi
SiguienteMasVendido:
    add esi, TAM_PROD
    loop CicloMasVendidoESI

    cmp ebx, 0
    je MostrarSinVentas
    mMostrarTexto lblMasVendido
    lea edx, [edi + PRODUCTO.nombre]
    call WriteString
    mMostrarTexto lblSep
    mov eax, ebx
    call ImprimirEntero
    mMostrarTexto lblUnidades
    jmp RevisarAlertasStock

MostrarSinVentas:
    mMostrarTexto lblSinVentas

RevisarAlertasStock:
    mov ecx, numProductos
    mov esi, OFFSET catalogo
CicloAlertasESI:
    mov eax, [esi + PRODUCTO.existencia]
    cmp eax, 5
    jae SigAlerta
    mMostrarTexto lblAlertaStock
    lea edx, [esi + PRODUCTO.nombre]
    call WriteString
    mMostrarTexto lblSep
    call ImprimirEntero
    mMostrarTexto lblUnidades
SigAlerta:
    add esi, TAM_PROD
    loop CicloAlertasESI

FinResumen:
    ret
MostrarResumen ENDP

; =============================================================================
; 4. PERSISTENCIA EN ARCHIVO CON DIRECTIVA 'USES'
; =============================================================================

; -----------------------------------------------------------------------------
; 5A. GuardarArchivo
; Guarda numProductos (4 bytes) + catalogo (480 bytes) = 484 bytes en disco.
; Registros conservados con USES: EAX, ECX, EDX.
; -----------------------------------------------------------------------------
GuardarArchivo PROC USES eax ecx edx
    mov edx, OFFSET nombreArchivo
    call CreateOutputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorGuardar

    mov manejadorArch, eax
    mov edx, OFFSET numProductos
    mov ecx, ARCHIVO_BYTES
    call WriteToFile
    cmp eax, ARCHIVO_BYTES
    jne CerrarYErrorG

    mov eax, manejadorArch
    call CloseFile

    mov cambiosSinG, 0
    mMostrarTexto okGuardado
    ret

CerrarYErrorG:
    mov eax, manejadorArch
    call CloseFile
ErrorGuardar:
    mMostrarTexto errArchivoG
    ret
GuardarArchivo ENDP

; -----------------------------------------------------------------------------
; 5B. CargarArchivo
; Lee 'inventario.dat' en buffer temporal, valida con ESI y actualiza catalogo.
; Registros conservados con USES: EAX, ECX, EDX, ESI, EDI.
; -----------------------------------------------------------------------------
CargarArchivo PROC USES eax ecx edx esi edi
    mov edx, OFFSET nombreArchivo
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je ErrorCargar

    mov manejadorArch, eax
    mov edx, OFFSET tempNumProd
    mov ecx, ARCHIVO_BYTES
    call ReadFromFile
    push eax
    mov eax, manejadorArch
    call CloseFile
    pop eax

    cmp eax, ARCHIVO_BYTES
    jne ErrorCargar

    mov ecx, tempNumProd
    cmp ecx, MAX_PROD
    ja ErrorCargar
    cmp ecx, 0
    je CopiarBufferACatalogo

    mov esi, OFFSET tempCatalogo
CicloValidarArchivoESI:
    mov edx, esi
    call ValidarFormatoCodigo
    cmp eax, 1
    jne ErrorCargar

    cmp BYTE PTR [esi + PRODUCTO.nombre], 0
    je ErrorCargar

    mov eax, [esi + PRODUCTO.precio]
    cmp eax, 1
    jb ErrorCargar
    cmp eax, 999999
    ja ErrorCargar

    mov eax, [esi + PRODUCTO.existencia]
    cmp eax, 100
    ja ErrorCargar

    add esi, TAM_PROD
    loop CicloValidarArchivoESI

CopiarBufferACatalogo:
    mov ecx, ARCHIVO_BYTES
    mov esi, OFFSET tempNumProd
    mov edi, OFFSET numProductos
CicloReemplazo:
    mov al, [esi]
    mov [edi], al
    inc esi
    inc edi
    loop CicloReemplazo

    mov cambiosSinG, 0
    mMostrarTexto okCargado
    ret

ErrorCargar:
    mMostrarTexto errArchivoC
    ret
CargarArchivo ENDP

END main