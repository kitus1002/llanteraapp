-- =========================================================================
-- PASO 31 — FIX RLS: CAUSAS DE BAJA Y UNIDADES DE TRABAJO
-- Descripción: Habilita los permisos necesarios para gestionar causas de baja
--              y unidades de trabajo en el sistema.
-- =========================================================================

-- 1. Políticas para cat_causas_baja
ALTER TABLE cat_causas_baja ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir select causas" ON cat_causas_baja;
CREATE POLICY "Permitir select causas" ON cat_causas_baja FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir insert causas" ON cat_causas_baja;
CREATE POLICY "Permitir insert causas" ON cat_causas_baja FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir update causas" ON cat_causas_baja;
CREATE POLICY "Permitir update causas" ON cat_causas_baja FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete causas" ON cat_causas_baja;
CREATE POLICY "Permitir delete causas" ON cat_causas_baja FOR DELETE USING (true);


-- 2. Políticas para cat_unidades_trabajo
ALTER TABLE cat_unidades_trabajo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir select unidades" ON cat_unidades_trabajo;
CREATE POLICY "Permitir select unidades" ON cat_unidades_trabajo FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir insert unidades" ON cat_unidades_trabajo;
CREATE POLICY "Permitir insert unidades" ON cat_unidades_trabajo FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir update unidades" ON cat_unidades_trabajo;
CREATE POLICY "Permitir update unidades" ON cat_unidades_trabajo FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete unidades" ON cat_unidades_trabajo;
CREATE POLICY "Permitir delete unidades" ON cat_unidades_trabajo FOR DELETE USING (true);
