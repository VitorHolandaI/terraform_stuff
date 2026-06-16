# default_proxmox

VM Proxmox — versão organizada da config, com responsabilidades separadas por arquivo. Mesma base do repo [`meu_terraform_proxmox`](https://github.com/VitorHolandaI/meu_terraform_proxmox).

## Arquivos

| Arquivo | Função |
|---------|--------|
| `provider.tf` | Provider `bpg/proxmox` |
| `variables.tf` | Declaração das variáveis |
| `locals.tf` | Valores locais (nó, storage, rede, template) |
| `vm.tf` | Recurso da VM |
| `outputs.tf` | Saídas (ex: IP/nome) |
| `terraform.tfvars` | Valores reais (**ignorado pelo git**) |
| `terraform.tfvars.example` | Template |

## Uso

```bash
cp terraform.tfvars.example terraform.tfvars   # preencha
terraform init
terraform plan
terraform apply
```
