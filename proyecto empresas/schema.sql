-- ==========================================
-- SCRIPT DE ACTUALIZACIÓN Y MANTENIMIENTO (IDEMPOTENTE)
-- Nombre: schema.sql
-- Descripción: Asegura que todas las tablas y columnas necesarias 
--              existan sin borrar datos previos.
-- ==========================================

-- 1. CREACIÓN DE TABLAS BASE SI NO EXISTEN
-- Esto garantiza que las tablas existan antes de cualquier ALTER o RLS
CREATE TABLE IF NOT EXISTS cat_cecos (
    id_ceco UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave_ceco TEXT NOT NULL,
    descripcion_ceco TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_tipos_rol (
    id_tipo_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_rol TEXT UNIQUE NOT NULL,
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

CREATE TABLE IF NOT EXISTS turnos (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          TEXT NOT NULL,
    hora_inicio     TIME NOT NULL,
    hora_fin        TIME,
    tolerancia_min  INT DEFAULT 10,
    limite_falta_min INT NOT NULL DEFAULT 60,
    ventana_desde   TIME,
    ventana_hasta   TIME,
    bloquear_fuera_ventana BOOLEAN DEFAULT FALSE,
    aplica_dias     TEXT[] DEFAULT '{"Lunes","Martes","Miércoles","Jueves","Viernes"}',
    activo          BOOLEAN DEFAULT TRUE,
    company_id      UUID,
    creado_el       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cat_tipos_checada (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo                  TEXT NOT NULL UNIQUE,
    label                 TEXT NOT NULL,
    requiere_codigo       BOOLEAN DEFAULT FALSE,
    icono                 TEXT,
    ordinal               INT DEFAULT 0,
    tolerancia_retorno_min INT DEFAULT 5,
    activo                BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS dispositivos_checadores (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre          TEXT NOT NULL,
    device_key      TEXT UNIQUE NOT NULL,
    tipo            TEXT DEFAULT 'tablet',
    ubicacion       TEXT,
    activo          BOOLEAN DEFAULT TRUE,
    company_id      UUID,
    ultimo_ping     TIMESTAMPTZ,
    creado_el       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checadas (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado           UUID NOT NULL REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    tipo_checada          TEXT NOT NULL,
    timestamp_checada     TIMESTAMPTZ NOT NULL DEFAULT now(),
    fecha_local           DATE NOT NULL,
    estatus_puntualidad   TEXT,
    retardo_minutos       INT DEFAULT 0,
    id_permiso            UUID,
    id_dispositivo        UUID REFERENCES dispositivos_checadores(id),
    id_turno              UUID REFERENCES turnos(id),
    metodo_identificacion TEXT DEFAULT 'QR',
    company_id            UUID,
    sincronizado          BOOLEAN DEFAULT TRUE,
    origen                TEXT DEFAULT 'web',
    notas                 TEXT,
    creado_el             TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS permisos_autorizados (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo            TEXT NOT NULL UNIQUE,
    id_empleado       UUID NOT NULL REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    tipo_checada      TEXT NOT NULL,
    vigencia_desde    TIMESTAMPTZ NOT NULL,
    vigencia_hasta    TIMESTAMPTZ NOT NULL,
    usos_maximos      INT DEFAULT 1,
    usos_realizados   INT DEFAULT 0,
    estatus           TEXT DEFAULT 'Activo',
    motivo            TEXT,
    company_id        UUID,
    creado_por        UUID,
    usado_en          TIMESTAMPTZ,
    usado_en_device   UUID REFERENCES dispositivos_checadores(id),
    cancelado_por     UUID,
    cancelado_el      TIMESTAMPTZ,
    creado_el         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auditoria_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id      UUID,
    accion          TEXT NOT NULL,
    entidad         TEXT NOT NULL,
    entidad_id      TEXT,
    datos_antes     JSONB,
    datos_despues   JSONB,
    company_id      UUID,
    ip_address      TEXT,
    creado_el       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cat_festivos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre TEXT NOT NULL,
    descripcion TEXT,
    fecha DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE,
    creado_el TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS config_descansos_globales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    fecha DATE NOT NULL UNIQUE,
    motivo TEXT,
    creado_el TIMESTAMPTZ DEFAULT now()
);

-- 2. ASEGURAR NUEVAS COLUMNAS Y REPARAR RELACIONES
DO $$ 
BEGIN
    -- cat_causas_baja
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_causas_baja') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_causas_baja' AND column_name='requiere_evidencia') THEN
            ALTER TABLE cat_causas_baja ADD COLUMN requiere_evidencia BOOLEAN DEFAULT FALSE;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='cat_causas_baja' AND column_name='rol_iniciador') THEN
            ALTER TABLE cat_causas_baja ADD COLUMN rol_iniciador TEXT DEFAULT 'Jefe';
        END IF;
    END IF;

    -- empleados
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleados') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='estado_civil') THEN
            ALTER TABLE empleados ADD COLUMN estado_civil TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='tipo_residencia') THEN
            ALTER TABLE empleados ADD COLUMN tipo_residencia TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='hijos_numero') THEN
            ALTER TABLE empleados ADD COLUMN hijos_numero INT DEFAULT 0;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='qr_token') THEN
            ALTER TABLE empleados ADD COLUMN qr_token TEXT UNIQUE DEFAULT gen_random_uuid()::TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='id_turno') THEN
            ALTER TABLE empleados ADD COLUMN id_turno UUID REFERENCES turnos(id) ON DELETE SET NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleados' AND column_name='fecha_actualizacion') THEN
            ALTER TABLE empleados ADD COLUMN fecha_actualizacion TIMESTAMPTZ DEFAULT now();
        END IF;
    END IF;

    -- empleado_adscripciones
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_adscripciones') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='empleado_adscripciones' AND column_name='es_jefe') THEN
            ALTER TABLE empleado_adscripciones ADD COLUMN es_jefe BOOLEAN DEFAULT FALSE;
        END IF;
    END IF;



    -- Reparar relación de empleado_salarios (Basado en el error reportado)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_salarios') THEN
        ALTER TABLE empleado_salarios DROP CONSTRAINT IF EXISTS empleado_salarios_id_empleado_fkey;
        ALTER TABLE empleado_salarios ADD CONSTRAINT empleado_salarios_id_empleado_fkey 
            FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado) ON DELETE CASCADE;
    END IF;

    -- Catálogos: Limpiar duplicados y asegurar UNIQUE
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_solicitud') THEN
        DELETE FROM cat_tipos_solicitud a USING cat_tipos_solicitud b WHERE a.ctid > b.ctid AND a.tipo_solicitud = b.tipo_solicitud;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_tipos_solicitud_tipo_solicitud_key') THEN
            ALTER TABLE cat_tipos_solicitud ADD CONSTRAINT cat_tipos_solicitud_tipo_solicitud_key UNIQUE (tipo_solicitud);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_incidencia') THEN
        DELETE FROM cat_tipos_incidencia a USING cat_tipos_incidencia b WHERE a.ctid > b.ctid AND a.tipo_incidencia = b.tipo_incidencia;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_tipos_incidencia_tipo_incidencia_key') THEN
            ALTER TABLE cat_tipos_incidencia ADD CONSTRAINT cat_tipos_incidencia_tipo_incidencia_key UNIQUE (tipo_incidencia);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_rol') THEN
        DELETE FROM cat_tipos_rol a USING cat_tipos_rol b WHERE a.id_tipo_rol > b.id_tipo_rol AND a.tipo_rol = b.tipo_rol;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_tipos_rol_tipo_rol_key') THEN
            ALTER TABLE cat_tipos_rol ADD CONSTRAINT cat_tipos_rol_tipo_rol_key UNIQUE (tipo_rol);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_causas_baja') THEN
        DELETE FROM cat_causas_baja a USING cat_causas_baja b WHERE a.id_causa_baja > b.id_causa_baja AND a.causa = b.causa;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_causas_baja_causa_key') THEN
            ALTER TABLE cat_causas_baja ADD CONSTRAINT cat_causas_baja_causa_key UNIQUE (causa);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_periodos_vacacionales') THEN
        DELETE FROM cat_periodos_vacacionales a USING cat_periodos_vacacionales b WHERE a.id_periodo > b.id_periodo AND a.periodo = b.periodo;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cat_periodos_vacacionales_periodo_key') THEN
            ALTER TABLE cat_periodos_vacacionales ADD CONSTRAINT cat_periodos_vacacionales_periodo_key UNIQUE (periodo);
        END IF;
    END IF;

    -- Habilitar RLS de forma segura
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_domicilio') THEN EXECUTE 'ALTER TABLE empleado_domicilio ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_ingreso') THEN EXECUTE 'ALTER TABLE empleado_ingreso ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_banco') THEN EXECUTE 'ALTER TABLE empleado_banco ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_salarios') THEN EXECUTE 'ALTER TABLE empleado_salarios ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_roles') THEN EXECUTE 'ALTER TABLE empleado_roles ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_incidencias') THEN EXECUTE 'ALTER TABLE empleado_incidencias ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='vacaciones_saldos') THEN EXECUTE 'ALTER TABLE vacaciones_saldos ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_adscripciones') THEN EXECUTE 'ALTER TABLE empleado_adscripciones ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='bajas') THEN EXECUTE 'ALTER TABLE bajas ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='auditoria') THEN EXECUTE 'ALTER TABLE auditoria ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='solicitud_aprobaciones') THEN EXECUTE 'ALTER TABLE solicitud_aprobaciones ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_periodos_vacacionales') THEN EXECUTE 'ALTER TABLE cat_periodos_vacacionales ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_incidencia') THEN EXECUTE 'ALTER TABLE cat_tipos_incidencia ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_solicitud') THEN EXECUTE 'ALTER TABLE cat_tipos_solicitud ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='turnos') THEN EXECUTE 'ALTER TABLE turnos ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='checadas') THEN EXECUTE 'ALTER TABLE checadas ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_checada') THEN EXECUTE 'ALTER TABLE cat_tipos_checada ENABLE ROW LEVEL SECURITY'; END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleados') THEN EXECUTE 'ALTER TABLE empleados ENABLE ROW LEVEL SECURITY'; END IF;
END $$;

-- 3. POLÍTICAS DE ACCESO
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_domicilio') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_domicilio' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_domicilio FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_ingreso') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_ingreso' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_ingreso FOR ALL USING (true);
        END IF;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_banco') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_banco' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_banco FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_salarios') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_salarios' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_salarios FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_roles') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_roles' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_roles FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_incidencias') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_incidencias' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_incidencias FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='vacaciones_saldos') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vacaciones_saldos' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON vacaciones_saldos FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleado_adscripciones') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleado_adscripciones' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleado_adscripciones FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='bajas') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bajas' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON bajas FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='auditoria') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'auditoria' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON auditoria FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='solicitud_aprobaciones') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'solicitud_aprobaciones' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON solicitud_aprobaciones FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_periodos_vacacionales') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_periodos_vacacionales' AND policyname = 'Public Read') THEN
            CREATE POLICY "Public Read" ON cat_periodos_vacacionales FOR SELECT USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='permisos_autorizados') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permisos_autorizados' AND policyname = 'Permitir select permisos') THEN
            CREATE POLICY "Permitir select permisos" ON permisos_autorizados FOR SELECT USING (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permisos_autorizados' AND policyname = 'Permitir update permisos') THEN
            CREATE POLICY "Permitir update permisos" ON permisos_autorizados FOR UPDATE USING (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permisos_autorizados' AND policyname = 'Permitir insert permisos') THEN
            CREATE POLICY "Permitir insert permisos" ON permisos_autorizados FOR INSERT WITH CHECK (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'permisos_autorizados' AND policyname = 'Permitir delete permisos') THEN
            CREATE POLICY "Permitir delete permisos" ON permisos_autorizados FOR DELETE USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_incidencia') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_tipos_incidencia' AND policyname = 'Public Read') THEN
            CREATE POLICY "Public Read" ON cat_tipos_incidencia FOR SELECT USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_solicitud') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_tipos_solicitud' AND policyname = 'Public Read') THEN
            CREATE POLICY "Public Read" ON cat_tipos_solicitud FOR SELECT USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='turnos') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'turnos' AND policyname = 'Public Read') THEN
            CREATE POLICY "Public Read" ON turnos FOR SELECT USING (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'turnos' AND policyname = 'Permitir insert turnos') THEN
            CREATE POLICY "Permitir insert turnos" ON turnos FOR INSERT WITH CHECK (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'turnos' AND policyname = 'Permitir update turnos') THEN
            CREATE POLICY "Permitir update turnos" ON turnos FOR UPDATE USING (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'turnos' AND policyname = 'Permitir delete turnos') THEN
            CREATE POLICY "Permitir delete turnos" ON turnos FOR DELETE USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_tipos_checada') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_tipos_checada' AND policyname = 'Public Read') THEN
            CREATE POLICY "Public Read" ON cat_tipos_checada FOR SELECT USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='checadas') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'checadas' AND policyname = 'Authenticated Insert') THEN
            CREATE POLICY "Authenticated Insert" ON checadas FOR INSERT WITH CHECK (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'checadas' AND policyname = 'Authenticated Select') THEN
            CREATE POLICY "Authenticated Select" ON checadas FOR SELECT USING (true);
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'checadas' AND policyname = 'Permitir update a todos checadas') THEN
            CREATE POLICY "Permitir update a todos checadas" ON checadas FOR UPDATE USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='empleados') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'empleados' AND policyname = 'Authenticated All') THEN
            CREATE POLICY "Authenticated All" ON empleados FOR ALL USING (true);
        END IF;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='cat_festivos') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cat_festivos' AND policyname = 'Authenticated All festivos') THEN
            CREATE POLICY "Authenticated All festivos" ON cat_festivos FOR ALL USING (true);
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='config_descansos_globales') THEN
        IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'config_descansos_globales' AND policyname = 'Authenticated All descansos') THEN
            CREATE POLICY "Authenticated All descansos" ON config_descansos_globales FOR ALL USING (true);
        END IF;
    END IF;
END $$;

-- 4. SEMILLAS (Datos faltantes)
INSERT INTO cat_tipos_rol (tipo_rol, dias_trabajo, dias_descanso) VALUES
('20x10', 20, 10),
('14x7', 14, 7),
('5x2 (Oficina)', 5, 2)
ON CONFLICT (tipo_rol) DO NOTHING;

INSERT INTO cat_causas_baja (causa, requiere_evidencia, rol_iniciador) VALUES 
('Término de contrato', FALSE, 'Sistema'),
('Separación voluntaria (renuncia)', FALSE, 'Empleado'),
('Abandono de empleo', TRUE, 'Jefe'),
('Defunción', FALSE, 'RH'),
('Clausura', FALSE, 'Directiva'),
('Otra', TRUE, 'Jefe'),
('Ausentismo', TRUE, 'Jefe'),
('Rescisión de contrato', TRUE, 'Jefe')
ON CONFLICT (causa) DO NOTHING;

INSERT INTO cat_tipos_solicitud (tipo_solicitud) VALUES
('Vacaciones'), ('Baja de Personal'), ('Permiso Especial'), ('Reingreso de Personal')
ON CONFLICT (tipo_solicitud) DO NOTHING;

INSERT INTO cat_tipos_incidencia (tipo_incidencia, bloquea_asistencia, cuenta_como_descanso) VALUES
('Falta Injustificada', TRUE, FALSE),
('Incapacidad', TRUE, FALSE),
('Vacaciones', TRUE, TRUE),
('Permiso con Goce', TRUE, FALSE),
('Retardo', FALSE, FALSE)
ON CONFLICT (tipo_incidencia) DO NOTHING;

-- TIPOS DE CHECADA
INSERT INTO cat_tipos_checada (tipo, label, requiere_codigo, color, ordinal, tolerancia_retorno_min) 
VALUES
  ('ENTRADA', 'ENTRADA', false, 'bg-green-600', 1, 0),
  ('SALIDA', 'SALIDA', false, 'bg-red-600', 2, 0),
  ('COMIDA_SALIDA', 'COMIDA – SALIDA', false, 'bg-amber-500', 3, 0),
  ('COMIDA_REGRESO', 'COMIDA – REGRESO', false, 'bg-amber-600', 4, 0),
  ('PERMISO_PERSONAL', 'PERMISO PERSONAL', true, 'bg-blue-600', 5, 5),
  ('SALIDA_OPERACIONES', 'SALIDA OPERACIONES', true, 'bg-indigo-600', 6, 5),
  ('REGRESO_PERMISO_PERSONAL', 'PERMISO REGRESO', false, 'bg-blue-500', 7, 0),
  ('REGRESO_OPERACIONES', 'OP. REGRESO', false, 'bg-indigo-500', 8, 0)
ON CONFLICT (tipo) DO UPDATE 
SET requiere_codigo = EXCLUDED.requiere_codigo, label = EXCLUDED.label, tolerancia_retorno_min = EXCLUDED.tolerancia_retorno_min;

-- 5. LÓGICA DE AUTOMATIZACIÓN DE VACACIONES
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
    IF TG_TABLE_NAME = 'empleado_ingreso' THEN
        emp_id := NEW.id_empleado;
        fecha_ing := NEW.fecha_ingreso;
    ELSE
        emp_id := NEW.id_empleado;
        fecha_ing := (SELECT fecha_ingreso FROM empleado_ingreso WHERE id_empleado = emp_id LIMIT 1);
    END IF;
    
    IF fecha_ing IS NULL THEN RETURN NEW; END IF;

    anio_ing := EXTRACT(YEAR FROM fecha_ing);
    anio_actual := EXTRACT(YEAR FROM CURRENT_DATE);

    FOR anio_iter IN anio_ing..anio_actual + 1 LOOP
        periodo_txt := anio_iter || ' - ' || (anio_iter + 1);
        
        INSERT INTO cat_periodos_vacacionales (periodo, fecha_inicio, fecha_fin)
        VALUES (periodo_txt, (anio_iter || '-01-01')::date, ((anio_iter + 1) || '-12-31')::date)
        ON CONFLICT (periodo) DO UPDATE SET periodo = EXCLUDED.periodo
        RETURNING id_periodo INTO periodo_id;

        dias_entitlement := fn_get_dias_vacaciones_lft(anio_iter - anio_ing + 1);

        INSERT INTO vacaciones_saldos (id_empleado, id_periodo, dias_asignados, dias_tomados)
        VALUES (emp_id, periodo_id, dias_entitlement, 0)
        ON CONFLICT (id_empleado, id_periodo) DO NOTHING;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
DROP TRIGGER IF EXISTS tr_generar_vacaciones_ingreso ON empleado_ingreso;
CREATE TRIGGER tr_generar_vacaciones_ingreso
AFTER INSERT OR UPDATE OF fecha_ingreso ON empleado_ingreso
FOR EACH ROW EXECUTE PROCEDURE public.fn_generar_saldos_vacaciones();

DROP TRIGGER IF EXISTS tr_generar_vacaciones_empleado ON empleados;
CREATE TRIGGER tr_generar_vacaciones_empleado
AFTER INSERT ON empleados
FOR EACH ROW EXECUTE PROCEDURE public.fn_generar_saldos_vacaciones();
-- 11. HELPERS DE CÁLCULO LEGAL (LFT)
CREATE OR REPLACE FUNCTION public.fn_get_overtime_lft(p_weekly_total NUMERIC)
RETURNS TABLE (dobles NUMERIC, triples NUMERIC) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        LEAST(9, p_weekly_total) as dobles,
        GREATEST(0, p_weekly_total - 9) as triples;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
