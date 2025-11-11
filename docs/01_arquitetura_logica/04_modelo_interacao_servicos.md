# **Modelo de Interação entre Serviços — POC Soluções EV-Costa**

## **1. Objetivo**
Este documento descreve os **padrões de interação entre os microsserviços**, destacando os fluxos síncronos (REST) e assíncronos (Kafka).  
O objetivo é garantir comunicação previsível, observável e segura entre os domínios, reduzindo acoplamento e facilitando evolução futura.

---

## **2. Tipos de Comunicação**

| Tipo | Canal | Uso | Exemplo |
|------|--------|-----|----------|
| **Síncrona (REST/HTTPS)** | API Gateway → Microsserviços | Operações transacionais e interativas. | Login, consulta de perfil, cálculo de rota. |
| **Assíncrona (Eventos Kafka)** | Microsserviço → Kafka → Consumidor | Processamento eventual e notificações. | Início de sessão de recarga, pagamento confirmado. |
| **Mensageria Interna (Redis / PubSub)** | Microsserviços core | Comunicação leve e temporária entre instâncias. | Cache de sessões, rate limiting. |

---

## **3. Padrão de Integração Síncrona (REST)**

sequenceDiagram
    participant App as Mobile App
    participant GW as API Gateway
    participant AU as Auth Service
    participant US as User Service
    participant RT as Routing Service
    participant CH as Charging Service
    participant PY as Payment Service

    App->>GW: Login (POST /auth/login)
    GW->>AU: Verifica credenciais / emite token JWT
    AU-->>GW: Token + refresh
    GW-->>App: Retorna token de acesso

    App->>GW: Solicita rota otimizada (GET /routing)
    GW->>RT: Calcula rota EV com base em SoC e POIs
    RT-->>GW: Rota otimizada
    GW-->>App: Exibe rota com pontos de carga

    App->>GW: Inicia recarga (POST /charging/start)
    GW->>CH: Cria sessão de recarga
    CH->>PY: Solicita pré-autorização de pagamento
    PY-->>CH: Confirma simulação
    CH-->>GW: Retorna ID da sessão
    GW-->>App: Sessão iniciada

---

## **4. Padrão de Integração Assíncrona (Eventos Kafka)**

graph LR
  CH[Charging Service] -->|Evento: ChargingSessionStarted| KAFKA[(Kafka Topic: charging.events)]
  PY[Payment Service] -->|Evento: PaymentAuthorized| KAFKA
  IN[Integrations Adapter] -->|Evento: ExternalUpdate| KAFKA

  KAFKA --> CH
  KAFKA --> PY
  KAFKA --> IN
  KAFKA --> OBS[Observabilidade / OpenTelemetry Collector]

### Tópicos Kafka Planejados

| Tópico | Origem | Consumidores | Descrição |
| :--- | :--- | :--- | :--- |
| `charging.events` | Charging Service | Payment, Integrations | Eventos de início, atualização e encerramento de recarga. |
| `payment.events` | Payment Service | Charging, Integrations | Eventos de simulação, autorização e falha de pagamento. |
| `integration.events` | Integrations | Charging | Atualizações de provedores externos. |

---

## 5. Segurança na Comunicação

* Todas as requisições REST utilizam **`TLS 1.3`** e são autenticadas via **`OIDC JWT`**.
* Cada evento Kafka contém `traceId` e `userId` pseudonimizado.
* O acesso aos tópicos Kafka é **segmentado por ACL** (Access Control List).
* Nenhum dado pessoal é trafegado em texto claro.
* Tokens de acesso possuem tempo de vida curto (≤ 15 min) e rotação automática.

## 6. Observabilidade e Rastreamento

* Todos os fluxos (REST e Kafka) propagam `traceId` e `spanId` via **OpenTelemetry Context**.
* Logs estruturados (JSON) são correlacionados por `service.name` e `traceId`.
* Dashboards Grafana exibem:
    * Latência p95 por serviço.
    * Throughput de eventos Kafka.
    * Taxa de erro por endpoint.
* **Jaeger** será usado para visualizar o fluxo ponta a ponta de cada requisição.
* (Inserir imagem flat moderna: fluxo de requisição com `traceId` percorrendo APIs e eventos Kafka)

## 7. Padrões de Erro e Idempotência

* Erros REST seguem o padrão **`RFC 7807 (Problem Details for HTTP APIs)`**.
* Operações críticas (ex: `/charging/start`) possuem `idempotency-key` no cabeçalho.
* Eventos Kafka incluem `eventId` e `correlationId` para deduplicação e replay seguro.

## 8. Políticas de Timeout e Retry

| Canal | Timeout | Retry Policy | Estratégia |
| :--- | :--- | :--- | :--- |
| REST | 5s | 3 tentativas com backoff exponencial | Circuit Breaker |
| Kafka | 10s | Reprocessamento via Dead Letter Queue | Retentativas seguras |
| Redis | 2s | No retry | Foco em performance |

## 9. Diretrizes de Evolução

* Avaliar uso de **`gRPC`** para chamadas inter-serviços no MVP.
* Introduzir **Schema Registry** para versionamento de eventos Kafka.
* Automatizar rastreabilidade de fluxos via **Service Map (Grafana Tempo)**.
* Revisar política de **QoS (Quality of Service)** para tópicos críticos.

---

**Responsável:**
Arquiteto de Software — *Soluções EV-Costa*

**Revisores:**
Engenharia Backend / SRE / Observabilidade
