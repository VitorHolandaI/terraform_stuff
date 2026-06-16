# lxc

Containers LXC no Proxmox (mais leve que VM).

## O que cria

`container.tf` define 3 containers via `for_each`:

- `lxc-nginx`
- `lxc-wordpress`
- `lxc-smb`

Rede via `eth0` na bridge do nó.

## Arquivos

| Arquivo | Função |
|---------|--------|
| `providers.tf` | Provider `bpg/proxmox` + variáveis |
| `container.tf` | `locals` + recurso `proxmox_virtual_environment_container` |
| `credentials.auto.tfvars` | Valores reais (**ignorado pelo git**) |
| `credentials.auto.tfvars.example` | Template |

## Uso

```bash
cp credentials.auto.tfvars.example credentials.auto.tfvars   # preencha
terraform init
terraform plan
terraform apply
```
