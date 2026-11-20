// Steal a Brainrot — Meme Madness, entry program for roblox-brainrot-01.
// Node 22, standard library only. It hands the game in: copies game.rbxl,
// PLAY.json, src/ and screenshots/ from beside this file into /output and
// writes /output/dossier.json with the vendored make.fun library.
// The game: a 3D conveyor buy-and-steal loop with a 32-character brainrot
// cast, 4 rotating events, rebirths, a shop (2x Cash / VIP gamepasses, Cash
// Pack product) and daily login rewards — all data-driven from src/shared.
//
//
// Run it the way the grader does, with out/ standing in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// The grader fails any output name that does not start with a letter, a digit
// or _ or that holds other characters than letters, digits, . _ and -, so
// dotfiles (.gitkeep, .DS_Store, .git) are never copied.

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** Skip every file or directory whose name starts with a dot. */
const keepNonDotted = (path: string): boolean => !basename(path).startsWith('.');

mkdirSync(out, { recursive: true });
copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: keepNonDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) {
	cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: keepNonDotted });
}

// Same caps the scorer enforces (reference/gate.json): text shapes the bytes,
// the rest refuse an entry the scorer would refuse outright.
writeFileSync(
	join(out, 'dossier.json'),
	buildDossier(out, {
		text_max_bytes: 65536,
		screenshots: { max: 4, max_bytes: 262144 },
		max_instances: 500000,
		scripts_max_source_bytes: 8388608,
		scripts_max_path_chars: 1048576,
	}),
);
