# Sts2SoloCoop — local two-instance co-op (one operator, two characters)

Controlling **both** co-op characters on one screen. STS2 co-op is a networked lockstep — its ~10
per-choice synchronizers (Event / Map / Reward / Combat / Act / RestSite / …) each wait for every
player's networked vote, so a single-process "hotseat" isn't practical. Instead we run **two real
instances** (genuine network peers → all synchronizers satisfied → the game works exactly as intended)
and unify **control + window layout** with the tools here. The `Sts2SoloCoop` mod adds the in-game
diagnostics.

## One-time setup
1. Enable the **`Sts2SoloCoop`** mod (both instances read the same `mods/` folder, so enabling once
   covers both). For a clean session, disable unrelated gameplay mods (they can desync co-op).
2. Set the game to **Windowed** mode (Settings → Video). Exclusive/borderless fullscreen ignores
   window tiling.
3. Keep **Steam running** (Steamworks init). Optional: install [AutoHotkey v2](https://www.autohotkey.com/)
   for one-key window switching.

## Launch + tile
```powershell
cd <this folder>
./coop-launch.ps1
```
- Ensures two instances are running (the 2nd is launched straight from the exe, bypassing Steam's
  single-instance lock) and tiles them **left = player 1, right = player 2**.
- `./coop-launch.ps1 -NoLaunch` just re-tiles instances that are already open.

## Connect the two instances (in-game) — native menu, no console
The scripts launch with **`--fastmp`**, which makes the game's **normal Multiplayer menu** use ENet
localhost. Just use the real menu:
- Left window → **Multiplayer → Host** (hosts on 127.0.0.1:33771, then the normal character select / lobby).
- Right window → **Multiplayer → Join** → a **join 127.0.0.1** button appears → click it.

Both pick a character, ready up, host begins the run — all through the game's own UI. No dev console,
no debug screen.
- Launching by hand? Add the arg yourself on **both**: `SlayTheSpire2.exe --fastmp` (a Steam-launched
  instance won't have it).
- Genuinely solo (one instance)? The mod's `AllowSoloBegin` patch lets a lone host begin a
  multiplayer-type run for smoke-testing — but a real 2nd instance is needed to actually play both.

## Control both characters
- **Left window = player 1, right = player 2.** Whichever window has focus receives your input.
- Switch with **Alt-Tab / click**, or — with AutoHotkey running `coop-control.ahk` — one key:
  - `F1` focus left (player 1), `F2` focus right (player 2), `F3` toggle, `F4` re-tile.

### Co-op is a shared vote — act on BOTH windows at decision points
STS2 co-op moves the party together: the **map, events, rewards** are shared votes that only resolve
once **every player has chosen**. So to advance you must act in **both** windows, e.g. to travel:
click the next node in the left panel **and** in the right panel. This is normal — not a stuck click.
Combat is per-player (each controls their own character), so play each on its own window.

### Embedded window (coop-embed.ps1)
Both instances live in one container; host auto-sorts to the left, client (window titled
"… (Client)") to the right once it joins. **Closing the container quits both games.**

## In-game diagnostics (mod console commands)
- `sc_probe` — dump the net type, players and their NetIds, and the local perspective.
- `sc_swap <netid>` — change `LocalContext.NetId` (the "who am I" perspective) for testing; guarded so
  an invalid id can't freeze the UI. Run `sc_probe` first to list valid NetIds.

## Files
| File | What |
|---|---|
| `coop-launch.ps1` | Launch two instances (`--fastmp`) side by side (top-level windows → cursor stays correct). `-Windowed` = borderless, one-window look, windowed; no flag = full-screen tiling. |
| `coop-embed.ps1` | **Experimental**: embed both instances INSIDE one container window (grid). Reparents via Win32 SetParent — may be fragile with the Godot game; falls back to `coop-launch.ps1`. |
| `coop-control.ahk` | Optional AutoHotkey v2 script: F1/F2/F3 window focus switch, F4 re-tile. |
