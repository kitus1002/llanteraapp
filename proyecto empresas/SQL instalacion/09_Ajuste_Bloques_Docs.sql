-- =========================================================================
-- PASO 12-C DE 13 — COLUMNA BLOCKS EN PLANTILLAS DE DOCUMENTOS
-- Nombre: 20260202_add_blocks_column.sql
-- Descripción: Agrega la columna blocks (JSONB) a document_templates.
--              Necesaria para el editor de bloques de documentos.
--              Requiere: PASO 12-B ejecutado primero.
-- =========================================================================

alter table document_templates
add column if not exists blocks jsonb default '[]'::jsonb;
