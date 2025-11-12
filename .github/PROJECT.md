Projeto: Board proposto para checkpix
===============================

Visão geral
-----------
Este documento descreve a proposta de um Project (quadro) para organizar o desenvolvimento do `checkpix`.

Colunas sugeridas (Kanban)
- Backlog — ideias e tasks propostas que ainda não foram priorizadas.
- To do — tarefas priorizadas para execução.
- In Progress — tarefas em andamento.
- Review / QA — tarefas finalizadas e aguardando revisão ou validação de segurança.
- Done — tarefas concluídas.

Automação sugerida
- Ao abrir um Pull Request com etiqueta `bug` ou `feature`, mova o cartão para "In Progress".
- Quando o workflow CI passa e o PR é aprovado, mova para "Review / QA".

Etiquetas (labels) sugeridas
- bug
- enhancement
- docs
- security
- help wanted

Como criar o Project (sugestão)
--------------------------------
1. Pelo GitHub UI: Projects → New project → selecionar "Board (Kanban)".
2. Criar as colunas acima e adicionar regras de automação se desejar.
3. Associar issues/PRs ao quadro usando a caixa lateral "Projects".

Observação: este arquivo é apenas documentação local com a proposta do board. Para criação automática, use `gh` (GitHub CLI) ou a API do GitHub.
