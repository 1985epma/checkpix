#!/bin/bash

# Sistema de Verificação de Status - PIX e Plataformas Financeiras
# Interface Gráfica com Zenity

# Configurações
TIMEOUT=10
ICON_ONLINE="dialog-information"
ICON_OFFLINE="dialog-error"
ICON_WARNING="dialog-warning"

# Array com os serviços a verificar
declare -A SERVICOS=(
    ["PIX - Banco Central"]="https://www.bcb.gov.br/pix"
    ["PIX - Status"]="https://www.bcb.gov.br/estabilidade"
    ["Nubank"]="https://www.nubank.com.br"
    ["Itaú"]="https://www.itau.com.br"
    ["MoneyPlus"]="https://www.moneyplus.com.br"
    ["Sinqia"]="https://www.sinqia.com.br"
)

# Cores para o output
VERDE="\033[0;32m"
VERMELHO="\033[0;31m"
AMARELO="\033[1;33m"
AZUL="\033[0;34m"
NC="\033[0m" # No Color

# Arquivo temporário para armazenar resultados
TEMP_FILE="/tmp/pix_status_$$"
RESULTADO_FILE="/tmp/pix_resultado_$$"

# Função para verificar URL
verificar_url() {
    local nome="$1"
    local url="$2"
    local inicio=$(date +%s%N)

    # Tenta conectar à URL
    local resposta=$(curl -s -o /dev/null -w "%{http_code}" --max-time $TIMEOUT "$url" 2>/dev/null)
    local fim=$(date +%s%N)

    # Calcula tempo de resposta em ms
    local tempo_ms=$(( (fim - inicio) / 1000000 ))

    # Determina o status
    if [ -z "$resposta" ]; then
        echo "❌ OFFLINE|$nome|Sem conexão|N/A ms"
    elif [ "$resposta" -lt 400 ]; then
        echo "✅ ONLINE|$nome|HTTP $resposta|${tempo_ms}ms"
    elif [ "$resposta" -lt 500 ]; then
        echo "⚠️ AVISO|$nome|HTTP $resposta|${tempo_ms}ms"
    else
        echo "❌ ERRO|$nome|HTTP $resposta|${tempo_ms}ms"
    fi
}

# Função para exibir janela de progresso
mostrar_progresso() {
    {
        local contador=0
        local total=${#SERVICOS[@]}

        for nome in "${!SERVICOS[@]}"; do
            url="${SERVICOS[$nome]}"
            echo "# Verificando: $nome"
            echo "$((contador * 100 / total))"

            verificar_url "$nome" "$url" >> "$RESULTADO_FILE"

            ((contador++))
        done

        echo "# Processando resultados..."
        echo "100"

    } | zenity --progress \
        --title="Verificador de Status - PIX e Plataformas" \
        --text="Verificando disponibilidade dos serviços...\n\nPor favor, aguarde..." \
        --percentage=0 \
        --auto-close \
        --no-cancel \
        --width=500 \
        --height=150
}

# Função para gerar relatório em HTML
gerar_relatorio_html() {
    local html_file="/tmp/pix_relatorio_$$.html"

    cat > "$html_file" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Status - PIX e Plataformas</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }

        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }

        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }

        .header p {
            font-size: 14px;
            opacity: 0.9;
        }

        .content {
            padding: 30px;
        }

        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }

        .stat-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            text-align: center;
            border-left: 4px solid #667eea;
        }

        .stat-box.online {
            border-left-color: #28a745;
        }

        .stat-box.offline {
            border-left-color: #dc3545;
        }

        .stat-box.warning {
            border-left-color: #ffc107;
        }

        .stat-number {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 5px;
        }

        .stat-label {
            font-size: 12px;
            color: #666;
            text-transform: uppercase;
        }

        .services-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }

        .services-table thead {
            background: #f8f9fa;
        }

        .services-table th {
            padding: 15px;
            text-align: left;
            font-weight: 600;
            color: #333;
            border-bottom: 2px solid #e9ecef;
        }

        .services-table td {
            padding: 15px;
            border-bottom: 1px solid #e9ecef;
        }

        .services-table tbody tr:hover {
            background: #f8f9fa;
        }

        .status-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }

        .status-badge.online {
            background: #d4edda;
            color: #155724;
        }

        .status-badge.offline {
            background: #f8d7da;
            color: #721c24;
        }

        .status-badge.warning {
            background: #fff3cd;
            color: #856404;
        }

        .response-time {
            font-weight: 600;
            color: #667eea;
        }

        .footer {
            background: #f8f9fa;
            padding: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
            border-top: 1px solid #e9ecef;
        }

        @media (max-width: 768px) {
            .stats {
                grid-template-columns: 1fr;
            }

            .services-table {
                font-size: 12px;
            }

            .services-table th,
            .services-table td {
                padding: 10px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔍 Verificador de Status</h1>
            <p>PIX e Plataformas Financeiras</p>
        </div>

        <div class="content">
            <div class="stats" id="stats">
                <!-- Preenchido dinamicamente -->
            </div>

            <table class="services-table">
                <thead>
                    <tr>
                        <th>Serviço</th>
                        <th>Status</th>
                        <th>Código HTTP</th>
                        <th>Tempo de Resposta</th>
                    </tr>
                </thead>
                <tbody id="services-body">
                    <!-- Preenchido dinamicamente -->
                </tbody>
            </table>
        </div>

        <div class="footer">
            <p>Relatório gerado em: <span id="timestamp"></span></p>
            <p>Sistema de Monitoramento de Serviços Financeiros</p>
        </div>
    </div>

    <script>
        // Dados dos serviços (será preenchido pelo script bash)
        const servicos = SERVICOS_DATA;

        function renderizar() {
            let online = 0, offline = 0, aviso = 0;
            let tbody = '';

            servicos.forEach(servico => {
                const [status, nome, info, tempo] = servico.split('|');

                if (status.includes('ONLINE')) online++;
                else if (status.includes('OFFLINE')) offline++;
                else aviso++;

                let statusClass = 'offline';
                if (status.includes('ONLINE')) statusClass = 'online';
                else if (status.includes('AVISO')) statusClass = 'warning';

                tbody += `
                    <tr>
                        <td>${nome}</td>
                        <td><span class="status-badge ${statusClass}">${status}</span></td>
                        <td>${info}</td>
                        <td><span class="response-time">${tempo}</span></td>
                    </tr>
                `;
            });

            document.getElementById('stats').innerHTML = `
                <div class="stat-box online">
                    <div class="stat-number">${online}</div>
                    <div class="stat-label">Online</div>
                </div>
                <div class="stat-box offline">
                    <div class="stat-number">${offline}</div>
                    <div class="stat-label">Offline</div>
                </div>
                <div class="stat-box warning">
                    <div class="stat-number">${aviso}</div>
                    <div class="stat-label">Avisos</div>
                </div>
            `;

            document.getElementById('services-body').innerHTML = tbody;
            document.getElementById('timestamp').textContent = new Date().toLocaleString('pt-BR');
        }

        renderizar();
    </script>
</body>
</html>
EOF

    echo "$html_file"
}

# Função para exibir resultados em janela
exibir_resultados() {
    local online=0
    local offline=0
    local aviso=0
    local texto_resultado=""

    while IFS='|' read -r status nome info tempo; do
        if [[ $status == *"ONLINE"* ]]; then
            ((online++))
            texto_resultado+="$status  $nome\n    └─ $info | $tempo\n\n"
        elif [[ $status == *"OFFLINE"* ]]; then
            ((offline++))
            texto_resultado+="$status  $nome\n    └─ $info | $tempo\n\n"
        else
            ((aviso++))
            texto_resultado+="$status  $nome\n    └─ $info | $tempo\n\n"
        fi
    done < "$RESULTADO_FILE"

    # Cria o texto do resumo
    local resumo="📊 RESUMO DE STATUS\n"
    resumo+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
    resumo+="✅ Online: $online\n"
    resumo+="❌ Offline: $offline\n"
    resumo+="⚠️  Avisos: $aviso\n"
    resumo+="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n"
    resumo+="📋 DETALHES:\n"
    resumo+="$texto_resultado"
    resumo+="⏰ Verificado em: $(date '+%d/%m/%Y às %H:%M:%S')\n"

    # Exibe em janela de texto
    zenity --text-info \
        --title="Resultado da Verificação - PIX e Plataformas" \
        --width=700 \
        --height=600 \
        --no-wrap \
        --filename=<(echo -e "$resumo")
}

# Função para menu principal
menu_principal() {
    zenity --list \
        --title="Verificador de Status - PIX e Plataformas" \
        --text="Selecione uma opção:" \
        --column="Opção" \
        --column="Descrição" \
        --width=600 \
        --height=300 \
        "1" "Verificar Status Agora" \
        "2" "Verificação Contínua (a cada 5 min)" \
        "3" "Exportar Relatório HTML" \
        "4" "Sair"
}

# Função para verificação contínua
verificacao_continua() {
    local contador=0
    local max_iteracoes=12  # 12 x 5 minutos = 1 hora

    while [ $contador -lt $max_iteracoes ]; do
        > "$RESULTADO_FILE"

        for nome in "${!SERVICOS[@]}"; do
            url="${SERVICOS[$nome]}"
            verificar_url "$nome" "$url" >> "$RESULTADO_FILE"
        done

        local online=0
        local offline=0

        while IFS='|' read -r status nome info tempo; do
            [[ $status == *"ONLINE"* ]] && ((online++)) || ((offline++))
        done < "$RESULTADO_FILE"

        local notificacao="Verificação #$((contador+1)) - Online: $online | Offline: $offline"
        notify-send "Status PIX e Plataformas" "$notificacao" -i "$ICON_ONLINE" 2>/dev/null || true

        ((contador++))

        if [ $contador -lt $max_iteracoes ]; then
            sleep 300  # 5 minutos
        fi
    done

    zenity --info \
        --title="Verificação Contínua Concluída" \
        --text="Foram realizadas $max_iteracoes verificações.\n\nVerificação concluída!" \
        --width=400
}

# Função principal
main() {
    while true; do
        opcao=$(menu_principal)

        case $opcao in
            1)
                > "$RESULTADO_FILE"
                mostrar_progresso
                exibir_resultados
                ;;
            2)
                zenity --question \
                    --title="Verificação Contínua" \
                    --text="Isso realizará verificações a cada 5 minutos por 1 hora.\n\nDeseja continuar?" \
                    --width=400

                if [ $? -eq 0 ]; then
                    verificacao_continua
                fi
                ;;
            3)
                > "$RESULTADO_FILE"

                {
                    local contador=0
                    local total=${#SERVICOS[@]}

                    for nome in "${!SERVICOS[@]}"; do
                        url="${SERVICOS[$nome]}"
                        echo "# Gerando relatório: $nome"
                        echo "$((contador * 100 / total))"

                        verificar_url "$nome" "$url" >> "$RESULTADO_FILE"

                        ((contador++))
                    done

                    echo "100"

                } | zenity --progress \
                    --title="Gerando Relatório HTML" \
                    --text="Processando dados..." \
                    --percentage=0 \
                    --auto-close \
                    --no-cancel

                local html_file=$(gerar_relatorio_html)

                # Insere os dados no HTML
                local dados_json="["
                local primeiro=true

                while IFS='|' read -r status nome info tempo; do
                    if [ "$primeiro" = true ]; then
                        dados_json+="\"$status|$nome|$info|$tempo\""
                        primeiro=false
                    else
                        dados_json+=",\"$status|$nome|$info|$tempo\""
                    fi
                done < "$RESULTADO_FILE"

                dados_json+="]"

                sed -i "s|SERVICOS_DATA|$dados_json|g" "$html_file"

                xdg-open "$html_file" 2>/dev/null || firefox "$html_file" 2>/dev/null || true

                zenity --info \
                    --title="Relatório Exportado" \
                    --text="Relatório HTML gerado com sucesso!\n\nArquivo: $html_file" \
                    --width=400
                ;;
            4)
                # Limpeza
                rm -f "$TEMP_FILE" "$RESULTADO_FILE"
                exit 0
                ;;
            *)
                zenity --error \
                    --title="Erro" \
                    --text="Opção inválida!" \
                    --width=300
                ;;
        esac
    done
}

# Verifica se zenity está instalado
if ! command -v zenity >/dev/null 2>&1; then
    echo "❌ Zenity não está instalado!"
    echo "Instale com: sudo apt-get install zenity"
    exit 1
fi

# Verifica se curl está instalado
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ Curl não está instalado!"
    echo "Instale com: sudo apt-get install curl"
    exit 1
fi

# Inicia o programa
main
