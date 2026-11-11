# Botões do DMM no Safari {#dmm-buttons-in-safari}

O botão **DMM🔎** da extensão do DMM aparece em sites de filmes e séries. Ele abre o título no DMM. Ao lado dos links magnet, a extensão adiciona um botão **DMM🧲**, que envia o torrent para a sua biblioteca do DMM.

No Chrome e no Firefox, instale a [extensão do Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) ou o [add-on do Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). O Safari usa o mesmo código como um [userscript do Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager), com um gerenciador de userscripts.

Escolha um gerenciador:

| Gerenciador | Preço | Funciona em | Atualiza o script |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Grátis | Mac, iPhone, iPad | Quando você toca em **Update** no popup dele |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | US$ 2,99 | Mac, iPhone, iPad | Sozinho |

## Com Userscripts {#with-userscripts}

1. Instale o [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) pela App Store e abra-o uma vez.
2. Ative a extensão:
   - **Mac:** Safari > **Ajustes** > **Extensões**, marque **Userscripts**.
   - **iPhone e iPad:** **Ajustes** > **Apps** > **Safari** > **Extensões** > **Userscripts**, ative **Allow Extension**.
3. Deixe ela rodar em todos os sites. Links magnet podem estar em qualquer site, então o script precisa funcionar em todos.
   - **Mac:** no mesmo painel **Extensões**, clique em **Edit Websites…** e defina **When visiting other websites** como **Allow**.
   - **iPhone e iPad:** na mesma tela do **Userscripts**, defina **All Websites** como **Allow**.
4. No Safari, abra o [arquivo do userscript do DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Ele aparece como texto simples.
5. Abra o popup do Userscripts: o botão dele na barra de ferramentas no Mac, ou o botão **aA** na barra de endereço no iPhone. Toque no aviso de instalação que aparecer e confirme.

Para atualizar depois, abra o popup do Userscripts e toque em **Update** quando ele listar o script do DMM.

## Com Tampermonkey {#with-tampermonkey}

1. Instale o [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) na App Store.
2. Ative-o e deixe que ele rode em todos os sites, como nos passos 2 e 3 acima, com **Tampermonkey** no lugar de **Userscripts**.
3. No Safari, abra a [página do script no Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) e clique em **Install this script**.
4. O Tampermonkey abre a página de instalação dele. Clique em **Install**.

O Tampermonkey verifica se há uma nova versão uma vez por dia.

## Verifique se funciona {#check-it-works}

Abra [Dune: Part Two no Letterboxd](https://letterboxd.com/film/dune-part-two/). Um botão verde-azulado **DMM🔎** aparece ao lado do título, e ele abre o filme no DMM.

Não aparece o botão? Confira estes pontos:

- O popup do gerenciador lista **Debrid Media Manager** e a chave dele está ligada.
- O Safari deixa o gerenciador rodar nesse site. Quando ele perguntar, escolha **Always Allow on Every Website**.
- A página terminou de carregar. Sites como TMDB, Wikipedia e AniList mostram o botão um pouco depois que a página aparece.
