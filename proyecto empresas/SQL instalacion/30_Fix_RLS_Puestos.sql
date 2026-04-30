-- =========================================================================
-- PASO 30 — FIX RLS: PUESTOS
-- Descripción: Habilita los permisos necesarios para crear, editar y ver
--              puestos en el sistema.
-- =========================================================================

-- Asegurar que RLS está activo
ALTER TABLE cat_puestos ENABLE ROW LEVEL SECURITY;

-- Política de Lectura
DROP POLICY IF EXISTS "Permitir select puestos" ON cat_puestos;
CREATE POLICY "Permitir select puestos" ON cat_puestos FOR SELECT USING (true);

-- Política de Inserción
DROP POLICY IF EXISTS "Permitir insert puestos" ON cat_puestos;
CREATE POLICY "Permitir insert puestos" ON cat_puestos FOR INSERT WITH CHECK (true);

-- Política de Actualización
DROP POLICY IF EXISTS "Permitir update puestos" ON cat_puestos;
CREATE POLICY "Permitir update puestos" ON cat_puestos FOR UPDATE USING (true);

-- Política de Eliminación
DROP POLICY IF EXISTS "Permitir delete puestos" ON cat_puestos;
CREATE POLICY "Permitir delete puestos" ON cat_puestos FOR DELETE USING (true);
