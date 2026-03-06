# ClarVision BI — Inteligencia Operacional para Clínica Oftalmológica

> Sistema de Business Intelligence end-to-end diseñado para reducir el ausentismo y optimizar la operación de una clínica oftalmológica. Construido con MySQL, Power BI y automatización con n8n.

---

## Problema de Negocio

Una clínica oftalmológica opera sin visibilidad sobre su rendimiento operacional. El equipo de dirección no tiene forma de saber cuántos pacientes no se presentan cada semana, qué médicos están sobrecargados ni cuándo la demanda cae de forma anormal.

**Impacto directo:** cada turno no atendido representa pérdida de ingresos, tiempo médico desperdiciado y deterioro en la calidad del servicio.

---

## Solución

ClarVision BI es un sistema de inteligencia operacional completo que transforma datos crudos de turnos en decisiones accionables. El sistema monitorea KPIs en tiempo real, detecta patrones de ausentismo y envía alertas automáticas cuando un indicador supera su umbral crítico.

---

## Dashboard

![Dashboard ClarVision BI](06_docs/dashboard_clarvision.png)

---

## Stack Tecnológico

| Herramienta | Rol |
|-------------|-----|
| MySQL 8.0 | Modelado relacional y almacenamiento |
| MySQL Workbench | Administración y queries analíticas |
| Power BI Desktop | Dashboard interactivo y visualización |
| n8n | Automatización de alertas y reportes |
| Slack | Canal de notificaciones del sistema |
| Excel | Validación y exploración de datos |
| draw.io | Diagrama del modelo de datos |

---

## Arquitectura del Sistema

```
MySQL (clarvision_db)
        │
        ├── Queries SQL analíticas
        │         │
        │         ├── Power BI Dashboard (KPIs visuales)
        │         │
        │         └── n8n Workflows
        │                   │
        │                   ├── Alerta ausentismo crítico → Slack
        │                   └── Reporte semanal automático → Slack
        │
        └── Excel (validación y exploración)
```

---

## Modelo de Datos

![Modelo de Datos](06_docs/modelo_datos.png)

El modelo consta de 5 tablas relacionales:

- **especialidades** — catálogo de especialidades médicas
- **medicos** — profesionales de la clínica con su especialidad
- **pacientes** — registro de pacientes activos
- **turnos** — núcleo operacional con estados: Confirmado, Completado, Cancelado, Ausente
- **alertas_log** — trazabilidad de todas las alertas generadas por el sistema

Y 3 vistas analíticas pre-calculadas para Power BI y n8n:

- **vw_turnos_mensual** — KPIs mensuales de ausentismo y efectividad
- **vw_ocupacion_medico** — ocupación semanal por médico
- **vw_kpi_semanal** — métricas semanales para disparar alertas

---

## KPIs Principales

| KPI | Resultado |
|-----|-----------|
| Total turnos analizados | 285 |
| Tasa de ausentismo promedio | 19.03% |
| Tasa de cancelación promedio | 10.06% |
| Mes con mayor ausentismo | Agosto 2024 (36%) |
| Especialidad con más demanda | Oftalmología General (40.7%) |

---

## Automatización con n8n

### Workflow 1 — Alerta de Ausentismo Crítico

Se ejecuta semanalmente. Si la tasa de ausentismo supera el 20%, envía una alerta inmediata a Slack con los detalles de la semana crítica.

![Workflow Alerta](06_docs/workflow_alerta.png)

### Workflow 2 — Reporte Semanal

Se ejecuta todos los lunes a las 8am. Envía un resumen completo de los KPIs de la semana anterior al canal de dirección en Slack.

![Workflow Reporte](06_docs/workflow_reporte.png)

---

## Estructura del Repositorio

```
ClarVision-BI/
├── 01_database/
│   ├── schema.sql          # Modelo relacional completo con índices y vistas
│   └── seed_data_v2.sql    # 285 turnos con patrones reales de 6 meses
├── 02_queries/
│   └── kpi_queries.sql     # 10 queries analíticas para cada KPI
├── 03_excel/
│   └── kpi_*.csv / .xlsx   # Exportaciones de cada KPI para análisis
├── 04_powerbi/
│   └── clarvision.pbix     # Dashboard interactivo conectado a MySQL
├── 05_n8n/
│   ├── workflow_alerta_ausentismo.json
│   └── workflow_reporte_semanal.json
└── 06_docs/
    ├── dashboard_clarvision.png
    ├── dashboard_clarvision.pdf
    ├── workflow_alerta.png
    ├── workflow_reporte.png
    └── modelo_datos.png
```

---

## Hallazgos Clave

Agosto 2024 registró una tasa de ausentismo del 36%, casi el doble del promedio del período. Este patrón estacional coincide con el período vacacional y representa la mayor pérdida operacional del año. El sistema detecta este tipo de anomalías automáticamente y notifica a dirección en tiempo real.

La especialidad de Oftalmología General concentra el 40.7% de la demanda total, lo que indica una oportunidad de expansión de agenda en esa especialidad para reducir la espera de nuevos pacientes.

---

## Cómo Reproducir el Proyecto

```sql
-- 1. Crear la base de datos
source 01_database/schema.sql

-- 2. Insertar datos de ejemplo
source 01_database/seed_data_v2.sql

-- 3. Ejecutar queries analíticas
source 02_queries/kpi_queries.sql
```

Para el dashboard abrir `04_powerbi/clarvision.pbix` con Power BI Desktop y actualizar la conexión a MySQL con las credenciales locales.

Para los workflows importar los archivos JSON de `05_n8n/` en una instancia de n8n y configurar las credenciales de MySQL y Slack.

---

## Autor

**Tomas Raspo** — Systems Analyst & Data Analytics Specialist

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Tomas_Raspo-blue)](https://www.linkedin.com/in/tomás-raspo-b03028214/)
[![Portfolio](https://img.shields.io/badge/Portfolio-tomas--raspo-green)](https://tomas-raspo-portfolio.vercel.app/)
