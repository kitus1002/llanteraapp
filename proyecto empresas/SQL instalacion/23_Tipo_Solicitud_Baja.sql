-- =========================================================================
-- PASO 12-E DE 13 — SEMILLA: TIPO DE SOLICITUD "BAJA"
-- Nombre: 20260202_insert_baja_request_type.sql
-- Descripción: Inserta el tipo de solicitud "Baja" en cat_tipos_solicitud.
--              Sin este dato el módulo de Solicitudes de baja no funciona.
--              Requiere: PASO 10 ejecutado primero.
-- =========================================================================

-- Insert 'Baja' request type if it doesn't exist
INSERT INTO cat_tipos_solicitud (tipo_solicitud)
SELECT 'Baja'
WHERE NOT EXISTS (
    SELECT 1 FROM cat_tipos_solicitud WHERE tipo_solicitud = 'Baja'
);
