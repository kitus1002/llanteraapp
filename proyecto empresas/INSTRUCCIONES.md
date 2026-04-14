# Guía de Duplicación — Sistema de RH

Este documento explica cómo desplegar o duplicar este sistema para una nueva empresa utilizando los scripts de base de datos organizados.

## 📂 Organización de Archivos SQL

Para mantener el orden y facilitar la duplicación, utiliza estos archivos ubicados en la carpeta `proyecto empresas/`:

1.  **[scripts_instalacion.sql](file:///c:/Users/Kitus100/Desktop/Lobmaq/rh-system/proyecto%20empresas/scripts_instalacion.sql)**: 
    *   **USO**: Instalaciones LIMPIAS (Proyectos nuevos de Supabase).
    *   **Contenido**: Crea todas las tablas, relaciones, roles, catálogos iniciales y lógica automatizada (vacaciones/horas extra).

2.  **[schema.sql](file:///c:/Users/Kitus100/Desktop/Lobmaq/rh-system/proyecto%20empresas/schema.sql)**: 
    *   **USO**: Mantenimiento y Actualización.
    *   **Contenido**: Asegura que una base de datos existente tenga todas las columnas y políticas (RLS) al día. Es seguro ejecutarlo varias veces (idempotente).

---

## 🚀 Proceso de 3 Pasos para Duplicar

### Paso 1: Configurar Base de Datos (Supabase)
1. Crea un nuevo proyecto en Supabase.
2. Ve a **SQL Editor** -> **New Query**.
3. Copia el contenido de `scripts_instalacion.sql` y ejecútalo. 
4. Tu base de datos ahora tiene toda la lógica legal y estructural del sistema original.

### Paso 2: Configurar la Aplicación (GitHub / Vercel)
1. Duplica este repositorio de GitHub o usa el mismo.
2. En la configuración de Vercel, asegúrate de actualizar las **Variables de Entorno**:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   con las llaves del nuevo proyecto de Supabase.

### Paso 3: Lanzamiento
Despliega el proyecto. El sistema detectará el nuevo backend y estará listo para registrar empleados y generar documentos.

---

> [!IMPORTANT]
> **Seguridad (RLS)**: Ambos scripts ya incluyen las políticas de seguridad necesarias. Cualquier cambio en los permisos se puede sincronizar ejecutando el script `schema.sql`.
