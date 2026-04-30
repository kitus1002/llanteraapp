-- =========================================================================
-- PASO 12-F DE 13 — SEMILLA: TIPO DE SOLICITUD "REINGRESO"
-- Nombre: 20260202_add_reingreso_request_type.sql
-- Descripción: Inserta el tipo de solicitud "Reingreso" en cat_tipos_solicitud.
--              Necesario para reincorporar empleados dados de baja.
--              Requiere: PASO 10 ejecutado primero.
-- =========================================================================

-- Add Reingreso request type
INSERT INTO cat_tipos_solicitud (tipo_solicitud) 
VALUES ('Reingreso') 
ON CONFLICT DO NOTHING;
