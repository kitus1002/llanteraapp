-- =========================================================================
-- PASO 11 DE 13 — SEMILLAS: TIPOS DE ROL (TURNOS ROTATIVOS)
-- Nombre: seeds_roles.sql
-- Descripción: Inserta los tipos de rol rotativo en cat_tipos_rol:
--              20x10, 14x7 y 5x2 (semana inglesa).
--              Necesario para Pre-Nómina y asignación de empleados.
--              Requiere: PASO 1 ejecutado primero.
-- =========================================================================

-- Semillas para Catálogo de Tipos de Rol (Turnos)
INSERT INTO cat_tipos_rol (tipo_rol, dias_trabajo, dias_descanso, descripcion) VALUES
('20x10', 20, 10, '20 días de trabajo por 10 de descanso'),
('14x7', 14, 7, '14 días de trabajo por 7 de descanso'),
('5x2', 5, 2, 'Semana inglesa (5 días trabajo, 2 descanso)')
ON CONFLICT DO NOTHING;
