# Parallax Framework – Roadmap

This roadmap outlines completed, in-progress, and planned features for the Parallax roleplay framework. Each item is tracked for reference, including historical tasks that have been completed earlier in development.

---

## Core Systems

- [x] Basic player data saving and loading
- [x] Character selection handler
- [x] Initial schema skeleton setup
- [x] Character creation handler
- [x] Character deletion support
- [x] Character data persistence (inventory, stats, metadata)

---

## User Interface

- [x] Base UI framework and styling
- [x] Gamepad-style main menu concept
- [x] Character creation screen (name, description, model selection)
- [x] Inventory screen (weight display, item tooltips)
- [ ] Death screen with respawn/spectate options
- [ ] Tooltip system for hover-based info
- [ ] Responsive HUD elements (health, ammo, status)

---

## Inventory System

- [x] Inventory persistence backend
- [ ] Weight-based capacity and movement impact
- [ ] UI item dragging and dropzones
- [ ] Stacking logic and merge rules

---

## Item System

- [x] Basic item registration
- [x] Networked item data sync
- [x] Item pickup/drop/use logic
- [x] Item categorization support

---

## Animation System

- [x] Animation handling for:
  - [x] `citizen_male`
  - [x] `citizen_female`
  - [x] `metrocop`
  - [x] `overwatch`
  - [x] `player`

---

## Framework Internals

- [x] `ax.relay` (secure value distribution)
- [x] `ax.sqlite` (dynamic SQLite abstraction)
- [ ] Test coverage for relay/event edge cases
- [ ] Expand relay scope to support metadata flags
- [ ] Add relay access control per scope

---

## Other Features

- [x] Rich notification system
- [x] Server-side logging and monitoring
- [x] In-game chat system (text, voice)

---

_Last updated: May 2025_
