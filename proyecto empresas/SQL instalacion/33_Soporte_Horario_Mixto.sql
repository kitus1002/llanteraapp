-- =========================================================================
-- PASO 33 — SOPORTE PARA HORARIOS MIXTOS (SÁBADOS)
-- Descripción: Agrega la capacidad de tener un turno diferente para los sábados.
-- =========================================================================

-- 1. Agregar columna para el turno del sábado en la tabla de empleados
ALTER TABLE empleados 
ADD COLUMN IF NOT EXISTS id_turno_sabado UUID REFERENCES turnos(id) ON DELETE SET NULL;

-- 2. Ejemplo de creación de turnos para un Horario Mixto (Opcional, pero ayuda al usuario)
-- Turno Lunes-Viernes (8:00 AM - 6:00 PM)
INSERT INTO turnos (nombre, hora_inicio, hora_fin, aplica_dias)
VALUES ('Oficina Lunes-Viernes', '08:00:00', '18:00:00', '{"Lunes","Martes","Miércoles","Jueves","Viernes"}')
ON CONFLICT DO NOTHING;

-- Turno Sábado (8:00 AM - 2:00 PM)
INSERT INTO turnos (nombre, hora_inicio, hora_fin, aplica_dias)
VALUES ('Oficina Sábado', '08:00:00', '14:00:00', '{"Sábado"}')
ON CONFLICT DO NOTHING;
