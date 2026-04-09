
const { createClient } = require('@supabase/supabase-js')
require('dotenv').config({ path: '.env.local' })

async function audit() {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    const supabase = createClient(url, key)

    console.log('--- AUDITORÍA DE EMPLEADOS Y TURNOS ---')
    
    // 1. Ver empleados con sus números y si tienen id_turno
    const { data: empleados, error: empError } = await supabase
        .from('empleados')
        .select('nombre, apellido_paterno, numero_empleado, id_turno, estado_empleado')
        .limit(10)

    if (empError) {
        console.log('Error al leer empleados:', empError.message)
        return
    }

    console.log('Total empleados encontrados:', empleados.length)
    empleados.forEach(e => {
        console.log(`- [${e.numero_empleado}] ${e.nombre} ${e.apellido_paterno} | Turno ID: ${e.id_turno || 'SIN ASIGNAR'} | Estatus: ${e.estado_empleado}`)
    })

    // 2. Ver turnos disponibles
    console.log('\n--- CATÁLOGO DE TURNOS ---')
    const { data: turnos, error: turnError } = await supabase
        .from('turnos')
        .select('*')

    if (turnError) {
        console.log('Error al leer turnos:', turnError.message)
    } else {
        turnos.forEach(t => {
            console.log(`- [${t.id}] ${t.nombre} (${t.hora_inicio} - ${t.hora_fin})`)
        })
    }
}

audit()
