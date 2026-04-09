-- =========================================================================
-- PASO 6 DE 13 — TOLERANCIA DE RETORNO EN TIPOS DE CHECADA
-- Nombre: SQL_FIX_TOLERANCIA_PERMISOS.sql
-- Descripción: Agrega la columna tolerancia_retorno_min a cat_tipos_checada.
--              Configura cuántos minutos de gracia tiene el empleado
--              para regresar después de un permiso/salida operaciones.
--              Requiere: PASO 4 ejecutado primero.
-- Proyecto: El Expediente (rh-system)
-- =========================================================================

-- 1. Añadimos la columna para configurar tolerancia en retornos (en minutos). Ej: 5 min, 10 min.
ALTER TABLE cat_tipos_checada 
ADD COLUMN IF NOT EXISTS tolerancia_retorno_min INT DEFAULT 5;

-- 2. Aseguramos que los tipos que son de SALIDA (que requieren retorno) tengan al menos una configuración inicial.
UPDATE cat_tipos_checada 
SET tolerancia_retorno_min = 5 
WHERE tipo IN ('PERMISO_PERSONAL', 'SALIDA_OPERACIONES');

-- Nota: El estatus "Completado" no requiere DDL ya que en Supabase la columna 'estatus' de permisos_autorizados
-- probablemente es de tipo TEXT o VARCHAR, por lo que acepta libremente 'Completado'.
-- (Si es un ENUM, habría que hacer un ALTER TYPE, pero por tu estructura asumo que es TEXT).
