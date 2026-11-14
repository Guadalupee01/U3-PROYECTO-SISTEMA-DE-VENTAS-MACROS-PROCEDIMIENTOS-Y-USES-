; Materia: Lenguajes de Interfaz
; Alumno: Jesús Guadalupe Flores Beltrán
; Horario: 09:00 - 10:00
; Docente: Dr. José Luis Medina Jiménez
; Práctica: 5 unidad 3

INCLUDE Irvine32.inc

; 
; Macro: MostrarMensaje
; Descripción: Imprime una cadena de texto en consola
; 
MostrarMensaje MACRO texto 
    mov edx, OFFSET texto
    call WriteString       ; Impresion (Llamada a procedimiento)
    call Crlf              ; Impresion (Llamada a procedimiento)
ENDM

; 
; Macro: Multiplicar
; Descripción: Multiplica dos valores y deja el resultado en EAX
; 
Multiplicar MACRO val1, val2
    mov eax, val1
    mov ebx, val2
    imul eax, ebx
ENDM

.data
    mensajeBienvenida BYTE "BIENVENIDO AL SISTEMA DE INVENTARIO", 0
    mensajeResultado  BYTE "El resultado de la multiplicacion es: ", 0
    mensajeFin        BYTE "HASTA LUEGO, VUELVA PRONTO", 0

.code
main PROC
    ; Mensaje inicial usando la macro
    MostrarMensaje mensajeBienvenida

    ; Imprimir texto del resultado
    mov edx, OFFSET mensajeResultado
    call WriteString       ; Impresion (Llamada a procedimiento)

    ; Uso de la nueva macro de multiplicación (ejemplo: 8 x 5)
    Multiplicar 8, 5
    
    ; Imprimir el número (EAX) resultante
    call WriteDec          ; Impresion (Llamada a procedimiento)
    call Crlf              ; Impresion (Llamada a procedimiento)

    ; Mensaje final usando la macro
    MostrarMensaje mensajeFin

    exit
main ENDP

END main