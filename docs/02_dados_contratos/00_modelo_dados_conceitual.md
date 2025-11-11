# **Modelo de Dados — Conceitual (POC Soluções EV-Costa)**

## 1. Objetivo
Descrever o **modelo conceitual de dados** da POC, cobrindo entidades, relacionamentos e regras de negócio essenciais.  
Foco: **PostgreSQL** como banco transacional, **Redis** para cache (sessões/rotas) e **Kafka** para eventos de domínio (fora deste escopo detalhado).

> **Premissas**
> - Dados pessoais **minimizados** e **tokenizados** conforme LGPD.  
> - Identificadores **UUID v7** para unicidade e ordenação temporal.  
> - Multi-tenant opcional via campo `tenant_id`.

---

## 2. Visão Geral (ER Conceitual)

erDiagram
    USER ||--o{ VEHICLE : "possui"
    USER ||--o{ PAYMENT_METHOD : "cadastra"
    USER ||--o{ ROUTE : "planeja"
    USER ||--o{ CHARGING_SESSION : "inicia/encerra"

    VEHICLE ||--o{ ROUTE : "informa SoC/autonomia"
    CHARGING_STATION ||--o{ CHARGING_POINT : "contém"
    CHARGING_POINT ||--o{ CHARGING_SESSION : "executa"

    PAYMENT_METHOD ||--o{ PAYMENT_TX : "autorização/captura"
    CHARGING_SESSION ||--|| PAYMENT_TX : "pré-autorização/fechamento"
    PAYMENT_TX ||--o{ INVOICE : "gera"

    ROUTE ||--o{ WAYPOINT : "compõe"
    ROUTE ||--o{ POI : "sugere recarga"
    PROVIDER ||--o{ PROVIDER_ASSET : "estações/external ids"
    PROVIDER_ASSET ||--o{ CHARGING_POINT : "mapeia"

---

## 3. Entidades Principais

### **User**
- **Campos mínimos (LGPD):** `email_tokenized`, `phone_tokenized`, `name_min` (primeiro nome apenas).  
- **Preferências (`prefs`):** idioma, unidade (km/mi), tema e consentimentos LGPD.  
- **Segurança:** dados sensíveis sempre **tokenizados** ou mascarados.

---

### **Vehicle**
- **Relacionamento:** vinculado a `User`.  
- **Campos principais:** `autonomy_km`, `connector_type` (ex.: CCS2, Type2).  
- **Uso:** base para o cálculo de rotas e paradas no módulo **Routing**.

---

### **ChargingStation / ChargingPoint**
- **ChargingStation:** representa o local físico da estação de recarga.  
- **ChargingPoint:** representa o conector individual, com potência e status dinâmico.  
- **Status:** atualizado via integrações externas, armazenado em **cache TTL (Redis)**.

---

### **ChargingSession**
- **Ciclo de vida:** `created → authorized → started → stopping → ended → invoiced`.  
- **Dados armazenados:** `energy_kwh`, duração total e custo estimado.  
- **Eventos:** publica atualizações no **Kafka** para monitoramento e faturamento.

---

### **PaymentMethod / PaymentTx / Invoice**
- **PaymentMethod:** referência tokenizada (`token_ref`), **não-PCI**.  
- **PaymentTx:** vincula a sessão, realiza pré-autorização e captura.  
- **Invoice:** gera e disponibiliza artefato PDF assinado, com **URL segura**.

---

### **Route / Waypoint / POI**
- **Route:** define origem, destino, tempo e distância estimados.  
- **Waypoint:** ordena coordenadas geográficas (trajeto).  
- **POI:** sugere pontos de recarga, com motivo (autonomia, preço, potência).

---

### **Provider / ProviderAsset**
- **Função:** camada de anti-corrupção — mapeia IDs externos de provedores (ex.: DSA-X, Shell Recharge).  
- **Dados:** mantém `external_id` e metadados adicionais para reconciliação.

---

## 4. Regras e Restrições Conceituais

### **Integridade**
- `ChargingPoint.station_id` é **obrigatório**.  
- `ChargingSession.point_id`, `user_id`, `vehicle_id` são **obrigatórios**.  
- `PaymentTx.session_id` e `Invoice.payment_tx_id` são **obrigatórios**.

### **Cardinalidades**
- `User` → *N* `Vehicle`, *N* `PaymentMethod`, *N* `Route`, *N* `ChargingSession`.  
- `ChargingStation` → *N* `ChargingPoint`.  
- `Route` → *N* `Waypoint`, *N* `POI`.

### **Geo e Dados**
- Campos de geolocalização usam **PostGIS (SRID 4326)**.  
- Valores monetários seguem **ISO 4217**, armazenados em **centavos** (`NUMERIC(12,2)`).

---

## 5. Estratégias de Identificação e Chaves
- **Chaves primárias:** `UUID v7` em todas as tabelas.  
- **Chaves estrangeiras:** `<referenced>_id` (ex.: `user_id`).  
- **Índices únicos:** `(provider_id, external_id)` em `ProviderAsset`.  
- **Correlação de eventos:** via `event_id` e `correlation_id` (Kafka).

---

## 6. Particionamento e Índices
- **Temporal:** `ChargingSession` particionada por `started_at`.  
- **Geoespacial:** índices **GiST** em `ChargingStation.location`.  
- **Performance:** índices em `user_id` para consultas frequentes no app.  
- **Provedores:** índice único `(provider_id, external_id)` para deduplicação.

---

## 7. LGPD e Segurança de Dados
- **Minimização:** armazenar apenas o necessário.  
- **Tokenização:** aplicada a e-mails, telefones e métodos de pagamento.  
- **Criptografia:**  
  - Em repouso: **TDE** e criptografia de colunas sensíveis.  
  - Em trânsito: **TLS 1.3**.  
- **Retenção:** conforme regras fiscais (ex.: faturas mantidas por 5 anos).  
- **Acesso:** controlado por **RBAC**; relatórios usam *views* anonimizadas.

---

## 8. Padrões de Acesso
- **Perfil do usuário:** `User` + `Vehicle` + `PaymentMethod`.  
- **Mapa:** listar estações próximas usando `ST_DWithin` (filtros: potência, preço).  
- **Rotas:** criar rotas com `waypoints` e `POI` sugeridos.  
- **Sessões:** iniciar, atualizar e encerrar recargas.  
- **Faturas:** recuperar `Invoice` associada a `PaymentTx`.

---

## 9. Convenções de Nomeação

| Tipo | Convenção | Exemplo |
|------|------------|---------|
| Tabela | `snake_case` singular | `charging_session` |
| PK | `id` (`UUID`) | — |
| FK | `<referenced>_id` | `user_id`, `vehicle_id` |
| Data/Hora | `*_at` (UTC) | `started_at` |
| Booleanos | prefixo `is_`, `has_` | `is_active`, `has_payment` |

---

## 10. Próximos Artefatos Relacionados
- `01_modelo_dados_logico.md` — modelo lógico detalhado.  
- `02_catalogo_APIs_eventos.md` — catálogo OpenAPI + eventos.  
- `schemas/openapi_v1.yaml` — contrato técnico inicial.  
- `events_catalog.json` — catálogo de eventos Kafka (sessão, pagamento, invoice).

---

**Responsável:** Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:** Engenharia de Dados / Segurança da Informação / SRE

