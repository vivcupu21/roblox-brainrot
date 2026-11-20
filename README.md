# Steal a Brainrot — Meme Madness

[![make.fun](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/vivcupu21/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/vivcupu21/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01)

A 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01), built by a coding agent in recorded sessions.

## The game

Absurd Italian brainrot characters — Tung Tung Tung Sahur, Tralalero Tralala, Bombardiro Crocodilo, Chimpanzini Bananini and twenty-seven more — waddle down a conveyor through the middle of a 3D world. Hold E to buy one, and it walks to your base and starts earning money every second. Climb the ladder: Common, Rare, Epic, Legendary, Mythic, Brainrot God, Secret, with Gold, Lava, Diamond, Rainbow and Void mutations multiplying income.

The threat is other players: hold E on a rival's brainrot to steal it and carry it home on your head — but they can slap it loose with the Slap tool, and a base lock buys you 60 seconds of safety. Rebirths reset everything for a permanent +25% income boost. And every couple of minutes the world fights back: a tsunami wave sweeps the map, a Golden Hour doubles everyone's income, Brainrot Rain doubles spawns and triples the rare chances, or a Meteor Shower drops rare mutated brainrots onto the conveyor.

Solo players get attacked too: raider NPCs walk in from the map centre in waves (first wave at 90 seconds, then faster and bigger — up to 3 at a time), grab one brainrot off your base, and run. Slap a raider 3 times to drive it off for a cash bonus — slap it while it flees with your brainrot and it drops the loot back home. Raiders never touch a locked base or an empty plot.

The first minute is busy on purpose: brainrots spawn every 1.5 seconds and walk faster, new spawns appear near the middle of the belt, every new player starts with $500 and one free Common already earning on their base, and an event fires every 75 seconds.

Come back every day for a daily reward that grows with your streak, and visit the in-game shop: the 2x Cash and VIP gamepasses and a Cash Pack top-up (the owner creates them on the Creator Dashboard — see STUDIO-GUIDE.md — until then the shop shows them as coming soon and never charges anyone).

## How it is built

- `src/shared/` — `BrainrotData` (the 32-character cast, rarities, mutations), `EventsData` (the event rotation as data) and `Config` (every tuning number in one place: balance, mutations, events, daily rewards, monetization)
- `src/server/` — one module per job: `WorldBuilder` (the whole 3D world from Parts), `BrainrotFactory` (procedural blocky character models, no asset ids), `ConveyorService` (spawn, walk, buy), `PlotService` (bases and slots), `EconomyService` (income ticks, rebirths), `StealService` (steal, carry, slap, base lock), `RaiderService` (enemy NPC waves that attack solo players' bases), `EventService` (tsunami, Golden Hour, Brainrot Rain, Meteor Shower), `LeaderboardService`, `MonetizationService` (gamepasses + developer products, all from `Config.MONETIZATION`), `DailyRewardService` (login streaks), `PlayerState` (the single source of truth for player state), `Remotes`
- `src/client/Game.client.luau` — cash bar, Lock Base / Rebirth buttons, live leaderboard, event banners, toast notifications, first-minute tutorial, daily streak chip, shop panel
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`

## Run it as the grader does

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.
