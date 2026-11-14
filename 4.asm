; Materia: Lenguajes de Interfaz
; Alumno: Jesús Guadalupe Flores Beltrán
; Horario: 09:00 - 10:00
; Docente: Dr. José Luis Medina Jiménez
; Práctica: 4. Unidad 3

INCLUDE Irvine32.inc

.code
main PROC
    mov ebx, 999
    push 3
    push 25

    call SumarPila         ; Llamada a procedimiento

    nop 
    exit
main ENDP

; 
; Procedimiento: SumarPila
; 
SumarPila PROC
    push ebp
    mov ebp, esp
    push ebx
    
    mov eax, [ebp+8]
    mov ebx, [ebp+12]
    imul eax, ebx

    pop ebx
    pop ebp

    ret 8
SumarPila ENDP

END main