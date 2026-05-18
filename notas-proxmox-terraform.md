# Proxmox + Terraform — do template à VM (minhas notas)

> Isso aqui é o que eu fiz aprendendo a usar Terraform com Proxmox, na pasta
> `default_proxmox/`. Anotei pra conseguir refazer depois sem ter que garimpar
> tudo de novo. O caminho é: **preparar a imagem cloud-init → criar
> usuário/token pro Terraform → montar o template base → deixar o Terraform
> clonar e provisionar.**

Meu setup (pra referência, ajusta pro teu):

- Node: `pve2`
- Storage: `local-btrfs`
- Bridge de rede: `vmbr0`
- Template base: VM id `9009`
- Provider: [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

---

## 1. Baixar a cloud image certa

Imagem **cloud** do Ubuntu (a `cloudimg`, não a ISO de instalação — essa já vem
pronta pra cloud-init).

```bash
wget -P /var/lib/vz/template/iso/ \
  https://cloud-images.ubuntu.com/daily/server/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
```

### Injetar o qemu-guest-agent na imagem

Sem o guest agent o Proxmox **não enxerga o status real da VM** (IP, estado,
etc). Dá pra instalar manualmente depois, mas é muito mais limpo já costurar na
própria imagem antes de virar template, usando `virt-customize`:

```bash
virt-customize -a /var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img \
    --install qemu-guest-agent \
    --run-command 'systemctl enable qemu-guest-agent'
```

> Depois, no Terraform, eu ligo `agent { enabled = true }` — é o lado de cá
> dessa mesma história.

---

## 2. Criar o usuário + token que o Terraform vai usar

A ideia: o Terraform **não** loga como root. Crio um role com as permissões
necessárias, jogo num grupo, aplico o role nos recursos, e o usuário entra no
grupo. No fim gero um token pra ele.

### 2.1 Criar o role com as ACLs

```bash
pveum role add TerraformUser2 -privs "Datastore.Allocate \
  Datastore.AllocateSpace Datastore.AllocateTemplate \
  Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify \
  SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM \
  VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType \
  VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate \
  VM.Console VM.PowerMgmt User.Modify"
```

Isso cria um **role** (um pacote de permissões). Ele ainda não está ligado a
ninguém — é só a definição.

### 2.2 Criar o grupo

Coloco o role no grupo pra ficar gerenciável. Se um dia quiser ser granular, dá
pra aplicar ACL direto no usuário também — mas grupo é mais limpo.

```bash
pveum group add terraform-users
pveum group list      # confere que o terraform-users apareceu
```

### 2.3 Aplicar o role nos recursos (as ACLs de verdade)

Aqui que a mágica acontece: associo o **role** ao **grupo** em cada caminho de
recurso. É isso que dá ao usuário (que vai entrar no grupo) acesso àquele
recurso.

```bash
pveum acl modify /storage   -group terraform-users -role TerraformUser2
pveum acl modify /vms       -group terraform-users -role TerraformUser2
pveum acl modify /sdn/zones -group terraform-users -role TerraformUser2
```

### 2.4 Criar o usuário e gerar o token

```bash
pveum useradd terradorm2@pve -groups terraform-users
pveum user list                                   # confere o terradorm2@pve com realm pve
pveum user token add terradorm2@pve token -privsep 0
```

> `-privsep 0` = o token herda **todas** as permissões do usuário (sem separação
> de privilégio). O comando cospe o **secret do token uma única vez** — copia na
> hora, depois não dá mais pra ver. A saída vem assim:
>
> ```
> full-tokenid   terradorm2@pve!token
> value          b412d05a-2661-446e-8f7e-9e31c72cd3ca   <- o secret, salva AGORA
> ```

O formato que o Terraform espera é `USER@REALM!TOKENID=UUID`, ou seja:
`terradorm2@pve!token=b412d05a-2661-446e-8f7e-9e31c72cd3ca`.

> Pra conferir o que ficou aplicado: `pveum acl list` mostra cada `path` com seu
> `roleid`, o `type` (user/group) e o `ugid` (quem recebeu).

---

## 3. Montar o template base

Esse é o template que TODAS as VMs vão clonar. No meu caso, uma única base
Ubuntu 24.04 cloud-init.

```bash
# cria o esqueleto da VM
qm create 9009 --name "ubuntu-24.04-cloud-init-template" \
  --memory 2048 --cores 2 --net0 virtio,bridge=vmbr1

# importa o disco da cloud image pro storage
qm importdisk 9009 /var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img local-btrfs
```

Depois do import o disco entra como **`unused0`** (não atachado). Confere com:

```bash
qm config 9009
# unused0: local-btrfs:9009/vm-9009-disk-0.raw
```

Atacho o disco num controller SCSI virtio:

```bash
qm set 9009 --scsihw virtio-scsi-pci \
  --scsi0 local-btrfs:9009/vm-9009-disk-0.raw
```

> Resize **só depois** de atachar — a cloud image vem pequena (~2-3G), então
> dou um tamanho de verdade:

```bash
qm resize 9009 scsi0 40G
```

Configuro boot, drive de cloud-init, rede e o usuário/senha inicial da imagem:

```bash
qm set 9009 --boot c --bootdisk scsi0
qm set 9009 --ide2 local-btrfs:cloudinit          # drive de cloud-init
qm set 9009 --ipconfig0 ip=dhcp
qm set 9009 --ciuser ubuntu --cipassword 'sua-senha-aqui'   # user/pass cloud-init
```

Converto em template (a partir daqui não dá mais pra dar boot nele direto, só
clonar):

```bash
qm template 9009
qm list   # confere que aparece como template
```

No `qm list` os meus templates/VMs ficam assim (o `9009 ubuntu-template` é a
base que o Terraform usa):

```
VMID  NAME              STATUS   MEM(MB)  BOOTDISK(GB)
201   new-ubuntu-vm     stopped  2048     13.50
9009  ubuntu-template   stopped  2048     20.00
```

**A partir daqui já dá pra ir pro Terraform.** Mas dá pra testar o clone na mão
antes, só pra ver que a base presta:

```bash
qm clone 9009 201 --name "new-ubuntu-vm"
qm resize 201 scsi0 +10G
qm start 201
```

---

## 4. O lado Terraform (`default_proxmox/`)

Estrutura: o Terraform lê **todos os `.tf`** da pasta e junta tudo. Eu separei
em arquivos por responsabilidade.

### `provider.tf` — quem é o backend

```hcl
terraform {
  required_version = ">=1.5"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true        # cert self-signed do Proxmox
}
```

### `variables.tf` — o que é secreto fica como variável

```hcl
variable "proxmox_api_url"   { type = string }
variable "proxmox_api_token" { type = string, sensitive = true }
variable "vm_password"       { type = string, sensitive = true }
```

### `terraform.tfvars` — os valores (ESSE NÃO VAI PRO GIT)

```hcl
proxmox_api_token = "terradorm2@pve!token2=<SECRET-AQUI>"
proxmox_api_url   = "https://10.66.66.19:8006/"
vm_password       = "<senha>"
```

> ⚠️ Bota isso no `.gitignore`. Token de Proxmox no histórico do git é dor de
> cabeça garantida.

### `locals.tf` — as constantes do meu ambiente num lugar só

```hcl
locals {
  target_node    = "pve2"
  storage        = "local-btrfs"
  network_bridge = "vmbr0"
  template_id    = 9009
  ssh_user       = "shabba"
}
```

### `vm.tf` — clona o template e provisiona via cloud-init

```hcl
resource "proxmox_virtual_environment_vm" "vm" {
  name      = "terraform-test"
  node_name = local.target_node
  started   = true
  on_boot   = true

  agent { enabled = true }      # o par do qemu-guest-agent que instalei na imagem

  clone {
    vm_id        = local.template_id
    full         = true         # clone completo, não linked
    datastore_id = local.storage
  }

  cpu    { cores = 2, sockets = 1, type = "host" }
  memory { dedicated = 2048 }

  disk {
    datastore_id = local.storage
    interface    = "scsi0"
    size         = 32
  }

  network_device {
    bridge = local.network_bridge
    model  = "virtio"
  }

  # cloud-init: usuário, senha, chave SSH e rede
  initialization {
    datastore_id = local.storage
    user_account {
      username = local.ssh_user
      password = var.vm_password
      keys     = [trimspace(file("~/.ssh/id_ed25519.pub"))]
    }
    ip_config {
      ipv4 { address = "dhcp" }
    }
  }
}
```

### `outputs.tf` — me devolve o IP depois do apply

```hcl
output "vm_ipv4_addresses" { value = proxmox_virtual_environment_vm.vm.ipv4_addresses }
output "vm_ipv6_addresses" { value = proxmox_virtual_environment_vm.vm.ipv6_addresses }
```

> O IP só aparece porque o guest agent está rodando dentro da VM. Sem ele, esse
> output vem vazio — tá tudo conectado.

---

## 5. Os comandos do dia a dia

```bash
terraform init                                   # baixa o provider
terraform plan  -var-file="terraform.tfvars"     # mostra o que vai fazer
terraform apply -var-file="terraform.tfvars"     # aplica
terraform apply -auto-approve -var-file="..."    # aplica sem perguntar

# salvar o plano e aplicar exatamente ele depois
terraform plan  -out="proxmox_plan" -var-file="terraform.tfvars"
terraform apply "proxmox_plan"

# derrubar tudo
terraform destroy -auto-approve -var-file="terraform.tfvars"
```

> Se o arquivo terminar em `.auto.tfvars`, o Terraform carrega sozinho e nem
> precisa do `-var-file`.

---

## Links que me ajudaram

- Ciclo de vida da VM (bpg): https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/vm-lifecycle
- Provisioning Proxmox 8 com Terraform + bpg: https://www.trfore.com/posts/provisioning-proxmox-8-vms-with-terraform-and-bpg/
- Guia no Medium: https://medium.com/@DatBoyBlu3/provisioning-proxmox-virtual-machines-with-terraform-d9e9c549f947
- Criando plugin (vídeo): https://www.youtube.com/watch?v=16qs7LJSyps
