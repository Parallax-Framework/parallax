# Legacy interface (frozen)

Everything under `gamemode/legacy/` is the **pre-rewrite** Parallax user interface. It is kept for reference only.

**Nothing in this directory is loaded.** The framework boot (`gamemode/framework/boot.lua`) includes `libraries`, `meta`, `core`, `hooks`, `networking` and `interface` relative to `gamemode/framework/`, and `ax.module` includes only the named subfolders of each module directory. `gamemode/legacy/` sits outside both, so no file here is ever `include`d or `AddCSLuaFile`d. Do not add it to a boot path — port what you need into the new UI instead.

The original paths are mirrored so a moved file maps back one-to-one:

| Legacy path | Original path |
| --- | --- |
| `legacy/framework/interface/` | `framework/interface/` |
| `legacy/framework/libraries/` | `framework/libraries/` |
| `legacy/modules/<module>/interface/` | `modules/<module>/interface/` |

## What moved

- **`framework/interface/`** — all 31 panel files (main menu, character create/load, tab menu, inventory, store/settings widgets, radial menu, scoreboard, help pages, tooltips, transitions, buttons, comboboxes, scrollers, text entries, frames).
- **`framework/libraries/`** — `cl_skin.lua` (the derma `SKIN` table), `cl_theme.lua` (`ax.theme` glass palette + drawing helpers), `cl_font.lua` (`ax.font`), `cl_markup.lua` (`ax.markup`), `cl_elements.lua` (`ax.elements` HUD registry).
- **`modules/*/interface/`** — panels for the `admin`, `chatbox`, `containers`, `doors` and `zones` modules.

## What deliberately stayed put

These are drawing/input substrate rather than UI design, and the new interface is expected to build on them:

- `framework/libraries/thirdparty/cl_rndx.lua` — `ax.render` (rounded boxes, blur, materials), used by non-UI code too.
- `framework/libraries/thirdparty/` — `cl_imgui`, `cl_mmask`, `cl_outline`, `cl_gfonts`, `cl_scrcache`, `cl_viewstack`.
- `framework/libraries/cl_bind.lua` — `ax.bind` key binding registry.
- `framework/libraries/cl_motion.lua` — `ax.motion`. Moved here in the first pass and since **restored** to the live tree: it eases arbitrary panel fields and depends only on `ax.ease` and the `performance.animations` option, so it is animation substrate rather than visual style. The new interface drives its hover and page transitions through it.
- `framework/libraries/sh_notification.lua` — `ax.notification` (draws directly, no panels).
- `framework/hooks/cl_hooks.lua` — HUD/menu hook bodies, view modifiers, `ax.client` caching.
- `modules/cl_ammo_counter.lua`, `modules/cl_curvy.lua`, `modules/cl_intro.lua`.
- Module `libraries/cl_*.lua` files (chatbox, recognition, zones editor, mapscene).

## Dangling references to fix during the rewrite

Code outside `legacy/` still calls into the moved libraries and panels. `vgui.Create` on an unregistered class logs `Tried to create unknown panel type ...` and returns nil (most call sites are already `IsValid`-guarded), but the direct library calls below will error until the new UI provides them.

**Library calls (will error):**

| Call | Site |
| --- | --- |
| `ax.elements:PaintHUD()` | `framework/hooks/cl_hooks.lua:308` (every frame) |
| `ax.elements:GetEntityDisplayText()` | `framework/hooks/cl_hooks.lua:312` |
| `ax.theme:GetGlass()` / `:GetMetrics()` / `:DrawGlassPanel()` / `:DrawGlassButton()` | `framework/core/sh_character.lua:127-143,377,481,596-597`; `modules/recognition/libraries/cl_recognition.lua:374-493` |
| `ax.markup.Parse()` | `modules/sh_3dtext.lua:105` |

`ax.theme` is gone for good rather than pending — the new interface commits to one look and reads flat tokens from `ax.color`, so the glass call sites above get rewritten against `ax.draw` when those screens are ported, not restored.

**Already resolved** by `framework/interface/cl_font.lua`: `ax.font:Load()` (`framework/hooks/sh_hooks.lua:22,44`, `framework/core/sh_options.lua`) and `ax.font:CreateFamily()` (`modules/admin/hooks/cl_hooks.lua:7-11`) — the new registry keeps the `ax.<size>[.bold][.italic][.shadow]` names, so existing font references such as `ax.small.bold` still resolve.

**Panel classes expected by non-legacy code:**

| Class | Requested from |
| --- | --- |
| `ax.main` | `framework/hooks/cl_hooks.lua:15`, `framework/networking/cl_networking.lua:18`, `framework/libraries/sv_character.lua:317`, `framework/networking/sv_networking.lua:492` (last two via `SendLua`) |
| `ax.tab` | `framework/hooks/cl_hooks.lua:28` |
| `ax.pause` | `framework/hooks/cl_hooks.lua:367` |
| `ax.chatbox` | `modules/chatbox/hooks/cl_hooks.lua:50`, `modules/chatbox/libraries/cl_chatbox.lua:72,153` |
| `ax.container.storage` | `modules/containers/networking/cl_networking.lua:29` |
| `ax.zone.editor` | `modules/zones/libraries/cl_editor.lua:402` |
| `ax.doors.config` | reached via `ax.gui.door_config` in `modules/doors/networking/cl_net.lua` |

`ax.gui.*` handles still referenced outside legacy: `main`, `tab`, `pause`, `inventory`, `settings`, `chatbox`, `journal`, `door_config`, `recognitionIntroduce`, `bPauseLegacy`.

The full list of panel classes the legacy UI registered is recoverable with:

```sh
grep -rhoE 'vgui\.Register\(\s*"[^"]+"' gamemode/legacy
```

## Schemas

The schemas (`parallax-hl2rp`, `parallax-bmrp`, `parallax-cvr`, `parallax-militaryrp`) were **not** touched. Their own `interface/` directories and `cl_hooks.lua` HUD code still derive from the panels and `ax.theme`/`ax.font` APIs that moved here, and will break until ported to the new interface.
