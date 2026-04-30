-- Create Perfiles table
CREATE TABLE IF NOT EXISTS perfiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo TEXT,
    rol TEXT DEFAULT 'Jefe', -- 'Administrativo', 'Jefe'
    id_departamento UUID REFERENCES cat_departamentos(id_departamento),
    creado_el TIMESTAMPTZ DEFAULT now(),
    actualizado_el TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS just in case (optional, but good practice)
ALTER TABLE perfiles ENABLE ROW LEVEL SECURITY;

-- Create policy to allow full access for now (adjust as needed for security)
DROP POLICY IF EXISTS "Public profiles access" ON perfiles;
CREATE POLICY "Public profiles access" ON perfiles FOR ALL USING (true);
