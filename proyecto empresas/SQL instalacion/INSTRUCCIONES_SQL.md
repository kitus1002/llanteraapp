# Guía de Instalación SQL - El Expediente (RH System)

**NUEVA ACTUALIZACIÓN CRÍTICA (Fix `tolerancia_retorno_min`):** 
El script `10_Schema_Actualizacion_RLS_Completo.sql` fallaba en la inserción porque la columna `tolerancia_retorno_min` fue añadida en un script posterior (parche) en el ciclo de vida del proyecto.
Para respetar el código 100% original sin modificar su contenido, **hemos reorganizado el orden de ejecución** para que los parches estructurales (`ALTER TABLE`) se ejecuten **antes** del volcado de mantenimiento (`INSERT`).

### 📋 Instrucciones de Ejecución
Ejecuta los archivos en el **SQL Editor de Supabase** siguiendo estrictamente la numeración del **01 al 27**.

---

### 🟢 Fase 1: Estructura Base 
1. **01_Instalacion_Base_Empleados.sql**: Crea `empleados`, expedientes y catálogos principales.
2. **02_Estructura_Checador_Fase2.sql**: Crea las tablas del módulo de asistencia (`turnos`, `checadas`, `dispositivos_checadores`).

### 🟡 Fase 2: Parches de Estructura (Nuevas Columnas)
> [!IMPORTANT]
> **Esta es la fase que resuelve los errores de "column does not exist".**
3. **03_Ajuste_Limites_Falta.sql**: Añade tolerancias a turnos.
4. **04_Fix_Tolerancias_Permisos.sql**: Añade `tolerancia_retorno_min` a tipos de checada.
5. **05_Update_Es_Jefe.sql**: Añade `es_jefe` a puestos.
6. **06_Update_Checadas_Manuales_y_Festivos.sql**: Soporte para registros manuales.
7. **07_Fix_Estructura_Checadas.sql**: Ajustes en puntualidad y geolocalización.
8. **08_Ajuste_Header_Footer_Docs.sql** y **09_Ajuste_Bloques_Docs.sql**: Columnas para el editor de plantillas.

### 🔵 Fase 3: Mantenimiento e Inserciones Base
10. **10_Schema_Actualizacion_RLS_Completo.sql**: Aplica RLS, triggers y hace las inserciones maestras (ahora que las columnas existen, no fallará).

### 🟠 Fase 4: Catálogos, Fixes Finales y Lógica
11. **11_Catalogos_Base_Seeds.sql** a **14_Calculos_LFT_Helpers.sql**: Catálogos, Semillas y Reglas LFT (Horas extra).
12. **15_Fix_Seguridad_RLS.sql** y **16_Fix_Retornos_Comida.sql**: Ajustes finales en permisos de UI.
13. **17_Config_Timezone.sql** a **26_Create_Table_Perfiles_Standalone.sql**: Inicialización de vacaciones, migraciones de jerarquía y catálogos de bajas IMSS.
14. **27_Fix_RLS_Vacaciones_Completo.sql**: Resuelve el error de permisos al guardar fechas de ingreso (cat_periodos_vacacionales).

---
**Conclusión:** Ejecutando del 01 al 27 en este nuevo orden, las dependencias de tablas y columnas encajarán a la perfección.
