; Materia: Lenguajes de Interfaz
; Alumno: Jesús Guadalupe Flores Beltrán
; Horario: 09:00 - 10:00
; Docente: Dr. José Luis Medina Jiménez
; Práctica: 3. Unidad 3

INCLUDE Irvine32.inc

.data
    prompt    BYTE "Ingresa una cadena (o presiona Enter para dejarla vacia): ", 0
    cadena    BYTE 100 DUP(0)  
    
    msgVacia  BYTE "Resultado: 0 - La cadena esta vacia.", 0dh, 0ah, 0
    msgLlena  BYTE "Resultado: 1 - La cadena tiene algo.", 0dh, 0ah, 0

.code
main PROC
    ; Leer la cadena desde el teclado para no tener que cambiar el codigo
    mov edx, OFFSET prompt
    call WriteString       ; Impresion (Llamada a procedimiento)

    mov edx, OFFSET cadena
    mov ecx, SIZEOF cadena
    call ReadString        ; Lectura (Llamada a procedimiento)

    ; Pasar la cadena al procedimiento
    mov edx, OFFSET cadena
    call ValidarCadena     ; Llamada a procedimiento

    ; Evaluar lo que devolvio el procedimiento en EAX
    cmp eax, 0
    je EsVacia

    ; Si EAX es 1
    mov edx, OFFSET msgLlena
    call WriteString       ; Impresion (Llamada a procedimiento)
    jmp Fin

EsVacia:
    ; Si EAX es 0
    mov edx, OFFSET msgVacia
    call WriteString       ; Impresion (Llamada a procedimiento)

Fin:
    exit
main ENDP

; 
; ValidarCadena
; Recibe: EDX apuntando a la cadena
; Devuelve: EAX = 1 (tiene algo), EAX = 0 (esta vacia)
; 
ValidarCadena PROC
    mov al, [edx]       ; Leer el primer byte
    cmp al, 0           ; Si el primer byte es 0, no se escribio nada
    je CadenaVacia

    mov eax, 1          ; Tiene contenido
    ret

CadenaVacia:
    mov eax, 0          ; Esta vacia
    ret
ValidarCadena ENDP

END main