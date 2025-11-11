# 02 — Topologia e Estratégia de Deploy por Ambiente

## 1. Objetivo

Definir a **topologia de rede e os processos de deploy** para os ambientes **Dev**, **Homologação (HML)** e **Produção (PROD)** da plataforma **Soluções EV-Costa**, garantindo consistência, isolamento e rastreabilidade.

---

## 2. Estrutura de Ambientes

| Ambiente | Finalidade | Escopo de Serviços | Tipo de Deploy | Observações |
|-----------|-------------|--------------------|----------------|-------------|
| **DEV** | Desenvolvimento e integração inicial | Microsserviços core (auth, user, payment, charging, routing) + mocks de provedores | CI/CD automatizado (GitLab CI) | Banco de dados efêmero; uso de containers locais |
| **HML** | Validação funcional e testes integrados | Todos os microsserviços e integrações externas (mocks reais) | Deploy canário controlado | Banco de dados persistente e rotas com tokens reais |
| **PROD** | Ambiente de produção estável | Todos os domínios com monitoramento completo | Blue-Green / Rolling | Logs auditáveis, métricas SLO, e alertas críticos |

---

## 3. Infraestrutura por Ambiente

### a) **Rede e VPC**
Cada ambiente possui uma **VPC isolada**, com sub-redes privadas e públicas:
- Sub-redes públicas: ALB, NAT Gateway, endpoints de observabilidade.  
- Sub-redes privadas: workloads EKS, bancos de dados, mensageria.  
- **CIDRs distintos** para evitar sobreposição entre ambientes.

### b) **Kubernetes (EKS)**
- Clusters independentes por ambiente (`eks-dev`, `eks-hml`, `eks-prod`).  
- Namespaces por domínio de negócio.  
- RBAC e policies distintas:
  - DEV → permissões ampliadas para desenvolvedores.
  - HML → restrição parcial com logs de auditoria.
  - PROD → acesso apenas via pipelines e SRE.

### c) **Bancos de Dados**
- **PostgreSQL (RDS)** com replicação Multi-AZ nos ambientes HML e PROD.  
- **Redis (ElastiCache)** e **Kafka (MSK)** configurados com topologia idêntica entre HML e PROD.  
- **Snapshots automáticos** diários e retenção conforme política de backup.

### d) **Segurança**
- Certificados TLS separados por ambiente (`*.dev.evcosta.com.br`, `*.hml.evcosta.com.br`, `*.evcosta.com.br`).  
- Políticas IAM segregadas (`evcosta-dev-role`, `evcosta-prod-role`).  
- CI/CD validado com **OIDC federation** e autenticação temporária para pipelines.

---

## 4. Estratégia de Deploy

### a) **Padrões Utilizados**
- **GitOps (ArgoCD ou FluxCD)** para reconciliação contínua do estado desejado.  
- **Pipelines CI/CD (GitLab)**:  
  - Build → Teste → Deploy → Monitoramento.  
  - Imagens versionadas (`service:1.2.3`) e armazenadas em **Amazon ECR**.  
- **Templates Helm** e **Kustomize** para parametrização por ambiente.

### b) **Modelos de Deploy**
| Modelo | Aplicação | Benefícios |
|---------|------------|------------|
| **Blue-Green** | PROD | Zero downtime, rollback imediato |
| **Canário** | HML | Teste gradual de novas versões |
| **Rolling Update** | DEV | Entrega contínua e rápida |

---

## 5. Observabilidade e Monitoramento

Cada ambiente conta com:
- **Prometheus / Grafana** para métricas e alertas.  
- **Loki / Jaeger** para logs e tracing.  
- Dashboards separados por cluster (`dev`, `hml`, `prod`).  
- Métricas DORA monitoradas no pipeline CI/CD.

---

## 6. Segurança e LGPD

- Dados anonimizados e mascarados nos ambientes não produtivos.  
- Segregação de credenciais e tokens via AWS Secrets Manager (cada ambiente tem seu prefixo).  
- Testes e logs em **HML/DEV** não devem conter dados pessoais reais.  
- Política de acesso revista trimestralmente.

---

## 7. Fluxo de Deploy Simplificado

flowchart LR
    Dev[Desenvolvedor] --> Commit[Commit em Git]
    Commit --> CI[Pipeline CI/CD]
    CI --> Registry[Amazon ECR]
    Registry --> EKS_HML[EKS - HML]
    EKS_HML -->|Validação OK| EKS_PROD[EKS - PROD]
    EKS_PROD --> Monitor[Prometheus/Grafana]

---

## 8. Artefatos Relacionados

| **Arquivo** | **Descrição** |
|--------------|----------------|
| `00_topologia_conceitual.md` | Descrição geral da arquitetura em 3 AZs |
| `01_gestao_secrets_cofres.md` | Gestão de secrets e políticas de segurança |
| `../07_devops_cicd_finops/00_pipelines_CICD.md` | Pipeline CI/CD completo |
| `../04_observabilidade_SRE/00_estrategia_observabilidade.md` | Estratégia de observabilidade integrada |

---

**Responsável:** Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:** DevOps / SRE / Segurança da Informação