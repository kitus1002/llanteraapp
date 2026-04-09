-- ==========================================
-- SCRIPT DE ACTUALIZACIÓN Y MANTENIMIENTO (IDEMPOTENTE)
-- Nombre: schema.sql
-- Descripción: Asegura que todas las tablas y columnas necesarias 
--              existan sin borrar datos previos.
-- ==========================================

-- 1. ASEGURAR TABLAS BASE Y NUEVAS COLUMNAS
DO $$ 
BEGIN
    -- cat_causas_baja
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_causas_baja' AND column_name='requiere_evidencia') THEN
        ALTER TABLE cat_causas_baja ADD COLUMN requiere_evidencia BOOLEAN DEFAULT FALSE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_causas_baja' AND column_name='rol_iniciador') THEN
        ALTER TABLE cat_causas_baja ADD COLUMN rol_iniciador TEXT DEFAULT 'Jefe';
    END IF;

    -- empleados
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='estado_civil') THEN
        ALTER TABLE empleados ADD COLUMN estado_civil TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='tipo_residencia') THEN
        ALTER TABLE empleados ADD COLUMN tipo_residencia TEXT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='hijos_numero') THEN
        ALTER TABLE empleados ADD COLUMN hijos_numero INT DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='fecha_actualizacion') THEN
        ALTER TABLE empleados ADD COLUMN fecha_actualizacion TIMESTAMPTZ DEFAULT now();
    END IF;

    -- Limpiar duplicados en catálogos antes de agregar UNIQUE
    -- Mantener solo el registro más antiguo (menor ctid) por cada valor duplicado
    DELETE FROM cat_tipos_solicitud a
        USING cat_tipos_solicitud b
        WHERE a.ctid > b.ctid
        AND a.tipo_solicitud = b.tipo_solicitud;

    DELETE FROM cat_tipos_incidencia a
        USING cat_tipos_incidencia b
        WHERE a.ctid > b.ctid
        AND a.tipo_incidencia = b.tipo_incidencia;

    -- Agregar restricciones UNIQUE solo si no existen ya
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'cat_tipos_solicitud_tipo_solicitud_key'
    ) THEN
        ALTER TABLE cat_tipos_solicitud ADD CONSTRAINT cat_tipos_solicitud_tipo_solicitud_key UNIQUE (tipo_solicitud);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'cat_tipos_incidencia_tipo_incidencia_key'
    ) THEN
        ALTER TABLE cat_tipos_incidencia ADD CONSTRAINT cat_tipos_incidencia_tipo_incidencia_key UNIQUE (tipo_incidencia);
    END IF;

    -- Habilitar RLS y Políticas Autenticadas (Idempotente)
    EXECUTE 'ALTER TABLE empleado_domicilio ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE empleado_banco ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE empleado_salarios ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE empleado_roles ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE empleado_incidencias ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE vacaciones_saldos ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE cat_tipos_incidencia ENABLE ROW LEVEL SECURITY';
    EXECUTE 'ALTER TABLE cat_tipos_solicitud ENABLE ROW LEVEL SECURITY';
END $$;

-- Aplicar políticas de acceso total para usuarios autenticados
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_domicilio' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON empleado_domicilio FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_banco' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON empleado_banco FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_salarios' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON empleado_salarios FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_roles' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON empleado_roles FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_incidencias' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON empleado_incidencias FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vacaciones_saldos' AND policyname = 'Authenticated All') THEN
        CREATE POLICY "Authenticated All" ON vacaciones_saldos FOR ALL USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_tipos_incidencia' AND policyname = 'Public Read') THEN
        CREATE POLICY "Public Read" ON cat_tipos_incidencia FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_tipos_solicitud' AND policyname = 'Public Read') THEN
        CREATE POLICY "Public Read" ON cat_tipos_solicitud FOR SELECT USING (true);
    END IF;
END $$;

-- 2. CREACIÓN DE TABLAS SI NO EXISTEN (Asegurando esquemas completos)
CREATE TABLE IF NOT EXISTS cat_cecos (
    id_ceco UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave_ceco TEXT NOT NULL,
    descripcion_ceco TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_tipos_rol (
    id_tipo_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_rol TEXT NOT NULL,
    dias_trabajo INT NOT NULL,
    dias_descanso INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS empleado_roles (
    id_empleado_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    id_tipo_rol UUID REFERENCES cat_tipos_rol(id_tipo_rol)
);

CREATE TABLE IF NOT EXISTS empleado_domicilio (
    id_empleado UUID PRIMARY KEY REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    calle TEXT, numero_exterior TEXT, colonia TEXT, codigo_postal TEXT,
    municipio TEXT, estado TEXT, ciudad TEXT
);

CREATE TABLE IF NOT EXISTS empleado_banco (
    id_empleado UUID PRIMARY KEY REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    numero_cuenta TEXT, clabe TEXT, banco TEXT
);

CREATE TABLE IF NOT EXISTS empleado_salarios (
    id_empleado_salario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    salario_diario NUMERIC(10,2) NOT NULL,
    motivo TEXT
);

CREATE TABLE IF NOT EXISTS cat_causas_baja_imss (
    id_causa_imss UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS bajas (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_baja DATE NOT NULL,
    tipo_baja TEXT, 
    motivo_baja TEXT,
    id_causa_baja UUID REFERENCES cat_causas_baja(id_causa_baja),
    id_causa_imss UUID REFERENCES cat_causas_baja_imss(id_causa_imss),
    id_solicitud UUID REFERENCES solicitudes(id_solicitud),
    creado_el TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (id_empleado, fecha_baja)
);

-- 3. SEMILLAS (Datos faltantes)
INSERT INTO cat_tipos_rol (tipo_rol, dias_trabajo, dias_descanso) VALUES
('20x10', 20, 10),
('14x7', 14, 7),
('5x2 (Oficina)', 5, 2)
ON CONFLICT DO NOTHING;

INSERT INTO cat_causas_baja (causa, requiere_evidencia, rol_iniciador) VALUES 
('Término de contrato', FALSE, 'Sistema'),
('Separación voluntaria (renuncia)', FALSE, 'Empleado'),
('Abandono de empleo', TRUE, 'Jefe'),
('Defunción', FALSE, 'RH'),
('Clausura', FALSE, 'Directiva'),
('Otra', TRUE, 'Jefe'),
('Ausentismo', TRUE, 'Jefe'),
('Rescisión de contrato', TRUE, 'Jefe')
ON CONFLICT DO NOTHING;

-- Semillas de Solicitudes
INSERT INTO cat_tipos_solicitud (tipo_solicitud) VALUES
('Vacaciones'),
('Baja de Personal'),
('Permiso Especial'),
('Reingreso de Personal')
ON CONFLICT (tipo_solicitud) DO NOTHING;

-- Semillas de Incidencias
INSERT INTO cat_tipos_incidencia (tipo_incidencia, bloquea_asistencia, cuenta_como_descanso) VALUES
('Falta Injustificada', TRUE, FALSE),
('Incapacidad', TRUE, FALSE),
('Vacaciones', TRUE, TRUE),
('Permiso con Goce', TRUE, FALSE),
('Retardo', FALSE, FALSE)
ON CONFLICT (tipo_incidencia) DO NOTHING;

-- LÓGICA DE AUTOMATIZACIÓN DE VACACIONES
CREATE OR REPLACE FUNCTION public.fn_get_dias_vacaciones_lft(anios int)
RETURNS int AS $$
BEGIN
    IF anios < 1 THEN RETURN 0; END IF;
    IF anios = 1 THEN RETURN 12; END IF;
    IF anios = 2 THEN RETURN 14; END IF;
    IF anios = 3 THEN RETURN 16; END IF;
    IF anios = 4 THEN RETURN 18; END IF;
    IF anios = 5 THEN RETURN 20; END IF;
    IF anios <= 10 THEN RETURN 22; END IF;
    IF anios <= 15 THEN RETURN 24; END IF;
    IF anios <= 20 THEN RETURN 26; END IF;
    IF anios <= 25 THEN RETURN 28; END IF;
    RETURN 30;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.fn_generar_saldos_vacaciones()
RETURNS trigger AS $$
DECLARE
    emp_id uuid;
    fecha_ing date;
    anio_ing int;
    anio_actual int;
    anio_iter int;
    periodo_txt text;
    periodo_id uuid;
    dias_entitlement int;
BEGIN
    -- Determinar el ID del empleado
    IF TG_TABLE_NAME = 'empleado_ingreso' THEN
        emp_id := NEW.id_empleado;
        fecha_ing := NEW.fecha_ingreso;
    ELSE
        emp_id := NEW.id_empleado;
        fecha_ing := (SELECT fecha_ingreso FROM empleado_ingreso WHERE id_empleado = emp_id LIMIT 1);
    END IF;
    
    -- Si no hay fecha de ingreso, no hacemos nada
    IF fecha_ing IS NULL THEN RETURN NEW; END IF;

    anio_ing := EXTRACT(YEAR FROM fecha_ing);
    anio_actual := EXTRACT(YEAR FROM CURRENT_DATE);

    -- Generar periodos desde el año de ingreso hasta el año actual + 1
    FOR anio_iter IN anio_ing..anio_actual + 1 LOOP
        periodo_txt := anio_iter || ' - ' || (anio_iter + 1);
        
        -- 1. Asegurar que el periodo exista
        INSERT INTO cat_periodos_vacacionales (periodo, fecha_inicio, fecha_fin)
        VALUES (periodo_txt, (anio_iter || '-01-01')::date, ((anio_iter + 1) || '-12-31')::date)
        ON CONFLICT (periodo) DO UPDATE SET periodo = EXCLUDED.periodo
        RETURNING id_periodo INTO periodo_id;

        -- 2. Calcular días correspondientes a ese año de servicio
        dias_entitlement := fn_get_dias_vacaciones_lft(anio_iter - anio_ing + 1);

        -- 3. Insertar saldo si no existe
        INSERT INTO vacaciones_saldos (id_empleado, id_periodo, dias_asignados, dias_tomados)
        VALUES (emp_id, periodo_id, dias_entitlement, 0)
        ON CONFLICT (id_empleado, id_periodo) DO NOTHING;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para empleado_ingreso (cambios de fecha)
DROP TRIGGER IF EXISTS tr_generar_vacaciones_ingreso ON empleado_ingreso;
CREATE TRIGGER tr_generar_vacaciones_ingreso
AFTER INSERT OR UPDATE OF fecha_ingreso ON empleado_ingreso
FOR EACH ROW EXECUTE PROCEDURE public.fn_generar_saldos_vacaciones();

-- Trigger para empleados (creación)
DROP TRIGGER IF EXISTS tr_generar_vacaciones_empleado ON empleados;
CREATE TRIGGER tr_generar_vacaciones_empleado
AFTER INSERT ON empleados
FOR EACH ROW EXECUTE PROCEDURE public.fn_generar_saldos_vacaciones();

