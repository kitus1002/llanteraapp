-- =========================================================================
-- PASO 13 DE 13 — TABLA DE DÍAS FESTIVOS (NUEVO — REQUERIDO)
-- Nombre: SQL_FESTIVOS.sql
-- Descripción: Crea cat_dias_festivos con festivos oficiales de México 2026.
--              Requerido por /configuracion/festivos/ y módulo Calendario.
--              ESTE ARCHIVO ES NUEVO — no existía antes, fue detectado como
--              tabla faltante en la revisión del sistema.
--              Requiere: PASO 1 ejecutado primero.
-- =========================================================================

-- TABLA: cat_dias_festivos
-- Usada por: /configuracion/festivos/ y módulo Calendario
CREATE TABLE IF NOT EXISTS cat_dias_festivos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    fecha DATE NOT NULL,
    tipo TEXT DEFAULT 'oficial', -- 'oficial' | 'empresa'
    activo BOOLEAN DEFAULT TRUE,
    creado_el TIMESTAMPTZ DEFAULT now()
);

-- Seguridad RLS
ALTER TABLE cat_dias_festivos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All festivos" ON cat_dias_festivos;
CREATE POLICY "Authenticated All festivos" ON cat_dias_festivos FOR ALL USING (true);

-- Semillas: Festivos oficiales México 2026 (LFT)
INSERT INTO cat_dias_festivos (nombre, fecha, tipo) VALUES
('Año Nuevo',                   '2026-01-01', 'oficial'),
('Constitución Mexicana',       '2026-02-02', 'oficial'),
('Natalicio de Benito Juárez',  '2026-03-16', 'oficial'),
('Semana Santa (Jueves Santo)', '2026-04-02', 'oficial'),
('Semana Santa (Viernes Santo)','2026-04-03', 'oficial'),
('Día del Trabajo',             '2026-05-01', 'oficial'),
('Independencia de México',     '2026-09-16', 'oficial'),
('Día de Muertos',              '2026-11-02', 'oficial'),
('Revolución Mexicana',         '2026-11-16', 'oficial'),
('Navidad',                     '2026-12-25', 'oficial')
ON CONFLICT DO NOTHING;
