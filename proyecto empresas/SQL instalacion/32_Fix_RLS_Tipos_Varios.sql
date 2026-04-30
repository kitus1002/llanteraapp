-- =========================================================================
-- PASO 32 — FIX RLS: TIPOS DE INCIDENCIA, SOLICITUD Y ROLES
-- Descripción: Habilita los permisos necesarios para gestionar catálogos
--              de incidencias, solicitudes y roles en el sistema.
-- =========================================================================

-- 1. Políticas para cat_tipos_incidencia
ALTER TABLE cat_tipos_incidencia ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir select incidencias" ON cat_tipos_incidencia;
CREATE POLICY "Permitir select incidencias" ON cat_tipos_incidencia FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir insert incidencias" ON cat_tipos_incidencia;
CREATE POLICY "Permitir insert incidencias" ON cat_tipos_incidencia FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir update incidencias" ON cat_tipos_incidencia;
CREATE POLICY "Permitir update incidencias" ON cat_tipos_incidencia FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete incidencias" ON cat_tipos_incidencia;
CREATE POLICY "Permitir delete incidencias" ON cat_tipos_incidencia FOR DELETE USING (true);


-- 2. Políticas para cat_tipos_solicitud
ALTER TABLE cat_tipos_solicitud ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir select solicitudes" ON cat_tipos_solicitud;
CREATE POLICY "Permitir select solicitudes" ON cat_tipos_solicitud FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir insert solicitudes" ON cat_tipos_solicitud;
CREATE POLICY "Permitir insert solicitudes" ON cat_tipos_solicitud FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir update solicitudes" ON cat_tipos_solicitud;
CREATE POLICY "Permitir update solicitudes" ON cat_tipos_solicitud FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete solicitudes" ON cat_tipos_solicitud;
CREATE POLICY "Permitir delete solicitudes" ON cat_tipos_solicitud FOR DELETE USING (true);


-- 3. Políticas para cat_tipos_rol
ALTER TABLE cat_tipos_rol ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Permitir select roles" ON cat_tipos_rol;
CREATE POLICY "Permitir select roles" ON cat_tipos_rol FOR SELECT USING (true);

DROP POLICY IF EXISTS "Permitir insert roles" ON cat_tipos_rol;
CREATE POLICY "Permitir insert roles" ON cat_tipos_rol FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir update roles" ON cat_tipos_rol;
CREATE POLICY "Permitir update roles" ON cat_tipos_rol FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Permitir delete roles" ON cat_tipos_rol;
CREATE POLICY "Permitir delete roles" ON cat_tipos_rol FOR DELETE USING (true);
