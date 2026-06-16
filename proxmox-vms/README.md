# proxmox-vms

VMs Proxmox a partir de um template cloud-init.

## O que cria

`server.tf` define 3 VMs Ubuntu via `for_each` (clonadas do template `9000`):

- `nginx`
- `wordpress`
- `smb`

Nó alvo `pve2`, storage `local-btrfs`, bridge `vmbr0`.

## Arquivos

| Arquivo | Função |
|---------|--------|
| `providers.tf` | Provider `bpg/proxmox` + variáveis (url, token, senha) |
| `server.tf` | `locals` + recurso `proxmox_virtual_environment_vm` |
| `credentials.auto.tfvars` | Valores reais (**ignorado pelo git**) |
| `credentials.auto.tfvars.example` | Template |
| `terraform_vars.tf` | Variáveis locais extras (**ignorado pelo git**) |

## Uso

```bash
cp credentials.auto.tfvars.example credentials.auto.tfvars   # preencha url, token, senha
terraform init
terraform plan
terraform apply
```
