# 01 — Gestão de Secrets e Cofres de Credenciais

## 1. Objetivo

Definir a arquitetura e os padrões de segurança utilizados na **gestão de segredos e credenciais** da plataforma **Soluções EV-Costa**, garantindo **confidencialidade, integridade e rastreabilidade** de dados sensíveis em todos os ambientes (dev, hml, prod).

---

## 2. Princípios Gerais

- **Segurança by Design:** nenhum segredo é persistido em código, imagens de container ou variáveis não seguras.  
- **Acesso Mínimo Necessário (Least Privilege):** apenas serviços e usuários com papel explícito têm acesso.  
- **Rotação Automática:** tokens e chaves renovados periodicamente conforme política de segurança.  
- **Auditoria e Rastreabilidade:** cada acesso é logado com `traceId`, `userId` e `timestamp`.  
- **Segregação de Ambientes:** secrets de `dev`, `hml` e `prod` são isolados logicamente.

---

## 3. Solução Técnica

### a) **AWS Secrets Manager**
Responsável por armazenar:
- Credenciais de bancos de dados (RDS PostgreSQL).  
- Chaves de APIs externas (DSA-X, Shell Recharge, Premmia, Eletrograal).  
- Certificados TLS privados.  
- Tokens OIDC (Auth0/Keycloak).

Configurações:
- Criptografia **AES-256** gerenciada por **AWS KMS**.  
- Políticas de acesso controladas via **IAM Role específica por microserviço**.  
- Rotação automática configurada para **90 dias** (ou conforme exigência do provedor).

### b) **Kubernetes Secrets (EKS)**
- Secrets sensíveis não são gravados diretamente no cluster.  
- Utilização do **External Secrets Operator (ESO)** para sincronização automática com o AWS Secrets Manager.  
- Permissões gerenciadas via **IAM Roles for Service Accounts (IRSA)**.  
- Secrets montados como volumes temporários (`tmpfs`) com tempo de expiração definido.

### c) **Vault (opcional para Híbrido / Multi-cloud)**
- Suporte futuro para integração com **HashiCorp Vault** caso haja extensão on-premise.  
- O Vault funcionará como camada intermediária para rotação dinâmica de credenciais (ex: RDS Dynamic Secrets).  

---

## 4. Estrutura de Nomeação e Acesso

| Tipo de Secret | Nome Padrão | Escopo | Exemplo |
|----------------|-------------|--------|----------|
| Banco de Dados | `/evcosta/db/{service}/{env}` | Serviço | `/evcosta/db/auth/prod` |
| API Key | `/evcosta/api/{provider}/{env}` | Integração | `/evcosta/api/shell/hml` |
| TLS | `/evcosta/tls/{domain}` | Global | `/evcosta/tls/api.evcosta.com.br` |
| OIDC Client | `/evcosta/oidc/{clientId}` | Auth | `/evcosta/oidc/mobile-app` |

Cada secret é identificado com **ARN** e versionado automaticamente pelo Secrets Manager.

---

## 5. Políticas de Acesso (IAM)

- **Principais Roles:**
  - `RoleEKSAuthService` → acesso apenas a `/evcosta/db/auth/*`
  - `RoleEKSPaymentService` → acesso apenas a `/evcosta/db/payment/*`
  - `RoleExternalSecrets` → sincronização dos secrets do AWS SM para EKS.

- **Regras de Segurança:**
  - Apenas leitura (`secretsmanager:GetSecretValue`) para workloads.
  - Escrita e rotação permitidas apenas para pipelines CI/CD com role específica.
  - Logs de acesso auditados via **AWS CloudTrail**.

---

## 6. Boas Práticas de Segurança

- **Nunca** armazenar secrets em variáveis de ambiente persistentes.  
- **Evitar** o uso de `kubectl create secret` direto — deve vir sempre via CI/CD.  
- **Usar KMS para criptografia adicional** de campos sensíveis (ex.: token antifraude).  
- **Revisar permissões trimestralmente** conforme política de governança de segurança.  
- **Monitorar acessos anômalos** via CloudWatch Alarms integrados ao SIEM.

---

## 7. Fluxo de Gestão de Secrets

flowchart LR
    DevOps[DevOps / CI Pipeline] -->|Cria/Atualiza| AWS_SM[AWS Secrets Manager]
    AWS_SM -->|Replica via ESO| K8S[EKS Secrets Store]
    K8S -->|Injeta Secrets| Pod[Microserviços (Auth, Payment, etc.)]
    Pod -->|Logs/Audit| CloudTrail[AWS CloudTrail / SIEM]

## 8. Conformidade e LGPD

- **Dados pessoais tokenizados:** apenas referências (tokens) são armazenadas.  
- **Criptografia ponta a ponta** em trânsito e repouso.  
- **Logs anonimizados:** apenas IDs correlacionáveis são mantidos.  
- **Revogação imediata** em caso de suspeita de comprometimento.

---

## 9. Artefatos Relacionados

| **Arquivo** | **Descrição** |
|--------------|----------------|
| `00_topologia_conceitual.md` | Contexto geral de rede e zonas AWS |
| `02_topologia_deploy_ambientes.md` | Ambientes e pipelines CI/CD seguros |
| `../05_seguranca_LGPD/02_politica_criptografia.md` | Política de criptografia e tokenização |

---

**Responsável:** Arquiteto de Software — *Soluções EV-Costa*  
**Revisores:** Segurança da Informação / DevSecOps / SRE
