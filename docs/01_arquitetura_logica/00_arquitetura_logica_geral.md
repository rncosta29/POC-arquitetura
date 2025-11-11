# **Arquitetura Lógica Geral — POC Soluções EV-Costa**

## **1. Objetivo**
Este documento apresenta a **arquitetura lógica** da *POC Soluções EV-Costa*, descrevendo seus componentes principais, domínios de negócio, integrações e padrões de comunicação.  
Seu propósito é garantir uma visão única e rastreável da estrutura da solução antes da implementação do MVP.

---

## **2. Princípios de Arquitetura**
A arquitetura da POC segue princípios modernos de **cloud-native design** e **Domain-Driven Design (DDD leve)**:

1. **Desacoplamento e modularidade** — cada domínio é isolado por responsabilidade.  
2. **Escalabilidade independente** — serviços podem evoluir separadamente.  
3. **Observabilidade integrada** — logs, métricas e tracing em todos os fluxos.  
4. **Segurança por design** — autenticação, autorização e isolamento de dados.  
5. **Resiliência e automação** — tratamento de falhas, filas assíncronas e autoescalonamento.  
6. **Governança leve e versionável** — decisões documentadas via ADRs e versionamento Git.

---

## **3. Camadas Lógicas**
A solução é organizada em cinco camadas principais:

| Camada | Descrição | Componentes |
|---------|------------|--------------|
| **Apresentação (Frontend)** | Interação com o usuário final através dos aplicativos móveis nativos. | Apps iOS (SwiftUI) / Android (Kotlin) |
| **Gateway / API Layer** | Ponto único de entrada autenticado (ingress, TLS, rate limit, OIDC). | API Gateway / Kong / NGINX ingress |
| **Domínio de Negócio** | Regras centrais e operações do ecossistema EV. | Auth, User/Profile, Routing, Charging, Payment |
| **Integrações Externas** | Conectores para provedores e parceiros de energia/pagamento. | DSA-X, Shell Recharge, Premmia, Eletrograal |
| **Infraestrutura e Observabilidade** | Suporte técnico, segurança, mensageria e telemetria. | Kafka, PostgreSQL, Redis, OpenTelemetry, Prometheus |

---

## **4. Componentes Principais**

### **4.1 Auth Service**
- Responsável por autenticação e autorização via OIDC (Keycloak/Auth0).  
- Emite tokens JWT com escopos e claims definidos.  
- Gerencia refresh tokens e sessão segura.  

### **4.2 User/Profile Service**
- Cadastro, atualização e gerenciamento de perfis de usuários.  
- Armazena dados pessoais tokenizados e anonimizáveis.  
- Expõe APIs REST para uso dos aplicativos móveis.  

### **4.3 Routing Service**
- Calcula rotas otimizadas com base na autonomia do veículo e disponibilidade de pontos de carga.  
- Usa integração simulada com GraphHopper ou OSRM.  
- Armazena resultados em cache (Redis) para otimização.  

### **4.4 Charging Service**
- Gerencia sessões de recarga (início, status, encerramento).  
- Emite eventos Kafka representando mudanças de estado.  
- Mantém histórico em PostgreSQL e telemetria via OpenTelemetry.  

### **4.5 Payment Service**
- Simula tokenização e processamento de pagamentos.  
- Integra com provedores mockados (PCI-safe).  
- Implementa antifraude básico por design (Chain of Responsibility).  

### **4.6 Integrations Adapter**
- Camada de abstração para integração com sistemas externos (Shell Recharge, Premmia, etc.).  
- Funciona como “Anti-Corruption Layer” (isolando APIs externas).  
- Implementa retry/backoff e logs estruturados.  

---

## **5. Comunicação Entre Componentes**
- **REST (HTTP/JSON):** para interações síncronas entre front e back.  
- **Kafka (Eventos):** para notificações assíncronas e integração de estados.  
- **gRPC (opcional futuro):** para chamadas de baixa latência entre microsserviços core.  

---

## **6. Padrões Arquiteturais Utilizados**

| Padrão | Aplicação | Benefício |
|---------|------------|------------|
| **Strategy** | Pagamentos, rotas e provedores externos | Extensibilidade sem alterar código existente |
| **State** | Sessão de recarga | Controle previsível de estados de operação |
| **Chain of Responsibility** | Validação de regras e antifraude | Fluxo modular e testável |
| **Outbox Pattern** | Publicação de eventos Kafka confiável | Idempotência garantida |
| **Circuit Breaker** | Comunicação com integrações externas | Evita cascata de falhas |
| **Caching Layer** | Resultados de rotas e dados estáticos | Desempenho e custo otimizados |

---

## **7. Modelos de Domínio**
A arquitetura está dividida em cinco **Bounded Contexts** principais:

| Domínio | Descrição | Serviços Relacionados |
|----------|------------|----------------------|
| **Identidade** | Autenticação, autorização e gestão de usuários. | Auth, User/Profile |
| **Navegação EV** | Planejamento e cálculo de rotas otimizadas. | Routing |
| **Recarga** | Gerenciamento de sessões e telemetria de carregamento. | Charging |
| **Pagamento** | Processamento e tokenização de transações. | Payment |
| **Integrações** | Conexão com provedores externos e eventos. | Integrations |

---

## **8. Observabilidade e Segurança Transversais**
Todos os serviços compartilham:
- **Tracing distribuído (OpenTelemetry).**  
- **Logs estruturados (JSON + correlação traceId/spanId).**  
- **Criptografia em trânsito (TLS 1.3) e em repouso (AES-256).**  
- **Monitoramento centralizado (Prometheus + Grafana).**  
- **Gestão de secrets via Vault/KMS.**

---

## **9. Riscos Arquiteturais Identificados**
| ID | Risco | Mitigação |
|----|--------|------------|
| R1 | Aumento de complexidade operacional dos microsserviços. | Modular Monolith evolutivo para MVP. |
| R2 | Integrações instáveis com provedores externos. | Mock determinístico + retries + Circuit Breaker. |
| R3 | Latência em rotas EV com grandes volumes de dados. | Cache Redis + indexação geográfica. |
| R4 | Duplicidade de logs e traces. | Padronização via OpenTelemetry Collector. |

---

## **10. Próximos Documentos Relacionados**
- `01_diagrama_containers.mmd` — diagrama de containers e relações.  
- `02_diagrama_componentes.mmd` — visão detalhada de componentes internos.  
- `03_context_map_DDD.md` — visão de domínios e dependências.  
- `04_modelo_interacao_servicos.md` — descrição dos fluxos de comunicação.

---

**Responsável:**  
Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:**  
Engenharia Backend / SRE / Segurança da Informação

