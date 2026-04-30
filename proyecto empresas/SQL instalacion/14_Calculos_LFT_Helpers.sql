-- ==========================================
-- SQL HELPERS: CÁLCULO DE HORAS EXTRA LFT
-- ==========================================

/**
 * Función: fn_get_overtime_lft
 * Calcula la división de horas dobles y triples según la LFT
 * basada en un acumulado semanal de 9 horas.
 */
CREATE OR REPLACE FUNCTION public.fn_get_overtime_lft(p_weekly_total NUMERIC)
RETURNS TABLE (dobles NUMERIC, triples NUMERIC) AS $$
BEGIN
    RETURN QUERY 
    SELECT 
        LEAST(9, p_weekly_total) as dobles,
        GREATEST(0, p_weekly_total - 9) as triples;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

/**
 * Ejemplo de uso en una consulta compleja:
 * SELECT 
 *   id_empleado,
 *   DATE_TRUNC('week', fecha_local) as semana,
 *   SUM(horas_extra_dia) as total_semanal,
 *   (public.fn_get_overtime_lft(SUM(horas_extra_dia))).dobles,
 *   (public.fn_get_overtime_lft(SUM(horas_extra_dia))).triples
 * FROM su_tabla_de_asistencia
 * GROUP BY 1, 2;
 */
