-- ============================================================
-- ClarVision BI — Queries Analíticas
-- Proyecto: Inteligencia Operacional para Clínica Oftalmológica
-- Autor: Tomas Raspo
-- Descripción: KPIs estratégicos para dashboard Power BI
-- ============================================================

USE clarvision_db;

-- ============================================================
-- KPI 1: RESUMEN EJECUTIVO MENSUAL
-- Visión general del período analizado
-- Usado en: tarjetas de resumen del dashboard
-- ============================================================
SELECT
    DATE_FORMAT(fecha_turno, '%Y-%m')           AS periodo,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Completado')                  AS completados,
    SUM(estado = 'Ausente')                     AS ausentes,
    SUM(estado = 'Cancelado')                   AS cancelados,
    SUM(estado = 'Confirmado')                  AS confirmados,
    ROUND(SUM(estado = 'Ausente')  * 100.0 / COUNT(*), 2) AS tasa_ausentismo_pct,
    ROUND(SUM(estado = 'Cancelado')* 100.0 / COUNT(*), 2) AS tasa_cancelacion_pct,
    ROUND(SUM(estado = 'Completado')* 100.0 / COUNT(*), 2) AS tasa_efectividad_pct
FROM turnos
GROUP BY periodo
ORDER BY periodo;

-- ============================================================
-- KPI 2: AUSENTISMO POR MÉDICO
-- Identifica qué médico tiene más pacientes ausentes
-- Usado en: gráfico de barras por médico
-- ============================================================
SELECT
    CONCAT(m.nombre, ' ', m.apellido)           AS medico,
    e.nombre                                    AS especialidad,
    COUNT(*)                                    AS total_turnos,
    SUM(t.estado = 'Ausente')                   AS ausentes,
    SUM(t.estado = 'Completado')                AS completados,
    ROUND(SUM(t.estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos t
INNER JOIN medicos m        ON t.id_medico      = m.id_medico
INNER JOIN especialidades e ON m.id_especialidad = e.id_especialidad
GROUP BY m.id_medico, medico, especialidad
ORDER BY tasa_ausentismo_pct DESC;

-- ============================================================
-- KPI 3: OCUPACIÓN SEMANAL POR MÉDICO
-- Detecta médicos sobrecargados o subutilizados
-- Usado en: alerta de sobrecarga en n8n
-- ============================================================
SELECT
    CONCAT(m.nombre, ' ', m.apellido)           AS medico,
    e.nombre                                    AS especialidad,
    YEARWEEK(t.fecha_turno, 1)                  AS semana,
    COUNT(*)                                    AS turnos_semana,
    ROUND(COUNT(*) * 100.0 / 10, 2)            AS porcentaje_ocupacion
FROM turnos t
INNER JOIN medicos m        ON t.id_medico      = m.id_medico
INNER JOIN especialidades e ON m.id_especialidad = e.id_especialidad
GROUP BY m.id_medico, medico, especialidad, semana
ORDER BY semana, porcentaje_ocupacion DESC;

-- ============================================================
-- KPI 4: DEMANDA POR DÍA DE LA SEMANA
-- Identifica los días con mayor y menor afluencia
-- Usado en: gráfico de calor en dashboard
-- ============================================================
SELECT
    DAYNAME(fecha_turno)                        AS dia_semana,
    DAYOFWEEK(fecha_turno)                      AS numero_dia,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Completado')                  AS completados,
    SUM(estado = 'Ausente')                     AS ausentes,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos
GROUP BY dia_semana, numero_dia
ORDER BY numero_dia;

-- ============================================================
-- KPI 5: DEMANDA POR FRANJA HORARIA
-- Identifica los horarios pico de atención
-- Usado en: optimización de agenda
-- ============================================================
SELECT
    hora_turno                                  AS horario,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Completado')                  AS completados,
    SUM(estado = 'Ausente')                     AS ausentes,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos
GROUP BY horario
ORDER BY horario;

-- ============================================================
-- KPI 6: RANKING DE ESPECIALIDADES
-- Cuál especialidad genera más demanda y ausentismo
-- Usado en: gráfico de torta en dashboard
-- ============================================================
SELECT
    e.nombre                                    AS especialidad,
    COUNT(*)                                    AS total_turnos,
    SUM(t.estado = 'Completado')                AS completados,
    SUM(t.estado = 'Ausente')                   AS ausentes,
    SUM(t.estado = 'Cancelado')                 AS cancelados,
    ROUND(SUM(t.estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct,
    ROUND(COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM turnos), 2)       AS participacion_total_pct
FROM turnos t
INNER JOIN medicos m        ON t.id_medico       = m.id_medico
INNER JOIN especialidades e ON m.id_especialidad  = e.id_especialidad
GROUP BY e.id_especialidad, especialidad
ORDER BY total_turnos DESC;

-- ============================================================
-- KPI 7: PACIENTES CON MÁS AUSENCIAS
-- Identifica pacientes con comportamiento recurrente de ausencia
-- Usado en: gestión proactiva de agenda
-- ============================================================
SELECT
    CONCAT(p.nombre, ' ', p.apellido)           AS paciente,
    p.obra_social,
    COUNT(*)                                    AS total_turnos,
    SUM(t.estado = 'Ausente')                   AS veces_ausente,
    ROUND(SUM(t.estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos t
INNER JOIN pacientes p ON t.id_paciente = p.id_paciente
GROUP BY p.id_paciente, paciente, p.obra_social
HAVING veces_ausente > 0
ORDER BY veces_ausente DESC
LIMIT 10;

-- ============================================================
-- KPI 8: AUSENTISMO POR OBRA SOCIAL
-- Detecta si alguna obra social tiene más ausentismo
-- Usado en: análisis de segmentación de pacientes
-- ============================================================
SELECT
    p.obra_social,
    COUNT(*)                                    AS total_turnos,
    SUM(t.estado = 'Ausente')                   AS ausentes,
    SUM(t.estado = 'Completado')                AS completados,
    ROUND(SUM(t.estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos t
INNER JOIN pacientes p ON t.id_paciente = p.id_paciente
GROUP BY p.obra_social
ORDER BY tasa_ausentismo_pct DESC;

-- ============================================================
-- KPI 9: TENDENCIA SEMANAL DE TURNOS
-- Detecta caídas o picos semana a semana
-- Usado en: alerta de caída de demanda en n8n
-- ============================================================
SELECT
    YEARWEEK(fecha_turno, 1)                    AS semana,
    MIN(fecha_turno)                            AS inicio_semana,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Completado')                  AS completados,
    SUM(estado = 'Ausente')                     AS ausentes,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct
FROM turnos
GROUP BY semana
ORDER BY semana;

-- ============================================================
-- KPI 10: ALERTA — SEMANAS CON AUSENTISMO CRÍTICO
-- Query que n8n ejecuta semanalmente para disparar alertas
-- Umbral: ausentismo > 20%
-- ============================================================
SELECT
    YEARWEEK(fecha_turno, 1)                    AS semana,
    MIN(fecha_turno)                            AS inicio_semana,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Ausente')                     AS ausentes,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo_pct,
    CASE
        WHEN ROUND(SUM(estado = 'Ausente') * 100.0 / COUNT(*), 2) > 20
        THEN '🔴 ALERTA CRÍTICA'
        WHEN ROUND(SUM(estado = 'Ausente') * 100.0 / COUNT(*), 2) > 15
        THEN '🟡 ATENCIÓN'
        ELSE '🟢 NORMAL'
    END                                         AS nivel_alerta
FROM turnos
GROUP BY semana
HAVING tasa_ausentismo_pct > 15
ORDER BY tasa_ausentismo_pct DESC;
