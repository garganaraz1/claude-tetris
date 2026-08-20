# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page Tetris implementation in vanilla JavaScript (ES6+), HTML5 Canvas, and CSS. No dependencies, no `package.json`, no build step, no test suite.

## Running the game

Open `index.html` directly, or serve it statically:

```bash
python3 -m http.server 8000   # then open http://localhost:8000
# or
npx serve .
```

There is no build, lint, or test command — the three files are loaded as-is by the browser.

## Architecture

The entire game lives in three files that map 1:1 to concerns: `index.html` (DOM/canvas structure), `style.css` (dark/retro theme), `game.js` (all logic, ~300 lines, single top-level scope, no modules/classes).

Everything in `game.js` operates on module-level mutable state (`board`, `current`, `next`, `score`, `lines`, `level`, `paused`, `gameOver`, `dropInterval`, etc.) rather than being passed explicitly between functions — keep this pattern when extending rather than introducing classes or state containers.

Key mechanics, if modifying game behavior:

- **Board**: `ROWS × COLS` matrix; each cell is `0` (empty) or a piece color index (1–7).
- **Pieces**: square matrices in `PIECES`; rotation is done via matrix transpose+reverse (`rotateCW`), not by storing pre-rotated states.
- **Collision** (`collide`): bounds + occupied-cell check, reused for movement, rotation, and ghost-piece projection.
- **Wall kicks** (`tryRotate`): on rotation collision, retries at x offsets `[0, -1, 1, -2, 2]` before giving up.
- **Locking** (`lockPiece` → `merge` + `clearLines` + `spawn`): called both when a piece can't fall further and on hard drop.
- **Line clear** (`clearLines`): scans bottom-up, splices completed rows out and unshifts empty rows in, re-checking the same index (`r++`) after a splice.
- **Scoring/leveling**: `LINE_SCORES = [0,100,300,500,800]` × `level`; hard drop is 2 pts/cell, soft drop 1 pt/row; level = `floor(lines/10)+1`; drop speed = `max(100, 1000 - (level-1)*90)` ms.
- **Game loop** (`loop`): `requestAnimationFrame`-driven, accumulates elapsed time and drops the piece when `dropAccum >= dropInterval`; pause/resume cancels/reschedules the animation frame rather than gating inside the loop.
- **Ghost piece** (`ghostY`): projects `current` straight down via `collide` and renders it at `globalAlpha = 0.2`.

If changing `COLS`, `ROWS`, or `BLOCK` in `game.js`, also update the `<canvas id="board">` `width`/`height` in `index.html` to match (`COLS × BLOCK`, `ROWS × BLOCK`).
