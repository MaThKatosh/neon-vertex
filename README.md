# NEON//VERTEX

Shoot'em up arcade geométrico com estética cyberpunk neon, feito em **Godot 4** (4.3 ou mais novo).
Você é um triângulo e enfrenta 4 setores, cada um com um chefe: **Quadrado, Círculo, Pentágono e Hexágono**.
Ao vencer os quatro, o jogo recomeça num **ciclo** mais difícil.

## Como abrir e jogar

1. Instale o Godot 4 (versão padrão, não precisa da .NET): https://godotengine.org/download
2. No Gerenciador de Projetos, clique em **Importar** e escolha o `project.godot` desta pasta.
3. Aperte **F5** (ou o botão ▶) para jogar.

> A primeira abertura leva 1 ou 2 segundos a mais porque os sons e as músicas são sintetizados por código.

## Controles

| Ação | Teclado | Controle | Celular |
|---|---|---|---|
| Mover | WASD / setas | analógico / D-pad | arraste o dedo em qualquer lugar |
| Tiro | automático | automático | automático |
| Foco (lento + hitbox) | Shift | LB / RB / gatilhos | — |
| Bomba (limpa a tela) | X | B ou X | botão **B** na tela |
| Pausa | Esc / P | Start | botão **II** no topo |
| Som liga/desliga | M | Back/Select | — |

## Mecânicas

- **3 corações**, com invulnerabilidade após levar dano. Ao ser atingido, as balas próximas são apagadas.
- **Poder (PWR 1–4)**: o item **P** aumenta o tiro, e levar dano diminui um nível.
- **Bombas**: o item **B** dá mais uma bomba. Ela apaga todas as balas e transforma cada uma em pontos.
- **Graze**: passar *raspando* numa bala dá pontos.
- **Hitbox** é o pontinho branco no centro da nave. Só ele conta como acerto.
- O item **V** dá uma vida extra (até 5). Ele cai quando um chefe é derrotado.

## Exportar

**Atalho:** dê dois cliques em `tools\export.cmd`. Ele gera `build\windows\NEON-VERTEX.exe`, o zip
`build\NEON-VERTEX-demo-windows.zip` e o `build\android\NEON-VERTEX.apk` (assinado com a chave em
`%USERPROFILE%\.android\neonvertex-release.keystore` — guarde essa chave e o arquivo INFO ao lado dela).

Manualmente, pelo editor:

- **PC (Windows)**: Projeto → Exportar → Adicionar → Windows Desktop. Na primeira vez, o Godot pede para baixar os *export templates*.
- **Android**: precisa do Android SDK + JDK configurados em Editor → Configurações do Editor → Exportar → Android.
  Depois é só Projeto → Exportar → Android. O jogo já está configurado para tela em retrato e controle por toque.
- **Web (bônus)**: exportar para Web gera uma página que roda no navegador do PC e do celular, boa para testes rápidos.

## Mapa do código

```
project.godot            configuração (resolução 540x960 retrato, glow HDR, autoloads)
scenes/main.tscn         cena única; tudo é montado por código em main.gd
scripts/
  cfg.gd                 CONSTANTES: paleta e números do jogador (balanceamento)
  stages.gd              ROTEIRO DAS FASES: ondas de inimigos como dados (edite à vontade)
  main.gd                estados do jogo, diretor das fases, colisões, pontuação
  player.gd              o triângulo
  enemy.gd               inimigos comuns (diamond, gunner, dart, orb, turret)
  bullets.gd             projéteis + padrões de disparo (ring, fan, aim_fan, stack, gap_ring)
  bosses/boss.gd         base dos chefes (fases, transições, barra de vida)
  bosses/boss_*.gd       os 4 chefes
  items.gd               itens P / B / V
  fx.gd                  partículas, tremor e flash
  background.gd          grade neon que rola
  hud.gd                 interface, menus e tela inicial
  neon.gd                funções de desenho neon (brilho em camadas)
  autoload/controls.gd   teclado + controle + toque
  autoload/sfx.gd        sons e músicas sintetizados
```

### Onde mexer para criar

- **Nova onda de inimigos**: adicione linhas em `stages.gd`.
- **Novo chefe**: copie um `boss_*.gd`, mude `_define`, `_phase` e `_draw_body`, e registre-o em `BOSS_SCRIPTS` no `main.gd`.
- **Dificuldade**: `cfg.gd` (jogador), `phase_hp` de cada chefe, e `_set_difficulty()` no `main.gd` (ciclos).
- **Fonte própria**: coloque um arquivo em `assets/fonts/game_font.ttf`.
- **Sons de verdade**: troque os itens de `Sfx.sounds` e `Sfx.tracks` por arquivos `.wav` ou `.ogg`.
