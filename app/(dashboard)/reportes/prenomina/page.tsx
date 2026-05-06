'use client'

import { useState, useEffect } from 'react'
import { supabase } from '@/utils/supabase/client'
import { FileDown, Search, Building, Calendar, CheckCircle, AlertTriangle, XCircle, Clock, Sparkles, X } from 'lucide-react'
import * as XLSX from 'xlsx'
import { eachDayOfInterval, format, parseISO, differenceInCalendarDays, differenceInYears, isBefore, startOfDay, startOfWeek } from 'date-fns'
import PrenominaEmployeeModal from '@/components/PrenominaEmployeeModal'
import { calculateSDI } from '@/utils/sdiLogic'
import { calculateDailyStatus } from '@/utils/rosterLogic'
import GeminiAssistant from '@/components/GeminiAssistant'

// ── Helpers de cálculo ────────────────────────────────────────────────────────

function calcAttendance(
    startDate: string,
    endDate: string,
    activeRole: any,
    checadas: any[],
    incidencias: any[],
    descansosGlobales: string[] = [],
    festivos: string[] = [], // ['YYYY-MM-DD', ...]
    fechaIngreso?: string,
    turnosDic: Record<string, any> = {}
) {
    const days = eachDayOfInterval({ start: parseISO(startDate), end: parseISO(endDate) })

    let asistencias = 0, retardos = 0, faltas = 0, diasTrabajoProgramados = 0, descansos = 0
    let asistenciasDomingo = 0, diasVacaciones = 0
    let suspensiones = 0, permisosGoce = 0, permisosSinGoce = 0, incapacidades = 0
    let horasExtraTotales = 0, horasExtraDobles = 0, horasExtraTriples = 0
    let diasFestivosTrabajados = 0
    const alerts: string[] = []
    const dailyBreakdown: any[] = []
    const incapacidadesList: string[] = []

    // Anniversary detection
    let esAniversario = false
    let yearsOfService = 0
    if (fechaIngreso) {
        // Use local parts to avoid TZ shifts if string is "YYYY-MM-DD"
        const ingDate = parseISO(fechaIngreso)
        const dayIng = ingDate.getUTCDate()
        const monthIng = ingDate.getUTCMonth()
        
        // Initial years based on end date
        yearsOfService = differenceInYears(parseISO(endDate), ingDate)

        for (const day of days) {
            // Check anniversary on this specific day
            if (day.getUTCDate() === dayIng && day.getUTCMonth() === monthIng) {
                esAniversario = true
                yearsOfService = differenceInYears(day, ingDate)
                break
            }
        }
    }

    for (const day of days) {
        const stats = calculateDailyStatus(day, activeRole, incidencias, checadas, descansosGlobales, festivos)
        const s = stats.status
        const dayOfWeek = day.getDay() // 0 = Sunday

        if (s === 'Asistencia' || s === 'Retardo') {
            asistencias++
            if (s === 'Retardo') retardos++
            if (dayOfWeek === 0) asistenciasDomingo++
        } else if (s === 'Falta') {
            faltas++
        } else if (s === 'Descanso') {
            descansos++
        } else if (s === 'Suspensión') {
            suspensiones++
        } else if (s === 'Permiso Con Goce') {
            permisosGoce++
        } else if (s === 'Permiso Sin Goce') {
            permisosSinGoce++
        } else if (s === 'Incapacidad') {
            incapacidades++
            const type = stats.details?.replace('Incidencia: ', '') || 'Incapacidad'
            if (!incapacidadesList.includes(type)) incapacidadesList.push(type)
        } else if (s === 'Vacaciones' || s === 'Incidencia') {
            const lowerDetails = stats.details?.toLowerCase() || ''
            if (s === 'Vacaciones' || lowerDetails.includes('vacaciones')) {
                diasVacaciones++
            }
        }

        const dayStr = format(day, 'yyyy-MM-dd')
        const esFestivo = (festivos || []).some(f => {
            if (!f) return false
            const fStr = typeof f === 'string' && f.includes('T') ? f.split('T')[0] : f
            return fStr === dayStr
        })

        if (esFestivo && (s === 'Asistencia' || s === 'Retardo')) {
            diasFestivosTrabajados++
        }

        // --- CÁLCULO DE HORAS EXTRA (Basado en Turno) ---
        let dailyExtraHrs = 0
        let assumedOut = false

        // --- CÁLCULO DE HORAS EXTRA Y ASIMILACIÓN DE SALIDA ---
        if ((s === 'Asistencia' || s === 'Retardo' || s === 'Laborando') && activeRole) {
            // Asegurar que las checadas estén ordenadas por tiempo
            const empChecadas = [...(checadas || [])].sort((a, b) => new Date(a.timestamp_checada).getTime() - new Date(b.timestamp_checada).getTime())
            const dayChecadas = empChecadas.filter(c => c.fecha_local === dayStr)

            const entTypes = ['ENTRADA', 'COMIDA_REGRESO', 'REGRESO_PERMISO_PERSONAL', 'REGRESO_OPERACIONES']
            const salTypes = ['SALIDA', 'COMIDA_SALIDA', 'PERMISO_PERSONAL', 'SALIDA_OPERACIONES']

            // Tomar la PRIMERA entrada del día
            const ent = dayChecadas.find(c => entTypes.includes(c.tipo_checada))

            if (ent) {
                const entReal = new Date(ent.timestamp_checada)
                const turnoId = ent.id_turno || activeRole.cat_tipos_rol?.id_tipo_rol || activeRole.id_turno
                
                // Buscador robusto de Turnos
                const turno = turnosDic[turnoId] || Object.values(turnosDic).find(t => 
                    String(t.id).toLowerCase() === String(turnoId).toLowerCase() || 
                    String(t.nombre).toLowerCase() === String(turnoId).toLowerCase()
                )

                // Buscar la salida que corresponda a este turno (dentro de una ventana de 18 horas)
                const entTimeNum = entReal.getTime()
                const possibleExits = empChecadas.filter(c => 
                    salTypes.includes(c.tipo_checada) && 
                    new Date(c.timestamp_checada).getTime() > entTimeNum &&
                    (new Date(c.timestamp_checada).getTime() - entTimeNum) < 18 * 60 * 60 * 1000
                )
                let sal = possibleExits.length > 0 ? possibleExits[possibleExits.length - 1] : null

                if (turno && turno.hora_fin) {
                    // LÓGICA DE HORARIO MIXTO: Detectar si el día de hoy es especial para el turno
                    const dayOfWeekFormatter = new Intl.DateTimeFormat('es-MX', { weekday: 'long' })
                    const rawDia = dayOfWeekFormatter.format(day)
                    const diaSemana = rawDia.charAt(0).toUpperCase() + rawDia.slice(1).toLowerCase()
                    const esDiaEspecial = turno?.dias_especiales?.includes(diaSemana)

                    const [hNom, mNom] = ((esDiaEspecial && turno.hora_fin_especial) ? turno.hora_fin_especial : (turno.hora_fin || '17:00')).split(':').map(Number)
                    const totalMinutosTurno = (hNom * 60) + mNom
                    
                    const [hIni, mIni] = ((esDiaEspecial && turno.hora_inicio_especial) ? turno.hora_inicio_especial : (turno.hora_inicio || '08:00')).split(':').map(Number)
                    const totalMinutosTurnoInicio = (hIni * 60) + mIni
                    const esNocturno = totalMinutosTurno < totalMinutosTurnoInicio

                    if (sal && sal.timestamp_checada) {
                        const salReal = new Date(sal.timestamp_checada)
                        const salH = salReal.getHours()
                        const salM = salReal.getMinutes()
                        let totalMinutosSalida = (salH * 60) + salM

                        const salDayStr = format(salReal, 'yyyy-MM-dd')
                        if (salDayStr !== dayStr) {
                            totalMinutosSalida += 1440
                        }

                        let targetMin = totalMinutosTurno
                        if (esNocturno) targetMin += 1440

                        const extraMin = Math.max(0, totalMinutosSalida - targetMin)
                        if (extraMin >= 15) {
                            dailyExtraHrs = extraMin / 60
                            horasExtraTotales += dailyExtraHrs
                        }
                    } else {
                        assumedOut = true
                    }
                } else if (sal) {
                    const salReal = new Date(sal.timestamp_checada)
                    const diffHrs = (salReal.getTime() - entReal.getTime()) / (1000 * 60 * 60)
                    if (diffHrs > 9) {
                        const turnoNom = turno?.nombre || turnoId || 'Sin Nombre'
                        const msg = `⚠️ CONFIGURAR HORARIO (${turnoNom})`
                        if (!alerts.includes(msg)) alerts.push(msg)
                    }
                }
            }
        }

        const isRest = s === 'Descanso' || stats.details?.toLowerCase().includes('descanso')
        const isWorkable = s !== 'Sin Rol' && s !== 'Previo a inicio de rol' && !isRest
        if (isWorkable) {
            diasTrabajoProgramados++
        }

        if (stats.details?.includes('Choque') || stats.details?.includes('Omisión')) {
            alerts.push(stats.details)
        }

        dailyBreakdown.push({
            fecha: format(day, 'yyyy-MM-dd'),
            estatus: s,
            detalle: stats.details,
            label: stats.label,
            extraHrs: dailyExtraHrs,
            assumedOut
        })
    }

    // Pass 2: Missing clockings (Alertas solo si son realmente necesarias o deseadas)
    for (const day of days) {
        const dayStr = format(day, 'yyyy-MM-dd')
        const entrada = checadas.find(c => c.fecha_local === dayStr && c.tipo_checada === 'ENTRADA')
        const salida = checadas.find(c => c.fecha_local === dayStr && c.tipo_checada === 'SALIDA')

        // Si el usuario prefiere asimilar, podríamos comentar esta alerta o dejarla como info
        if (entrada && !salida) {
            // alerts.push(`Omisión de checada de SALIDA el ${format(day, 'dd/MM')}`)
        }
    }

    if (!activeRole) {
        alerts.push("Sin Rol / Turno asignado")
    }

    // --- LÓGICA LFT: 9 HORAS DOBLES POR SEMANA ---
    const extraHoursByWeek: Record<string, number> = {}

    dailyBreakdown.forEach(day => {
        if (day.extraHrs > 0) {
            // Agrupamos por el inicio de la semana (Lunes)
            const weekKey = format(startOfWeek(parseISO(day.fecha), { weekStartsOn: 1 }), 'yyyy-MM-dd')
            extraHoursByWeek[weekKey] = (extraHoursByWeek[weekKey] || 0) + day.extraHrs
        }
    })

    horasExtraDobles = 0
    horasExtraTriples = 0
    Object.values(extraHoursByWeek).forEach(weeklyTotal => {
        const dobles = Math.min(9, weeklyTotal)
        const triples = Math.max(0, weeklyTotal - 9)
        horasExtraDobles += dobles
        horasExtraTriples += triples
    })

    return {
        asistencias, retardos, faltas, diasTrabajoProgramados, descansos,
        asistenciasDomingo, diasVacaciones, suspensiones,
        permisosGoce, permisosSinGoce, incapacidades,
        esAniversario, yearsOfService, alerts, dailyBreakdown,
        incapacidadesList,
        horasExtraTotales, horasExtraDobles, horasExtraTriples,
        diasFestivosTrabajados
    }
}

// ─────────────────────────────────────────────────────────────────────────────

export default function PrenominaPage() {
    const [loading, setLoading] = useState(false)
    const [startDate, setStartDate] = useState(format(new Date(), 'yyyy-MM-dd'))
    const [endDate, setEndDate] = useState(format(new Date(), 'yyyy-MM-dd'))
    const [reportData, setReportData] = useState<any[]>([])
    const [incidentTypes, setIncidentTypes] = useState<any[]>([])
    const [departments, setDepartments] = useState<any[]>([])
    const [selectedDept, setSelectedDept] = useState('all')
    const [search, setSearch] = useState('')
    const [selectedEmployee, setSelectedEmployee] = useState<any | null>(null)
    const [descansosGlobales, setDescansosGlobales] = useState<string[]>([])
    const [calculateOvertime, setCalculateOvertime] = useState(true)

    useEffect(() => { fetchMetadata() }, [])

    async function fetchMetadata() {
        const { data: types } = await supabase.from('cat_tipos_incidencia').select('*').eq('activo', true).order('tipo_incidencia')
        const { data: depts } = await supabase.from('cat_departamentos').select('*').eq('activo', true).order('departamento')
        const filteredTypes = (types || []).filter(t =>
            !t.tipo_incidencia.toLowerCase().includes('falta') &&
            !t.tipo_incidencia.toLowerCase().includes('descanso')
        )
        setIncidentTypes(filteredTypes)
        setDepartments(depts || [])
    }

    async function generateReport() {
        setLoading(true)
        console.log("Pre-Nomina: Generating report for period", startDate, "to", endDate)

        try {
            const { data: empsRaw, error: empsErr } = await supabase
                .from('empleados')
                .select('id_empleado, numero_empleado, nombre, apellido_paterno, apellido_materno, id_turno, paga_horas_extra')
                .eq('estado_empleado', 'Activo')
                .order('apellido_paterno')

            if (empsErr) throw empsErr
            if (!empsRaw) { setLoading(false); return }

            const empIds = empsRaw.map(e => e.id_empleado)

            const { data: turns } = await supabase.from('turnos').select('*').eq('activo', true)
            const turnosDic: Record<string, any> = {}
            turns?.forEach(t => { turnosDic[t.id] = t })

            const { data: rolesRaw } = await supabase
                .from('empleado_roles')
                .select('id_empleado, fecha_inicio, cat_tipos_rol(id_tipo_rol, tipo_rol, dias_trabajo, dias_descanso)')
                .in('id_empleado', empIds)
                .order('fecha_inicio', { ascending: false })

            const { data: incidenciasRaw } = await supabase
                .from('empleado_incidencias')
                .select('id_empleado, id_tipo_incidencia, fecha_inicio, fecha_fin, estado, cat_tipos_incidencia(tipo_incidencia)')
                .in('id_empleado', empIds)
                .eq('estado', 'Aprobada')
                .lte('fecha_inicio', endDate)
                .gte('fecha_fin', startDate)

            const incidencias = (incidenciasRaw || []).map(inc => {
                const tipoInc = Array.isArray(inc.cat_tipos_incidencia) ? inc.cat_tipos_incidencia[0] : inc.cat_tipos_incidencia
                return { ...inc, tipo_incidencia: tipoInc?.tipo_incidencia || 'Incidencia' }
            })

            const { data: checadasRaw } = await supabase
                .from('checadas')
                .select('id_empleado, fecha_local, tipo_checada, estatus_puntualidad, timestamp_checada')
                .in('id_empleado', empIds)
                .gte('fecha_local', startDate)
                .lte('fecha_local', format(new Date(new Date(endDate).getTime() + 24 * 60 * 60 * 1000), 'yyyy-MM-dd'))

            const { data: festRaw } = await supabase
                .from('cat_festivos')
                .select('fecha')
                .gte('fecha', startDate)
                .lte('fecha', endDate)
                .eq('activo', true)
            const festivosDates = festRaw?.map(f => f.fecha) || []

            const { data: descRaw } = await supabase
                .from('config_descansos_globales')
                .select('fecha')
                .gte('fecha', startDate)
                .lte('fecha', endDate)
            const dGlobals = descRaw?.map(d => d.fecha) || []
            setDescansosGlobales(dGlobals)

            const checadasPorEmp: Record<string, any[]> = {}
            for (const c of (checadasRaw || [])) {
                if (!checadasPorEmp[c.id_empleado]) checadasPorEmp[c.id_empleado] = []
                checadasPorEmp[c.id_empleado].push(c)
            }

            const { data: adscRaw } = await supabase
                .from('empleado_adscripciones')
                .select('id_empleado, id_departamento, cat_departamentos(departamento)')
                .in('id_empleado', empIds)
                .order('fecha_inicio', { ascending: false })

            const adscMap: Record<string, any> = {}
            adscRaw?.forEach(a => {
                if (!adscMap[a.id_empleado]) {
                    const depto = Array.isArray(a.cat_departamentos) ? a.cat_departamentos[0] : a.cat_departamentos
                    adscMap[a.id_empleado] = { id: a.id_departamento, name: depto?.departamento }
                }
            })

            const { data: salRaw } = await supabase
                .from('empleado_salarios')
                .select('id_empleado, salario_diario, fecha_inicio_vigencia')
                .in('id_empleado', empIds)
                .order('fecha_inicio_vigencia', { ascending: false })

            const salMap: Record<string, number> = {}
            salRaw?.forEach(s => { if (!salMap[s.id_empleado]) salMap[s.id_empleado] = s.salario_diario || 0 })

            const { data: ingRaw } = await supabase
                .from('empleado_ingreso')
                .select('id_empleado, fecha_ingreso')
                .in('id_empleado', empIds)
            const ingMap: Record<string, string> = {}
            ingRaw?.forEach(i => { ingMap[i.id_empleado] = i.fecha_ingreso })

            const rolesByEmp: Record<string, any[]> = {}
            rolesRaw?.forEach(r => {
                if (!rolesByEmp[r.id_empleado]) rolesByEmp[r.id_empleado] = []
                rolesByEmp[r.id_empleado].push(r)
            })

            const processed = empsRaw.map(emp => {
                const roles = rolesByEmp[emp.id_empleado] || []

                // Buscar el rol que estaba activo DURANTE este periodo. 
                // Como están ordenados por fecha_inicio DESC, el primero cuya fecha_inicio <= endDate es el correcto.
                let activeRole = roles.find(r => r.fecha_inicio <= endDate) || null

                if (!activeRole && emp.id_turno && turnosDic[emp.id_turno]) {
                    const tInfo = turnosDic[emp.id_turno]
                    activeRole = {
                        is_turno: true,
                        fecha_inicio: startDate,
                        cat_tipos_rol: { id_tipo_rol: tInfo.id, tipo_rol: tInfo.nombre, aplica_dias: tInfo.aplica_dias, dias_trabajo: 6, dias_descanso: 1 }
                    }
                }

                if (activeRole) {
                    const config = Array.isArray(activeRole.cat_tipos_rol) ? activeRole.cat_tipos_rol[0] : activeRole.cat_tipos_rol
                    activeRole = { ...activeRole, cat_tipos_rol: config }
                }

                const depto = adscMap[emp.id_empleado]?.name || 'No asignado'
                const baseSueldo = salMap[emp.id_empleado] || 0
                const fechaIngreso = ingMap[emp.id_empleado]
                const sdiValue = calculateSDI(baseSueldo, fechaIngreso || new Date())

                const empIncidencias = incidencias.filter(i => i.id_empleado === emp.id_empleado)
                const empChecadas = (checadasPorEmp[emp.id_empleado] || []).map(c => ({ ...c, id_turno: emp.id_turno }))
                const res = calcAttendance(startDate, endDate, activeRole, empChecadas, empIncidencias, dGlobals, festivosDates, fechaIngreso, turnosDic)
                const {
                    asistencias, retardos, faltas, diasTrabajoProgramados, descansos,
                    asistenciasDomingo, diasVacaciones, suspensiones,
                    permisosGoce, permisosSinGoce, incapacidades,
                    esAniversario, yearsOfService, alerts, dailyBreakdown,
                    incapacidadesList,
                    horasExtraTotales, horasExtraDobles, horasExtraTriples,
                    diasFestivosTrabajados
                } = res

                const sdValue = baseSueldo
                if (sdValue <= 0) alerts.push("⚠️ Sueldo Diario no configurado")
                if (depto === 'No asignado') alerts.push("🚨 Departamento faltante")
                const isDuplicate = empsRaw.filter(e =>
                    `${e.apellido_paterno} ${e.apellido_materno} ${e.nombre}`.trim() ===
                    `${emp.apellido_paterno} ${emp.apellido_materno} ${emp.nombre}`.trim()
                ).length > 1
                if (isDuplicate) alerts.push("🚫 Posible registro duplicado")
                if (faltas >= 3) alerts.unshift("🚨 ALERTA GESTOR: Posible Abandono (3+ Faltas)")

                // Manual Toggles Logic
                const payPrimaDominical = asistenciasDomingo > 0
                const payPrimaVacacional = esAniversario

                // Prima Dominical Calculation
                const pDominical = payPrimaDominical ? (asistenciasDomingo * 0.25 * sdValue) : 0

                // --- LÓGICA DE PRIMAS (LFT 25%) ---
                // Prima Proporcional (Días gozados * 0.25 * SD)
                const pVacacionalProporcional = 0 // Desactivamos la proporcional por ahora a favor de la de ley anual

                let pVacacionalAnual = 0
                let vDaysCount = 0
                if (fechaIngreso) {
                    const years = yearsOfService
                    if (years === 1) vDaysCount = 12
                    else if (years === 2) vDaysCount = 14
                    else if (years === 3) vDaysCount = 16
                    else if (years === 4) vDaysCount = 18
                    else if (years === 5) vDaysCount = 20
                    else if (years >= 6 && years <= 10) vDaysCount = 22
                    else if (years >= 11 && years <= 15) vDaysCount = 24
                    else if (years >= 16 && years <= 20) vDaysCount = 26
                    else if (years >= 21 && years <= 25) vDaysCount = 28
                    else if (years >= 26 && years <= 30) vDaysCount = 30
                    else if (years >= 31) vDaysCount = 32

                    // Se paga sobre la totalidad de los días de ley en el aniversario o si está marcado
                    if (payPrimaVacacional) {
                        pVacacionalAnual = vDaysCount * 0.25 * sdValue
                        if (esAniversario) alerts.push(`🎉 Aniversario detectado (${years} años - ${vDaysCount} días)`)
                    }
                }

                // --- LÓGICA DE PAGO (CORREGIDA PARA EVITAR CASTIGO DOBLE) ---
                // Días a pagar: Los que efectivamente se trabajaron o son permisos/vacaciones pagadas.
                const diasPagados = asistencias + descansos + diasVacaciones + permisosGoce

                // Cálculo de Pago por Festivos (Triple = Día normal + 200% adicional)
                const pagoFestivo = diasFestivosTrabajados * (sdValue * 2)

                // Cálculo de Horas Extra (Dobles y Triples) condicionadas
                const shouldPayHE = calculateOvertime && emp.paga_horas_extra !== false
                const pagoExtraDobles = shouldPayHE ? horasExtraDobles * (sdValue / 8 * 2) : 0
                const pagoExtraTriples = shouldPayHE ? horasExtraTriples * (sdValue / 8 * 3) : 0

                const totalPercepciones = (diasPagados * sdValue) + pDominical + pVacacionalProporcional + pVacacionalAnual + pagoFestivo + pagoExtraDobles + pagoExtraTriples

                // Las faltas y permisos sin goce YA quedaron fuera de 'diasPagados'. 
                // Restarlos aquí de nuevo crearía un "castigo doble" sobre el sueldo bruto.
                const totalDeducciones = 0

                let neto = totalPercepciones - totalDeducciones
                if (neto < 0) { alerts.push("⚠️ Neto negativo detectado"); neto = 0 }

                let systemObs = "OK"
                if (sdValue <= 0) systemObs = "Revisar sueldo base"
                else if (totalPercepciones - totalDeducciones < 0) systemObs = "Neto negativo"
                else if (isDuplicate) systemObs = "Registro duplicado"
                else if (depto === 'No asignado') systemObs = "Departamento faltante"
                else if (alerts.length > 0) systemObs = "Revisar incidencias"

                return {
                    id: emp.id_empleado,
                    numero: emp.numero_empleado,
                    nombre: `${emp.apellido_paterno} ${emp.apellido_materno} ${emp.nombre}`,
                    depto: depto, deptoId: adscMap[emp.id_empleado]?.id,
                    rol: activeRole?.cat_tipos_rol?.tipo_rol || 'Sin Rol',
                    programados: diasTrabajoProgramados,
                    asistencias, retardos, faltas, descansos, diasVacaciones, suspensiones,
                    permisosGoce, permisosSinGoce, incapacidades,
                    incapacidadesDetalle: incapacidadesList.join(', '),
                    // Primas logic
                    payPrimaDominical, payPrimaVacacional,
                    asistenciasDomingo, vDays: vDaysCount,
                    primaDominical: pDominical, primaVacacional: pVacacionalAnual,
                    pagoFestivo, pagoExtraDobles, pagoExtraTriples,
                    horasExtraDobles, horasExtraTriples, diasFestivosTrabajados,
                    totalPercepciones, totalDeducciones, neto,
                    sd: sdValue, sdi: sdiValue, systemObs, alerts,
                    dailyBreakdown: dailyBreakdown,
                    festivos: festivosDates, // Pasar festivos para el modal
                    rawRole: activeRole,
                    rawIncidencias: empIncidencias,
                    rawChecadas: empChecadas,
                    rawTurno: turnosDic[emp.id_turno] || activeRole?.cat_tipos_rol
                }
            })
            setReportData(processed)
        } catch (e) { console.error(e); alert('Error al generar reporte') } finally { setLoading(false) }
    }

    const togglePrima = (empId: string, field: 'payPrimaDominical' | 'payPrimaVacacional') => {
        setReportData(current => current.map(row => {
            if (row.id !== empId) return row

            const newRow = { ...row, [field]: !row[field] }

            // Recalculate Primas
            const pDom = newRow.payPrimaDominical ? (newRow.asistenciasDomingo || 0) * 0.25 * newRow.sd : 0
            const pVacAnual = newRow.payPrimaVacacional ? (newRow.vDays || 0) * 0.25 * newRow.sd : 0
            const pVacProp = (newRow.diasVacaciones || 0) * 0.25 * newRow.sd

            newRow.primaDominical = pDom
            newRow.primaVacacional = pVacAnual

            // --- LÓGICA DE PAGO (CORREGIDA) ---
            const diasPagados = newRow.asistencias + newRow.descansos + newRow.diasVacaciones + newRow.permisosGoce
            newRow.totalPercepciones = (diasPagados * newRow.sd) + newRow.primaDominical + newRow.primaVacacional

            // Deducciones de ausentismo son 0 porque ya se excluyeron de percepciones
            newRow.totalDeducciones = 0

            newRow.neto = Math.max(0, newRow.totalPercepciones - newRow.totalDeducciones)

            return newRow
        }))
    }

    const exportToExcel = () => {
        if (reportData.length === 0) return
        const workbook = XLSX.utils.book_new()

        const dateStr = `${format(parseISO(startDate), 'dd/MM/yyyy')} al ${format(parseISO(endDate), 'dd/MM/yyyy')}`

        // --- CONSTRUCCIÓN DE LA HOJA DE RESUMEN (ESTILO EJECUTIVO) ---
        const aoa: any[][] = []

        // 1. Encabezado de Identidad
        aoa.push(['SISTEMA DE GESTIÓN DE CAPITAL HUMANO - RH BASE'])
        aoa.push(['REPORTE EJECUTIVO DE PRE-NÓMINA'])
        aoa.push([`Periodo de Pago: ${dateStr}`])
        aoa.push([`Fecha de Generación: ${format(new Date(), 'dd/mm/yyyy HH:MM')}`])
        aoa.push([]) // Espacio

        // 2. Resumen General (KPIs)
        const totalNeto = filteredData.reduce((a, r) => a + r.neto, 0)
        const totalPerc = filteredData.reduce((a, r) => a + r.totalPercepciones, 0)
        const count = filteredData.length

        aoa.push(['--- RESUMEN FINANCIERO DEL PERIODO ---'])
        aoa.push(['Concepto', 'Total'])
        aoa.push(['Colaboradores Procesados', count])
        aoa.push(['Suma de Percepciones', totalPerc])
        aoa.push(['Suma de Deducciones', 0])
        aoa.push(['Total Neto a Dispersar', totalNeto])
        aoa.push([]) // Espacio
        aoa.push(['--- DETALLE POR COLABORADOR ---'])

        const headers = [
            'ID EMP', 'COLABORADOR', 'DEPARTAMENTO', 'PUESTO / ROL',
            'SD ($)', 'SDI ($)', 'DÍAS PROG.', 'ASIST.', 'FALTAS', 'DESC.', 'VAC.',
            'P. GOCE', 'SUSP.', 'FEST. TRAB.', 'PAGO FEST.',
            'P. DOM.', 'P. VAC.',
            'TOTAL PERCEPCIONES', 'TOTAL DEDUCCIONES', 'NETO A PAGAR', 'NOTAS'
        ]
        aoa.push(headers)

        filteredData.forEach((row: any) => {
            aoa.push([
                row.numero,
                row.nombre,
                row.depto,
                row.rol,
                row.sd,
                row.sdi,
                row.programados,
                row.asistencias,
                row.faltas,
                row.descansos,
                row.diasVacaciones,
                row.permisosGoce,
                row.suspensiones,
                row.diasFestivosTrabajados || 0,
                row.pagoFestivo || 0,
                row.primaDominical || 0,
                row.primaVacacional || 0,
                row.totalPercepciones,
                row.totalDeducciones,
                row.neto,
                row.systemObs
            ])
        })

        const wsResumen = XLSX.utils.aoa_to_sheet(aoa)

        // Configuración de anchos de columna (ajustados para visibilidad)
        wsResumen['!cols'] = [
            { wch: 8 }, { wch: 40 }, { wch: 25 }, { wch: 25 },
            { wch: 10 }, { wch: 10 }, { wch: 10 }, { wch: 8 }, { wch: 8 }, { wch: 8 }, { wch: 8 },
            { wch: 8 }, { wch: 8 }, { wch: 12 }, { wch: 12 },
            { wch: 10 }, { wch: 10 },
            { wch: 20 }, { wch: 20 }, { wch: 20 }, { wch: 30 }
        ]

        XLSX.utils.book_append_sheet(workbook, wsResumen, 'Resumen_Nomina')

        // 3. Hoja de Detalle Diario (Simplificada y Limpia)
        const dailyAOA: any[][] = []
        dailyAOA.push(['DETALLE DIARIO DE INCIDENCIAS - RHBASE'])
        dailyAOA.push([`Periodo: ${dateStr}`])
        dailyAOA.push([])
        dailyAOA.push(['ID', 'NOMBRE', 'FECHA', 'ESTATUS', 'NOTAS / TURNO'])

        filteredData.forEach(row => {
            row.dailyBreakdown.forEach((day: any) => {
                dailyAOA.push([
                    row.numero,
                    row.nombre,
                    day.fecha,
                    day.estatus,
                    day.detalle || day.label || '-'
                ])
            })
            dailyAOA.push([]) // Espacio entre empleados
        })

        const wsDetalle = XLSX.utils.aoa_to_sheet(dailyAOA)
        wsDetalle['!cols'] = [{ wch: 8 }, { wch: 40 }, { wch: 15 }, { wch: 15 }, { wch: 40 }]

        XLSX.utils.book_append_sheet(workbook, wsDetalle, 'Bitacora_Diaria')

        XLSX.writeFile(workbook, `PRENOMINA_EJECUTIVA_${startDate}_${endDate}.xlsx`)
    }

    const filteredData = reportData.filter(row => {
        const matchesDept = selectedDept === 'all' || row.deptoId === selectedDept
        const matchesSearch = row.nombre.toLowerCase().includes(search.toLowerCase()) || row.numero?.toString().includes(search)
        return matchesDept && matchesSearch
    })

    return (
        <div className="space-y-6 animate-in fade-in duration-500 max-w-[1800px] mx-auto pb-10">
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 bg-white p-8 rounded-3xl shadow-xl border-b-4 border-indigo-900">
                <div className="space-y-1">
                    <div className="flex items-center gap-2 mb-2">
                        <span className="px-3 py-1 bg-indigo-50 text-indigo-700 text-[10px] font-black uppercase tracking-widest rounded-full border border-indigo-100">Reporte Operativo</span>
                        <div className="w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse"></div>
                    </div>
                    <h1 className="text-4xl font-black text-zinc-900 tracking-tighter leading-none">Pre-Nómina <span className="text-indigo-900">Ejecutiva</span></h1>
                    <p className="text-zinc-500 font-medium text-sm">Control centralizado de devengos, deducciones e incidencias del personal.</p>
                </div>
                <div className="flex flex-col md:flex-row items-stretch gap-3 w-full md:w-auto">
                    <div className="flex items-center gap-3 bg-zinc-50 p-2.5 rounded-2xl border border-zinc-200">
                        <div className="flex flex-col px-1">
                            <label className="text-[9px] font-black text-zinc-400 uppercase tracking-tighter">Periodo Inicio</label>
                            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className="bg-transparent border-none p-0 focus:ring-0 text-sm font-bold text-zinc-800" />
                        </div>
                        <div className="w-px h-10 bg-zinc-200"></div>
                        <div className="flex flex-col px-1">
                            <label className="text-[9px] font-black text-zinc-400 uppercase tracking-tighter">Periodo Fin</label>
                            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className="bg-transparent border-none p-0 focus:ring-0 text-sm font-bold text-zinc-800" />
                        </div>
                        <div className="flex items-center gap-2 bg-indigo-50/50 p-2 px-3 rounded-xl border border-indigo-100">
                            <input 
                                type="checkbox" 
                                id="overtime-toggle"
                                checked={calculateOvertime}
                                onChange={(e) => setCalculateOvertime(e.target.checked)}
                                className="w-4 h-4 text-indigo-900 border-zinc-300 rounded focus:ring-indigo-500"
                            />
                            <label htmlFor="overtime-toggle" className="text-xs font-black text-indigo-900 uppercase cursor-pointer select-none">
                                Calcular Horas Extra
                            </label>
                        </div>
                    </div>
                    <button onClick={generateReport} disabled={loading} className="bg-indigo-900 text-white px-8 py-4 rounded-2xl font-black hover:bg-black transition-all flex items-center justify-center disabled:opacity-50 text-sm shadow-lg shadow-indigo-100">
                        {loading ? <Clock className="w-4 h-4 animate-spin mr-2" /> : <Sparkles className="w-4 h-4 mr-2" />}
                        {loading ? 'Calculando...' : 'Procesar Reporte'}
                    </button>
                    {reportData.length > 0 && (
                        <button onClick={exportToExcel} className="inline-flex items-center justify-center bg-emerald-600 text-white px-6 py-4 rounded-2xl font-bold hover:bg-emerald-700 transition-all shadow-lg shadow-emerald-50 text-sm">
                            <FileDown className="w-4 h-4 mr-2" /> Exportar
                        </button>
                    )}
                </div>
            </div>

            {reportData.length > 0 && (
                <div className="space-y-6">
                    {/* KPI Section */}
                    <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                        {[
                            { label: 'Empleados', val: filteredData.length, icon: Building, color: 'text-zinc-600 bg-white border-zinc-200' },
                            { label: 'Percepciones', val: `$${filteredData.reduce((a, r) => a + r.totalPercepciones, 0).toLocaleString('en-US')}`, icon: CheckCircle, color: 'text-emerald-700 bg-emerald-50' },
                            { label: 'Deducciones', val: `$${filteredData.reduce((a, r) => a + r.totalDeducciones, 0).toLocaleString('en-US')}`, icon: XCircle, color: 'text-rose-700 bg-rose-50' },
                            { label: 'Total Neto', val: `$${filteredData.reduce((a, r) => a + r.neto, 0).toLocaleString('en-US')}`, icon: Sparkles, color: 'text-indigo-700 bg-indigo-50 ring-2 ring-indigo-100' },
                            { label: 'Alertas', val: filteredData.filter(r => r.alerts.length > 0).length, icon: AlertTriangle, color: 'text-amber-700 bg-amber-50' }
                        ].map(kpi => (
                            <div key={kpi.label} className={`flex flex-col p-4 rounded-2xl border ${kpi.color}`}>
                                <span className="text-[10px] font-black uppercase opacity-70 mb-1">{kpi.label}</span>
                                <div className="text-xl font-black">{kpi.val}</div>
                            </div>
                        ))}
                    </div>

                    {/* Table Filters */}
                    <div className="flex gap-3 bg-white p-2 rounded-xl border border-zinc-200 shadow-sm">
                        <div className="flex-1 relative">
                            <Search className="absolute left-3 top-3 h-4 w-4 text-zinc-400" />
                            <input type="text" placeholder="Filtrar por nombre o ID..." value={search} onChange={e => setSearch(e.target.value)} className="pl-10 w-full border-none bg-zinc-50 rounded-lg text-sm h-10" />
                        </div>
                        <select value={selectedDept} onChange={e => setSelectedDept(e.target.value)} className="w-64 border-none bg-zinc-50 rounded-lg text-sm h-10 outline-none">
                            <option value="all">Todos los Deptos</option>
                            {departments.map(d => <option key={d.id_departamento} value={d.id_departamento}>{d.departamento}</option>)}
                        </select>
                    </div>

                    {/* Table */}
                    <div className="rounded-2xl border border-zinc-200 shadow-sm bg-white overflow-hidden">
                        <div className="overflow-x-auto">
                            <table className="min-w-full divide-y divide-zinc-200 text-sm italic-none">
                                <thead className="bg-zinc-100/50">
                                    <tr className="bg-zinc-100/50">
                                        <th rowSpan={2} className="px-5 py-4 text-left text-[11px] font-black text-zinc-500 uppercase sticky left-0 z-10 bg-zinc-100/80 border-r">Colaborador</th>
                                        <th colSpan={2} className="px-2 py-2 text-center text-[9px] font-black text-zinc-400 uppercase border-b">Sueldos</th>
                                        <th colSpan={4} className="px-2 py-2 text-center text-[9px] font-black text-emerald-600 uppercase border-b bg-emerald-50/30">Días Pagables</th>
                                        <th colSpan={3} className="px-2 py-2 text-center text-[9px] font-black text-rose-600 uppercase border-b bg-rose-50/30">Descuentos</th>
                                        <th colSpan={3} className="px-2 py-2 text-center text-[9px] font-black text-indigo-600 uppercase border-b bg-indigo-50/30">Incidencias</th>
                                        <th colSpan={3} className="px-2 py-2 text-center text-[9px] font-black text-amber-600 uppercase border-b bg-amber-50/30">Extras / Fest</th>
                                        <th colSpan={2} className="px-2 py-2 text-center text-[9px] font-black text-emerald-600 uppercase border-b bg-emerald-50/30">Primas</th>
                                        <th colSpan={4} className="px-2 py-2 text-center text-[9px] font-black text-zinc-900 uppercase border-b bg-zinc-100">Finales</th>
                                    </tr>
                                    <tr>
                                        <th className="px-2 py-3 text-[10px] font-bold border-r">SD</th>
                                        <th className="px-2 py-3 text-[10px] font-bold border-r text-zinc-400">SDI</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50">Prog</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50">Asist</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50">Desc</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50 border-r">Vac</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-rose-50/50">Faltas</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-rose-50/50">Susp</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-rose-50/50 border-r">PSG</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-indigo-50/50">PCG</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-indigo-50/50">Incap</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-indigo-50/50 border-r">Ret</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-amber-50/50">H.E.2</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-amber-50/50">H.E.3</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-amber-50/50 border-r">Fes.Trab</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50">P.Dom</th>
                                        <th className="px-2 py-3 text-[10px] font-bold bg-emerald-50/50 border-r">P.Vac</th>
                                        <th className="px-4 py-3 text-[10px] font-bold bg-zinc-100">Percep</th>
                                        <th className="px-4 py-3 text-[10px] font-bold bg-zinc-100">Deduc</th>
                                        <th className="px-4 py-3 text-[10px] font-black bg-indigo-100/50">Neto</th>
                                        <th className="px-6 py-3 text-[10px] font-black bg-zinc-100">Obs</th>
                                    </tr>
                                </thead>
                                <tbody className="bg-white divide-y divide-zinc-100">
                                    {filteredData.map(row => (
                                        <tr key={row.id} className="hover:bg-zinc-50/80 cursor-default">
                                            <td className="px-5 py-3 sticky left-0 z-10 bg-white border-r cursor-pointer" onClick={() => setSelectedEmployee(row)}>
                                                <div className="flex flex-col">
                                                    <span className="text-sm font-bold text-zinc-900">{row.nombre}</span>
                                                    <span className="text-[10px] font-bold text-zinc-400 uppercase">{row.depto}</span>
                                                </div>
                                            </td>
                                            <td className="px-2 py-3 text-center text-zinc-600 font-bold border-r">${row.sd.toFixed(0)}</td>
                                            <td className="px-2 py-3 text-center text-zinc-400 text-xs border-r">${row.sdi.toFixed(2)}</td>
                                            <td className="px-2 py-3 text-center text-emerald-700 font-bold bg-emerald-50/20">{row.programados}</td>
                                            <td className="px-2 py-3 text-center text-emerald-700 font-bold bg-emerald-50/20">{row.asistencias}</td>
                                            <td className="px-2 py-3 text-center text-emerald-700 font-bold bg-emerald-50/20">{row.descansos}</td>
                                            <td className="px-2 py-3 text-center text-emerald-700 font-bold bg-emerald-50/20 border-r">{row.diasVacaciones}</td>
                                            <td className={`px-2 py-3 text-center font-bold bg-rose-50/20 ${row.faltas > 0 ? 'text-rose-700' : 'text-zinc-300'}`}>{row.faltas}</td>
                                            <td className={`px-2 py-3 text-center font-bold bg-rose-50/20 ${row.suspensiones > 0 ? 'text-rose-700' : 'text-zinc-300'}`}>{row.suspensiones}</td>
                                            <td className={`px-2 py-3 text-center font-bold bg-rose-50/20 border-r ${row.permisosSinGoce > 0 ? 'text-rose-700' : 'text-zinc-300'}`}>{row.permisosSinGoce}</td>
                                            <td className={`px-2 py-3 text-center font-bold bg-indigo-50/20 ${row.permisosGoce > 0 ? 'text-indigo-700' : 'text-zinc-300'}`}>{row.permisosGoce}</td>
                                            <td className={`px-2 py-3 text-center font-bold bg-indigo-50/20 ${row.incapacidades > 0 ? 'text-indigo-700' : 'text-zinc-300'}`} title={row.incapacidadesDetalle}>
                                                <div className="flex flex-col">
                                                    <span>{row.incapacidades}</span>
                                                    {row.incapacidades > 0 && (
                                                        <span className="text-[8px] text-indigo-400 font-medium truncate max-w-[60px]">{row.incapacidadesDetalle}</span>
                                                    )}
                                                </div>
                                            </td>
                                            <td className={`px-2 py-3 text-center font-bold bg-indigo-50/20 border-r ${row.retardos > 0 ? 'text-amber-600' : 'text-zinc-300'}`}>{row.retardos}</td>

                                            {/* Horas Extra y Festivos */}
                                            <td className={`px-2 py-3 text-center font-bold bg-amber-50/10 ${row.horasExtraDobles > 0 ? 'text-amber-700' : 'text-zinc-300'}`}>
                                                {row.horasExtraDobles > 0 ? `${row.horasExtraDobles.toFixed(1)}h` : '0'}
                                            </td>
                                            <td className={`px-2 py-3 text-center font-bold bg-amber-50/10 ${row.horasExtraTriples > 0 ? 'text-orange-700' : 'text-zinc-300'}`}>
                                                {row.horasExtraTriples > 0 ? `${row.horasExtraTriples.toFixed(1)}h` : '0'}
                                            </td>
                                            <td className={`px-2 py-3 text-center font-bold bg-amber-50/10 border-r ${row.diasFestivosTrabajados > 0 ? 'text-indigo-700' : 'text-zinc-300'}`}>
                                                {row.diasFestivosTrabajados > 0 ? row.diasFestivosTrabajados : '0'}
                                            </td>

                                            {/* Primas with Toggles */}
                                            <td className="px-2 py-3 text-center bg-emerald-50/10">
                                                <div className="flex flex-col items-center gap-1">
                                                    <input
                                                        type="checkbox"
                                                        checked={row.payPrimaDominical || false}
                                                        onChange={() => togglePrima(row.id, 'payPrimaDominical')}
                                                        className="w-4 h-4 rounded border-emerald-300 text-emerald-600 focus:ring-emerald-500"
                                                    />
                                                    <span className="text-[10px] font-bold text-emerald-700">${row.primaDominical.toFixed(0)}</span>
                                                </div>
                                            </td>
                                            <td className="px-2 py-3 text-center bg-emerald-50/10 border-r">
                                                <div className="flex flex-col items-center gap-1">
                                                    <input
                                                        type="checkbox"
                                                        checked={row.payPrimaVacacional || false}
                                                        onChange={() => togglePrima(row.id, 'payPrimaVacacional')}
                                                        className="w-4 h-4 rounded border-emerald-300 text-emerald-600 focus:ring-emerald-500"
                                                    />
                                                    <span className="text-[10px] font-bold text-emerald-700">${row.primaVacacional.toFixed(0)}</span>
                                                </div>
                                            </td>

                                            <td className="px-4 py-3 text-center font-bold text-emerald-700 bg-emerald-50/30">${row.totalPercepciones.toLocaleString('en-US', { minimumFractionDigits: 0 })}</td>
                                            <td className="px-4 py-3 text-center font-bold text-rose-700 bg-rose-50/30">${row.totalDeducciones.toLocaleString('en-US', { minimumFractionDigits: 0 })}</td>
                                            <td className="px-4 py-3 text-center font-black text-indigo-900 bg-indigo-100/30 ring-1 ring-inset ring-indigo-200">${row.neto.toLocaleString('en-US', { minimumFractionDigits: 2 })}</td>
                                            <td className="px-6 py-3">
                                                {row.systemObs === 'OK' ? (
                                                    <span className="px-2 py-1 bg-emerald-50 text-emerald-700 text-[10px] font-black rounded border">OK</span>
                                                ) : (
                                                    <span className="px-2 py-1 bg-rose-50 text-rose-700 text-[10px] font-black rounded border truncate max-w-[100px]">{row.systemObs}</span>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            )}

            {!reportData.length && !loading && (
                <div className="flex flex-col items-center justify-center py-32 bg-zinc-50 rounded-3xl border-2 border-dashed border-zinc-200">
                    <Calendar className="w-12 h-12 text-zinc-300 mb-4" />
                    <h3 className="text-xl font-bold text-zinc-800">Cargar Pre-Nómina</h3>
                    <p className="text-zinc-500">Seleccione el rango de fechas para comenzar el análisis.</p>
                </div>
            )}

            <PrenominaEmployeeModal
                isOpen={!!selectedEmployee} onClose={() => setSelectedEmployee(null)}
                employeeData={selectedEmployee} startDate={startDate} endDate={endDate} descansosGlobales={descansosGlobales}
            />

            <GeminiAssistant screenContext={filteredData} />
        </div>
    )
}
