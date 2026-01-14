## PR checklist (Style & Hygiene)

Tick all that apply. If something doesn’t apply, briefly explain why.

- [ ] camelCase locals/fields and SCREAMING_SNAKE_CASE constants
- [ ] PascalCase for functions/methods that are part of a public API
- [ ] Guard clauses preferred over deep nesting
- [ ] One statement per line; spaces inside parentheses and around operators
- [ ] Hooks have named identifiers and delegate to named functions
- [ ] No mystery globals; explicit `local` when possible
- [ ] GLua operators used consistently (`!`, `!=`) where applicable
- [ ] `IsValid()` used for entity validity checks
- [ ] Files are named using lower_snake_case.lua by realm when relevant (cl_/sh_/sv_)
- [ ] Public APIs include brief LDOC-style comments
- [ ] Third-party code not modified (placed under `gamemode/framework/thirdparty/`)

Reference: `.github/STYLING.md`
