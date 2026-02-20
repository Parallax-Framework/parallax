# Copilot instructions — Parallax Framework

This file gives an immediate, actionable orientation for an AI coding agent working in Parallax.

## 1) Big picture (where things live)
- **Entry points**: `gamemode/init.lua` (server) and `gamemode/cl_init.lua` (client). They include `framework/util.lua` and `framework/boot.lua`.
- **Framework auto-loads**: `framework/boot.lua` includes these directories in order: `libraries/`, `meta/`, `core/`, `hooks/`, `networking/`, `interface/`.
- **Global namespace**: Top-level framework table is `ax` (e.g. `ax.util`, `ax.config`, `ax.character`, `ax.item`, `ax.gui`). Add new subsystems under `framework/` or standalone modules under `modules/`.
- **Schema architecture**: Schemas extend the framework (see `minerva-hl2rp/gamemode/schema/` for example). Schemas have their own `boot.lua`, `factions/`, `classes/`, `items/`, `hooks/`, etc.

## 2) Naming / realm conventions (critical)
- **File prefixes determine realm**: `cl_` = client-only, `sv_` = server-only, `sh_` = shared. `ax.util:DetectFileRealm` and `ax.util:Include` follow this pattern automatically.
- **Prefer framework inclusion**: Place files under existing framework directories and rely on `ax.util:IncludeDirectory("...")` rather than manual `include`/`AddCSLuaFile` calls.
- **File naming**: Use lowercase with underscores (e.g. `chat_util.lua`, `sh_movement.lua`).

## 3) Loading & initialization patterns
- **Boot sequence**: `framework/boot.lua` auto-includes framework directories, then `GM:OnReloaded()` in `hooks/sh_hooks.lua` handles schema/module loading.
- **OnReloaded hook**: Calls `ax.faction:Include()`, `ax.class:Include()`, `ax.item:Include()`, `ax.module:Include()`, and `ax.schema:Initialize()` for hot-reloadable systems.
- **Module pattern**: Modules can have their own `OnReloaded()` method for initialization (see `modules/sh_ambients.lua` example).

## 4) Store & networking pattern (common & important)
- **Store factory**: `framework/store_factory.lua` provides the canonical store pattern. Stores have `registry`, `defaults`, `values`, and `networkedKeys`.
- **Config vs Options**: `ax.config` (server→client settings) vs `ax.option` (client→server preferences). Both use `ax.util:CreateStore()` with different `spec.name` and `authority`.
- **Networking setup**: Server registers nets automatically. `ax.config` broadcasts changes to clients via `spec.net.set`. `ax.option` syncs client preferences to server cache.
- **Adding networked settings**: Set `data.bNetworked = true` in store registration to enable automatic sync.
- **Persistence**: Stores auto-save to JSON files via `ax.util:ReadJSON`/`ax.util:WriteJSON`.

## 5) Debugging & developer workflow
- **No build step**: Drop gamemode folder into `garrysmod/gamemodes/`, start with `+gamemode your-schema-name`.
- **Developer mode**: Set `developer 1` ConVar to enable `ax.util:PrintDebug` output and detailed framework logging.
- **Linting**: Use `.glualint.json` configuration. Follow `STYLE.md` conventions (4 spaces, colon methods, K&R formatting).
- **Documentation**: LDoc generates docs to `public/` via `config.ld`. Use LDOC comments with `@realm`, `@param`, `@return`, `@usage`.
- **Version tracking**: `version.json` contains version/build info, updated by CI workflows.

## 6) Project-specific patterns and gotchas
- **Include helpers**: Prefer `ax.util:Include(path)` and `ax.util:IncludeDirectory(dir)` over raw `include`/`AddCSLuaFile` - they handle realm detection and path normalization.
- **Logging consistency**: Use `ax.util:Print*` helpers (Error, Warning, Debug, Success) instead of `MsgC`/`print` for framework-consistent output.
- **JSON persistence**: Framework provides `ax.util:ReadJSON` and `ax.util:WriteJSON` - stores automatically use these for config persistence.
- **LocalPlayer wrapper**: `boot.lua` wraps `LocalPlayer()` to return `ax.client` when set, respect this in client code.
- **Module hot-reload**: Modules can implement `MODULE:OnReloaded()` for initialization - see ambients module example.

## 7) Where to look (quick pointers)
- **Include/realm logic**: `gamemode/framework/util.lua`
- **Store/networking patterns**: `gamemode/framework/store_factory.lua`
- **Load order and initialization**: `gamemode/framework/boot.lua` + `gamemode/framework/hooks/sh_hooks.lua`
- **Entry points**: `gamemode/init.lua`, `gamemode/cl_init.lua`
- **Schema example**: `minerva-hl2rp/gamemode/schema/` (real working schema)
- **Style guide**: `STYLE.md`; **Overview**: `README.md`; **Module docs**: `MODULES.md`

## 8) Short actionable examples (copyable patterns)
- **Add client UI file**: Create `gamemode/framework/interface/cl_newpanel.lua` - auto-included, no manual AddCSLuaFile needed.
- **Register networked config**: `ax.config:Add("myKey", ax.type.string, "default", {bNetworked = true})` - auto-syncs to clients.
- **Create module with init**: Add `MODULE:OnReloaded()` method for hot-reload initialization (see modules/sh_ambients.lua pattern).

## 9) Styling & docs
- **Explicit style**: Repository defines strict rules in `STYLE.md`. Key points:
  - **Indentation**: 4 spaces (no tabs)
  - **Method notation**: Use colon (`:`) for methods expecting `self` (e.g. `function ax.util:Foo()`)
  - **Spacing**: K&R-like with spaces inside parentheses and around operators; blank lines between logical blocks
  - **File naming**: lowercase with underscores (e.g. `chat_util.lua`)
  - **Documentation**: LDOC-style comments for public functions — include `@realm`, `@param`, `@return`, `@usage`
  - **Linter**: `.glualint.json` available; CI runs linting on PRs

## 10) License & attribution
- **MIT license**: Files include copyright header. Preserve attribution on modified files.
- **Headers required**: All new files need the standard Parallax Framework copyright header.

If any section above is unclear or you want more examples (adding a store, wiring net messages, schema patterns), tell me which area to expand and I'll iterate.

# Copilot instructions — Commit messages
You are writing a Git commit message. Follow these rules exactly, matching Refined GitHub’s expectations:

FORMAT
- Use Conventional Commits:
  <type>[optional scope]: <short description>
- Allowed <type> values: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- Breaking changes: either `type!:` or include a `BREAKING CHANGE:` footer
- Optional [scope]: folder, package, module, or subsystem name (e.g., [hud], [swep], [gm], [ui])

TITLE (first line)
- Max 72 characters. No trailing period. Imperative mood. Example: "fix(hud): clamp ammo display to non-negative"
- Be specific; prefer the most affected subsystem as scope
- Lowercase after the colon unless it’s a proper noun

BODY (optional, after a blank line)
- Wrap lines to ~72 characters
- Explain the “why” and the impact, not every diff hunk
- When helpful, use concise bullets or short paragraphs
- Mention edge cases, decisions, and trade-offs

FOOTERS (optional, each on its own line)
- Closes #123  (or)  Fixes #123
- Refs #456
- Co-authored-by: Name <email>
- BREAKING CHANGE: describe what changed and migration steps

STYLE DOs
- Group changes logically; one commit per coherent change
- Describe behavior, not file names (“fix NRE on empty magazine” > “update hud.lua”)
- Keep noise out of titles: no emojis, no tags other than type/scope

STYLE DON’Ts
- Don’t exceed 72 chars in the title
- Don’t end the title with punctuation
- Don’t write past-tense or vague junk like “misc fixes”

GOOD EXAMPLES
- feat(swep): add MW-style rotational aim sway with smoothing
- fix(hud): prevent negative ammo values when clip1 < 0
- refactor(net): replace deprecated umsg with net messages
- perf(pathing): cache nav areas to cut lookup time by ~30%
- docs(readme): add setup steps for Linux dedicated server
- chore(ci): run Lua linter and unit tests on pull_request

BAD EXAMPLES (don’t do these)
- "update files"
- "Fixes"
- "big changes to stuff in gamemode"

TEMPLATE (use this structure):

<type>[optional scope]: <short description within 72 chars>

[why and impact; wrapped to ~72 columns; bullets allowed]

[Closes #id]
[Refs #id]
[Co-authored-by: Name <email>]
[BREAKING CHANGE: explanation and migration]

Now, based on the staged changes, generate a single, best-possible commit message that follows the above rules.
