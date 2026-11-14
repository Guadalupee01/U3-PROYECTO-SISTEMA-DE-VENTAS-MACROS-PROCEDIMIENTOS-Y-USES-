# Prácticas de la Unidad 3 - Lenguajes de Interfaz

Materia: Lenguajes de Interfaz
Alumno: Jesús Guadalupe Flores Beltrán
Horario: 09:00 - 10:00
Docente: Dr. José Luis Medina Jiménez

---

## Descripción de las Prácticas y Comprobación

### Práctica 1 (1.asm) - Procedimientos Básicos
Qué hace el programa: Introduce la declaración y uso de procedimientos personalizados (PROC y ENDP) mediante el procedimiento mensajeAviso, el cual es invocado múltiples veces desde el procedimiento principal (main).
Qué se comprobó al ejecutarlo: Se comprobó cómo la instrucción call desvía el flujo de ejecución hacia el procedimiento y cómo ret regresa exactamente a la línea siguiente en main, manteniendo la ejecución ordenada sin importar las modificaciones al registro EAX entre llamadas.

### Práctica 2 (2.asm) - Validación de Cadena con Procedimientos
Qué hace el programa: Solicita al usuario ingresar una cadena de texto en consola y pasa su dirección de memoria (OFFSET) a un procedimiento llamado ValidarCadena, el cual verifica si la cadena tiene contenido o si está vacía.
Qué se comprobó al ejecutarlo: Se comprobó el paso de parámetros por referencia usando EDX y el retorno de resultados en EAX (1 con texto, 0 vacía). Al presionar solo Enter, el programa detecta el carácter nulo (0) en el primer byte ([edx]) e imprime que está vacía; al escribir caracteres, confirma que contiene información.

### Práctica 4 (4.asm) - Paso de Parámetros por la Pila (Stack)
Qué hace el programa: Inserta dos valores numéricos (3 y 25) en la pila usando push y llama al procedimiento SumarPila, el cual accede a estos parámetros a través del puntero de base (EBP) y realiza una multiplicación con imul.
Qué se comprobó al ejecutarlo: Se comprobó la creación del Stack Frame (push ebp / mov ebp, esp), el acceso a parámetros en la pila mediante [ebp+8] y [ebp+12], la preservación del registro EBX (conservando su valor original de 999 al salir del procedimiento) y la limpieza correcta de los parámetros en la pila con ret 8.

### Práctica 5 (5.asm) - Uso de Macros con Parámetros
Qué hace el programa: Define y utiliza dos macros con argumentos: MostrarMensaje para automatizar la impresión de cadenas de texto y Multiplicar para calcular el producto de dos valores recibidos como parámetros y mostrar el resultado en pantalla.
Qué se comprobó al ejecutarlo: Se comprobó la expansión de código de las macros durante el ensamblado y cómo simplifican tareas repetitivas, mostrando correctamente los mensajes del sistema de inventario y el resultado 40 de la multiplicación 8 x 5.
