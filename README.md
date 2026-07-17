# Mikudes Super Hub

Apple Liquid Glass-styled loader hub for Roblox executors.

```
loadstring(game:HttpGet("https://raw.githubusercontent.com/levox00/RobloxHub/main/init.lua"))()
```

## What is this?

A single loadstring entry point (`init.lua`) that:

1. Fetches `auth.json` from the repo
2. Shows a **Discord gate** (copy-invite step)
3. Shows a **key gate** (shared keys in `auth.json`)
4. Renders the **hub shell** with three tabs:
   - **Profile** — your Roblox avatar, current game, server invite copy
   - **Games** — list of supported games with one-click load (Adopt Me, Blox Fruits, Grow A Garden 2, Keyboard Escape)
   - **Info** — changelog, Discord link, credits
5. Visual style: **Apple Liquid Glass** (frosted white panels, glass edges, top reflection sweep, soft shadows, Back.Out scale-in)

## Repo layout

```
Mikudes Super Hub/
├── init.lua              # single entry point
├── auth.json             # discord + keys + ui config + changelog (EDIT ME)
├── ui/
│   ├── init.lua          # UI primitives (theme + GlassCard / Button / Input / Slider / Toggle / Pill / Notify / drag)
│   ├── Profile.lua       # user + game card
│   ├── Games.lua         # game registry + search + load buttons
│   └── Info.lua          # changelog + discord + credits
├── Games/
│   ├── AdoptMe.lua       # game module (skeleton)
│   ├── BloxFruits.lua    # game module (skeleton)
│   ├── GrowAGarden2.lua  # game module (skeleton)
│   └── keyboardEscape.lua # universal: rejoin-servers
└── LiquidGlass.lua       # standalone Apple Glass panel (legacy — kept for reference)
```

## Editing auth.json

```json
{
  "discord": { "invite_url": "https://discord.gg/YOUR_INVITE", ... },
  "keys":    { "valid": ["MikuHub-XXXX", ...] },
  "ui":      { "accent_color": [255, 105, 180], "tabs": ["Profile", "Games", "Info"] }
}
```

The hub fetches this file at load time — push a commit and the next user gets your new keys/config automatically.

## Adding a new game

1. Drop `Games/YourGame.lua` — module pattern: a `main()` that builds its own `ScreenGui`
2. Edit `ui/Games.lua` — add an entry to `REGISTRY`:
   ```lua
   { key = "yourgame", label = "Your Game", description = "What it does",
     path = "Games/YourGame.lua", placeIds = {12345} }
   ```
3. Pull latest + commit + push

## Contributing

See `Contributing Guidelines.md`.
