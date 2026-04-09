-- =========================================================================
-- PASO 7 DE 13 — COLUMNA ES_JEFE EN ADSCRIPCIONES
-- Nombre: UPDATE_SCHEMA_ES_JEFE.sql
-- Descripción: Agrega la columna es_jefe a empleado_adscripciones.
--              Permite marcar si el empleado es jefe en su departamento.
--              Requerido por el módulo de Empleados y Dashboard.
--              Requiere: PASO 1 ejecutado primero.
-- =========================================================================

-- Run this in Supabase SQL Editor
ALTER TABLE empleado_adscripciones ADD COLUMN IF NOT EXISTS es_jefe BOOLEAN DEFAULT FALSE;
