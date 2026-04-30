-- =========================================================================
-- PASO 29 — FIX RLS: DEPARTAMENTOS
-- Descripción: Habilita los permisos necesarios para crear, editar y ver
--              departamentos en el sistema.
-- =========================================================================

-- Asegurar que RLS está activo
ALTER TABLE cat_departamentos ENABLE ROW LEVEL SECURITY;

-- Política de Lectura (Pública/Autenticada)
DROP POLICY IF EXISTS "Permitir select departamentos" ON cat_departamentos;
CREATE POLICY "Permitir select departamentos" ON cat_departamentos FOR SELECT USING (true);

-- Política de Inserción
DROP POLICY IF EXISTS "Permitir insert departamentos" ON cat_departamentos;
CREATE POLICY "Permitir insert departamentos" ON cat_departamentos FOR INSERT WITH CHECK (true);

-- Política de Actualización
DROP POLICY IF EXISTS "Permitir update departamentos" ON cat_departamentos;
CREATE POLICY "Permitir update departamentos" ON cat_departamentos FOR UPDATE USING (true);

-- Política de Eliminación
DROP POLICY IF EXISTS "Permitir delete departamentos" ON cat_departamentos;
CREATE POLICY "Permitir delete departamentos" ON cat_departamentos FOR DELETE USING (true);
