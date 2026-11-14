; Materia: Lenguajes de Interfaz
; Alumno: Jesús Guadalupe Flores Beltrán
; Horario: 09:00 - 10:00
; Docente: Dr. José Luis Medina Jiménez
; Práctica: 1. Unidad 3

INCLUDE Irvine32.inc

.data
    mensajeInicio BYTE "Inicio de programa", 0
    mensajeProcedimiento BYTE "Estoy dentro del procedimiento", 0
    mensajeFin BYTE "Fin del programa", 0

.code
main PROC
    ; Imprimir el mensaje 
    mov edx, OFFSET mensajeInicio
    call WriteString       ; Impresion (Llamada a procedimiento)
    call crlf

    call mensajeAviso      ; Llamada a procedimiento

    ; Segunda llamada al procedimiento
    mov eax, 10         
    call mensajeAviso      ; Llamada a procedimiento
    mov eax, 20         

    ; Imprimir el mensaje de fin
    mov edx, OFFSET mensajeFin
    call WriteString       ; Impresion (Llamada a procedimiento)
    call Crlf
    
    exit
main ENDP

; 
; Procedimiento: mensajeAviso
; 
mensajeAviso PROC
    mov edx, OFFSET mensajeProcedimiento
    call WriteString       ; Impresion (Llamada a procedimiento)
    call crlf
    ret
mensajeAviso ENDP

END main