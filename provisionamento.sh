#!/usr/bin/env bash
# Author: mr-reinaldo
# Description: Script de Provisionamento de um Servidor Web.
# Date: 04/02/2023
# Version: 1.0

# Variáveis
PACOTES_INSTALACAO=("apache2" "unzip")                                                                  # Pacotes a serem instalados
LINK_ARQUIVOS_APLICACAO="https://github.com/denilsonbonatti/linux-site-dio/archive/refs/heads/main.zip" # Link para o arquivo zip
LOG_FILE="/tmp/provisionamento.log"                                                                     # Arquivo de log
# Variáveis de cores
REDC='\033[0;31m'    # Cor vermelha
GREENC='\033[0;32m'  # Cor verde
YELLOWC='\033[0;33m' # Cor amarela
BLUEC='\033[0;34m'   # Cor azul
NC='\033[0m'         # Sem cor

# Função para verificar a quantidade de atualizações
function verifica_atualizacoes() {
    echo -e "${BLUEC}[1/7] Verificando a quantidade de atualizações disponíveis... ${NC}"
    apt update &>/dev/null
    QUANTIDADE_ATUALIZACOES=$(apt list --upgradable 2>/dev/null | wc -l)
    if [ ${QUANTIDADE_ATUALIZACOES} -gt 0 ]; then
        echo -e "${YELLOWC} [!] Há ${QUANTIDADE_ATUALIZACOES} atualizações disponíveis! ${NC}"
        atualizar_sistema
    else
        echo -e "${GREENC} [✓] Não há atualizações disponíveis! ${NC}"
    fi
}

# Função para atualizar o sistema
function atualizar_sistema() {
    echo -e "${BLUEC} [2/7] Iniciando a atualização do sistema... ${NC}"
    apt update &>/dev/null && apt upgrade -y &>/dev/null && apt dist-upgrade -y &>/dev/null
    verifica_codigo_retorno
}

# Função para instalar pacotes
function instalar_pacotes() {
    echo -e "${BLUEC} [3/7] Iniciando a instalação dos pacotes... ${NC}"
    for pacote in ${PACOTES_INSTALACAO[@]}; do
        echo -e "${YELLOWC} Instalando o pacote: ${pacote} ${NC}"
        apt install ${pacote} -y &>/dev/null
        verifica_codigo_retorno
    done
}

# Função de verificação de codigo de retorno
function verifica_codigo_retorno() {
    if [ $? -eq 0 ]; then
        echo -e "${GREENC}[✓] Processo concluído com sucesso! ${NC}"
    else
        echo -e "${REDC}[x] Ocorreu um erro no processo! ${NC}"
        exit 1
    fi
}

# Função para baixar o arquivo zip para /tmp
function baixar_arquivos() {
    echo -e "${BLUEC} [4/7] Iniciando o download dos arquivos... ${NC}"
    wget ${LINK_ARQUIVOS_APLICACAO} -O /tmp/arquivos.zip &>/dev/null
    verifica_codigo_retorno
}

# Função para descompactar o arquivo zip e copiar os arquivos para /var/www/html.
function descompactar_arquivo() {
    echo -e "${BLUEC} [5/7] Descompactando o arquivo zip... ${NC}"
    # Descompacta o arquivo zip e replace se o diretório já existir
    unzip -o /tmp/arquivos.zip -d /tmp/ &>/dev/null
    verifica_codigo_retorno
    echo -e "${BLUEC} [6/7] Copiando os arquivos para /var/www/html... ${NC}"
    cp -R /tmp/linux-site-dio-main/* /var/www/html/ &>>${LOG_FILE}
    verifica_codigo_retorno
}

# Função para reiniciar o serviço apache2
function reiniciar_apache() {
    echo -e "${BLUEC} [7/7] Reiniciando o serviço apache2... ${NC}"
    systemctl restart apache2 &>/dev/null || service apache2 restart &>/dev/null
    verifica_codigo_retorno
}

# Função para verificar se o usuário é root
function verifica_usuario_root() {
    if [ $(id -u) -ne 0 ]; then
        echo -e "${REDC} O script deve ser executado como root! ${NC}"
        echo -e "${REDC} Execute o comando: sudo ./provisionamento.sh ${NC}"
        exit 1
    fi
}

# Função principal
function main() {
    clear
    cat <<EOF
    +------------------------------------------------+
    |                                                |
    |   Script de Provisionamento de um Servidor Web |
    |                                                |
    +------------------------------------------------+
EOF

    verifica_usuario_root # Verifica se o usuário é root
    verifica_atualizacoes # Verifica se há atualizações
    instalar_pacotes      # Instala os pacotes
    baixar_arquivos       # Baixa os arquivos da aplicação
    descompactar_arquivo  # Descompacta os arquivos e copia para /var/www/html
    reiniciar_apache      # Reinicia o serviço apache2
}

# Chamada da função principal
main
