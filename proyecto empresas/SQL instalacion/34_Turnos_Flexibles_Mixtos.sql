-- =========================================================================
-- PASO 34 — TURNOS FLEXIBLES (HORARIOS MIXTOS DENTRO DEL MISMO TURNO)
-- Descripción: Permite que un mismo turno tenga horas diferentes para días específicos.
-- =========================================================================

-- 1. Limpieza del intento anterior (opcional para mantener orden)
ALTER TABLE empleados DROP COLUMN IF EXISTS id_turno_sabado;

-- 2. Agregar columnas de flexibilidad a la tabla de turnos
ALTER TABLE turnos 
ADD COLUMN IF NOT EXISTS hora_inicio_especial TIME,
ADD COLUMN IF NOT EXISTS hora_fin_especial TIME,
ADD COLUMN IF NOT EXISTS dias_especiales TEXT[] DEFAULT '{}'; -- Ej: '{"Sábado"}'

-- 3. Ejemplo de actualización de un turno existente a Horario Mixto
-- Supongamos que queremos que el turno de "Oficina" sea de 8-6 entre semana, pero 8-2 los sábados.
-- UPDATE turnos 
-- SET hora_inicio_especial = '08:00:00', 
--     hora_fin_especial = '14:00:00', 
--     dias_especiales = '{"Sábado"}'
-- WHERE nombre = 'Oficina Lunes-Viernes';
