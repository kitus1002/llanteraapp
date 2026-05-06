-- =========================================================================
-- PASO 35 — FIX DE SINCRONIZACIÓN Y SOPORTE FLEXIBLE EN ROLES
-- Descripción: Asegura que cat_tipos_rol tenga las mismas columnas que turnos
-- para que el calendario pueda calcular correctamente los horarios especiales.
-- =========================================================================

-- 1. Agregar columnas de flexibilidad a la tabla de cat_tipos_rol
-- (Estas columnas permiten que los Roles también tengan horarios especiales por día)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_tipos_rol' AND column_name='hora_inicio') THEN
        ALTER TABLE cat_tipos_rol ADD COLUMN hora_inicio TIME DEFAULT '08:00:00';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_tipos_rol' AND column_name='hora_fin') THEN
        ALTER TABLE cat_tipos_rol ADD COLUMN hora_fin TIME DEFAULT '17:00:00';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_tipos_rol' AND column_name='hora_inicio_especial') THEN
        ALTER TABLE cat_tipos_rol ADD COLUMN hora_inicio_especial TIME;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_tipos_rol' AND column_name='hora_fin_especial') THEN
        ALTER TABLE cat_tipos_rol ADD COLUMN hora_fin_especial TIME;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_tipos_rol' AND column_name='dias_especiales') THEN
        ALTER TABLE cat_tipos_rol ADD COLUMN dias_especiales TEXT[] DEFAULT '{}';
    END IF;
END $$;

-- 2. Corrección de Integridad: Asegurar que los tipos de datos sean compatibles con el front-end
-- Nota: Si se usa SQLite local, el tipo TEXT[] se trata como TEXT simple. 
-- El front-end ya está preparado para manejar ambos casos.

-- 3. Comentario de Auditoría
COMMENT ON COLUMN cat_tipos_rol.dias_especiales IS 'Días con horario especial (ej: Sábado) para el rol asignado';

-- 4. Re-sincronización de índices (Opcional, mejora rendimiento del calendario)
CREATE INDEX IF NOT EXISTS idx_checadas_sync_cal ON checadas(id_empleado, fecha_local, tipo_checada);
