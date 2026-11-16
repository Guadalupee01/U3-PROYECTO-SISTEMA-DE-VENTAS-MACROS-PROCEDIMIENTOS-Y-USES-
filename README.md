# Proyecto: Sistema de Ventas e Inventario (Tienda de Videojuegos) - Unidad 3

Este repositorio contiene el proyecto integrador de la Unidad 3 para la materia de Lenguajes de Interfaz. El sistema está desarrollado en ensamblador MASM x86 (32 bits) empleando la librería Irvine32. La versión actual está refactorizada utilizando **macros**, **procedimientos** y la directiva **`USES`**.

## Archivos del Proyecto
* **Código fuente (.asm):** Lógica del sistema, validaciones y regla de negocio.
* **inventario.dat:** Archivo binario de longitud fija (484 bytes) con los registros de prueba.
* **Reporte Técnico:** Documento con la justificación técnica, tabla de antes y después, y tabla de pruebas.

## Instrucciones de Compilación y Ejecución
1. Abrir la solución `Project.sln` en **Visual Studio 2019** (ubicada en `C:\Irvine\examples\Project32_VS2019`).
2. Asegurar que la configuración activa sea **Debug** y la plataforma **Win32 (x86)**.
3. Verificar en **Proyecto -> Propiedades -> Vinculador -> Entrada** que esté incluida la dependencia `Irvine32.lib`.
4. Presionar **`Ctrl + Shift + B`** para compilar la solución.
5. Presionar **`F5`** (o ir a Depurar -> Iniciar depuración) para ejecutar el sistema en la consola.