# STUDIO GUIDE — what Ade does on his Windows/Mac computer

The game code is done and `game.rbxl` is built. These steps need Roblox
Studio, so only Ade can do them. Do them in order, before the deadline
**20 Nov 2026 21:30 WIB**.

## 0. Before anything: age check + Studio

1. If Roblox asks, pass the age check once ("Buka Kunci" in the Roblox app
   or on the site — facial estimate or government ID). An account cannot
   publish until it is past this check and at least 2 days old.
2. Install Roblox Studio from https://create.roblox.com and sign in with
   the XboXMeta_1 account.

## 1. Open the game and play-test it

1. In Studio: File → Open from File → pick `game.rbxl` from this repo.
2. Press **Play** (F5). Walk around with WASD, camera with right mouse.
3. Wait a few seconds: brainrots should walk down the middle conveyor.
   Hold **E** near one to buy it (you start with $100 — buy Noobini
   Pizzanini for $15). It should walk to your base and your cash should
   start ticking up at the top of the screen.
4. Press **Stop**. If anything looks wrong, tell Lonte what you saw.

## 2. Take 3 screenshots (1280×720, each under 256 KiB)

1. Press Play again. While the game is running, take captures with
   Studio's screenshot tool (View → Screenshot, or the camera icon).
2. Take exactly these three, and save them into this repo's `screenshots/`
   folder with these names:
   - `1-thumbnail.png` — the COVER: stand near the conveyor with several
     brainrots walking and your base behind. This one is also uploaded as
     the game's thumbnail (step 4), so make it the best shot.
   - `2-play.png` — mid-game: your character near a brainrot, cash bar
     visible at the top.
   - `3-base.png` — your base with brainrots standing on their slots.
3. Each file must be 16:9 (1280×720 is perfect), at most 256 KiB — if one
   is bigger, re-save it as JPEG quality ~80 or scale it down. Keep the
   HUD text clear of the top-left corner (Roblox's own menu sits there).
4. Delete any other files in `screenshots/` — only these three.

## 3. Publish as a Public experience

1. In Studio: File → Publish to Roblox As → **Create new experience**,
   name it **"Steal a Brainrot — Meme Madness"**, then Publish.
2. File → Game Settings → Basic Info: write a description (any text about
   the game) and add the make.fun play code (ask Lonte for the code — run
   `node cli/makefun.mjs check --repo <repo> --play-code 0` in the kit),
   pick a Genre, answer the content questions (say No to age-restricted
   content), Save.
3. On the Creator Dashboard (https://create.roblox.com/dashboard/creations)
   open the experience → set it **Public**.
4. Find the two ids and write them into this repo's `PLAY.json`:
   - `place_id`: the number in the play link
     (https://www.roblox.com/games/<place_id>).
   - `universe_id`: the number after `experiences/` in the experience's
     Creator Dashboard address (or `game.GameId` in Studio).
   - `url`: `https://www.roblox.com/games/<place_id>`

## 4. Upload the icon + thumbnail (Creator Dashboard)

1. Same page: Configurations → Places → start place (star) → **Icon**:
   upload a square picture (512×512 is best — any clear picture of the
   game works).
2. Same place → **Thumbnails** → Experience Detail Page tab: upload
   `1-thumbnail.png` FIRST (it must be the first thumbnail, and the same
   picture as the file in `screenshots/`).
3. Wait until the experience's page on Roblox shows both the icon and the
   thumbnail. Roblox reviews each upload — do not submit while either is
   still "in review".

## 5. Tell Lonte, then he finishes

Once steps 2–4 are done, tell Lonte. He will re-run `node main.ts`,
run the kit's `check`, and submit with the sealed recording before the
deadline. Do NOT edit any `.luau` file by hand in Studio — hand-typed
script text does not count as agent-written and hurts the transcript gate.

## 6. Turn on the money (after the bounty — long-term)

The game already has a shop (2x Cash gamepass, VIP gamepass, Cash Pack
product) and a daily reward. Both need two things from you on the Creator
Dashboard. Do this after the bounty submit, not before — the entry works
fine with the shop showing "SOON".

1. **Daily rewards that remember players:** in Studio, File → Game
   Settings → Security → turn ON "Enable Studio Access to API Services",
   Save, then publish the update. Without this the daily reward still
   pays once per visit, but streaks reset every session.
2. **Create the gamepasses:** Creator Dashboard → your experience →
   Monetization → Passes → Create Pass. Make two:
   - **2x Cash** — price 99 Robux. Copy its asset id (the number in its
     page address).
   - **VIP** — price 199 Robux. Copy its asset id.
3. **Create the developer product:** Monetization → Developer Products →
   Create Product: **Cash Pack** — price 49 Robux. Copy its product id.
4. **Paste the ids into the game:** in this repo open
   `src/shared/Config.luau`, find `MONETIZATION`, and replace the three
   `assetId = 0` values with the real ids (one row each — 2x Cash, VIP,
   Cash Pack). Tell Lonte, and he rebuilds `game.rbxl` and you publish
   the update from Studio.
5. **Check:** open the game, press the 🛒 Shop button — the items should
   now show their Robux prices instead of SOON. (You cannot buy your own
   gamepass with the same account, so test the purchase flow with a
   second account if you have one.)
