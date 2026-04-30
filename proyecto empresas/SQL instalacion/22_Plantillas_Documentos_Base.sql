-- =========================================================================
-- PASO 12-B DE 13 — TABLA DE PLANTILLAS DE DOCUMENTOS (Base)
-- Nombre: 20260202_create_templates.sql
-- Descripción: Crea la tabla document_templates con su RLS.
--              Base del módulo de Documentos.
--              Requiere: PASO 1 ejecutado primero.
-- =========================================================================

-- Create table for document templates
create table if not exists document_templates (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  name text not null,
  type text not null, -- 'contrato', 'constancia', 'carta', etc.
  content jsonb, -- JSON content from Tiptap or HTML string
  margins jsonb default '{"top": 2.5, "right": 2.5, "bottom": 2.5, "left": 2.5}'::jsonb -- Margins in cm
);

-- Enable RLS
alter table document_templates enable row level security;

-- Create policy to allow all access (since it's an internal tool for now, can be refined later)
DROP POLICY IF EXISTS "Enable all access for authenticated users" on document_templates;
create policy "Enable all access for authenticated users" on document_templates
  for all using (true) with check (true);
