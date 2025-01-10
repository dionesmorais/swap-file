# Script de Criação de Memória Swap

## Descrição

Este script foi desenvolvido por Diones Alves com o objetivo de criar um arquivo de swap para aumentar a memória virtual do sistema. Ele verifica se o arquivo de swap já existe, pergunta ao usuário se deseja abortar ou criar um novo arquivo com um nome diferente, e executa as etapas necessárias para configurar o swap.

## Uso

Para executar o script, abra o terminal e digite:

```bash
sudo ./create-swap-file.sh
```

Certifique-se de executar o script como superusuário (root) para ter as permissões necessárias.

## Problemas Encontrados

### Problema com `fallocate`

Inicialmente, usamos o comando `fallocate` para criar o arquivo de swap, pois ele é mais rápido do que `dd`. No entanto, encontramos problemas ao ativar o swap em sistemas de arquivos Btrfs. O comando `swapon` falhava com a mensagem de erro:

```
swapon: /opt/swapfile: swapon failed: Argumento inválido
```

### Solução para Btrfs

Após investigar os logs de erro com `dmesg`, descobrimos que o arquivo de swap não pode ter o atributo "copy-on-write" (CoW) no sistema de arquivos Btrfs. Para resolver isso, seguimos as etapas abaixo:

1. Criamos o arquivo de swap sem usar `fallocate` ou `dd` diretamente.
2. Desativamos o CoW no arquivo de swap usando o comando `chattr +C`.
3. Configuramos o arquivo de swap com as permissões corretas e o ativamos.

## Código do Script

Aqui está o código do script atualizado:

```bash
#!/bin/bash
###############################################################
# Script para criar memória swap
# Coder: Diones Alves
# Data : 15/05/2018
# Email: diones.acesso@gmail.com
# Descrição: Este script cria um arquivo de swap para aumentar a memória virtual.
##############################################################
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
```

## Licença

Este script está disponível sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.
