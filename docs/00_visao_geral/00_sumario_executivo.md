# **Sumário Executivo Técnico — POC Soluções EV-Costa**

## **1. Contexto**
A POC *Soluções EV-Costa* tem como objetivo validar a viabilidade técnica e arquitetural de uma plataforma nacional de mobilidade elétrica.  
O escopo abrange login seguro, rotas otimizadas para veículos elétricos, sessões de recarga e pagamento tokenizado — integrando provedores parceiros de energia e recarga.

O projeto é a base para um ecossistema escalável, seguro e observável, que permitirá a expansão futura para o MVP e posterior operação comercial.

---

## **2. Objetivos**
- **Validar arquitetura de microsserviços** com domínios independentes (Auth, User, Payment, Routing, Charging).  
- **Comprovar desempenho** sob carga moderada (p95 < 500 ms).  
- **Testar segurança e conformidade** (ASVS L2 / LGPD).  
- **Garantir rastreabilidade ponta a ponta** via OpenTelemetry.  
- **Medir custo operacional** por requisição (FinOps inicial).  

---

## **3. Escopo da Prova de Conceito**
A POC abrange as seguintes entregas documentais e conceituais:
- Arquitetura lógica completa e modelagem de domínios.  
- Modelos de dados, APIs e eventos.  
- Estratégia de segurança e observabilidade.  
- Plano de desempenho e governança.  
- Documentação de infraestrutura conceitual e rede.  

Não haverá desenvolvimento ou implantação nesta fase — apenas consolidação documental e validação teórica das decisões.

---

## **4. Premissas Arquiteturais**
- Arquitetura em **microsserviços DDD leve**.  
- Comunicação síncrona (REST) e assíncrona (Kafka).  
- **Segurança by design**: autenticação OIDC, criptografia, segregação de dados.  
- **Observabilidade por padrão** (OpenTelemetry, Prometheus, Grafana).  
- Infraestrutura pensada para **Kubernetes e IaC**.  
- Stack principal: **Java 21 / Spring Boot**, **PostgreSQL**, **Redis**, **Kafka**.

---

## **5. Critérios de Sucesso (SLOs)**
| Indicador | Meta | Observação |
|------------|------|-------------|
| Latência p95 | < 500 ms | APIs core sob carga moderada |
| Disponibilidade | ≥ 99,5 % | Simulação de carga controlada |
| Custo unitário | < R$ 0,02 / requisição | Estimativa FinOps |
| MTTR | < 10 min | Tempo médio de restauração esperado |
| Segurança | ASVS L2 / LGPD | Cobertura completa de requisitos |

---

## **6. Principais Riscos**
| Categoria | Risco | Mitigação |
|------------|--------|------------|
| Arquitetura | Custo cognitivo de microsserviços no MVP | Avaliar modular monolith evolutivo |
| Integrações | Limites de APIs externas (Shell/DSA-X) | Mock determinístico via WireMock |
| Desempenho | Latência alta em rotas e cálculos EV | Cache Redis + pré-busca POIs |
| Segurança | Vazamento de segredos | Secret Manager + rotação automática |

---

## **7. Governança e Próximos Passos**
1. Concluir documentação dos módulos técnicos (Arquitetura, Dados, Infra, Observabilidade, Segurança).  
2. Formalizar decisões técnicas (ADRs).  
3. Revisar matriz de riscos e trade-offs.  
4. Consolidar relatório executivo final da POC.  

---

## **8. Resultado Esperado**
Ao final desta fase, a POC *Soluções EV-Costa* terá:
- **Pacote documental completo e versionado**, pronto para revisão e auditoria técnica.  
- **Arquitetura validada conceitualmente**, com decisões justificadas e riscos mapeados.  
- **Base sólida** para construção do MVP com previsibilidade de custo, desempenho e segurança.

---

**Responsável:** Arquiteto de Software — Soluções EV-Costa  
**Público-alvo:** Diretoria Técnica e Engenharia de Software

