# terraform_learn

Laboratório de estudos de Terraform. Foco em Proxmox (VMs + LXC) e um warm-up com Docker.

## Estrutura

| Pasta | O que provisiona | Provider |
|-------|------------------|----------|
| [`proxmox-vms/`](proxmox-vms/) | VMs Proxmox (nginx, wordpress, smb) a partir de template cloud-init | `bpg/proxmox` |
| [`default_proxmox/`](default_proxmox/) | VM Proxmox — versão organizada (locals/variables/outputs separados) | `bpg/proxmox` |
| [`lxc/`](lxc/) | Containers LXC Proxmox (nginx, wordpress, smb) | `bpg/proxmox` |
| [`terraform_labs/lab0/`](terraform_labs/lab0/) | Warm-up: 2 containers Docker locais (sintaxe pura) | `kreuzwerker/docker` |

Cada pasta é uma config Terraform independente (state próprio). Rode os comandos **dentro** da pasta.

## Fluxo padrão

```bash
cd <pasta>
terraform init                     # baixa provider, cria .terraform/, gera lockfile
terraform fmt -recursive           # formata
terraform validate                 # valida sintaxe
terraform plan                     # mostra o que vai mudar
terraform apply                    # aplica
terraform destroy                  # derruba tudo
```

Configs Proxmox carregam `credentials.auto.tfvars` automaticamente (sufixo `.auto.tfvars`).

## Segredos

Nada de credencial vai pro git. `.gitignore` ignora `*.tfvars`, `*.tfstate*`, `.terraform/` e planos.

Para configurar uma pasta Proxmox: copie o template e preencha os valores reais:

```bash
cp credentials.auto.tfvars.example credentials.auto.tfvars   # depois edite
```

Os arquivos `.example` (rastreados) mostram o formato; os reais (`credentials.auto.tfvars`) ficam só na máquina.

## Notas

- [`notas-proxmox-terraform.md`](notas-proxmox-terraform.md) — anotações de Proxmox + Terraform.
