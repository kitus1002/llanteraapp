'use client'

import { useState } from 'react'
import {
    Activity,
    TrendingUp,
    Award,
    Clock,
    UserCheck,
    Briefcase,
    Zap,
    Target,
    BarChart3,
    Calendar,
    ChevronRight,
    Search,
    BrainCircuit,
    Star,
    Sparkles,
    ArrowUpRight,
    AlertCircle
} from 'lucide-react'
import {
    AreaChart,
    Area,
    XAxis,
    YAxis,
    CartesianGrid,
    Tooltip,
    ResponsiveContainer,
    BarChart,
    Bar,
    PieChart,
    Pie,
    Cell,
    RadarChart,
    PolarGrid,
    PolarAngleAxis,
    PolarRadiusAxis,
    Radar,
} from 'recharts'

// Mock Data for the Dashboard
const performanceData = [
    { month: 'Ene', score: 85, target: 80 },
    { month: 'Feb', score: 88, target: 80 },
    { month: 'Mar', score: 92, target: 82 },
    { month: 'Abr', score: 89, target: 82 },
    { month: 'May', score: 95, target: 85 },
    { month: 'Jun', score: 98, target: 85 },
]

const behaviorData = [
    { subject: 'Puntualidad', A: 95, fullMark: 100 },
    { subject: 'Proactividad', A: 88, fullMark: 100 },
    { subject: 'Liderazgo', A: 75, fullMark: 100 },
    { subject: 'Trabajo Equipo', A: 92, fullMark: 100 },
    { subject: 'Responsabilidad', A: 98, fullMark: 100 },
]

const activityLog = [
    { title: 'Certificación ISO 9001', date: '12 May, 2026', type: 'Examen', result: '98/100', icon: Award, color: 'text-amber-500' },
    { title: 'Capacitación Liderazgo Humano', date: '05 May, 2026', type: 'Curso', result: 'Aprobado', icon: BrainCircuit, color: 'text-purple-500' },
    { title: 'Examen Trimestral de Operaciones', date: '28 Abr, 2026', type: 'Examen', result: '92/100', icon: ClipboardList, color: 'text-blue-500' },
]

function ClipboardList(props: any) {
    return (
        <svg
            {...props}
            xmlns="http://www.w3.org/2000/svg"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
        >
            <rect width="8" height="4" x="8" y="2" rx="1" ry="1" />
            <path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2" />
            <path d="M9 12h6" />
            <path d="M9 16h6" />
            <path d="M9 8h6" />
        </svg>
    )
}

const COLORS = ['#F59E0B', '#10B981', '#3B82F6', '#8B5CF6']

export default function EvaluacionesPage() {
    const [selectedEmployee, setSelectedEmployee] = useState({
        name: 'Roberto Sánchez',
        puesto: 'Gerente de Planta',
        score: 94,
        status: 'Excelente',
        image: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80'
    })

    return (
        <div className="space-y-6 lg:p-2">
            {/* Header Section */}
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
                <div>
                    <h1 className="text-3xl font-black text-white tracking-tight flex items-center gap-2">
                        <Activity className="h-8 w-8 text-amber-500" />
                        Análisis de Desempeño
                    </h1>
                    <p className="text-zinc-500 text-sm mt-1">Evaluación integral basada en KPIs, comportamiento y crecimiento profesional.</p>
                </div>
                <div className="flex items-center gap-3">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-zinc-500" />
                        <input
                            type="text"
                            placeholder="Buscar empleado..."
                            className="pl-9 pr-4 py-2 bg-zinc-900 border-zinc-800 rounded-full text-sm text-zinc-300 focus:ring-amber-500 focus:border-amber-500 w-64 ring-1 ring-zinc-800"
                        />
                    </div>
                    <button className="p-2 bg-amber-500 text-black rounded-full hover:bg-amber-400 transition-colors shadow-lg shadow-amber-500/20">
                        <Sparkles className="h-5 w-5" />
                    </button>
                </div>
            </div>

            {/* Profile Overview Card */}
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                <div className="lg:col-span-1 bg-zinc-950 border border-zinc-800 rounded-3xl p-6 flex flex-col items-center text-center relative overflow-hidden group">
                    <div className="absolute top-0 right-0 p-4">
                        <span className="flex items-center gap-1 bg-green-500/10 text-green-500 text-[10px] font-bold px-2 py-1 rounded-full uppercase tracking-tighter ring-1 ring-green-500/20">
                            <TrendingUp className="w-3 h-3" /> +5% este mes
                        </span>
                    </div>
                    <div className="relative mb-4">
                        <div className="h-32 w-32 rounded-full border-4 border-amber-500/30 p-1 group-hover:border-amber-500 transition-all duration-500">
                            <img
                                src={selectedEmployee.image}
                                alt={selectedEmployee.name}
                                className="h-full w-full rounded-full object-cover shadow-2xl"
                            />
                        </div>
                        <div className="absolute -bottom-2 -right-2 h-10 w-10 bg-amber-500 rounded-full flex items-center justify-center text-black font-black border-4 border-zinc-950">
                            {selectedEmployee.score}
                        </div>
                    </div>
                    <h2 className="text-xl font-bold text-white leading-tight">{selectedEmployee.name}</h2>
                    <p className="text-zinc-500 text-sm">{selectedEmployee.puesto}</p>
                    <div className="mt-4 w-full h-px bg-zinc-800" />
                    <div className="mt-4 grid grid-cols-2 w-full gap-4">
                        <div className="text-left">
                            <p className="text-[10px] text-zinc-500 uppercase font-bold tracking-widest">Estatus</p>
                            <p className="text-sm text-amber-500 font-bold">{selectedEmployee.status}</p>
                        </div>
                        <div className="text-left">
                            <p className="text-[10px] text-zinc-500 uppercase font-bold tracking-widest">Antigüedad</p>
                            <p className="text-sm text-zinc-300 font-bold">4.2 Años</p>
                        </div>
                    </div>
                    <button className="mt-6 w-full py-2.5 bg-zinc-900 border border-zinc-800 rounded-xl text-xs font-bold text-zinc-300 hover:bg-zinc-800 transition-all flex items-center justify-center gap-2">
                        Ver Expediente Digital <ChevronRight className="w-3 h-3" />
                    </button>
                </div>

                {/* Main Stats Area */}
                <div className="lg:col-span-3 grid grid-cols-1 md:grid-cols-3 gap-6">
                    {/* Performance History */}
                    <div className="md:col-span-2 bg-zinc-950 border border-zinc-800 rounded-3xl p-6 relative">
                        <div className="flex items-center justify-between mb-6">
                            <h3 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
                                <BarChart3 className="w-4 h-4 text-amber-500" /> Evolución de Rendimiento
                            </h3>
                            <select className="bg-transparent text-[10px] font-bold text-zinc-500 border-none focus:ring-0 uppercase cursor-pointer">
                                <option>Últimos 6 meses</option>
                                <option>Último año</option>
                            </select>
                        </div>
                        <div className="h-[200px] w-full">
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={performanceData}>
                                    <defs>
                                        <linearGradient id="colorScore" x1="0" y1="0" x2="0" y2="1">
                                            <stop offset="5%" stopColor="#F59E0B" stopOpacity={0.3} />
                                            <stop offset="95%" stopColor="#F59E0B" stopOpacity={0} />
                                        </linearGradient>
                                    </defs>
                                    <Tooltip
                                        contentStyle={{ backgroundColor: '#09090b', border: '1px solid #27272a', borderRadius: '12px' }}
                                        labelStyle={{ color: '#71717a' }}
                                        itemStyle={{ color: '#f59e0b' }}
                                    />
                                    <Area type="monotone" dataKey="score" stroke="#F59E0B" strokeWidth={3} fillOpacity={1} fill="url(#colorScore)" />
                                    <Area type="monotone" dataKey="target" stroke="#27272a" strokeWidth={1} strokeDasharray="5 5" fill="transparent" />
                                </AreaChart>
                            </ResponsiveContainer>
                        </div>
                        <div className="mt-4 flex items-center gap-4 text-[10px]">
                            <div className="flex items-center gap-1.5 font-bold text-zinc-400 capitalize">
                                <div className="w-2 h-2 rounded-full bg-amber-500" /> Puntuación Real
                            </div>
                            <div className="flex items-center gap-1.5 font-bold text-zinc-400 capitalize">
                                <div className="w-2 h-2 rounded-full bg-zinc-800" /> Meta Esperada
                            </div>
                        </div>
                    </div>

                    {/* AI Behavior Analysis */}
                    <div className="bg-zinc-950 border border-zinc-800 rounded-3xl p-6 flex flex-col items-center">
                        <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
                            <UserCheck className="w-4 h-4 text-amber-500" /> Perfil Conductual
                        </h3>
                        <div className="h-[180px] w-full">
                            <ResponsiveContainer width="100%" height="100%">
                                <RadarChart cx="50%" cy="50%" outerRadius="80%" data={behaviorData}>
                                    <PolarGrid stroke="#27272a" />
                                    <PolarAngleAxis dataKey="subject" tick={{ fill: '#71717a', fontSize: 10 }} />
                                    <Radar name="Comportamiento" dataKey="A" stroke="#F59E0B" fill="#F59E0B" fillOpacity={0.4} />
                                </RadarChart>
                            </ResponsiveContainer>
                        </div>
                    </div>
                </div>
            </div>

            {/* Bottom Row */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Insights and Predictions */}
                <div className="lg:col-span-1 space-y-6">
                    {/* Growth Prediction */}
                    <div className="bg-zinc-950 border border-zinc-800 rounded-3xl p-6 bg-gradient-to-br from-zinc-950 to-amber-500/5 relative overflow-hidden">
                        <div className="absolute top-0 right-0 translate-x-1/4 -translate-y-1/4 opacity-10">
                            <TrendingUp className="w-40 h-40 text-amber-500" />
                        </div>
                        <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4 flex items-center gap-2">
                            <Zap className="w-4 h-4 text-amber-500 " /> Predicción de Crecimiento
                        </h3>
                        <div className="flex items-end justify-between">
                            <div>
                                <p className="text-3xl font-black text-white">88<span className="text-amber-500 text-lg">%</span></p>
                                <p className="text-[10px] text-zinc-500 uppercase font-black tracking-widest leading-none mt-1">Probabilidad de Ascenso</p>
                            </div>
                            <div className="text-right">
                                <p className="text-sm font-bold text-green-500 flex items-center justify-end gap-1">
                                    <ArrowUpRight className="w-4 h-4" /> Recomendado
                                </p>
                                <p className="text-[10px] text-zinc-500 uppercase font-black tracking-widest leading-none mt-1">Nivel: Senior / Director</p>
                            </div>
                        </div>
                        <div className="mt-4 bg-zinc-900 h-2 rounded-full overflow-hidden">
                            <div className="bg-amber-500 h-full w-[88%] rounded-full shadow-[0_0_10px_rgba(245,158,11,0.5)]" />
                        </div>
                    </div>

                    {/* Salary/Bonus Suggestion */}
                    <div className="bg-zinc-950 border border-zinc-800 rounded-3xl p-6">
                        <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-4 flex items-center gap-2">
                            <AlertCircle className="w-4 h-4 text-blue-500" /> Sugerencia de Retención
                        </h3>
                        <p className="text-xs text-zinc-400 mb-4 italic">"Basado en el desempeño del último semestre y competencia de mercado, se sugiere un ajuste preventivo."</p>
                        <div className="px-4 py-3 bg-blue-500/10 rounded-2xl border border-blue-500/20 flex items-center justify-between">
                            <div>
                                <p className="text-[10px] text-zinc-400 uppercase font-bold">Aumento Sugerido</p>
                                <p className="text-lg font-black text-blue-400">+12.5%</p>
                            </div>
                            <button className="px-3 py-1.5 bg-blue-500 text-white text-[10px] font-bold rounded-lg hover:bg-blue-400 transition-colors">Aprobar</button>
                        </div>
                    </div>
                </div>

                {/* Training and Exams timeline */}
                <div className="lg:col-span-1 bg-zinc-950 border border-zinc-800 rounded-3xl p-6">
                    <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2 font-mono">
                        <Target className="w-4 h-4 text-amber-500" /> Trayectoria y Capacitación
                    </h3>
                    <div className="space-y-6">
                        {activityLog.map((log, i) => (
                            <div key={i} className="flex gap-4 relative">
                                {i < activityLog.length - 1 && <div className="absolute left-[19px] top-10 bottom-[-24px] w-px bg-zinc-800" />}
                                <div className="h-10 w-10 shrink-0 bg-zinc-900 border border-zinc-800 rounded-xl flex items-center justify-center">
                                    <log.icon className={`h-5 w-5 ${log.color}`} />
                                </div>
                                <div>
                                    <p className="text-xs font-bold text-white">{log.title}</p>
                                    <p className="text-[10px] text-zinc-500 flex items-center gap-2 mt-1 uppercase tracking-wider font-semibold">
                                        <Calendar className="w-3 h-3" /> {log.date}
                                    </p>
                                    <div className="mt-2 text-[10px] font-bold text-zinc-400 bg-zinc-900/50 px-2 py-1 rounded inline-block">
                                        Resultado: <span className={log.result.includes('Aprobado') || parseInt(log.result) > 90 ? 'text-green-500' : 'text-amber-500'}>{log.result}</span>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Best Moments Log */}
                <div className="lg:col-span-1 bg-zinc-950 border border-zinc-800 rounded-3xl p-6 flex flex-col">
                    <h3 className="text-sm font-bold text-white uppercase tracking-wider mb-6 flex items-center gap-2">
                        <Star className="w-4 h-4 text-amber-500 fill-amber-500" /> Top Highlights
                    </h3>
                    <div className="flex-1 space-y-4">
                        <div className="p-4 bg-zinc-900/50 border border-zinc-800 rounded-2xl hover:border-amber-500/50 transition-colors group cursor-default">
                            <div className="flex items-center gap-2 mb-2">
                                <div className="w-1.5 h-1.5 rounded-full bg-amber-500 flex-shrink-0" />
                                <p className="text-xs font-black text-zinc-300 group-hover:text-amber-500 transition-colors uppercase italic tracking-tighter">Liderazgo Excepcional</p>
                            </div>
                            <p className="text-[11px] text-zinc-500 leading-relaxed italic">"Logró coordinar la migración de la planta B sin una sola falta de asistencia en 90 días."</p>
                        </div>
                        <div className="p-4 bg-zinc-900/50 border border-zinc-800 rounded-2xl hover:border-amber-500/50 transition-colors group cursor-default">
                            <div className="flex items-center gap-2 mb-2">
                                <div className="w-1.5 h-1.5 rounded-full bg-amber-500 flex-shrink-0" />
                                <p className="text-xs font-black text-zinc-300 group-hover:text-amber-500 transition-colors uppercase italic tracking-tighter">Optimización de Procesos</p>
                            </div>
                            <p className="text-[11px] text-zinc-500 leading-relaxed italic">"Propuso la nueva rotación de turnos que redujo las horas extra innecesarias en un 15%."</p>
                        </div>
                    </div>
                    <div className="mt-8 pt-6 border-t border-zinc-800 text-center">
                        <p className="text-[10px] text-zinc-500 uppercase tracking-widest font-black mb-2 flex items-center justify-center gap-1"><BrainCircuit className="w-3 h-3 text-amber-500" /> Análisis Predictivo</p>
                        <p className="text-xs text-white font-bold px-4">"Candidato ideal para sucesión de Dirección Regional."</p>
                    </div>
                </div>
            </div>
        </div>
    )
}
