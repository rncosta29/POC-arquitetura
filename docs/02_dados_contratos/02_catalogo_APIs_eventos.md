# **Catálogo de APIs e Eventos — POC Soluções EV-Costa**

## 1. Objetivo
Descrever os principais **contratos REST** e **eventos assíncronos (Kafka)** dos microsserviços da POC *Soluções EV-Costa*, com foco em interoperabilidade, rastreabilidade e padronização de mensagens.

---

## 2. Padrões Gerais de API

| Item | Padrão | Descrição |
|------|---------|------------|
| **Protocolo** | HTTPS + JSON | Todas as chamadas via TLS 1.3 |
| **Autenticação** | OAuth2 / OIDC (Keycloak) | Token Bearer |
| **Versionamento** | `v1`, `v2` via path | `/api/v1/users` |
| **Formatação de datas** | ISO-8601 (UTC) | `2025-11-07T14:00:00Z` |
| **Paginação** | `page`, `size`, `sort` | Padrão Spring Pageable |
| **Erro padrão** | RFC 7807 (Problem+JSON) | Campos: `status`, `title`, `detail`, `traceId` |

---

## 3. Principais Endpoints REST (v1)

### **Auth Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `POST` | `/auth/login` | Autentica usuário e gera token JWT |
| `POST` | `/auth/refresh` | Renova tokens de acesso |
| `POST` | `/auth/register` | Cria novo usuário |
| `POST` | `/auth/logout` | Invalida o token ativo |

---

### **User/Profile Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `GET` | `/users/me` | Retorna o perfil do usuário logado |
| `PATCH` | `/users/me` | Atualiza dados do perfil |
| `GET` | `/users/me/vehicles` | Lista veículos do usuário |
| `POST` | `/users/me/vehicles` | Adiciona novo veículo |
| `GET` | `/users/me/payments` | Lista métodos de pagamento |

---

### **Routing Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `POST` | `/routing/plan` | Calcula rota otimizada com base na autonomia |
| `GET` | `/routing/history` | Lista rotas recentes do usuário |
| `GET` | `/routing/suggestions` | Retorna sugestões de pontos de recarga |

---

### **Charging Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `POST` | `/charging/start` | Inicia sessão de recarga |
| `POST` | `/charging/stop` | Encerra sessão de recarga |
| `GET` | `/charging/session/{id}` | Consulta detalhes da sessão |
| `GET` | `/charging/status/{pointId}` | Retorna status atual do ponto |

---

### **Payment Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `POST` | `/payments/authorize` | Autoriza pagamento (pré-autorização) |
| `POST` | `/payments/capture` | Captura pagamento após recarga |
| `GET` | `/payments/status/{txId}` | Consulta status da transação |
| `GET` | `/invoices/{invoiceId}` | Baixa fatura PDF segura |

---

### **Integration Service**
| Método | Endpoint | Descrição |
|---------|-----------|-----------|
| `GET` | `/integrations/providers` | Lista provedores ativos (DSA-X, Shell, etc) |
| `GET` | `/integrations/stations` | Busca estações externas |
| `POST` | `/integrations/sync` | Sincroniza dados de provedores |

---

## 4. Estrutura de Mensagem — REST (Exemplo)

{
  "status": "started",
  "sessionId": "a2e17b6b-fb23-41d8-bef4-122cb9b81b4a",
  "pointId": "cdbcb8da-e00a-4d7f-8f79-709b63ec4c28",
  "vehicleId": "8a0df173-7b71-4e0e-b0aa-f1c7d4d2e6d4",
  "energyKwh": 0.0,
  "startedAt": "2025-11-07T13:00:00Z",
  "traceId": "4fb77e31d8a742d3b845e2e80efae44e"
}

---

## 5. Eventos Assíncronos (Kafka)

| **Tópico** | **Origem** | **Descrição** | **Esquema (valor)** |
|-------------|-------------|----------------|----------------------|
| `evcosta.charging.session.started` | Charging Service | Início de recarga | `charging_session_started.json` |
| `evcosta.charging.session.ended` | Charging Service | Fim de recarga | `charging_session_ended.json` |
| `evcosta.payment.authorized` | Payment Service | Pagamento autorizado | `payment_authorized.json` |
| `evcosta.payment.captured` | Payment Service | Pagamento capturado | `payment_captured.json` |
| `evcosta.payment.failed` | Payment Service | Pagamento rejeitado | `payment_failed.json` |
| `evcosta.integration.station.updated` | Integration Service | Atualização de status de ponto | `station_updated.json` |


{
  "eventId": "c4f3b2e7-77e3-49f3-90e3-493a7e9e28ce",
  "type": "charging.session.ended",
  "timestamp": "2025-11-07T14:45:00Z",
  "payload": {
    "sessionId": "a2e17b6b-fb23-41d8-bef4-122cb9b81b4a",
    "userId": "d2b98f7e-8bbf-4b6f-b8d0-2a9dc46b21a3",
    "vehicleId": "8a0df173-7b71-4e0e-b0aa-f1c7d4d2e6d4",
    "energyKwh": 28.3,
    "durationMin": 37,
    "totalValue": 41.50,
    "currency": "BRL",
    "status": "completed"
  },
  "correlationId": "4fb77e31d8a742d3b845e2e80efae44e",
  "source": "charging-service"
}

---

## 6. Padrões e Convenções de Eventos

- **Chaves Kafka:** `eventId` como UUID v7.  
- **Formato:** JSON com cabeçalho `type`, `timestamp`, `payload`, `source`, `correlationId`.  
- **Entrega:** *at least once* (com deduplicação idempotente).  
- **Schema Registry:** todos os eventos validados via **Confluent Schema Registry**.  
- **Ordem lógica:** garantida por chave de partição `sessionId` ou `paymentTxId`.

---

## 7. Observabilidade e Auditoria

- Cada request e evento inclui `traceId` e `spanId` (OpenTelemetry).  
- Auditoria armazenada em tabela `audit_log` com os campos:
  - `event_type`, `user_id`, `timestamp`, `payload_digest`.  
- Métricas expostas via endpoint `/actuator/metrics` (Spring Boot).

---

## 8. Próximos Artefatos Relacionados

| **Arquivo** | **Descrição** |
|--------------|----------------|
| `03_modelo_dados_fisico.sql` | DDL físico (PostgreSQL) |
| `openapi_v1.yaml` | Esquema OpenAPI resumido (v1) |
| `events_catalog.json` | Schemas detalhados dos tópicos Kafka |

---

**Responsável:** Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:** Engenharia de Integração / Backend / Segurança / SRE
