# 00 — Topologia Conceitual de Infraestrutura

## 1. Visão Geral

A infraestrutura da **Soluções EV-Costa** é implantada em uma **arquitetura distribuída em três Zonas de Disponibilidade (AZs)** dentro da região **AWS sa-east-1 (São Paulo)**, garantindo **alta disponibilidade, resiliência e escalabilidade horizontal**.

A camada de aplicação é orquestrada via **Amazon EKS (Elastic Kubernetes Service)**, com **NodeGroups replicados** em cada zona.  
A camada de dados utiliza serviços **gerenciados e multi-AZ**, enquanto a observabilidade é tratada de forma independente e resiliente.

O diagrama `zonas_disponibilidade_v3.drawio.xml` representa visualmente esta topologia em estilo AWS oficial.

---

## 2. Camadas Principais

### a) Ingress e Segurança Perimetral
- **AWS Application Load Balancer (ALB)** + **AWS WAF**: Proteção contra ataques de camada 7 e roteamento inteligente para microserviços.
- **Ingress Controller (Nginx / Istio Gateway)** no EKS: Terminação TLS e encaminhamento de tráfego interno.
- **Segurança:** TLS 1.3, OIDC (Keycloak/Auth0), e rate limiting via API Gateway ou Service Mesh.

### b) Camada de Aplicação (EKS)
- **Amazon EKS Cluster**:
  - Namespaces lógicos por domínio (Auth, User, Charging, Payment, Routing).
  - Deploys canário e blue/green via ArgoCD ou GitLab CI.
  - AutoScaling horizontal (HPA) e vertical (VPA).
- **NodeGroups** distribuídos:
  - AZ-a → Auth e User Services  
  - AZ-b → Charging e Payment Services  
  - AZ-c → Routing e Integrations Services  

### c) Camada de Dados
- **Amazon RDS (PostgreSQL)** — Multi-AZ, com failover automático e replicação síncrona.  
- **Amazon ElastiCache (Redis)** — cache distribuído e replicado entre AZs, usado para sessões e rate limits.  
- **Amazon MSK (Kafka)** — mensageria resiliente para eventos assíncronos (recargas, pagamentos, faturas).

### d) Observabilidade e Logs
- **Prometheus / Grafana / Loki / Jaeger** hospedados na AZ-c.  
- Coleta de métricas, traces e logs via **OpenTelemetry**.  
- Dashboards integrados com alertas para SLOs e incidentes críticos.

### e) Storage e Backups
- **Amazon S3**: Armazena logs, faturas, backups de banco e exportações de métricas.
- Versionamento habilitado e ciclo de vida automatizado (lifecycle rules para retenção e arquivamento).

---

## 3. Alta Disponibilidade e Recuperação

| Camada               | Estratégia                              | Nível de Redundância |
|----------------------|------------------------------------------|----------------------|
| Aplicação (EKS)      | NodeGroups replicados entre 3 AZs        | Alta |
| Banco de Dados (RDS) | Multi-AZ, failover automático             | Alta |
| Cache (Redis)        | Replicação síncrona + fallback local      | Alta |
| Mensageria (Kafka)   | Cluster MSK replicado                    | Alta |
| Observabilidade       | Stack dedicada em AZ-c                   | Média/Alta |
| Storage (S3)          | Serviço regional com replicação interna  | Muito Alta |

---

## 4. Conectividade e Isolamento

- **VPC única com sub-redes públicas e privadas por AZ.**
- **Sub-redes públicas**: Load Balancers, NAT Gateways.  
- **Sub-redes privadas**: EKS, bancos de dados, mensageria.  
- **Security Groups** definidos por domínio lógico.  
- **NACLs** restritivas para controlar o tráfego entre camadas.  
- Comunicação inter-serviços via **REST (HTTP/HTTPS)** e **Kafka** (assíncrono).

---

## 5. Observações de Design

- **Desempenho priorizado:** baixa latência, balanceamento otimizado e caching agressivo.  
- **Custos sob controle:** instâncias spot configuradas em workloads não críticos.  
- **Escalabilidade linear:** dimensionamento automático de pods e brokers Kafka.  
- **Infraestrutura como Código (IaC):** Terraform e Helm Charts versionados.

---

## 6. Artefatos Relacionados

| Arquivo | Descrição |
|----------|------------|
| `zonas_disponibilidade_v3.drawio.xml` | Diagrama oficial das zonas e serviços |
| `02_topologia_deploy_ambientes.md` | Descrição detalhada de ambientes (dev, hml, prod) |
| `01_gestao_secrets_cofres.md` | Estratégia de armazenamento seguro de credenciais |
| `img/diagrama_rede_conceitual.png` | Visualização resumida de rede e VPC |

---

**Responsável:** Arquiteto de Software — Soluções EV-Costa  
**Revisores:** Engenharia de Plataforma / SRE / Segurança  

---
