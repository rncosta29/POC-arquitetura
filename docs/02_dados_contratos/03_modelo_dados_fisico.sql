-- ============================================================
--  Soluções EV-Costa — Modelo de Dados Físico (PostgreSQL)
--  Versão: v1.0 (POC)
--  Autor: Arquiteto de Software — Soluções EV-Costa
--  Revisores: Engenharia de Dados / Segurança / DevOps
-- ============================================================

-- Extensões necessárias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_partman";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ============================================================
--  Tabela: user
-- ============================================================

CREATE TABLE "user" (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_min VARCHAR(100) NOT NULL,
    email_tokenized VARCHAR(255) UNIQUE NOT NULL,
    phone_tokenized VARCHAR(50) UNIQUE,
    prefs JSONB,
    tenant_id UUID,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
--  Tabela: vehicle
-- ============================================================

CREATE TABLE vehicle (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    make_model VARCHAR(100) NOT NULL,
    year INT,
    autonomy_km INT,
    connector_type VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_vehicle_user_id ON vehicle(user_id);

-- ============================================================
--  Tabela: charging_station
-- ============================================================

CREATE TABLE charging_station (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(120) NOT NULL,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    address_min VARCHAR(255),
    amenities JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_station_location ON charging_station USING GIST(location);

-- ============================================================
--  Tabela: charging_point
-- ============================================================

CREATE TABLE charging_point (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    station_id UUID NOT NULL REFERENCES charging_station(id) ON DELETE CASCADE,
    external_id VARCHAR(100) UNIQUE,
    power_kw INT,
    connector_type VARCHAR(50),
    status VARCHAR(30) DEFAULT 'available',
    last_update TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_point_station_id ON charging_point(station_id);

-- ============================================================
--  Tabela: charging_session
-- ============================================================

CREATE TABLE charging_session (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES "user"(id),
    vehicle_id UUID NOT NULL REFERENCES vehicle(id),
    point_id UUID NOT NULL REFERENCES charging_point(id),
    started_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,
    energy_kwh NUMERIC(10,2),
    status VARCHAR(20) DEFAULT 'created',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_session_user_id_started_at ON charging_session(user_id, started_at DESC);

-- ============================================================
--  Tabela: payment_method
-- ============================================================

CREATE TABLE payment_method (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES "user"(id),
    provider VARCHAR(100) NOT NULL,
    token_ref VARCHAR(255) NOT NULL,
    is_3ds_enabled BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payment_user_id ON payment_method(user_id);

-- ============================================================
--  Tabela: payment_tx
-- ============================================================

CREATE TABLE payment_tx (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES "user"(id),
    session_id UUID NOT NULL REFERENCES charging_session(id),
    amount NUMERIC(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BRL',
    status VARCHAR(20) DEFAULT 'pending',
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_payment_tx_user_session ON payment_tx(user_id, session_id);

-- ============================================================
--  Tabela: invoice
-- ============================================================

CREATE TABLE invoice (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    payment_tx_id UUID NOT NULL REFERENCES payment_tx(id),
    issued_at TIMESTAMPTZ DEFAULT now(),
    status VARCHAR(20) DEFAULT 'issued',
    pdf_link VARCHAR(512)
);

-- ============================================================
--  Tabela: route
-- ============================================================

CREATE TABLE route (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES "user"(id),
    vehicle_id UUID NOT NULL REFERENCES vehicle(id),
    origin GEOGRAPHY(Point, 4326) NOT NULL,
    destination GEOGRAPHY(Point, 4326) NOT NULL,
    estimated_km INT,
    estimated_time_min INT,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_route_user_id ON route(user_id);

-- ============================================================
--  Tabela: waypoint
-- ============================================================

CREATE TABLE waypoint (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES route(id) ON DELETE CASCADE,
    location GEOGRAPHY(Point, 4326) NOT NULL,
    order_idx INT,
    is_charge_stop BOOLEAN DEFAULT false
);

CREATE INDEX idx_waypoint_route_id ON waypoint(route_id);

-- ============================================================
--  Tabela: poi
-- ============================================================

CREATE TABLE poi (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id UUID NOT NULL REFERENCES route(id) ON DELETE CASCADE,
    station_id UUID REFERENCES charging_station(id),
    order_idx INT,
    reason VARCHAR(50)
);

CREATE INDEX idx_poi_route_id ON poi(route_id);

-- ============================================================
--  Tabela: provider / provider_asset
-- ============================================================

CREATE TABLE provider (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50)
);

CREATE TABLE provider_asset (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_id UUID NOT NULL REFERENCES provider(id),
    external_id VARCHAR(255) NOT NULL,
    extra JSONB,
    UNIQUE (provider_id, external_id)
);

-- ============================================================
--  Segurança e Auditoria
-- ============================================================

CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(100),
    user_id UUID,
    timestamp TIMESTAMPTZ DEFAULT now(),
    payload_digest VARCHAR(256)
);

-- ============================================================
--  Políticas de Segurança (RLS)
-- ============================================================

ALTER TABLE "user" ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_isolation_policy ON "user"
  USING (id = current_setting('app.current_user_id')::uuid);

-- ============================================================
--  Comentários e Metadados
-- ============================================================

COMMENT ON TABLE "user" IS 'Usuários do sistema — dados minimizados e tokenizados (LGPD)';
COMMENT ON COLUMN "user".email_tokenized IS 'E-mail tokenizado (não armazenar em claro)';
COMMENT ON COLUMN payment_tx.amount IS 'Valor em centavos (NUMERIC(12,2))';
COMMENT ON COLUMN charging_session.energy_kwh IS 'Energia total consumida (kWh)';

-- ============================================================
--  Fim do modelo físico v1.0
-- ============================================================
