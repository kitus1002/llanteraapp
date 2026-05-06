-- ==============================================================================
-- 36_Fix_RLS_Checadas.sql
-- Propósito: Añadir políticas de seguridad (RLS) para permitir la eliminación 
-- y modificación de registros en la tabla "checadas" desde el panel de Asistencia.
-- ==============================================================================

-- 1. Añadir política para permitir eliminar (DELETE) checadas
-- Esto permite que los botones de "Eliminar" en el menú de asistencias funcionen
DROP POLICY IF EXISTS "Permitir delete a todos checadas" ON checadas;
CREATE POLICY "Permitir delete a todos checadas" ON checadas FOR DELETE USING (true);

-- 2. Añadir política para permitir actualizar (UPDATE) checadas
-- Esto permite que los botones de "Editar" en el menú de asistencias funcionen
DROP POLICY IF EXISTS "Permitir update a todos checadas" ON checadas;
CREATE POLICY "Permitir update a todos checadas" ON checadas FOR UPDATE USING (true) WITH CHECK (true);

-- Nota: Estas políticas asumen que el control de acceso principal 
-- se maneja a nivel de aplicación (ej. verificando que el usuario es RH).
