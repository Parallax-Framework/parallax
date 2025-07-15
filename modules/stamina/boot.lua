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

    local esLocalization = {}
    esLocalization["config.stamina"] = "Resistencia"
    esLocalization["config.stamina.drain"] = "Tasa de consumo de resistencia"
    esLocalization["config.stamina.drain.help"] = "La velocidad a la que disminuye la resistencia del jugador."
    esLocalization["config.stamina.help"] = "Activar o desactivar la resistencia."
    esLocalization["config.stamina.max"] = "Resistencia máxima"
    esLocalization["config.stamina.max.Help"] = "La cantidad máxima de resistencia que puede tener el jugador (debe reaparecer para aplicar este cambio)."
    esLocalization["config.stamina.regen"] = "Tasa de regeneración de resistencia"
    esLocalization["config.stamina.regen.help"] = "La velocidad a la que se regenera la resistencia del jugador."
    esLocalization["config.stamina.tick"] = "Frecuencia de actualización de resistencia"
    esLocalization["config.stamina.tick.help"] = "La frecuencia con la que se actualiza la resistencia del jugador."

    local ptLocalization = {}
    ptLocalization["config.stamina"] = "Resistência"
    ptLocalization["config.stamina.drain"] = "Taxa de consumo de resistência"
    ptLocalization["config.stamina.drain.help"] = "A velocidade a que a resistência do jogador diminui."
    ptLocalization["config.stamina.help"] = "Ativar ou desativar a resistência."
    ptLocalization["config.stamina.max"] = "Resistência máxima"
    ptLocalization["config.stamina.max.Help"] = "A quantidade máxima de resistência que o jogador pode ter (precisa de renascer para aplicar esta alteração)."
    ptLocalization["config.stamina.regen"] = "Taxa de regeneração de resistência"
    ptLocalization["config.stamina.regen.help"] = "A velocidade a que a resistência do jogador se regenera."
    ptLocalization["config.stamina.tick"] = "Frequência de atualização de resistência"
    ptLocalization["config.stamina.tick.help"] = "A frequência com que a resistência do jogador é atualizada."

    local bgLocalisation = {}
    bgLocalisation["config.stamina"] = "Издръжливост"
    bgLocalisation["config.stamina.drain"] = "Скорост на изразходване на издръжливостта"
    bgLocalisation["config.stamina.drain.help"] = "Скоростта, с която издръжливостта на играча се изразходва."
    bgLocalisation["config.stamina.help"] = "Активиране или деактивиране на издръжливостта."
    bgLocalisation["config.stamina.max"] = "Максимална издръжливост"
    bgLocalisation["config.stamina.max.Help"] = "Максималното количество издръжливост, което играчът може да има (трябва да се възроди, за да приложи това)."
    bgLocalisation["config.stamina.regen"] = "Скорост на възстановяване на издръжливостта"
    bgLocalisation["config.stamina.regen.help"] = "Скоростта, с която издръжливостта на играча се възстановява."
    bgLocalisation["config.stamina.tick"] = "Честота на актуализация на издръжливостта"
    bgLocalisation["config.stamina.tick.help"] = "Честотата, с която се актуализира издръжливостта на играча."

    ax.localization:Register("de", deLocalization)
    ax.localization:Register("en", enLocalization)
    ax.localization:Register("ru", ruLocalization)
    ax.localization:Register("es-ES", esLocalization)
    ax.localization:Register("pt-PT", ptLocalization)
    ax.localisation:Register("bg", bgLocalisation)
end