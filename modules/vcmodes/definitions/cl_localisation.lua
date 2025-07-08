--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

local enLocalisation = {
    ["config.voicechat.modes.enabled"] = "Enable Voice Chat Modes",
    ["config.voicechat.modes.enabled.help"] = "Enable or disable the voice chat modes feature. When enabled, players can change their voice chat mode to adjust the distance at which they can be heard by others.",
}

local ruLocalisation = {
    ["config.voicechat.modes.enabled"] = "Включить режимы голосового чата",
    ["config.voicechat.modes.enabled.help"] = "Включить или отключить функцию режимов голосового чата. При включении игроки могут изменять свой режим голосового чата, чтобы настроить расстояние, на котором их могут слышать другие.",
}

local deLocalisation = {
    ["config.voicechat.modes.enabled"] = "Voice Chat Modus aktivieren",
    ["config.voicechat.modes.enabled.help"] = "Aktivieren oder deaktivieren Sie die Funktion Voice Chat Modus. Wenn aktiviert, können Spieler ihren Voice Chat Modus ändern, um die Entfernung anzupassen, in der sie von anderen gehört werden können.",
}

local bgLocalisation = {
    ["config.voicechat.modes.enabled"] = "Активиране на режимите на гласовия чат",
    ["config.voicechat.modes.enabled.help"] = "Активиране или деактивиране на функцията за режимите на гласовия чат. Когато е активирана, играчите могат да променят режима си на гласов чат, за да регулират разстоянието, от което могат да бъдат чути от другите.",
}

ax.localisation:Register("en", enLocalisation)
ax.localisation:Register("ru", ruLocalisation)
ax.localisation:Register("de", deLocalisation)
ax.localisation:Register("bg", bgLocalisation)