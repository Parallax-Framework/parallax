--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Stamina"
MODULE.Description = "Cross-realm stamina management system."
MODULE.Author = "Riggs"

if ( CLIENT ) then
    local deLocalization = {}
    deLocalization["config.stamina"] = "Ausdauer"
    deLocalization["config.stamina.drain"] = "Ausdauerabflussrate"
    deLocalization["config.stamina.drain.help"] = "Die Rate, mit der die Ausdauer des Spielers abfließt."
    deLocalization["config.stamina.help"] = "Aktivieren oder deaktivieren Sie die Ausdauer."
    deLocalization["config.stamina.max"] = "Maximale Ausdauer"
    deLocalization["config.stamina.max.Help"] = "Die maximale Menge an Ausdauer, die der Spieler haben kann. Spieler müssen sich neu spawn, um dies anzuwenden."
    deLocalization["config.stamina.regen"] = "Ausdauerregenerationsrate"
    deLocalization["config.stamina.regen.help"] = "Die Rate, mit der die Ausdauer des Spielers regeneriert wird."
    deLocalization["config.stamina.tick"] = "Ausdauer-Tickrate"
    deLocalization["config.stamina.tick.help"] = "Die Rate, mit der die Ausdauer des Spielers aktualisiert wird."

    local enLocalization = {}
    enLocalization["config.stamina"] = "Stamina"
    enLocalization["config.stamina.drain"] = "Stamina Drain Rate"
    enLocalization["config.stamina.drain.help"] = "The rate at which the player's stamina drains."
    enLocalization["config.stamina.help"] = "Enable or disable stamina."
    enLocalization["config.stamina.max"] = "Max Stamina"
    enLocalization["config.stamina.max.Help"] = "The maximum amount of stamina the player can have, players need to respawn to apply this."
    enLocalization["config.stamina.regen"] = "Stamina Regen Rate"
    enLocalization["config.stamina.regen.help"] = "The rate at which the player's stamina regenerates."
    enLocalization["config.stamina.tick"] = "Stamina Tick Rate"
    enLocalization["config.stamina.tick.help"] = "The rate at which the player's stamina is updated."

    local ruLocalization = {}
    ruLocalization["config.stamina"] = "Выносливость"
    ruLocalization["config.stamina.drain"] = "Скорость поглощения выносливости"
    ruLocalization["config.stamina.drain.help"] = "Скорость с которой поглащается выносливость игрока."
    ruLocalization["config.stamina.help"] = "Должна ли выносливость быть включена?"
    ruLocalization["config.stamina.max"] = "Максимальная выносливость"
    ruLocalization["config.stamina.max.Help"] = "Максимальное кол-во выносливости которое может иметь игрок, для принятия эффекта игрок должен перевозродиться."
    ruLocalization["config.stamina.regen"] = "Скорость восстановления выносливости"
    ruLocalization["config.stamina.regen.help"] = "Скорость с которой восстанавливается выносливость игрока."
    ruLocalization["config.stamina.tick"] = "Интервал обновления выносливости"
    ruLocalization["config.stamina.tick.help"] = "Интервал, с которым обновляется выносливость игрока."

    ax.localization:Register("de", deLocalization)
    ax.localization:Register("en", enLocalization)
    ax.localization:Register("ru", ruLocalization)
end