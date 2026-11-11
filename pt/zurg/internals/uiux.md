# Avaliação de UI/UX da configuração de diretórios {#directory-configuration-uiux-assessment}

## Escopo e estado atual {#scope-and-current-state}
- Página: `Directory Configuration` em `http://localhost:9999/directories/`.
- UI atual: uma única tabela simples listando os diretórios sob títulos como "MEDIA" e "RECENT", com colunas para o nome do diretório, a ordem numérica e links de ação ("Edit", "Delete").
- Comportamento: editar e excluir disparam ações simples; não há agrupamento além dos títulos, e não existe um fluxo dedicado de criação ou edição para as opções completas de YAML.

## Principais lacunas de UX {#key-ux-gaps}
- **Arquitetura de informação**
  - Os grupos ficam visualmente achatados; o usuário não consegue focar em um grupo por vez.
  - A ordenação depende de números manuais (`group_order`), o que é pouco intuitivo e fácil de errar.
  - Não há barra de busca/filtro para localizar rapidamente os diretórios.
  - Não há ações em massa (excluir/mover) nem recursos de seleção.
- **Experiência de criação/edição**
  - Os fluxos de edição/adição não mostram o esquema YAML completo (configurações gerais, filtros de tamanho/arquivo/tag/tempo).
  - Não há um layout estruturado; os campos não são agrupados, o que gera sobrecarga cognitiva conforme as opções aumentam.
  - Falta um construtor de regras AND/OR aninhadas para espelhar a lógica de filtros aninhados do YAML.
  - Os campos relacionados a tags (`tags_match_all`, `tags_match_any`) são difíceis de descobrir e não oferecem ajuda para seleção.
  - Não há pré-visualização ao vivo dos torrents que correspondem às configurações de filtro atuais.
- **Orientação e validação**
  - Faltam tooltips/ícones de informação em cada campo e links para documentação mais detalhada (por exemplo, `tags.md`).
  - Não há aviso proativo quando um diretório não vai gerar nenhum torrent ou não tem os filtros obrigatórios.
  - Campos de regex e outros padrões não têm feedback de validação em tempo real.
  - As exclusões acontecem sem confirmação nem opção de desfazer.
- **Acessibilidade e responsividade**
  - O contraste e a legibilidade não foram verificados segundo o WCAG; ações só com ícone podem não ter rótulos.
  - Não há arrastar e soltar; não existe um caminho de reordenação acessível pelo teclado.
  - O layout para celular não está otimizado (a tabela não se adapta a cartões empilhados; os formulários podem não rolar bem).
  - As ações dependem de links só com texto; faltam ícones e áreas de toque claras.
- **Desempenho e polimento da interação**
  - Busca/filtro (quando for adicionado) vai precisar de debounce e de paginação/virtualização para listas grandes.
  - Arrastar e soltar (quando for adicionado) precisa de persistência e de um fallback elegante caso a persistência falhe.

## Mudanças de UI/UX recomendadas {#recommended-uiux-changes}
- **Apresentação dos grupos**
  - Mostre cada `group` de nível superior (por exemplo, media/recent/example) como um card ou seção recolhível, com sua própria lista.
  - Ofereça ações rápidas por grupo (recolher/expandir, seleção em massa).
- **Ordenação**
  - Troque a coluna numérica de ordem por alças de arrastar para reordenar dentro do grupo. Mostre a ordem calculada em um tooltip ou em um badge na linha.
  - Ofereça controles de reordenação que funcionem bem com teclado (botões de mover para cima/baixo), como alternativa de acessibilidade e para celular.
- **Busca e ações em massa**
  - Adicione uma barra de busca/filtro acima da lista. Use debounce no campo de entrada.
  - Adicione checkboxes para excluir ou mover em massa, com a opção "select all in group" para selecionar tudo do grupo de uma vez.
- **Tela de adicionar/editar**
  - Use um modal ou painel lateral com layout em seções: General, Size Filters, File Filters, Tag Filters, Time Filters e Advanced.
  - Adicione subseções recolhíveis para reduzir a sobrecarga visual. Mantenha o estado de expansão durante a sessão.
- **Construtor de regras**
  - Ofereça um construtor visual de AND/OR que espelhe a estrutura do YAML: grupos aninhados, pílulas de condição e seletores de propriedade, operador e valor (por exemplo, has_episodes, regex com matches/does not match).
  - Permita trocar entre AND e OR em cada nó e mostre uma prévia da expressão resultante.
- **Seletor de tags**
  - Use seleção múltipla com autocomplete alimentado pelas tags disponíveis. Mostre descrições em tooltips e as contagens, quando existirem.
  - Deixe bem claro a diferença entre `tags_match_all` e `tags_match_any`.
- **Prévia**
  - Adicione "Preview matching torrents" para buscar resultados de exemplo com o estado atual dos filtros. Mostre skeletons e estados de carregamento, e trate os erros.
- **Orientação**
  - Use tooltips inline ou ícones de informação para cada campo. Coloque links para a documentação completa quando precisar (por exemplo, [tags.md](../reference/tags.md)).
  - Mostre dicas contextuais, como "Only show largest file", que explicam os efeitos colaterais do comportamento.
- **Validação e segurança**
  - Bloqueie o salvamento quando filtros obrigatórios estiverem vazios ou a validação falhar. Mostre os erros inline.
  - Valide regex em tempo real no cliente e confirme também no servidor ao enviar, para evitar divergências.
  - Avise quando a configuração não der match em nenhum torrent, com base na prévia ou em heurísticas.
  - Mostre uma caixa de confirmação antes de excluir. Quando for possível, ofereça um undo curto em forma de snackbar (com soft delete, se for suportado).
- **Acessibilidade e design responsivo**
  - Verifique o contraste da paleta escolhida. Garanta estados de foco e ARIA labels para os controles.
  - Garanta que collapsibles, alças de arrastar e ações sejam acessíveis por teclado.
  - No celular, mostre os grupos como cards empilhados. Garanta que modais e painéis sejam roláveis, com cabeçalhos fixos (sticky) para as ações.
  - Acompanhe ícones com rótulos nas ações principais e garanta nomes acessíveis para os botões que têm só ícone.
- **Acabamento visual**
  - Use iconografia consistente para editar, excluir e reordenar. Adicione divisores sutis e chips para indicar o contexto ou o status do grupo.
  - Considere usar cores por grupo para facilitar a leitura rápida, sempre com contraste acessível.

## Dependências e premissas a confirmar {#dependencies-and-assumptions-to-confirm}
- API support for: persisting group order, bulk operations, nested AND/OR serialization, tag metadata source, and preview query endpoint.
- Behavior of deletes: soft vs hard delete, undo window, and audit needs.
- Ownership/permissions model (if multi-user) for displaying last-edited metadata and preventing conflicts.
- Performance constraints for preview/search; paging or virtualization strategy for large datasets.

## Prioridades de implementação {#implementation-priorities}
1) Reestruture a lista em cards/seções recolhíveis; adicione uma barra de busca/filtro e caixas de diálogo de confirmação.
2) Introduza um modal ou painel lateral de adicionar/editar, com seções, dicas (tooltips) e validação básica; adicione seleção múltipla de tags.
3) Adicione arrastar e soltar + reordenação pelo teclado, com persistência; implemente um construtor de regras E/OU (AND/OR).
4) Adicione uma prévia dos torrents que correspondem às regras, com requisições com debounce e tratamento de erros.
5) Finalize a acessibilidade (caminhos pelo teclado, ARIA) e um layout de cards empilhados e responsivo para celular.
