-- =========================================================================
-- PASO 4 DE 13 — TIPOS DE CHECADA: RETORNOS
-- Nombre: SQL_FIX_RETORNOS.sql
-- Descripción: Inserta los tipos de checada de regreso:
--              REGRESO_PERMISO_PERSONAL y REGRESO_OPERACIONES.
--              El kiosko no mostrará botones de regreso sin este script.
--              Requiere: PASO 2 ejecutado primero.
-- Ejecutar en el Editor SQL de Supabase
-- Proyecto: El Expediente (rh-system)
-- =========================================================================

-- INSERTAR NUEVOS TIPOS DE REGRESO PARA PERMISOS
INSERT INTO cat_tipos_checada (tipo, label, requiere_codigo, color, ordinal) 
VALUES
  ('REGRESO_PERMISO_PERSONAL', 'PERMISO REGRESO', false, 'bg-blue-500', 7),
  ('REGRESO_OPERACIONES', 'OP. REGRESO', false, 'bg-indigo-500', 8)
ON CONFLICT (tipo) DO UPDATE 
SET requiere_codigo = EXCLUDED.requiere_codigo, label = EXCLUDED.label;
