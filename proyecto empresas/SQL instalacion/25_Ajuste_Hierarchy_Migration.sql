-- =========================================================================
-- PASO 8 DE 13 — COLUMNA ES_JEFE EN CATÁLOGO DE PUESTOS
-- Nombre: migration_hierarchy.sql
-- Descripción: Agrega la columna es_jefe a cat_puestos.
--              Identifica qué puesto tiene función de jefatura.
--              Requerido por el módulo de Catálogos y Empleados.
--              Requiere: PASO 1 ejecutado primero.
-- =========================================================================

-- Run this in your Supabase SQL Editor to add the Manager flag
ALTER TABLE cat_puestos 
ADD COLUMN IF NOT EXISTS es_jefe boolean DEFAULT false;

-- Optional: If you want to link departments specifically to a "Titular"
-- ALTER TABLE cat_departamentos ADD COLUMN id_titular uuid REFERENCES empleados(id_empleado);
