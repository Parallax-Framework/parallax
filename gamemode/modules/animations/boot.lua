--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.name = "Animations"
MODULE.description = "Handles player animations."
MODULE.author = "riggs9162"

ax.config:Add("animations.ik", ax.type.bool, true, {
    category = "animations",
    subCategory = "general",
    description = "animations.ik.help"
})

local LANG = {}
LANG["config.animations.ik"] = "Inverse Kinematics (IK)"
LANG["config.animations.ik.help"] = "When enabled, the player's feet will adjust to uneven terrain for more realistic movement."
LANG["category.animations"] = "Animations"

ax.localization:Register("en", LANG)

LANG = {}
LANG["config.animations.ik"] = "Ters Kinematik (IK)"
LANG["config.animations.ik.help"] = "Etkinleştirildiğinde, oyuncunun ayakları daha gerçekçi hareket için engebeli zemine uyum sağlar."
LANG["category.animations"] = "Animasyonlar"

ax.localization:Register("tr", LANG)

LANG = {}
LANG["config.animations.ik"] = "Inverse Kinematik (IK)"
LANG["config.animations.ik.help"] = "Wenn aktiviert, passen sich die Füße des Spielers für realistischere Bewegung an unebenes Gelände an."
LANG["category.animations"] = "Animationen"

ax.localization:Register("de", LANG)

LANG = {}
LANG["config.animations.ik"] = "Кинематика (IK)"
LANG["config.animations.ik.help"] = "При включении ноги игрока будут адаптироваться к неровной поверхности для более реалистичного движения."
LANG["category.animations"] = "Анимации"

ax.localization:Register("ru", LANG)

LANG = {}
LANG["config.animations.ik"] = "Cinemática Inversa (IK)"
LANG["config.animations.ik.help"] = "Cuando está habilitado, los pies del jugador se ajustarán al terreno irregular para un movimiento más realista."
LANG["category.animations"] = "Animaciones"

ax.localization:Register("es", LANG)
