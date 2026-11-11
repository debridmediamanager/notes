# Configuração {#setup}

O instalador binário é o caminho mais curto no Linux, macOS e Windows. O Docker continua disponível em um host Linux quando um contêiner faz mais sentido. O Docker Desktop no macOS e no Windows roda os contêineres em uma VM, então o mount não aparece no Finder ou no Explorer e o rex não consegue acessar o zurg: use o binário nesses casos.

## Instaladores de uma linha só {#one-line-convenience-installers}

The instaladores baixam um nightly de sponsor. Seja sponsor no [gatekeeper](https://gatekeeper.debridmediamanager.com/) primeiro. Isso dá acesso à sua conta do GitHub.

Para uma instalação nova de sponsor, escolha o comando para o seu host:

+++ Linux e macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker no Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
No PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

O bootstrap verifica os pré-requisitos da plataforma, faz login no GitHub para acesso de sponsor, baixa o build correspondente e executa o seletor de provedor. Binários e configs existentes são preservados. Cada guia abaixo também traz o caminho manual completo.

- [Linux](linux.md)
- [Docker](docker.md) (hosts Linux)
- [macOS](macos.md)
- [Windows](windows.md)

Depois que o zurg estiver instalado, a página [Providers](../providers/index.md) mostra como apontá-lo para uma conta. Há uma página por serviço, com a credencial, a entrada `config.yml` e o que aquele serviço faz de diferente. Essas páginas são escritas para Docker. Em uma instalação por binário, a entrada `config.yml` do provedor e os passos do Dashboard são os mesmos, mas `./zurg service restart` (`.\zurg.exe service restart` no Windows) substitui `docker compose restart zurg`, e a linha `docker compose run --rm zurg setup` vira `./zurg setup` (`.\zurg.exe setup` no Windows), com as mesmas flags, exceto `--no-service --skip-downloads --mount-path /zurg_mnt/zurg` do contêiner. Uma flag `--…-file` então aponta para um arquivo na sua máquina, em vez de um em `/config`.
