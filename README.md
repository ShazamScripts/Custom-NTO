# Shazam Scripts

Custom para OTCv8/vBot com CaveBot, TargetBot, combate, utilidades e interface personalizada.

## Instalacao

1. Baixe a versao mais recente da custom.
2. Coloque os arquivos na pasta do perfil do bot.
3. Ative `00_FREE_UNIVERSAL.lua` no OTCv8.
4. Reinicie o cliente depois de uma atualizacao.

## Atualizacao automatica

A custom verifica a versao publicada ao abrir o OTCv8. Quando encontra uma
versao mais nova, baixa os arquivos para uma area separada e avisa o jogador.
A instalacao ocorre somente depois de fechar e abrir novamente o OTCv8.

Antes de substituir os arquivos, o atualizador cria um backup. Se houver uma
falha, restaura a versao anterior.

## Dados preservados

O atualizador nao deve substituir configuracoes pessoais. As pastas abaixo nao sao publicadas:

- `storage/`
- `cavebot_configs/`
- `targetbot_configs/`
- `shazam_scripts/`
- `TimeSpelleEnemy/`

## Versao

Versao atual: **2.3.1**

Repositorio oficial: https://github.com/ShazamScripts/Custom-NTO
