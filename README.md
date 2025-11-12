# checkpix

`checkpix` é um script Bash simples para verificar o status do PIX e de outras plataformas/serviços financeiros. Ele fornece uma interface gráfica mínima (via `zenity`) para executar checagens, mostrar progresso e exportar um relatório em HTML com os resultados.

## Funcionalidades

- Verifica múltiplas URLs definidas no script (`SERVICOS`).
- Mostra uma barra de progresso enquanto executa as requisições.
- Exibe um resumo com detalhes (online/offline/avisos) em uma janela gráfica via `zenity`.
- Gera um relatório HTML visual, com contadores e tabela de resultados.
- Modo de verificação contínua (a cada 5 minutos por 1 hora) com notificações do sistema.

## Requisitos

- Sistema Linux com ambiente gráfico (X11/Wayland) para que `zenity` funcione.
- `bash` (v3+), `curl` e `zenity` instalados.
- `xdg-open` ou um navegador (por exemplo `firefox`) para abrir o relatório HTML.

Instalação de dependências (Debian/Ubuntu):

```bash
sudo apt-get update
sudo apt-get install -y curl zenity xdg-utils
```

## Como usar

1. Dê permissão de execução ao script (se ainda não tiver):

```bash
chmod +x pix.sh
```

2. Execute o script:

```bash
./pix.sh
```

O script abrirá uma janela com opções. As opções disponíveis são:

- Verificar Status Agora: executa uma checagem única de todos os serviços mostrando progresso e depois um resumo detalhado.
- Verificação Contínua (a cada 5 min): roda verificações periódicas (12 iterações de 5 min = 1 hora) e envia notificações do sistema a cada iteração.
- Exportar Relatório HTML: gera um arquivo HTML com o relatório e tenta abri-lo no navegador.
- Sair: encerra o programa.

## Como funciona (internals)

- O arquivo define um array associativo `SERVICOS` com pares `nome -> url`.

## Executando no Windows / WSL

O script foi escrito para rodar em ambientes POSIX (Linux). Em Windows existem algumas opções para executá-lo:

- Recomendado: usar WSL (Windows Subsystem for Linux).

  - Windows 11 (WSLg): suporte a apps gráficos via WSLg. Instale/ative o WSL e uma distro (por exemplo Ubuntu):

    ```powershell
    wsl --install -d ubuntu
    ```

    Depois, abra a distro (Ubuntu), atualize e instale dependências:

    ```bash
    sudo apt-get update
    sudo apt-get install -y curl zenity xdg-utils
    chmod +x pix.sh
    ./pix.sh
    ```

    Observações:
    - No Windows 11 com WSLg, `zenity` abrirá janelas gráficas automaticamente.
    - Para abrir o relatório HTML gerado a partir do WSL no navegador do Windows, você pode usar:

    ```bash
    explorer.exe "$(wslpath -w /tmp/pix_relatorio_<PID>.html)"
    ```

    ou instalar `wslu` e usar `wslview`:

    ```bash
    sudo apt install -y wslu
    wslview /tmp/pix_relatorio_<PID>.html
    ```

- WSL2 no Windows 10 (sem WSLg): use um servidor X no Windows (por exemplo VcXsrv ou X410).

  1. Instale e inicie o servidor X no Windows (VcXsrv).
  2. No WSL, exporte a variável DISPLAY apontando para o host do X (exemplo comum):

    ```bash
    export DISPLAY=$(grep -m1 nameserver /etc/resolv.conf | awk '{print $2}'):0
    export LIBGL_ALWAYS_INDIRECT=1
    ```

  3. Instale dependências e execute o script como no exemplo do Ubuntu acima.

  Observação: variáveis de ambiente e firewall podem bloquear a comunicação com o servidor X; verifique a documentação do VcXsrv.

- Git Bash / MSYS2 / Cygwin

  - É possível executar o script em ambientes como Git Bash, mas muitas distribuições Windows não têm `zenity` nem `xdg-open` por padrão. Isso significa que as janelas gráficas e a abertura automática do HTML podem não funcionar.
  - Para uma experiência completa recomenda-se usar WSL/WSLg ou uma instalação Linux. Se preferir tentar no Git Bash, instale `curl` (via Git for Windows bundle ou pacotes) e execute o script, mas espere que algumas funcionalidades gráficas não estejam disponíveis.

## Dicas úteis

- Se o relatório HTML não abrir automaticamente, localize o arquivo no terminal (o script imprime o path) e abra manualmente no Windows com `explorer.exe` ou arrastando para o navegador.
- Para converter caminhos entre WSL e Windows use `wslpath`.
- Em caso de problemas com janelas gráficas no WSL2 + X server, verifique firewall e se o servidor X está aceitando conexões.

- Para cada serviço, a função `verificar_url` faz um `curl --max-time <TIMEOUT>` e obtém apenas o código HTTP (via `-w "%{http_code}"`). Também mede o tempo de resposta em milissegundos.
- Os resultados são escritos numa variável/arquivo temporário (`/tmp/pix_resultado_$$`) no formato:

```
<EMOJI/STATUS>|<NOME>|<INFO>|<TEMPO>
```

- A interface usa `zenity --progress` para mostrar progresso enquanto percorre os serviços.
- A exportação HTML gera um arquivo temporário contendo um template. O script injeta os dados dos serviços no template substituindo o placeholder `SERVICOS_DATA` por um array JSON simples. Depois o arquivo é aberto com `xdg-open` ou `firefox`.

## Arquivos temporários

O script usa arquivos em `/tmp` com sufixo `$$` (PID) para evitar colisões, por exemplo:

- `/tmp/pix_resultado_$$`
- `/tmp/pix_relatorio_$$.html`

Observação: o script já remove os temporários ao sair da opção `Sair`, mas melhorias possíveis (recomendadas) são usar `mktemp` e um `trap` para garantir limpeza em qualquer saída.

## Saída e códigos

- O script indica status baseado no código HTTP retornado pelo `curl`:
  - códigos < 400 → ONLINE
  - códigos >= 400 e < 500 → AVISO
  - códigos >= 500 → ERRO
  - ausência de resposta → OFFLINE

## Troubleshooting

- Se o script encerrar imediatamente com mensagens sobre falta de comandos, verifique e instale `zenity` e `curl`.
- Se `zenity` não abrir janelas, confirme que você está em um ambiente gráfico com DISPLAY configurado (ou execute localmente em uma sessão gráfica).
- Caso o relatório HTML não abra automaticamente, localize o arquivo impresso no terminal (ex.: `/tmp/pix_relatorio_<PID>.html`) e abra manualmente com o navegador.

## Melhorias recomendadas

- Usar `mktemp` para criar arquivos temporários de forma segura.
- Adicionar `trap 'cleanup' EXIT` para garantir limpeza de temporários em sinais/erros.
- Substituir a injeção de dados via `sed` por um gerador mais robusto (por exemplo `jq` para preparar JSON) para evitar falhas quando os campos tiverem caracteres especiais.
- Adicionar retries com backoff ao `curl` para maior robustez em redes instáveis.
- Adicionar verificação e instruções de instalação automática opcionais (por exemplo: prompt para instalar dependências).
- Rodar `shellcheck` e aplicar recomendações para estilo/segurança.

## Contribuindo

Pull requests são bem-vindos. Para pequenas correções e melhorias, abra uma issue descrevendo o problema ou a melhoria proposta. Para mudanças de comportamento, prefira abrir uma issue primeiro para discutir.

## Licença

Este projeto está licenciado sob a MIT License. Consulte o arquivo `LICENSE` no repositório para os termos completos.

---

Se quiser, eu posso aplicar algumas das melhorias recomendadas automaticamente (por exemplo: migrar para `mktemp` + adicionar `trap` e tornar a injeção de dados no HTML mais robusta). Diga qual melhoria prefere que eu implemente primeiro.
