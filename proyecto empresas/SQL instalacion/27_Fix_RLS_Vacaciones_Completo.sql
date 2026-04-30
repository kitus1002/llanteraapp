-- =========================================================================
-- PASO 27 — FIX RLS: PERIODOS VACACIONALES Y SALDOS
-- Descripción: Permite que el sistema inserte periodos y saldos automáticamente
--              cuando se registra un empleado o su fecha de ingreso.
-- =========================================================================

-- 1. Políticas para cat_periodos_vacacionales
ALTER TABLE cat_periodos_vacacionales ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir insert periodos" ON cat_periodos_vacacionales;
CREATE POLICY "Permitir insert periodos" ON cat_periodos_vacacionales FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir select periodos" ON cat_periodos_vacacionales;
CREATE POLICY "Permitir select periodos" ON cat_periodos_vacacionales FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir update periodos" ON cat_periodos_vacacionales;
CREATE POLICY "Permitir update periodos" ON cat_periodos_vacacionales FOR UPDATE USING (true);


-- 2. Políticas para vacaciones_saldos
ALTER TABLE vacaciones_saldos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir insert saldos" ON vacaciones_saldos;
CREATE POLICY "Permitir insert saldos" ON vacaciones_saldos FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir select saldos" ON vacaciones_saldos;
CREATE POLICY "Permitir select saldos" ON vacaciones_saldos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir update saldos" ON vacaciones_saldos;
CREATE POLICY "Permitir update saldos" ON vacaciones_saldos FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete saldos" ON vacaciones_saldos;
CREATE POLICY "Permitir delete saldos" ON vacaciones_saldos FOR DELETE USING (true);

-- 3. Asegurar que el trigger tenga permisos de ejecución (Security Definer)
-- Esto hace que la función se ejecute con permisos de sistema y no falle por RLS del usuario
ALTER FUNCTION public.fn_generar_saldos_vacaciones() SECURITY DEFINER;
