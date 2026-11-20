# ROADMAP — Steal a Brainrot: Meme Madness (long-term plan)

This game is not a one-off bounty entry. It is a long-term asset: publish
it, grow it, and let it earn Robux. The code is built for that — every
piece of content is DATA in one file, so an update is a small edit, never
a rewrite. This file is the plan the owner follows after the bounty.

## How updates work (read this first)

| To add... | Edit this file only | Then |
|---|---|---|
| A new brainrot character | `src/shared/BrainrotData.luau` — one row (name, rarity, cost, income, colours, body, accessory) | Rebuild `game.rbxl` with Rojo, publish the update from Studio |
| A new mutation | `src/shared/Config.luau` — one row in `MUTATIONS` (name, chance, multiplier) + its glow colour in `BrainrotFactory` | Same as above |
| A new event | `src/shared/EventsData.luau` — one row (id, banner text, length) + one handler in `EventService` | Same as above |
| A new gamepass / product | `src/shared/Config.luau` — one row in `MONETIZATION` + create it on the Creator Dashboard, paste the asset id in | Same as above |
| A balance tweak | `src/shared/Config.luau` — spawn rate, prices, income, lock times, rebirth cost | Same as above |

Never edit a `.luau` file by hand inside Studio — hand-typed script text
breaks the recorded-session history. Edit in the repo, rebuild, publish.

## Phase 1 — Launch (20 Nov 2026, bounty deadline 21:30 WIB)

- [ ] Play-test `game.rbxl` in Studio, take 3 screenshots, publish Public
- [ ] Upload icon + thumbnail, fill `PLAY.json`, submit the bounty entry
- [ ] Turn on DataStore API access (Game Settings → Security → "Enable
      Studio Access to API Services") so daily-reward streaks persist
- [ ] Create the 2x Cash + VIP gamepasses and the Cash Pack product on the
      Creator Dashboard, paste their asset ids into `Config.MONETIZATION`
      (see STUDIO-GUIDE.md section 6), publish the update

## Phase 2 — Week 1: promote + fix

- [ ] Post the game on X (@hawa_211) and YouTube (AAK_204): a short clip of
      the conveyor + a steal, link to the experience
- [ ] Watch the first players: which brainrots get bought, where players
      get stuck, what the comments ask for
- [ ] Fix the first bugs (usually: spawn balance, steal fairness, a label
      overlapping the HUD). One small update, not a rebuild
- [ ] First weekly character drop: 2 new brainrots (one Common, one Rare)

## Phase 3 — Weeks 2–4: weekly content + money on

- [ ] Every week: 2–3 new brainrot characters (one row each in
      `BrainrotData`) + one balance tweak from player feedback
- [ ] Gamepasses live: 2x Cash + VIP earning Robux; check Creator
      Dashboard sales weekly
- [ ] Add one new event (a row in `EventsData` + one handler) — ideas:
      "Brainrot Rush" (spawn x3 for 60s), "Freeze Tag" (everyone frozen
      except the richest player for 15s)
- [ ] Add one more gamepass when the first two sell: "Lucky Aura" (better
      mutation luck, +10% mutation chance) — one row in `MONETIZATION`

## Phase 4 — Month 2+: seasons + cash-out

- [ ] Season leaderboard: a monthly top-players board (cash earned in the
      season, not all-time). Needs a second DataStore + a season id in
      Config — build it as its own module, like DailyRewardService
- [ ] Seasonal events: Halloween / Christmas / Ramadan reskins — a new
      event row + a handful of seasonal characters (one week of work, then
      remove the characters from the spawn table when the season ends)
- [ ] Cash out Robux with DevEx once the balance passes 30,000 Robux
      (≈ $105): needs a verified Roblox account, 13+, Premium membership
- [ ] If the game grows past 8 plots: raise `PLOT_COUNT` in Config and add
      more plots to the ring (WorldBuilder builds them from the number)

## What NOT to do

- Do not add paid-only power that ruins free play (2x Cash is a boost,
  not a requirement — a free player must still reach the top).
- Do not copy another game's characters, names or images — the cast is
  original riffs; keep it that way.
- Do not promise Robux or real money inside the game. The shop sells
  gamepasses and cash packs only.
