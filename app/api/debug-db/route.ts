
import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export const dynamic = 'force-dynamic'

export async function GET() {
    try {
        const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
        const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
        const supabase = createClient(supabaseUrl, supabaseKey)

        // 1. Probar conexión y ver columnas de 'empleados'
        // 1. Probar conexión y ver lista de empleados
        const { data: sample, error: sampleError } = await supabase
            .from('empleados')
            .select('id_empleado, nombre, numero_empleado, id_turno')
            .limit(10)

        // 2. Verificar tablas de checador
        const { count: checadasCount } = await supabase.from('checadas').select('*', { count: 'exact', head: true })
        const { data: turnos } = await supabase.from('turnos').select('id, nombre').limit(5)

        return NextResponse.json({
            ok: true,
            diagnostico: {
                conexion: !!sample || !!sampleError,
                empleados_visto: !!sample,
                error_empleados: sampleError || null,
                columnas_posibles: sample ? Object.keys(sample[0] || {}) : [],
                lista_empleados: sample || [], // Se agregan los datos reales
                resumen_tablas: {
                    checadas: checadasCount,
                    turnos_ejemplo: turnos
                }
            }
        })
    } catch (e: any) {
        return NextResponse.json({ ok: false, error: e.message })
    }
}
