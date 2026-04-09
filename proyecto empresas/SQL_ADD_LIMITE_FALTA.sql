-- =========================================================================
-- PASO 5 DE 13 — LÍMITE DE FALTA EN TURNOS
-- Nombre: SQL_ADD_LIMITE_FALTA.sql
-- Descripción: Agrega la columna limite_falta_min a la tabla turnos.
--              Define cuántos minutos después de la hora de entrada
--              se considera FALTA (default: 60 min).
--              Requiere: PASO 2 ejecutado primero.
-- =========================================================================

-- Agregar columna limite_falta_min a la tabla turnos
ALTER TABLE turnos ADD COLUMN IF NOT EXISTS limite_falta_min INT NOT NULL DEFAULT 60;
