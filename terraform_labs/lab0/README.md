# Projeto 00 — Warm-up Docker (sintaxe pura)

**Status:** ativo
**Início:** —
**Fim:** —

## Objetivo

Rodar o ciclo `init → plan → apply → destroy` várias vezes provisionando 2 containers Docker locais. Foco em sintaxe Terraform, não em Docker.

## Por quê

Antes de mergulhar em Proxmox + cloud-init + API tokens, fixar a forma do código: bloco `terraform`, `provider`, `resource`, `variable`, `output`. Provider Docker dá ciclo de segundos.

## Escopo

**Dentro:**
- Provider `kreuzwerker/docker`
- 2 containers: nginx (porta 8080) + redis (porta 6379)
- Rede Docker bridge customizada
- `variables.tf` mínimo (porta nginx parametrizada)
- 1 output (URL do nginx)
- `.gitignore` correto (state, `.terraform/`)

**Fora:**
- Volume persistente (fica no projeto 09)
- `depends_on` (fica no 05)
- Múltiplos providers

## Critério de sucesso

- `terraform apply` sobe os 2 containers
- `curl http://localhost:8080` retorna nginx default
- `redis-cli -p 6379 ping` retorna PONG
- `terraform destroy` apaga tudo

## Tópicos a estudar

- [X] Bloco `terraform { required_providers {} }`
- [X] `terraform init` (baixa provider, cria `.terraform/`, gera lockfile)
- [X] `terraform fmt`, `validate`, `plan`, `apply`, `destroy`, `show`
- [X] Leitura do arquivo `terraform.tfstate` — entender estrutura
- [X] Diferença `resource` vs `data` (só mencionar; data fica no projeto 04)

## Comandos-chave

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform show
cat terraform.tfstate | jq '.resources'
terraform destroy
```

## Pegadinhas

- Docker daemon precisa estar rodando
- Em Linux: provider usa socket `/var/run/docker.sock` — usuário no grupo `docker`
- Esqueceu `.gitignore` → commitou state com possíveis dados sensíveis

## Links

- [Provider `kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
- [Tutorial Docker get started (HashiCorp)](https://developer.hashicorp.com/terraform/tutorials/docker-get-started)
- [projetos.md (visão geral)](../projetos.md)

