# rex para Android: política de privacidade {#rex-for-android-privacy-policy}

*Última atualização: 14 de novembro de 2026.*

O rex para Android roda um servidor de mídia no seu dispositivo. Ele não tem conta conosco, não tem anúncios nem análises, e não envia para nós a sua biblioteca, o que você assiste nem nenhuma informação sobre você, exceto pelo rex-direct e pelos logs que você escolher enviar, ambos citados abaixo.

## O que sai do seu dispositivo e para onde vai {#what-leaves-your-device-and-where-it-goes}

| Onde | O quê | Quando |
|---|---|---|
| **plex.tv** (Plex, Inc.) | Um pedido de código de login com um identificador de app aleatório e o nome deste servidor; depois, quando você aprovar, um pedido único de código de reivindicação | Quando você escolher Sign in to Plex |
| **plex.tv** | O nome, o identificador, a versão do servidor e os endereços pelos quais os apps do Plex conseguem acessá-lo | Enquanto o rex estiver rodando e conectado, como qualquer servidor Plex se anuncia |
| **Serviço de metadados do Plex** | Os ids dos títulos que seus addons adicionam, para buscar pôsteres e descrições | Enquanto o rex estiver rodando e conectado |
| **debridmediamanager.com** (rex-direct) | O identificador do servidor, o token de servidor que o Plex deu a ele, seus endereços IP locais e públicos e sua porta | Depois de conectar, e então a cada 6 horas, para que os apps do Plex consigam acessar o rex por HTTPS quando você estiver fora de casa |
| **logs.debridmediamanager.com** (logs de suporte) | As versões do app e do rex, o modelo do aparelho, a versão do Android e o tipo de processador, a porta e o estado do rex, o nome, a versão, o repositório, o estado, a quantidade de títulos, a última sincronização e o último erro de cada addon, o deslocamento de fuso horário, e os logs do app desta execução e da anterior, com tokens, chaves, senhas e os dois últimos blocos dos endereços IP públicos ocultados. Nunca suas configurações de addon, sua conta do Plex ou tokens | Somente quando você pressionar Send em Send logs to support, depois de ver tudo isso. Você recebe um código para passar ao suporte; só a equipe de suporte consegue ler, e ele é apagado após 7 dias |
| **Repositórios de addons que você adiciona** (como github.com) | Um pedido pelo conteúdo do repositório | Quando você adiciona ou atualiza um repositório |
| **Sites de cada addon** | O que o addon pede, como um pedido de catálogo ao archive.org | Quando um addon sincroniza ou um título é reproduzido |

Sua senha da conta Plex nunca passa pelo app: você faz login na própria página do Plex. O
token de conta que esse login dá ao app é usado uma única vez para reivindicar o servidor e depois descartado. O rex
guarda apenas o token de servidor que o Plex emite para ele.

## O que fica no seu dispositivo {#what-stays-on-your-device}

Suas bibliotecas, histórico de exibição, configurações de addons (incluindo as chaves que você digitar) e logs. O app mantém os logs desta execução e da anterior para que, se ocorrer um crash, eles não sejam perdidos. Os logs ocultam tokens, chaves, senhas e o final dos endereços IP públicos, e só saem do aparelho se você escolher Share ou Send logs to support na tela Logs. Desinstalar o app apaga tudo isso.

## Complementos {#addons}

Um addon é um código de quem o escreveu, instalado a partir de um repositório que você adicionou. Ele roda isolado do resto do seu dispositivo e só consegue acessar os sites que ele declara, o que o rex mostra para você antes de instalar. Instale addons apenas de pessoas em quem você confia.

Um addon que precisa de uma conta no site dele, como o YouTube, faz login com um código: você digita esse código na própria página do site, então sua senha nunca passa pelo app. O token que o site entrega ao addon fica no seu dispositivo e só é enviado de volta para esse site. Remover o addon apaga tudo.

## Crianças {#children}

O aplicativo não é voltado para crianças.

## Contato {#contact}

support@debridmediamanager.com
