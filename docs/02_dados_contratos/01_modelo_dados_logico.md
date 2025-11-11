# **Modelo de Dados — Lógico (POC Soluções EV-Costa)**

## 1. Objetivo
Apresentar o **modelo lógico de dados** baseado no modelo conceitual, com detalhamento de tipos, chaves, índices, constraints e padrões aplicados no **PostgreSQL** (banco transacional principal).

---

## 2. Padrões Gerais de Modelagem

| Tipo de Campo | Padrão | Exemplo |
|----------------|--------|---------|
| Identificadores | `UUID v7` | `user.id`, `session.id` |
| Datas e Horas | `TIMESTAMP WITH TIME ZONE (UTC)` | `created_at`, `ended_at` |
| Campos Monetários | `NUMERIC(12,2)` | `amount` |
| JSONs configuráveis | `JSONB` | `prefs`, `metadata` |
| Localização | `GEOGRAPHY(Point, 4326)` | `location` |
| Textos curtos | `VARCHAR(255)` | `email_tokenized`, `name_min` |
| Flags e estados | `BOOLEAN` ou `ENUM` | `is_active`, `status` |

---

## 3. Entidades Principais

### **user**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Identificador único do usuário |
| name_min | VARCHAR(100) | NOT NULL | Primeiro nome (minimizado) |
| email_tokenized | VARCHAR(255) | UNIQUE, NOT NULL | Token do e-mail |
| phone_tokenized | VARCHAR(50) | UNIQUE | Token do telefone |
| prefs | JSONB | NULL | Preferências do usuário |
| tenant_id | UUID | NULL | Suporte a multi-tenant |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data de criação |

---

### **vehicle**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Identificador do veículo |
| user_id | UUID | FK → user(id) | Dono do veículo |
| make_model | VARCHAR(100) | NOT NULL | Marca e modelo |
| year | INT | NULL | Ano de fabricação |
| autonomy_km | INT | NULL | Autonomia máxima em km |
| connector_type | VARCHAR(50) | NULL | Tipo de conector (CCS2, Type2) |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data de criação |

---

### **charging_station**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Identificador da estação |
| name | VARCHAR(120) | NOT NULL | Nome amigável |
| location | GEOGRAPHY(Point, 4326) | NOT NULL | Coordenadas geográficas |
| address_min | VARCHAR(255) | NULL | Endereço resumido |
| amenities | JSONB | NULL | Serviços adicionais |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data de criação |

---

### **charging_point**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Identificador do ponto |
| station_id | UUID | FK → charging_station(id) | Estação associada |
| external_id | VARCHAR(100) | UNIQUE | ID no provedor externo |
| power_kw | INT | NULL | Potência |
| connector_type | VARCHAR(50) | NULL | Tipo de conector |
| status | VARCHAR(30) | DEFAULT 'available' | Status atual |
| last_update | TIMESTAMPTZ | DEFAULT now() | Última atualização |

---

### **charging_session**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Sessão de recarga |
| user_id | UUID | FK → user(id) | Usuário |
| vehicle_id | UUID | FK → vehicle(id) | Veículo |
| point_id | UUID | FK → charging_point(id) | Ponto de recarga |
| started_at | TIMESTAMPTZ | NULL | Início |
| ended_at | TIMESTAMPTZ | NULL | Fim |
| energy_kwh | NUMERIC(10,2) | NULL | Energia consumida |
| status | VARCHAR(20) | DEFAULT 'created' | Estado |
| created_at | TIMESTAMPTZ | DEFAULT now() | Criação |

---

### **payment_method**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Método de pagamento |
| user_id | UUID | FK → user(id) | Dono |
| provider | VARCHAR(100) | NOT NULL | Provedor (ex.: Stripe, Adyen) |
| token_ref | VARCHAR(255) | NOT NULL | Token seguro (não-PCI) |
| is_3ds_enabled | BOOLEAN | DEFAULT false | Autenticação 3DS |
| created_at | TIMESTAMPTZ | DEFAULT now() | Data de criação |

---

### **payment_tx**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Transação de pagamento |
| user_id | UUID | FK → user(id) | Usuário |
| session_id | UUID | FK → charging_session(id) | Sessão relacionada |
| amount | NUMERIC(12,2) | NOT NULL | Valor |
| currency | VARCHAR(3) | DEFAULT 'BRL' | Moeda |
| status | VARCHAR(20) | DEFAULT 'pending' | Estado |
| metadata | JSONB | NULL | Dados adicionais |
| created_at | TIMESTAMPTZ | DEFAULT now() | Criação |

---

### **invoice**
| Campo | Tipo | Restrição | Descrição |
|--------|------|------------|------------|
| id | UUID | PK | Fatura |
| payment_tx_id | UUID | FK → payment_tx(id) | Pagamento vinculado |
| issued_at | TIMESTAMPTZ | DEFAULT now() | Emissão |
| status | VARCHAR(20) | DEFAULT 'issued' | Estado |
| pdf_link | VARCHAR(512) | NULL | Link para documento assinado |

---

### **route / waypoint / poi**
Estruturas auxiliares ligadas ao planejamento de rotas.

| Entidade | Campos Chave | Descrição |
|-----------|---------------|-----------|
| **route** | origem/destino, distância, tempo | Representa uma rota planejada |
| **waypoint** | ordem, coordenadas | Ponto intermediário |
| **poi** | estação sugerida, razão | Ponto de recarga recomendado |

---

## 4. Índices Recomendados

| Tabela | Índice | Tipo |
|---------|---------|------|
| user | `email_tokenized`, `phone_tokenized` | UNIQUE |
| charging_station | `location` | GiST |
| charging_session | `(user_id, started_at DESC)` | BTREE |
| payment_tx | `(user_id, session_id)` | BTREE |
| provider_asset | `(provider_id, external_id)` | UNIQUE |

---

## 5. Particionamento e Storage
- **`charging_session`**: particionada por mês (`started_at`), facilitando expurgo e relatórios.  
- **`payment_tx` e `invoice`**: agrupadas por período fiscal (ano/mês).  
- **`charging_point.status`**: armazenado parcialmente em cache Redis (TTL curto).

---

## 6. Políticas de Segurança (SQL-Level)

CREATE POLICY user_isolation_policy ON user
  USING (id = current_setting('app.current_user_id')::uuid);

ALTER TABLE user ENABLE ROW LEVEL SECURITY;

- **Objetivo:** Isolar dados dados por usuário autenticado.
- **View Minimizada:** Apenas campos não sensiveis expostos via API. 

---

## 7. Extensões Recomendadas PostgreSQL

- **uuid-ossp** → geração de UUIDs.  
- **postgis** → geolocalização.  
- **pgcrypto** → criptografia de colunas.  
- **pg_partman** → particionamento automático.  
- **pg_stat_statements** → análise de desempenho.

---

## 8. Próximos Artefatos

- `02_catalogo_APIs_eventos.md` — contratos REST + eventos.  
- `03_modelo_dados_fisico.sql` — DDL inicial para PostgreSQL.  
- `scripts/migrations/` — migrações versionadas (Liquibase/Flyway).

---

**Responsável:** Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:** Engenharia de Dados / Segurança / DevOps

