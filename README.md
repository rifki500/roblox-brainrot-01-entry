# Snackrot Market — a 3D Roblox brainrot game

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/rifki500/roblox-brainrot-01-entry/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard)
[![reward](https://make.fun/badge/roblox-brainrot-01/rifki500/roblox-brainrot-01-entry/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A make.fun entry for **roblox-brainrot-01**: a 3D brainrot game built by an AI
agent. Entered on [make.fun](https://make.fun/bounty/roblox-brainrot-01).

**Snackrot Market** is a night market where absurd snack-animal hybrids roll
down a conveyor belt. Walk up to one, hold E to buy it, and keep it on your
base — each snackrot earns money every second. Climb the ladder of rarities
(Common, Rare, Epic, Legendary) and mutations (Golden, Diamond, Rainbow),
rebirth for a permanent income multiplier, and steal snackrots from other
players' bases — unless their owner is home defending. Every two minutes a
Snack Storm sweeps the map and clears the belt, so grab your catch and run
home.

The cast is original: Mie Meong (noodle cat), Burger Banteng (burger bull),
Pisang Penguin (banana penguin), Kopi Kucing (coffee cat), Durian Dino,
Sambal Shark (chili shark), Rendang Robot and Nasi Naga (fried-rice dragon).

## How it plays

- Walk to a snackrot on the belt, hold **E** to buy it (if you can afford it).
- It moves to your base and earns money every second, shown on the HUD.
- **Sell** a snackrot from your base for half its price (hold E on it).
- **Steal** a snackrot from another player's base (hold E for 3 seconds) —
  blocked while its owner stands near their base.
- **Rebirth** (button, bottom right): reset your money and base for +50%
  income forever. Cost doubles each rebirth.
- Every 120 seconds a **Snack Storm** sweeps the belt: un-bought snackrots
  are swept away, so buy before the wave hits.

## How it runs

`main.ts` (Node 22, standard library only) hands the game in: it copies
`game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out
every name that starts with a dot, and writes `/output/dossier.json` with
`vendor/makefun-roblox.ts`, the kit's copy, unchanged.

The place is built Rojo-first, no Studio needed:

    ~/tools/rojo build default.project.json --output game.rbxl
    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

- `src/shared/Data.luau` — the cast, rarities, mutations, bases and economy.
- `src/server/Game.luau` — belt, bases, economy, stealing, rebirths, the storm.
- `src/server/CharacterFactory.luau` — builds each snackrot's 3D model.
- `src/client/Game.client.luau` — the HUD: money, income, feed, rebirth button.

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the
kit's RULES.txt.
