# **Glossário de Termos Técnicos — POC Soluções EV-Costa**

## **1. Objetivo**
Este glossário estabelece uma linguagem comum entre os times de arquitetura, engenharia, segurança e diretoria técnica no contexto da POC *Soluções EV-Costa*.  
Ele descreve termos recorrentes utilizados nos documentos técnicos, ADRs e relatórios da POC.

---

## **2. Termos Gerais**

| Termo | Definição |
|--------|------------|
| **POC (Proof of Concept)** | Prova de Conceito. Fase de validação teórica e documental do projeto, sem desenvolvimento. |
| **MVP (Minimum Viable Product)** | Primeira versão funcional do produto com valor mínimo validável pelo usuário. |
| **Microsserviço** | Unidade de software independente, responsável por um domínio funcional específico e comunicando-se via APIs. |
| **DDD (Domain-Driven Design)** | Abordagem de design centrada no domínio de negócio e suas regras. |
| **Arquitetura Cloud-Native** | Conjunto de práticas e tecnologias que permitem construir aplicações escaláveis e resilientes em ambientes de nuvem. |

---

## **3. Termos Técnicos da Arquitetura**

| Termo | Definição |
|--------|------------|
| **Auth Service** | Serviço responsável por autenticação e autorização de usuários via OIDC/OAuth2. |
| **Routing Service** | Serviço responsável por calcular rotas otimizadas para veículos elétricos, considerando autonomia (SoC) e pontos de recarga. |
| **Charging Service** | Serviço que gerencia sessões de recarga de veículos e emite eventos assíncronos (Kafka). |
| **Payment Service** | Serviço responsável por tokenizar e simular pagamentos, garantindo isolamento PCI. |
| **Integrations Service** | Camada de abstração de APIs externas (DSA-X, Shell Recharge, Premmia, etc.). |
| **Kafka** | Plataforma de mensageria distribuída para troca de eventos entre microsserviços. |
| **Redis** | Banco de dados em memória utilizado como cache e controle de sessão. |
| **PostgreSQL** | Banco de dados relacional transacional utilizado para persistência principal. |
| **REST API** | Interface HTTP padrão para comunicação síncrona entre serviços. |
| **OIDC (OpenID Connect)** | Protocolo de autenticação baseado em OAuth2 para identificação segura de usuários. |
| **JWT (JSON Web Token)** | Token assinado digitalmente usado para autenticação e autorização. |

---

## **4. Termos de Segurança e LGPD**

| Termo | Definição |
|--------|------------|
| **ASVS (Application Security Verification Standard)** | Padrão da OWASP que define níveis de verificação de segurança em aplicações (L1–L3). |
| **LGPD (Lei Geral de Proteção de Dados)** | Lei brasileira de proteção de dados pessoais. |
| **DPO (Data Protection Officer)** | Encarregado pela proteção e conformidade de dados. |
| **Tokenização** | Substituição de dados sensíveis por identificadores não reversíveis. |
| **Cofre de Segredos (Secret Manager)** | Serviço seguro para armazenamento e rotação de chaves, senhas e tokens. |
| **TLS (Transport Layer Security)** | Protocolo de segurança que criptografa a comunicação entre sistemas. |

---

## **5. Termos de Observabilidade e SRE**

| Termo | Definição |
|--------|------------|
| **OpenTelemetry (OTel)** | Framework aberto para coleta padronizada de métricas, logs e traces. |
| **Prometheus** | Ferramenta open-source para monitoramento e coleta de métricas. |
| **Grafana** | Plataforma de visualização e alertas baseada em métricas e logs. |
| **Jaeger** | Ferramenta de tracing distribuído que permite rastrear requisições entre microsserviços. |
| **SLO (Service Level Objective)** | Meta de desempenho ou confiabilidade definida para um serviço. |
| **SLI (Service Level Indicator)** | Métrica usada para medir o cumprimento de um SLO. |
| **MTTR (Mean Time to Restore)** | Tempo médio necessário para restaurar um serviço após falha. |
| **Error Budget** | Margem de erro tolerável dentro de um SLO antes de bloquear novas mudanças. |

---

## **6. Termos de DevOps e Infraestrutura**

| Termo | Definição |
|--------|------------|
| **IaC (Infrastructure as Code)** | Prática de declarar infraestrutura como código versionável. |
| **Terraform / Helm** | Ferramentas de provisionamento e orquestração de infraestrutura em nuvem e Kubernetes. |
| **CI/CD (Continuous Integration / Continuous Delivery)** | Processo automatizado de integração, testes e deploy contínuos. |
| **Canário / Blue-Green Deploy** | Estratégias de implantação gradual e segura em produção. |
| **FinOps** | Prática de gestão financeira aplicada à operação em nuvem. |

---

## **7. Termos de Desempenho e Escalabilidade**

| Termo | Definição |
|--------|------------|
| **p95 / p99** | Percentis de latência que medem o tempo de resposta mais lento em 95% ou 99% das requisições. |
| **Backpressure** | Mecanismo de controle de fluxo que evita sobrecarga de consumo em filas assíncronas. |
| **Circuit Breaker** | Padrão de resiliência que isola falhas para evitar cascatas de erro. |
| **Bulkhead** | Estratégia de isolamento para evitar que a falha de um componente afete outros. |
| **Cache Invalidation** | Processo de atualização ou remoção de dados obsoletos do cache. |

---

## **8. Convenções**
- **Termos técnicos** devem ser mantidos em inglês no código e documentação técnica.  
- **Termos de negócio** (usuário, rota, recarga, pagamento) devem ser em português.  
- Todas as siglas devem aparecer por extenso na primeira ocorrência de cada documento.  

---

**Responsável:**  
Arquiteto de Software — *Soluções EV-Costa*  
**Última revisão:** Novembro / 2025

