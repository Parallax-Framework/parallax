-- === Parallax LDoc config ===

project = "Parallax"
title   = "Parallax Documentation"
description = "Documentation for the Parallax framework"

-- output
dir = "public"
style = true -- looks for ldoc.css next to this config (drop your overrides here)
format = "markdown" -- optional; LDoc will fall back if a parser isn't installed

-- input: scan your gamemode, skip vendored libs
topics = "manuals"
file = {
  "gamemode",
  exclude = {
    "gamemode/framework/libraries/thirdparty",
  }
}

-- merging
merge = true -- merge files that declare the same @module

-- parsing / presentation
boilerplate         = true   -- ignore leading license banners
all                 = true   -- include locals/private for full API surface
sort                = false  -- keep source order; set true for alpha
backtick_references = true   -- turn `like.this` into links when possible
readme              = "README.md" -- include a project README at the top

-- rename kinds in the left nav if you want
kind_names = {
  module = "Libraries",
  script = "Scripts",
  topic  = "Manual",
}

-- -----------------------------------------------------------------------------
-- Parallax / GMod style tags
-- -----------------------------------------------------------------------------
-- map your custom tags to built-ins or create new sections

alias("realm",    "usage")   -- renders @realm blocks like usage notes
alias("internal", "private") -- treat @internal as @private (hidden from docs)

-- create a new item type for UI panels if you annotate with @panel
new_type("panel", "Panels")

-- handy param shorthands (so you can use @str, @tbl, @num)
tparam_alias("str", "string")
tparam_alias("tbl", "table")
tparam_alias("num", "number")

-- If you have extra file extensions you want parsed as Lua, uncomment:
-- add_language_extension("inc", "lua")
-- add_language_extension("txt", "lua")  -- only if you're embedding Lua in .txt
