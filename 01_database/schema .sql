-- ============================================================
-- ClarVision BI — Modelo Relacional
-- Proyecto: Inteligencia Operacional para Clínica Oftalmológica
-- Autor: Tomas Raspo
-- Stack: MySQL 8.0 | Workbench | Power BI | n8n
-- Versión: 1.0
-- ============================================================

-- ------------------------------------------------------------
-- CONFIGURACIÓN INICIAL
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS clarvision_db;
CREATE DATABASE clarvision_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE clarvision_db;

-- ------------------------------------------------------------
-- TABLA: especialidades
-- Catálogo de especialidades médicas disponibles en la clínica
-- ------------------------------------------------------------
CREATE TABLE especialidades (
    id_especialidad     INT             NOT NULL AUTO_INCREMENT,
    nombre              VARCHAR(100)    NOT NULL,
    descripcion         VARCHAR(255)    NULL,
    activa              TINYINT(1)      NOT NULL DEFAULT 1,
    fecha_creacion      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_especialidades PRIMARY KEY (id_especialidad),
    CONSTRAINT uq_especialidad_nombre UNIQUE (nombre)
);

-- ------------------------------------------------------------
-- TABLA: medicos
-- Registro de profesionales médicos de la clínica
-- ------------------------------------------------------------
CREATE TABLE medicos (
    id_medico           INT             NOT NULL AUTO_INCREMENT,
    id_especialidad     INT             NOT NULL,
    nombre              VARCHAR(100)    NOT NULL,
    apellido            VARCHAR(100)    NOT NULL,
    email               VARCHAR(150)    NOT NULL,
    telefono            VARCHAR(20)     NULL,
    matricula           VARCHAR(50)     NOT NULL,
    activo              TINYINT(1)      NOT NULL DEFAULT 1,
    fecha_ingreso       DATE            NOT NULL,
    fecha_creacion      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_medicos PRIMARY KEY (id_medico),
    CONSTRAINT uq_medico_email UNIQUE (email),
    CONSTRAINT uq_medico_matricula UNIQUE (matricula),
    CONSTRAINT fk_medico_especialidad FOREIGN KEY (id_especialidad)
        REFERENCES especialidades (id_especialidad)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- TABLA: pacientes
-- Registro de pacientes de la clínica
-- ------------------------------------------------------------
CREATE TABLE pacientes (
    id_paciente         INT             NOT NULL AUTO_INCREMENT,
    nombre              VARCHAR(100)    NOT NULL,
    apellido            VARCHAR(100)    NOT NULL,
    fecha_nacimiento    DATE            NOT NULL,
    email               VARCHAR(150)    NULL,
    telefono            VARCHAR(20)     NOT NULL,
    dni                 VARCHAR(20)     NOT NULL,
    obra_social         VARCHAR(100)    NULL,
    fecha_registro      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo              TINYINT(1)      NOT NULL DEFAULT 1,

    CONSTRAINT pk_pacientes PRIMARY KEY (id_paciente),
    CONSTRAINT uq_paciente_dni UNIQUE (dni)
);

-- ------------------------------------------------------------
-- TABLA: turnos
-- Núcleo operacional del sistema — registro de todos los turnos
-- Estado posibles: Confirmado | Completado | Cancelado | Ausente
-- ------------------------------------------------------------
CREATE TABLE turnos (
    id_turno            INT             NOT NULL AUTO_INCREMENT,
    id_paciente         INT             NOT NULL,
    id_medico           INT             NOT NULL,
    fecha_turno         DATE            NOT NULL,
    hora_turno          TIME            NOT NULL,
    estado              ENUM(
                            'Confirmado',
                            'Completado',
                            'Cancelado',
                            'Ausente'
                        )               NOT NULL DEFAULT 'Confirmado',
    motivo_consulta     VARCHAR(255)    NULL,
    observaciones       TEXT            NULL,
    fecha_creacion      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion DATETIME        NULL ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_turnos PRIMARY KEY (id_turno),
    CONSTRAINT fk_turno_paciente FOREIGN KEY (id_paciente)
        REFERENCES pacientes (id_paciente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_turno_medico FOREIGN KEY (id_medico)
        REFERENCES medicos (id_medico)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT uq_turno_medico_fecha_hora UNIQUE (id_medico, fecha_turno, hora_turno)
);

-- ------------------------------------------------------------
-- TABLA: alertas_log
-- Registro de alertas automáticas generadas por n8n
-- Permite trazabilidad y auditoría del sistema de alertas
-- ------------------------------------------------------------
CREATE TABLE alertas_log (
    id_alerta           INT             NOT NULL AUTO_INCREMENT,
    tipo_alerta         ENUM(
                            'AUSENTISMO_CRITICO',
                            'MEDICO_SOBRECARGADO',
                            'CAIDA_DEMANDA',
                            'REPORTE_SEMANAL'
                        )               NOT NULL,
    descripcion         VARCHAR(500)    NOT NULL,
    valor_detectado     DECIMAL(10,2)   NOT NULL,
    umbral_configurado  DECIMAL(10,2)   NOT NULL,
    fecha_alerta        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enviada             TINYINT(1)      NOT NULL DEFAULT 0,
    fecha_envio         DATETIME        NULL,
    destinatario        VARCHAR(150)    NULL,

    CONSTRAINT pk_alertas_log PRIMARY KEY (id_alerta)
);

-- ============================================================
-- ÍNDICES DE PERFORMANCE
-- Optimizan las queries analíticas más frecuentes
-- ============================================================

-- Índices en turnos para análisis temporal y por estado
CREATE INDEX idx_turnos_fecha        ON turnos (fecha_turno);
CREATE INDEX idx_turnos_estado       ON turnos (estado);
CREATE INDEX idx_turnos_medico       ON turnos (id_medico);
CREATE INDEX idx_turnos_paciente     ON turnos (id_paciente);

-- Índice compuesto para queries de KPI más comunes
CREATE INDEX idx_turnos_medico_fecha ON turnos (id_medico, fecha_turno);
CREATE INDEX idx_turnos_fecha_estado ON turnos (fecha_turno, estado);

-- Índice en alertas para consultas por tipo y fecha
CREATE INDEX idx_alertas_tipo        ON alertas_log (tipo_alerta);
CREATE INDEX idx_alertas_fecha       ON alertas_log (fecha_alerta);

-- ============================================================
-- VISTAS ANALÍTICAS
-- Pre-calculan métricas clave para Power BI y n8n
-- ============================================================

-- Vista: resumen mensual de turnos por estado
CREATE VIEW vw_turnos_mensual AS
SELECT
    YEAR(fecha_turno)                           AS anio,
    MONTH(fecha_turno)                          AS mes,
    DATE_FORMAT(fecha_turno, '%Y-%m')           AS periodo,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Completado')                  AS completados,
    SUM(estado = 'Ausente')                     AS ausentes,
    SUM(estado = 'Cancelado')                   AS cancelados,
    SUM(estado = 'Confirmado')                  AS confirmados,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo,
    ROUND(SUM(estado = 'Cancelado') * 100.0
        / COUNT(*), 2)                          AS tasa_cancelacion
FROM turnos
GROUP BY anio, mes, periodo;

-- Vista: ocupación semanal por médico
CREATE VIEW vw_ocupacion_medico AS
SELECT
    m.id_medico,
    m.nombre,
    m.apellido,
    e.nombre                                    AS especialidad,
    YEARWEEK(t.fecha_turno, 1)                  AS semana,
    COUNT(*)                                    AS total_turnos,
    SUM(t.estado = 'Completado')                AS completados,
    SUM(t.estado = 'Ausente')                   AS ausentes,
    ROUND(COUNT(*) * 100.0 / 10, 2)            AS porcentaje_ocupacion
FROM turnos t
INNER JOIN medicos m        ON t.id_medico      = m.id_medico
INNER JOIN especialidades e ON m.id_especialidad = e.id_especialidad
GROUP BY m.id_medico, m.nombre, m.apellido, e.nombre, semana;

-- Vista: KPI semanal para alertas n8n
CREATE VIEW vw_kpi_semanal AS
SELECT
    YEARWEEK(fecha_turno, 1)                    AS semana,
    MIN(fecha_turno)                            AS inicio_semana,
    COUNT(*)                                    AS total_turnos,
    SUM(estado = 'Ausente')                     AS ausentes,
    SUM(estado = 'Completado')                  AS completados,
    ROUND(SUM(estado = 'Ausente') * 100.0
        / COUNT(*), 2)                          AS tasa_ausentismo,
    ROUND(SUM(estado = 'Completado') * 100.0
        / COUNT(*), 2)                          AS tasa_efectividad
FROM turnos
GROUP BY semana;

-- ============================================================
-- VERIFICACIÓN FINAL
-- ============================================================
SELECT 'ClarVision DB creada exitosamente' AS status;
SHOW TABLES;
