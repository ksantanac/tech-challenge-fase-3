# ToggleMaster — Tech Challenge Fase 3 (FIAP POSTECH)

Automação completa do ecossistema de microsserviços **ToggleMaster** com **Infraestrutura como
Código (Terraform)**, **CI/CD + DevSecOps (GitHub Actions)** e **GitOps (ArgoCD)**.

> Lema da fase: **"se não está no código, não existe"** — infraestrutura imutável, pipelines de
> segurança e deploy declarativo.

---

## 📋 Relatório de Entrega

| | |
|---|---|
| **Nome** | Kaue Matheus Santana Alexandre |
| **RM** | 372355 |
| **Discord** | ksantanac_ |

- **Repositório / Documentação:** https://github.com/ksantanac/tech-challenge-fase-3
- **Vídeo de demonstração:** _(adicionar link do YouTube)_

---

## 🏗️ Arquitetura

Os 5 microsserviços da Fase 2 (auth, flag, targeting, evaluation, analytics) agora têm **todo o
ciclo de vida automatizado**:

```
Dev faz push  ──►  GitHub Actions (CI + DevSecOps)  ──►  ECR (imagem escaneada)
                          │
                          └──►  atualiza a tag no gitops/  ──►  ArgoCD  ──►  EKS (deploy)

Terraform  ──►  VPC + EKS + RDS×3 + Redis + DynamoDB + SQS + ECR   (state remoto no S3)
```

## 📁 Estrutura do repositório

```
.
├── terraform/                # Infraestrutura como Código (módulos)
│   ├── versions.tf           # providers + backend S3 (state remoto)
│   ├── main.tf               # composição dos módulos
│   ├── 00-bootstrap-backend.sh
│   └── modules/
│       ├── networking/       # VPC, subnets pub/priv, IGW, route tables
│       ├── eks/              # cluster + node group (LabRole, IMDS hop-limit=2)
│       ├── databases/        # 3x RDS Postgres, ElastiCache Redis, DynamoDB
│       ├── messaging/        # SQS
│       ├── ecr/              # 5 repositórios
│       └── argocd/           # ArgoCD via Helm
├── .github/workflows/        # 5 pipelines CI/DevSecOps (+ 2 templates reutilizáveis)
├── gitops/
│   ├── apps/<serviço>/       # manifestos K8s (Deployment/Service) — ArgoCD sincroniza
│   └── argocd/               # Applications do ArgoCD (App of Apps)
├── scripts/bootstrap-config.sh  # cria namespace/configmap/secret a partir dos outputs do TF
├── auth-service/ … analytics-service/   # código dos 5 microsserviços
└── docker-compose.yml        # ambiente local
```

## 1️⃣ Infraestrutura como Código (Terraform)

- **Modular:** um módulo por domínio (networking, eks, databases, messaging, ecr, argocd).
- **State remoto:** `terraform.tfstate` em um bucket **S3** com `use_lockfile` (lock nativo, sem
  DynamoDB), versionamento e acesso público bloqueado.
- **AWS Academy:** o Terraform **não cria IAM** — a **LabRole** existente é importada via
  `data "aws_iam_role"` e associada ao cluster e ao node group.
- Provisiona: VPC (subnets públicas e privadas, IGW, route tables), cluster **EKS** + node group,
  **3x RDS PostgreSQL**, **ElastiCache Redis**, tabela **DynamoDB** (`ToggleMasterAnalytics`),
  fila **SQS** e **5 repositórios ECR**.

## 2️⃣ CI + DevSecOps (GitHub Actions)

Um pipeline por microsserviço (roda em **Pull Request** e **push na main**), com os estágios:

| Estágio | Ferramenta | Bloqueia? |
|---|---|---|
| **Build & Test** | go build/test · pip + compileall/pytest | ✅ |
| **Lint** | golangci-lint · flake8 | advisory |
| **SCA** (dependências) | **Trivy** (`fs`) | ✅ **falha em CRÍTICO** |
| **SAST** (código) | gosec · bandit | advisory |
| **Docker + Container Scan** | docker build + **Trivy** (`image`) | ✅ **falha em CRÍTICO** |
| **Push ECR** | tag = `v1.0.0-<commit>` | ✅ |
| **GitOps** | atualiza a tag no `gitops/` | ✅ |

> **Regra de bloqueio:** se o Trivy encontrar uma vulnerabilidade **CRÍTICA** (nas dependências ou
> na imagem), o pipeline **falha** e a imagem não é publicada.

## 3️⃣ CD + GitOps (ArgoCD)

- **ArgoCD** instalado no EKS via Helm (Terraform).
- Padrão **App of Apps**: um `root-app` cria os 5 Applications (um por microsserviço).
- O ArgoCD monitora a pasta `gitops/` e **sincroniza automaticamente** (`automated: prune + selfHeal`).
- Quando o CI atualiza a tag da imagem no `gitops/`, o ArgoCD detecta e faz o **deploy sozinho**.

## 🚀 Como provisionar (resumo)

```bash
# 1. Backend do state (uma vez)
bash terraform/00-bootstrap-backend.sh

# 2. Provisionar a infra
cd terraform && terraform init
terraform apply -target=module.networking -target=module.eks \
                -target=module.databases -target=module.messaging -target=module.ecr
terraform apply            # aplica o restante (ArgoCD)

# 3. Conectar o kubectl e criar config/secret a partir dos outputs
aws eks update-kubeconfig --name togglemaster-eks --region us-east-1
DB_PASSWORD='suaSenha' bash scripts/bootstrap-config.sh

# 4. Ativar o GitOps
kubectl apply -f gitops/argocd/root-app.yaml
```

> Os **secrets do GitHub Actions** (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`,
> `AWS_SESSION_TOKEN`) devem ser preenchidos com as credenciais do AWS Academy (renovadas por sessão).

## 🔒 Decisões e desafios

- **Fixes da Fase 2 embutidos no Terraform:** `authentication_mode = API_AND_CONFIG_MAP` (o modo `API`
  puro ignora o aws-auth e quebrava a LabRole) e node group com **IMDS `hop_limit = 2`** (para os pods
  herdarem a LabRole e acessarem SQS/DynamoDB).
- **Segredos fora do git:** o `terraform.tfvars` e o Secret do Kubernetes nunca são versionados —
  o Secret é criado no cluster a partir dos outputs do Terraform (`scripts/bootstrap-config.sh`).
- **DevSecOps com gate real:** o Trivy bloqueia o pipeline em vulnerabilidades CRÍTICAS; lint e SAST
  são advisory para não travar a esteira com achados de estilo/baixo risco.
- **Academy:** sem NAT Gateway (nós em subnets públicas) para reduzir custo; RDS/Redis em subnets
  privadas.
