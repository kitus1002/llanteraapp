# Guía de Instalación para Nuevo Proyecto Empresa

En esta carpeta se han recopilado **todos** los archivos SQL de tu proyecto actual, tanto los que estaban en la carpeta principal como en la carpeta `supabase/`. 

Si quieres crear un nuevo cliente o empresa y quieres tener exactamente la misma estructura y funcionalidades (con el checador, permisos, roles, etc.), te recomiendo seguir este orden al copiar y pegar el código en el SQL Editor de tu nuevo proyecto de Supabase:

### 1. Base Principal
Copia y pega todo el contenido de este archivo primero. Contiene las tablas de empleados, vacaciones, empresas y los catálogos base.
- `SCRIPTS_NUEVA_EMPRESA.sql`

### 2. Módulo de Checador y Turnos (Fase 2)
Este archivo agrega toda la funcionalidad avanzada del checador de fase 2.
- `SQL_CHECADOR_FASE_2.sql`

### 3. Parches y Correcciones Posteriores
Después de ejecutar el checador, asegúrate de correr estos parches en cualquier orden, ya que son ajustes específicos de permisos y lógica que hicimos después:
- `SQL_FIX_PERMISOS.sql` (Muy importante para que las políticas RLS funcionen en el checador).
- `SQL_FIX_RETORNOS.sql` (Corrige la lógica de retornos de funciones RPC).
- `SQL_ADD_LIMITE_FALTA.sql` (Agrega el tiempo límite a los turnos).
- `SQL_FIX_TOLERANCIA_PERMISOS.sql` (Aplica tolerancias).
- `UPDATE_SCHEMA_ES_JEFE.sql` (Actualiza funciones del dashboard).
- `CREATE_TABLE_PERFILES.sql` (Solo si no venía ya en el script principal).

### 4. Semillas Extras
Si te hace falta información de roles que no venía por defecto:
- `seeds.sql` o `seeds_roles.sql`

> **Nota:** Puedes ignorar los archivos que dicen `schema_dump.sql`, `schema.sql` o `schema_current.sql`, ya que regularmente son copias de seguridad de la estructura y correrlos de golpe puede dar error por objetos duplicados. Lo mejor es seguir el orden detallado aquí arriba.
