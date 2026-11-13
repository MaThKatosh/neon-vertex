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
- O item **V** dá uma vida extra. Ele cai quando um chefe é derrotado.
- **Armas** (item **W**, que troca de arma enquanto cai): **Leque**, **Laser** (atravessa) e **Enxame** (teleguiado).

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
  autoload/profile.gd    perfil salvo: créditos, upgrades, recorde
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
