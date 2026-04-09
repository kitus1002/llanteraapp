-- ==========================================
-- PASO 1 DE 13 — BASE PRINCIPAL (VERSIÓN COMPLETA)
-- Nombre: SCRIPTS_NUEVA_EMPRESA.sql
-- Descripción: Tablas base (empleados, catálogos, solicitudes,
--              documentos, perfiles, roles, salarios) + RLS esencial.
-- EJECUTAR PRIMERO — todo lo demás depende de este.
-- ==========================================

-- 1. CATÁLOGOS BASE
CREATE TABLE IF NOT EXISTS cat_unidades_trabajo (
    id_unidad UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    unidad_trabajo TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_departamentos (
    id_departamento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    departamento TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_puestos (
    id_puesto UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    puesto TEXT NOT NULL,
    id_departamento UUID REFERENCES cat_departamentos(id_departamento),
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_cecos (
    id_ceco UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave_ceco TEXT NOT NULL,
    descripcion_ceco TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_tipos_rol (
    id_tipo_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_rol TEXT UNIQUE NOT NULL, -- "20x10", "14x7"
    dias_trabajo INT NOT NULL,
    dias_descanso INT NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_tipos_incidencia (
    id_tipo_incidencia UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_incidencia TEXT UNIQUE NOT NULL, -- "Vacaciones", "Incapacidad", etc.
    bloquea_asistencia BOOLEAN DEFAULT FALSE,
    requiere_evidencia BOOLEAN DEFAULT FALSE,
    cuenta_como_descanso BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_tipos_solicitud (
    id_tipo_solicitud UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tipo_solicitud TEXT UNIQUE NOT NULL, -- "Vacaciones", "Baja de Personal", etc.
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_periodos_vacacionales (
    id_periodo UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    periodo TEXT UNIQUE NOT NULL, -- "2025-2026"
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_causas_baja (
    id_causa_baja UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    causa TEXT UNIQUE NOT NULL,
    requiere_evidencia BOOLEAN DEFAULT FALSE,
    rol_iniciador TEXT DEFAULT 'Jefe',
    activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS cat_causas_baja_imss (
    id_causa_imss UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    clave TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    activo BOOLEAN DEFAULT TRUE
);

-- 2. EMPLEADOS (NÚCLEO)
CREATE TABLE IF NOT EXISTS empleados (
    id_empleado UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    numero_empleado INT UNIQUE NOT NULL,
    estado_empleado TEXT DEFAULT 'Activo', -- "Activo", "Baja"
    nombre TEXT NOT NULL,
    apellido_paterno TEXT NOT NULL,
    apellido_materno TEXT,
    sexo TEXT,
    fecha_nacimiento DATE,
    curp TEXT UNIQUE,
    rfc TEXT UNIQUE,
    nss TEXT UNIQUE,
    telefono TEXT,
    correo_electronico TEXT,
    estado_civil TEXT,
    tipo_residencia TEXT, -- "Local/Foráneo"
    hijos_numero INT DEFAULT 0,
    foto_url TEXT,
    fecha_creacion TIMESTAMPTZ DEFAULT now(),
    fecha_actualizacion TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS empleado_ingreso (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE PRIMARY KEY,
    fecha_ingreso DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS empleado_domicilio (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE PRIMARY KEY,
    calle TEXT,
    numero_exterior TEXT,
    colonia TEXT,
    codigo_postal TEXT,
    municipio TEXT,
    estado TEXT,
    ciudad TEXT
);

CREATE TABLE IF NOT EXISTS empleado_banco (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE PRIMARY KEY,
    numero_cuenta TEXT,
    clabe TEXT,
    banco TEXT
);

-- 3. HISTORIAL LABORAL
CREATE TABLE IF NOT EXISTS empleado_adscripciones (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    categoria TEXT, -- "Administrativo/Operativo"
    id_departamento UUID REFERENCES cat_departamentos(id_departamento),
    id_puesto UUID REFERENCES cat_puestos(id_puesto),
    id_unidad UUID REFERENCES cat_unidades_trabajo(id_unidad),
    id_ceco UUID REFERENCES cat_cecos(id_ceco),
    razon_social TEXT,
    jefe_directo_nombre TEXT,
    es_jefe BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (id_empleado, fecha_inicio)
);

CREATE TABLE IF NOT EXISTS empleado_salarios (
    id_empleado_salario UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_inicio_vigencia DATE NOT NULL,
    fecha_fin_vigencia DATE,
    salario_diario NUMERIC(10,2) NOT NULL,
    motivo TEXT
);

-- Asegurar relación correcta (Fix para instalaciones previas inconsistentes)
ALTER TABLE empleado_salarios DROP CONSTRAINT IF EXISTS empleado_salarios_id_empleado_fkey;
ALTER TABLE empleado_salarios ADD CONSTRAINT empleado_salarios_id_empleado_fkey 
    FOREIGN KEY (id_empleado) REFERENCES empleados(id_empleado) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS empleado_roles (
    id_empleado_rol UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    id_tipo_rol UUID REFERENCES cat_tipos_rol(id_tipo_rol)
);

-- 4. INCIDENCIAS Y VACACIONES
CREATE TABLE IF NOT EXISTS empleado_incidencias (
    id_incidencia UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE NOT NULL,
    id_tipo_incidencia UUID REFERENCES cat_tipos_incidencia(id_tipo_incidencia) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    comentarios TEXT,
    evidencia_url TEXT,
    estado TEXT DEFAULT 'Aprobada',
    creado_el TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vacaciones_saldos (
    id_empleado UUID REFERENCES empleados(id_empleado) ON DELETE CASCADE,
    id_periodo UUID REFERENCES cat_periodos_vacacionales(id_periodo),
    dias_asignados INT DEFAULT 0,
    dias_tomados INT DEFAULT 0,
    PRIMARY KEY (id_empleado, id_periodo)
);

-- 5. SOLICITUDES Y BAJAS
CREATE TABLE IF NOT EXISTS solicitudes (
    id_solicitud UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_tipo_solicitud UUID REFERENCES cat_tipos_solicitud(id_tipo_solicitud),
    id_empleado_objetivo UUID REFERENCES empleados(id_empleado),
    folio TEXT UNIQUE,
    estatus TEXT DEFAULT 'Pendiente',
    payload JSONB,
    creado_el TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS solicitud_aprobaciones (
    id_solicitud UUID REFERENCES solicitudes(id_solicitud) ON DELETE CASCADE,
    orden INT NOT NULL,
    aprobador_user_id UUID NOT NULL, 
    estatus TEXT DEFAULT 'Pendiente', -- "Pendiente", "Aprobado", "Rechazado"
    comentario TEXT,
    decidido_el TIMESTAMPTZ,
    PRIMARY KEY (id_solicitud, orden)
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

-- 6. CONFIGURACIÓN Y AUDITORÍA
CREATE TABLE IF NOT EXISTS configuracion_empresa (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre_empresa TEXT,
    rfc TEXT,
    direccion TEXT,
    registro_patronal TEXT,
    logo_base64 TEXT,
    actualizado_el TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS auditoria (
    id_evento UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, 
    accion TEXT NOT NULL,
    entidad TEXT NOT NULL,
    id_entidad UUID,
    antes JSONB,
    despues JSONB,
    fecha TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS perfiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    nombre_completo TEXT,
    rol TEXT DEFAULT 'Jefe' CHECK (rol IN ('Administrativo', 'Jefe')),
    id_departamento UUID REFERENCES cat_departamentos(id_departamento),
    creado_el TIMESTAMPTZ DEFAULT now(),
    actualizado_el TIMESTAMPTZ DEFAULT now()
);

-- 7. SEGURIDAD (RLS)
ALTER TABLE configuracion_empresa ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read" ON configuracion_empresa;
CREATE POLICY "Public Read" ON configuracion_empresa FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated All" ON configuracion_empresa;
CREATE POLICY "Authenticated All" ON configuracion_empresa FOR ALL USING (true);

ALTER TABLE solicitudes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON solicitudes;
CREATE POLICY "Authenticated All" ON solicitudes FOR ALL USING (true);

ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleados;
CREATE POLICY "Authenticated All" ON empleados FOR ALL USING (true);

ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own profile" ON perfiles;
CREATE POLICY "Users can view their own profile" ON perfiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Admins can all" ON perfiles FOR ALL USING (
    EXISTS (SELECT 1 FROM perfiles WHERE id = auth.uid() AND rol = 'Administrativo')
);

-- Tablas Relacionales Empleados (Acceso Autenticado)
ALTER TABLE empleado_ingreso ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_ingreso;
CREATE POLICY "Authenticated All" ON empleado_ingreso FOR ALL USING (true);

ALTER TABLE empleado_domicilio ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_domicilio;
CREATE POLICY "Authenticated All" ON empleado_domicilio FOR ALL USING (true);

ALTER TABLE empleado_banco ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_banco;
CREATE POLICY "Authenticated All" ON empleado_banco FOR ALL USING (true);

ALTER TABLE empleado_salarios ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_salarios;
CREATE POLICY "Authenticated All" ON empleado_salarios FOR ALL USING (true);

ALTER TABLE empleado_roles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_roles;
CREATE POLICY "Authenticated All" ON empleado_roles FOR ALL USING (true);

ALTER TABLE empleado_incidencias ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_incidencias;
CREATE POLICY "Authenticated All" ON empleado_incidencias FOR ALL USING (true);

ALTER TABLE vacaciones_saldos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON vacaciones_saldos;
CREATE POLICY "Authenticated All" ON vacaciones_saldos FOR ALL USING (true);

ALTER TABLE empleado_adscripciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON empleado_adscripciones;
CREATE POLICY "Authenticated All" ON empleado_adscripciones FOR ALL USING (true);

ALTER TABLE bajas ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON bajas;
CREATE POLICY "Authenticated All" ON bajas FOR ALL USING (true);

ALTER TABLE auditoria ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON auditoria;
CREATE POLICY "Authenticated All" ON auditoria FOR ALL USING (true);

ALTER TABLE solicitud_aprobaciones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Authenticated All" ON solicitud_aprobaciones;
CREATE POLICY "Authenticated All" ON solicitud_aprobaciones FOR ALL USING (true);

ALTER TABLE cat_periodos_vacacionales ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read" ON cat_periodos_vacacionales;
CREATE POLICY "Public Read" ON cat_periodos_vacacionales FOR SELECT USING (true);

ALTER TABLE cat_tipos_incidencia ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read" ON cat_tipos_incidencia;
CREATE POLICY "Public Read" ON cat_tipos_incidencia FOR SELECT USING (true);

ALTER TABLE cat_tipos_solicitud ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public Read" ON cat_tipos_solicitud;
CREATE POLICY "Public Read" ON cat_tipos_solicitud FOR SELECT USING (true);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.perfiles (id, nombre_completo, rol)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', 'Jefe');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 8. SEMILLAS (DATA INICIAL)
INSERT INTO cat_tipos_incidencia (tipo_incidencia, bloquea_asistencia, cuenta_como_descanso) VALUES
('Falta Injustificada', TRUE, FALSE),
('Incapacidad', TRUE, FALSE),
('Vacaciones', TRUE, TRUE),
('Permiso con Goce', TRUE, FALSE),
('Retardo', FALSE, FALSE)
ON CONFLICT (tipo_incidencia) DO NOTHING;

INSERT INTO cat_tipos_solicitud (tipo_solicitud) VALUES
('Vacaciones'),
('Baja de Personal'),
('Permiso Especial'),
('Reingreso de Personal')
ON CONFLICT (tipo_solicitud) DO NOTHING;

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

INSERT INTO cat_tipos_rol (tipo_rol, dias_trabajo, dias_descanso) VALUES
('20x10', 20, 10),
('14x7', 14, 7),
('5x2 (Oficina)', 5, 2)
ON CONFLICT DO NOTHING;

-- 10. LÓGICA DE AUTOMATIZACIÓN DE VACACIONES
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
