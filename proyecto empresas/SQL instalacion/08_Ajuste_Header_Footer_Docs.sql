-- =========================================================================
-- PASO 12-D DE 13 — COLUMNAS HEADER/FOOTER EN PLANTILLAS
-- Nombre: 20260202_add_header_footer.sql
-- Descripción: Agrega header_content y footer_content (JSONB) a document_templates.
--              Necesarias para el encabezado y pie de página de documentos.
--              Requiere: PASO 12-B ejecutado primero.
-- =========================================================================

alter table document_templates 
add column if not exists header_content jsonb,
add column if not exists footer_content jsonb;
