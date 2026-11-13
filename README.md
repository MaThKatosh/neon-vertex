# NEON//VERTEX

Shoot'em up arcade geométrico com estética cyberpunk neon, feito em **Godot 4** (4.3 ou mais novo).
Você é um triângulo e atravessa **10 setores**, cada um com um chefe geométrico:
**Quadrado, Círculo, Triângulo Rival, Pentágono, Hexágono, Estrela, Gêmeos, Octógono, Tesserato** e, no fim,
**CAOS**, um polígono irregular que usa os poderes de todos os outros.

É um **roguelite**: toda partida começa no setor 1, mas os **créditos** que você ganha ficam salvos e compram
upgrades permanentes no **Hangar**. Quanto mais você joga, mais forte fica. Zerou? Dá para seguir num **ciclo** mais difícil.

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
| Foco (lento + hitbox) | Shift / C | RB / gatilhos | segure o botão **FOCO** |
| Bomba (limpa a tela) | X | B ou X | botão **B** na tela |
| Pausa | Esc / P | Start | botão **II** no topo |
| Som liga/desliga | M | Back/Select | — |

Todas as teclas e botões podem ser trocados em **CONTROLES** no menu inicial (2 teclas + 1 botão de controle por ação).
No celular dá para ajustar a sensibilidade do arrasto, o lado dos botões (canhotos) e ligar/desligar o botão de foco.

## Mecânicas

- **3 corações**, com invulnerabilidade após levar dano. Ao ser atingido, as balas próximas são apagadas.
- **Poder (PWR 1–4)**: o item **P** aumenta o tiro, e levar dano diminui um nível.
- **Bombas**: o item **B** dá mais uma bomba. Ela apaga todas as balas e transforma cada uma em pontos.
- **Graze**: passar *raspando* numa bala dá pontos.
- **Hitbox** é o pontinho branco no centro da nave. Só ele conta como acerto.
- O item **V** dá uma vida extra. Ele cai quando um chefe é derrotado.
- **Armas** (item **W**, que troca de arma enquanto cai): **Leque**, **Laser** (atravessa) e **Enxame** (teleguiado).
  Exclusivas do NG+: **Prisma** (divide em 3), **Pulso** (ondas largas que atravessam) e **Vertex** (tudo junto).

## NEW GAME + (NG+1 a NG+10)

- Zerar o jogo libera o **NG+1**; zerar o NG+1 libera o NG+2, e assim até o **NG+10**. O modo é escolhido no Hangar.
- Cada nível: inimigos com +25% de vida, +10% de cadência, balas 6% mais rápidas, inimigos que soltam balas ao morrer
  e +25% de créditos. Do NG+3 em diante a trilha já começa mais intensa.
- Cada primeira vitória libera um item **exclusivo** na aba **ELITE** do Hangar:
  Prisma (zerar), Coletor (NG+1), Pulso (NG+2), Segunda Chance (NG+3), Escudo Vivo (NG+4), Bomba Nova (NG+5),
  Terceiro Drone (NG+6), Graze Vampírico (NG+7), Núcleo Estável (NG+8), Sobrecarga (NG+9) e a arma **Vertex** (NG+10).

## Trilha sonora

A música é gerada por código em 5 níveis de intensidade: a cada 2 setores o andamento sobe (120 → 156 BPM)
e entram camadas novas (chimbal em semicolcheias, arpejo rápido, bumbo sincopado, lead e viradas). O chefe toca um nível acima.

## Hangar (loja) e créditos

- Créditos vêm de inimigos (1–8 cada), chefes (40 + 20 por setor) e +1000 por zerar os 10 setores.
- Ficam salvos ao derrotar cada chefe, ao pausar e ao fim da partida.
- Upgrades: Corações, Bombas, Poder inicial, Dano, Cadência, Ímã, Recuperação, **Escudo** (absorve acertos),
  **Drones** (naves auxiliares) e liberar **Laser/Enxame** como arma inicial.
- Preços e efeitos ficam em `cfg.gd` (`UPGRADES`) e `autoload/profile.gd`.

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
  stages.gd              ROTEIRO DOS 10 SETORES: ondas de inimigos como dados (edite à vontade)
  main.gd                estados do jogo, diretor das fases, colisões, pontuação
  player.gd              o triângulo
  enemy.gd               inimigos comuns (diamond, gunner, dart, orb, turret)
  bullets.gd             projéteis, lasers dos chefes e padrões (ring, fan, aim_fan, stack, gap_ring)
  bosses/boss.gd         base dos chefes (fases, transições, barra de vida, partes, escudo)
  bosses/boss_*.gd       os 10 chefes
  items.gd               itens P / B / V / W
  fx.gd                  partículas, tremor e flash
  background.gd          grade neon que rola
  hud.gd                 interface, menus e tela inicial
  neon.gd                funções de desenho neon (brilho em camadas)
  autoload/controls.gd   teclado + controle + toque
  autoload/sfx.gd        sons e músicas sintetizados
  autoload/profile.gd    perfil salvo: créditos, upgrades, NG+, recorde
  synth.gd               sintetizador usado pelos sons e músicas
tests/
  smoke_test.gd          joga os 10 setores sozinho e testa loja/escudo/morte
  screenshots.gd         gera capturas do Hangar e dos chefes
```

### Onde mexer para criar

- **Nova onda de inimigos**: adicione linhas em `stages.gd`.
- **Novo chefe**: copie um `boss_*.gd`, mude `_define`, `_phase` e `_draw_body`, e registre-o em `BOSS_SCRIPTS` no `main.gd`.
- **Dificuldade**: `cfg.gd` (jogador), `phase_hp` de cada chefe, e `_set_difficulty()` no `main.gd` (ciclos).
- **Fonte própria**: coloque um arquivo em `assets/fonts/game_font.ttf`.
- **Sons de verdade**: troque os itens de `Sfx.sounds` e `Sfx.tracks` por arquivos `.wav` ou `.ogg`.
