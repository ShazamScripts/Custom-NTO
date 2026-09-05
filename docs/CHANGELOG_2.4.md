# Shazam Scripts 2.4

## Estabilidade
- Camada central de seguranca para `getDistanceBetween()` e `findPath()`.
- Posicoes e criaturas sao validadas antes de operacoes sensiveis.
- Funcoes CaveBot que terminam sem `return` agora viram `false`, evitando erro do executor.
- `getNearTiles()` e helpers de containers receberam protecoes contra valores ausentes.

## Performance
- Loops de Follow, Stairs, Stack, Jump, Bug Map, Travel, Mystic, PK tracker e timer foram desacelerados onde 1 ms nao traz beneficio pratico.
- Loops de combate do Combo/Especiais foram preservados em alta frequencia para nao alterar a responsividade das rotinas de combate.

## Compatibilidade
- Mantida a estrutura atual de CaveBot/TargetBot e os modulos existentes.
- Sem remocao de funcoes da custom.
