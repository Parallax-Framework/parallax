--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("weapon.raise.time", ax.type.number, 0.25, {
    description = "config.weapon.raise.time.help",
    min = 0,
    max = 2,
    decimals = 2,
    category = "gameplay",
    subCategory = "weapon_safety",
})

ax.config:Add("weapon.raise.alwaysraised", ax.type.bool, false, {
    description = "config.weapon.raise.alwaysraised.help",
    category = "gameplay",
    subCategory = "weapon_safety",
})

ax.localization:Register("en", {
    ["subcategory.weapon_safety"] = "Weapon Safety",
    ["config.weapon.raise.time"] = "Weapon Raise Hold Time",
    ["config.weapon.raise.alwaysraised"] = "Always Weapon Raised",
    ["config.weapon.raise.time.help"] = "How long the reload key must be held (in seconds) before toggling weapon raise.",
    ["config.weapon.raise.alwaysraised.help"] = "When enabled, all players will always have their weapon raised regardless of individual state.",
})

ax.localization:Register("tr", {
    ["subcategory.weapon_safety"] = "Silah Güvenliği",
    ["config.weapon.raise.time"] = "Silah Kaldırma Basılı Tutma Süresi",
    ["config.weapon.raise.alwaysraised"] = "Silah Her Zaman Kaldırılı",
    ["config.weapon.raise.time.help"] = "Silah kaldırmayı değiştirmek için yeniden yükleme tuşunun kaç saniye basılı tutulması gerektiği.",
    ["config.weapon.raise.alwaysraised.help"] = "Etkinleştirildiğinde, tüm oyuncular bireysel durumdan bağımsız olarak silahlarını her zaman kaldırılı tutacak.",
})

ax.localization:Register("es", {
    ["subcategory.weapon_safety"] = "Seguridad de Armas",
    ["config.weapon.raise.time"] = "Tiempo de Pulsación para Levantar Arma",
    ["config.weapon.raise.alwaysraised"] = "Arma Siempre Levantada",
    ["config.weapon.raise.time.help"] = "Cuánto tiempo debe mantenerse presionada la tecla de recarga (en segundos) para alternar el levantamiento del arma.",
    ["config.weapon.raise.alwaysraised.help"] = "Cuando está activado, todos los jugadores siempre tendrán su arma levantada independientemente del estado individual.",
})

ax.localization:Register("ru", {
    ["subcategory.weapon_safety"] = "Безопасность Оружия",
    ["config.weapon.raise.time"] = "Время удержания для поднятия оружия",
    ["config.weapon.raise.alwaysraised"] = "Оружие всегда поднято",
    ["config.weapon.raise.time.help"] = "Как долго нужно удерживать клавишу перезарядки (в секундах) для переключения поднятия оружия.",
    ["config.weapon.raise.alwaysraised.help"] = "При включении все игроки всегда будут держать оружие поднятым, независимо от индивидуального состояния.",
})

ax.localization:Register("de", {
    ["subcategory.weapon_safety"] = "Waffensicherheit",
    ["config.weapon.raise.time"] = "Haltezeit zum Waffe heben",
    ["config.weapon.raise.alwaysraised"] = "Waffe immer gehoben",
    ["config.weapon.raise.time.help"] = "Wie lange die Nachladen-Taste gehalten werden muss (in Sekunden), bevor das Heben der Waffe umgeschaltet wird.",
    ["config.weapon.raise.alwaysraised.help"] = "Wenn aktiv, haben alle Spieler ihre Waffe immer gehoben, unabhaengig vom individuellen Status.",
})

ax.localization:Register("bg", {
    ["subcategory.weapon_safety"] = "Безопасност на Оръжието",
    ["config.weapon.raise.time"] = "Време на задържане за вдигане на оръжие",
    ["config.weapon.raise.alwaysraised"] = "Оръжието винаги вдигнато",
    ["config.weapon.raise.time.help"] = "Колко дълго трябва да се задържи клавишът за презареждане (в секунди), за да се превключи вдигането на оръжието.",
    ["config.weapon.raise.alwaysraised.help"] = "Когато е включено, всички играчи винаги ще имат вдигнато оръжие, независимо от индивидуалното им състояние.",
})
