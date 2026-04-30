-- =========================================================================
-- PASO 28 — FIX: NÚMERO DE EMPLEADO AUTO-INCREMENTAL
-- Descripción: Convierte el campo numero_empleado en auto-incremental para
--              evitar errores de "duplicate key" al registrar nuevos empleados.
-- =========================================================================

-- 1. Crear una secuencia basada en el valor máximo actual (para no perder el orden)
DO $$
DECLARE
    max_val INT;
BEGIN
    SELECT COALESCE(MAX(numero_empleado), 0) + 1 INTO max_val FROM empleados;
    
    -- Creamos la secuencia si no existe
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'empleados_numero_empleado_seq') THEN
        EXECUTE 'CREATE SEQUENCE empleados_numero_empleado_seq START WITH ' || max_val;
        
        -- Asignamos la secuencia como valor por defecto de la columna
        ALTER TABLE empleados ALTER COLUMN numero_empleado SET DEFAULT nextval('empleados_numero_empleado_seq');
    END IF;
END $$;

-- 2. Asegurar que la secuencia esté sincronizada con los datos existentes
SELECT setval('empleados_numero_empleado_seq', COALESCE((SELECT MAX(numero_empleado) FROM empleados), 1));
