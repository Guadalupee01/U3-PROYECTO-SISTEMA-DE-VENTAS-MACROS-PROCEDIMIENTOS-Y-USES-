; Materia: Lenguajes de Interfaz
; Alumno: Jesús Guadalupe Flores Beltrán
; Horario: 09:00 - 10:00
; Docente: Dr. José Luis Medina Jiménez
; Práctica: 2. Lectura de Cadena y Conteo de Caracteres

INCLUDE Irvine32.inc

.data 
    mensajeEntrada     BYTE "Escribe tu nombre: ", 0
    caracteresEscritos BYTE "Numero de caracteres: ", 0
    nombre             BYTE 20 DUP(0)

.code
main PROC
    mov edx, OFFSET mensajeEntrada
    call WriteString       ; Impresion (Llamada a procedimiento)
    
    mov edx, OFFSET nombre
    mov ecx, SIZEOF nombre
    call ReadString        ; Lectura (Llamada a procedimiento)
    call Crlf              ; Impresion (Llamada a procedimiento)

    mov edx, OFFSET nombre
    call WriteString       ; Impresion (Llamada a procedimiento)
    call Crlf              ; Impresion (Llamada a procedimiento)

    mov edx, OFFSET caracteresEscritos 
    call WriteString       ; Impresion (Llamada a procedimiento)
    call WriteDec          ; Impresion (Llamada a procedimiento)

    exit 
main ENDP

END main