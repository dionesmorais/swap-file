#!/bin/bash
###################################################################################
# Script para criar memória swap
# Coder: Diones Alves
# Data : 15/05/2018
# Autalização: 10/01/2025
# Email: diones.acesso@gmail.com
# Descrição: Este script cria um arquivo de swap para aumentar a memória virtual.
# OBS.: Foi necessário modificar a lógica para usar o comando chattr +C "$SWAPFILE" 
# para desativar o CoW no arquivo de swap e assim atender ao requisio do sistema de arquivos Btrfs.
##################################################################################
clear
free -m
echo "Criando swap, por favor aguarde."
SWAPFILE="/opt/swapfile"

# Verificar se o arquivo swap já existe
if [ -f "$SWAPFILE" ]; then
    read -p "O arquivo de swap já existe: $SWAPFILE. Deseja abortar (a) ou criar com um novo nome (n)? " escolha
    if [ "$escolha" == "a" ]; then
        echo "Abortando a criação do swap."
        exit 1
    elif [ "$escolha" == "n" ]; then
        read -p "Por favor, forneça um novo nome para o arquivo de swap: " novo_nome
        SWAPFILE="/opt/$novo_nome"
        echo "Criando swap com o novo nome: $SWAPFILE"
    else
        echo "Opção inválida. Abortando."
        exit 1
    fi
fi

# Solicitar permissões de superusuário
if [ "$EUID" -ne 0 ]; then
    clear
    echo "O usuário $USER não possui permissão para criar o arquivo $SWAPFILE"
    echo "Por favor, execute este script como root."
    exit 1
fi

# Criar o arquivo de swap sem CoW
sudo touch "$SWAPFILE"
sudo chattr +C "$SWAPFILE"  # Desativar CoW
sudo dd if=/dev/zero of="$SWAPFILE" bs=1M count=2000 status=progress
sudo chmod 0600 "$SWAPFILE"

# Verificar o tipo de arquivo e permissões
file "$SWAPFILE"
ls -lh "$SWAPFILE"

sudo mkswap "$SWAPFILE"
sudo swapon "$SWAPFILE" || { echo "Erro ao ativar o swap. Verifique os logs com dmesg."; sudo dmesg | tail; exit 1; }
echo .
free -m

echo "Arquivo de swap criado com sucesso em $SWAPFILE."
