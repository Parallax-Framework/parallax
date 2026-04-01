ax.localization:Register("de", {
    -- General
    ["yes"] = "Ja",
    ["no"] = "Nein",
    ["ok"] = "OK",
    ["cancel"] = "Abbrechen",
    ["apply"] = "Anwenden",
    ["close"] = "Schließen",
    ["back"] = "Zurück",
    ["next"] = "Weiter",
    ["unknown"] = "Unbekannt",

    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Fraktionen",
    ["mainmenu.category.01_identity"] = "Identität",
    ["mainmenu.category.02_appearance"] = "Aussehen",
    ["mainmenu.category.03_other"] = "Sonstiges",
    ["mainmenu.create"] = "Charakter erstellen",
    ["mainmenu.disconnect"] = "Trennen",
    ["mainmenu.load"] = "Charakter laden",
    ["mainmenu.options"] = "Optionen",
    ["mainmenu.play"] = "Spielen",

    -- Tab Menu Translations
    ["tab.config"] = "Konfiguration",
    ["tab.help"] = "Hilfe",
    ["tab.help.overview"] = "Uebersicht",
    ["tab.help.commands"] = "Befehle",
    ["tab.help.factions"] = "Fraktionen",
    ["tab.help.modules"] = "Module",
    ["tab.inventory"] = "Inventar",
    ["tab.scoreboard"] = "Punktestand",
    ["tab.settings"] = "Einstellungen",
    ["tab.characters"] = "Charaktere",

    -- Category Translations
    ["category.chat"] = "Chat",
    ["category.gameplay"] = "Gameplay",
    ["category.general"] = "Allgemein",
    ["category.audio"] = "Audio",
    ["category.interface"] = "Oberfläche",
    ["category.modules"] = "Module",
    ["category.recognition"] = "Erkennung",
    ["category.schema"] = "Schema",

    -- Subcategory Translations
    ["subcategory.basic"] = "Grundlagen",
    ["subcategory.buttons"] = "Schaltflächen",
    ["subcategory.characters"] = "Charaktere",
    ["subcategory.colors"] = "Farben",
    ["subcategory.display"] = "Anzeige",
    ["subcategory.appearance"] = "Aussehen",
    ["subcategory.animations"] = "Animationen",
    ["subcategory.performance"] = "Leistung",
    ["subcategory.behavior"] = "Verhalten",
    ["subcategory.distances"] = "Distanzen",
    ["subcategory.effects"] = "Effekte",
    ["subcategory.formatting"] = "Formatierung",
    ["subcategory.fonts"] = "Schriftarten",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Interaktion",
    ["subcategory.inventory"] = "Inventar",
    ["subcategory.layout"] = "Layout",
    ["subcategory.movement"] = "Bewegung",
    ["subcategory.notifications"] = "Benachrichtigungen",
    ["subcategory.position"] = "Position",
    ["subcategory.size"] = "Groesse",
    ["subcategory.typography"] = "Typografie",
    ["subcategory.general"] = "Allgemein",
    ["subcategory.ooc"] = "OOC",
    ["subcategory.audio"] = "Audio",
    ["subcategory.audio"] = "Audio",
    ["subcategory.tools"] = "Werkzeuge",

    -- Store Translations
    ["store.enabled"] = "Aktiviert",
    ["store.disabled"] = "Deaktiviert",
    ["store.default"] = "Standard",
    ["store.type.bool"] = "Schalter",
    ["store.type.number"] = "Zahl",
    ["store.type.string"] = "Text",
    ["store.type.color"] = "Farbe",
    ["store.type.array"] = "Auswahl",
    ["store.type.keybind"] = "Tastenbindung",

    -- Config Translations

    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "IC-Chat-Distanz",
    ["config.chat.me.distance"] = "ME-Chat-Distanz",
    ["config.chat.ooc.distance"] = "OOC-Chat-Distanz",
    ["config.chat.yell.distance"] = "RUF-Chat-Distanz",
    ["config.chat.ooc.enabled"] = "OOC-Chat aktivieren",
    ["config.chat.ooc.delay"] = "OOC-Nachrichtenverzoegerung (Sekunden)",
    ["config.chat.ooc.rate_limit"] = "OOC-Nachrichten pro 10 Minuten",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Maximale Handkraft",
    ["config.hands.force.max.throw"] = "Maximale Wurfkraft",
    ["config.hands.max.carry"] = "Maximales Tragegewicht",
    ["config.hands.range.max"] = "Maximale Reichweite",

    ---- Inventory
    ["config.inventory.weight.max"] = "Maximales Inventargewicht",
    ["config.inventory.sync.delta"] = "Delta-Synchronisierung des Inventars",
    ["config.inventory.sync.debounce"] = "Entprellzeit der Inventarsynchronisierung",
    ["config.inventory.sync.full_refresh_interval"] = "Intervall fuer vollständige Inventaraktualisierung",
    ["config.inventory.action.rate_limit"] = "Limit fuer Inventaraktionen",
    ["config.inventory.transfer.rate_limit"] = "Limit fuer Inventartransfers",
    ["config.inventory.pagination.default_page_size"] = "Standard-Seitengroesse des Inventars",
    ["config.inventory.pagination.max_page_size"] = "Maximale Seitengroesse des Inventars",
    ["config.inventory.restore.batch_size"] = "Wiederherstellungs-Batchgroesse des Inventars",
    ["config.inventory.sync.delta.help"] = "Aktiviert Delta-Inventarsynchronisierung, damit nur geänderte Gegenstände gesendet werden.",
    ["config.inventory.sync.debounce.help"] = "Verzoegerung in Sekunden, bevor Inventar-Synchronisierungen gesendet werden.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Minimale Sekunden zwischen vollständigen Aktualisierungen, wenn Delta-Synchronisierung aktiv ist.",
    ["config.inventory.action.rate_limit.help"] = "Minimale Verzoegerung in Sekunden zwischen Gegenstandsaktionen pro Spieler.",
    ["config.inventory.transfer.rate_limit.help"] = "Minimale Verzoegerung in Sekunden zwischen Inventartransfer-Anfragen pro Spieler.",
    ["config.inventory.pagination.default_page_size.help"] = "Standardanzahl an Gegenstandsstapeln pro Inventarseite.",
    ["config.inventory.pagination.max_page_size.help"] = "Maximale Anzahl an Gegenstandsstapeln pro Seite.",
    ["config.inventory.restore.batch_size.help"] = "Anzahl an Weltinventar-Gegenständen, die pro Synchronisierungs-Batch wiederhergestellt werden.",

    ---- Movement
    ["config.jump.power"] = "Sprungkraft",
    ["config.movement.bunnyhop.reduction"] = "Geschwindigkeitsreduktion beim Bunnyhop",
    ["config.speed.run"] = "Laufgeschwindigkeit",
    ["config.speed.walk"] = "Gehgeschwindigkeit",
    ["config.speed.walk.crouched"] = "Gehgeschwindigkeit in der Hocke",
    ["config.speed.walk.slow"] = "Langsame Gehgeschwindigkeit",

    ---- Misc
    ["respawning"] = "Respawne...",
    ["command.notvalid"] = "Das sieht nicht nach einem gueltigen Befehl aus.",
    ["command.notfound"] = "Es gibt keinen Befehl mit diesem Namen. Pruefe die Schreibweise.",
    ["command.executionfailed"] = "Dieser Befehl konnte nicht ausgefuehrt werden. Versuche es erneut.",
    ["command.unknownerror"] = "Etwas ist schiefgelaufen. Bitte versuche es erneut.",

    ["buildmenu.name.spawn"] = "spawn",
    ["buildmenu.name.context"] = "Kontext",
    ["buildmenu.requires_tools"] = "Du brauchst Bauwerkzeuge, um das %s-Menue zu oeffnen.",

    --- General
    ---- Basic
    ["config.language"] = "Sprache",

    ---- Characters
    ["config.autosave.interval"] = "Charakter-Autospeicherintervall",
    ["config.characters.max"] = "Max. Charaktere",

    -- Audio
    ["config.proximity"] = "Sprachchat nach Nähe aktivieren",
    ["config.proximityMaxDistance"] = "Maximale Distanz fuer Nähe",
    ["config.proximityMaxTraces"] = "Maximale Anzahl an Nähe-Traces",
    ["config.proximityMaxVolume"] = "Maximale Lautstärke bei Nähe",
    ["config.proximityMuteVolume"] = "Stumm-Lautstärke bei Nähe",
    ["config.proximityUnMutedDistance"] = "Entstumm-Distanz",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Chat-Sounds aktivieren",
    ["option.chat.timestamps"] = "Zeitstempel im Chat anzeigen",
    ["option.chat.timestamps.24hour"] = "24-Stunden-Zeitformat verwenden",
    ["option.chat.randomized.verbs"] = "Zufällige Chat-Verben verwenden",
    ["option.chat.randomized.verbs.help"] = "Wenn aktiviert, verwenden Chatnachrichten verschiedene Verben (ruft, murmelt, schreit). Wenn deaktiviert, werden die Standardverben verwendet (sagt, flustert, ruft).",

    ---- Position
    ["option.chat.x"] = "X-Position des Chats",
    ["option.chat.y"] = "Y-Position des Chats",

    ---- Size
    ["option.chat.width"] = "Breite des Chats",
    ["option.chat.height"] = "Hoehe des Chats",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "IC-Chat-Farbe",
    ["config.chat.me.color"] = "ME-Chat-Farbe",
    ["config.chat.ooc.color"] = "OOC-Chat-Farbe",
    ["config.chat.yell.color"] = "RUF-Chat-Farbe",
    ["config.chat.whisper.color"] = "FLÜSTERN-Chat-Farbe",

    ---- Buttons
    ["option.button.delay.click"] = "Klickverzoegerung fuer Schaltflächen",

    ---- Display
    ["option.interface.scale"] = "UI-Skalierung",
    ["option.interface.theme"] = "UI-Thema",
    ["option.interface.theme.help"] = "Wähle das Farbthema fuer die Oberfläche.",
    ["option.interface.glass.roundness"] = "Glas-Rundung",
    ["option.interface.glass.roundness.help"] = "Passe den Eckenradius von UI-Elementen im Glasstil an.",
    ["option.interface.glass.blur"] = "Glas-Unschärfeintensität",
    ["option.interface.glass.blur.help"] = "Steuert die Unschärfe hinter UI-Elementen im Glasstil.",
    ["option.interface.glass.opacity"] = "Glas-Deckkraft",
    ["option.interface.glass.opacity.help"] = "Passe die Deckkraft von UI-Panels im Glasstil an.",
    ["option.interface.glass.borderOpacity"] = "Glas-Rand-Deckkraft",
    ["option.interface.glass.borderOpacity.help"] = "Steuert die Sichtbarkeit der UI-Ränder im Glasstil.",
    ["option.interface.glass.gradientOpacity"] = "Glas-Verlaufsdeckkraft",
    ["option.interface.glass.gradientOpacity.help"] = "Passe die Stärke von Verlaufs-Overlays auf Glas-Panels an.",
    ["option.performance.animations"] = "Oberflächenanimationen aktivieren",
    ["option.performance.animations.help"] = "Schaltet Interpolations- und Übergangsanimationen der Oberfläche um.",
    ["option.performance.blur"] = "Oberflächen-Unschärfe aktivieren",
    ["option.performance.blur.help"] = "Deaktiviert aufwendige Hintergrund-Unschärfeeffekte bei Glas-UI-Elementen.",
    ["option.performance.vignette.trace"] = "Vignetten-Nähe-Trace aktivieren",
    ["option.performance.vignette.trace.help"] = "Steuert den Nahwand-Trace zur Anpassung der Vignettenintensität.",
    ["option.performance.voice.indicators"] = "Sprachindikatoren aktivieren",
    ["option.performance.voice.indicators.help"] = "Schaltet HUD- und Welt-Sprachaktivitätsanzeigen für Spieler um.",

    -- Theme Names
    ["theme.dark"] = "Dunkel",
    ["theme.light"] = "Hell",
    ["theme.blue"] = "Blau",
    ["theme.purple"] = "Lila",
    ["theme.green"] = "Gruen",
    ["theme.red"] = "Rot",
    ["theme.orange"] = "Orange",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Allgemeine Schriftskalierung",
    ["option.fontScaleGeneral.help"] = "Allgemeiner Multiplikator fuer die Schriftskalierung.",
    ["option.fontScaleSmall"] = "Kleine Schriftskalierung",
    ["option.fontScaleSmall.help"] = "Skalierungsmodifikator fuer kleine Schrift. Niedrigere Werte machen kleine Schrift groesser.",
    ["option.fontScaleBig"] = "Grosse Schriftskalierung",
    ["option.fontScaleBig.help"] = "Skalierungsmodifikator fuer grosse Schrift. Hoehere Werte machen grosse Schrift kleiner.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Ruestungsleiste anzeigen",
    ["option.hud.bar.health.show"] = "Gesundheitsleiste anzeigen",
    ["option.notification.enabled"] = "Benachrichtigungen aktivieren",
    ["option.notification.length.default"] = "Standarddauer fuer Benachrichtigungen",
    ["option.notification.scale"] = "Skalierung der Benachrichtigungen",
    ["option.notification.sounds"] = "Benachrichtigungssounds aktivieren",
    ["option.notification.position"] = "Position der Benachrichtigungen",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Kategorienamen kursiv darstellen",
    ["option.inventory.columns"] = "Anzahl der Inventarspalten",
    ["option.inventory.sort.categories"] = "Sortiermodus der Inventarkategorien",
    ["option.inventory.sort.items"] = "Sortiermodus der Inventargegenstände",
    ["option.inventory.search.live"] = "Live-Inventarsuche",
    ["option.inventory.categories.collapsible"] = "Einklappbare Inventarkategorien",
    ["option.inventory.pagination.page_size"] = "Seitengroesse des Inventars",
    ["option.inventory.actions.confirm_bulk_drop"] = "Massenablage bestätigen",
    ["option.inventory.sort.categories.help"] = "Wähle, wie Inventarkategorien sortiert werden.",
    ["option.inventory.sort.items.help"] = "Wähle, wie Gegenstände innerhalb jeder Kategorie sortiert werden.",
    ["option.inventory.search.live.help"] = "Aktualisiert Suchergebnisse während der Eingabe.",
    ["option.inventory.categories.collapsible.help"] = "Erlaubt das Ein- und Ausklappen von Inventarkategorien.",
    ["option.inventory.pagination.page_size.help"] = "Anzahl der Inventarstapel pro Seite.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Fragt vor dem Ablegen mehrerer Gegenstände aus einem Stapel nach einer Bestätigung.",
    ["inventory.sort.alphabetical"] = "Alphabetisch",
    ["inventory.sort.manual"] = "Manuell",
    ["inventory.sort.weight"] = "Gewicht",
    ["inventory.sort.class"] = "Klasse",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "OOC-Chat ist auf diesem Server derzeit deaktiviert.",
    ["notify.chat.ooc.wait"] = "Bitte warte %d Sekunde(n), bevor du eine weitere OOC-Nachricht sendest.",
    ["notify.chat.ooc.rate_limited"] = "Du hast das OOC-Nachrichtenlimit (%d) fuer die letzten %d Minuten erreicht.",

    ---- Flags
    ["flag.p.name"] = "Physgun-Berechtigung",
    ["flag.p.description"] = "Erlaubt die Nutzung der Physgun.",

    ["flag.t.name"] = "Toolgun-Berechtigung",
    ["flag.t.description"] = "Erlaubt die Nutzung der Toolgun.",

    ["config.interface.font.antialias"] = "Schriftglättung",
    ["config.interface.font.multiplier"] = "Schriftskalierung",

    ["config.interface.vignette.enabled"] = "Vignetteneffekt aktivieren",
    ["config.interface.vignette.enabled.help"] = "Schaltet den Vignetteneffekt an den Bildschirmrändern ein oder aus.",

    ["config.interface.buildmenu.requires_tools"] = "Bauwerkzeuge fuer Spawn-/Kontextmenues erforderlich",
    ["config.interface.buildmenu.requires_tools.help"] = "Blockiert Spawn- und Kontextmenues, solange der Spieler kein Bauwerkzeug in der Hand hält.",
    ["config.interface.buildmenu.notify_attempts"] = "Benachrichtigungsschwelle fuer blockierte Menues",
    ["config.interface.buildmenu.notify_attempts.help"] = "Wie viele blockierte Menueversuche noetig sind, bevor eine Benachrichtigung angezeigt wird.",
    ["config.interface.buildmenu.notify_reset_delay"] = "Ruecksetzverzoegerung fuer blockierte Menues",
    ["config.interface.buildmenu.notify_reset_delay.help"] = "Sekunden, bis der Zähler fuer blockierte Menueversuche zurueckgesetzt wird.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Sag etwas...",
    ["chatbox.recommendations.no_description"] = "Keine Beschreibung vorhanden.",
    ["chatbox.recommendations.truncated"] = "Es werden die ersten %d Ergebnisse angezeigt.",
    ["chatbox.menu.close"] = "Chat schliessen",
    ["chatbox.menu.clear_history"] = "Chatverlauf loeschen",
    ["chatbox.menu.reset_position"] = "Position zuruecksetzen",
    ["chatbox.menu.reset_size"] = "Groesse zuruecksetzen",
    ["chatbox.menu.confirm_clear_title"] = "Chatverlauf loeschen",
    ["chatbox.menu.confirm_clear_message"] = "Gesamten Chatverlauf loeschen?",

    ["config.chatbox.max_message_length"] = "Maximale Nachrichtenlänge des Chats",
    ["config.chatbox.history_size"] = "Groesse des Chat-Eingabeverlaufs",
    ["config.chatbox.chat_type_history"] = "Groesse des Chattyp-Verlaufs",
    ["config.chatbox.looc_prefix"] = "LOOC-Präfix des Chats",
    ["config.chatbox.recommendations.debounce"] = "Entprellzeit fuer Chat-Empfehlungen",
    ["config.chatbox.recommendations.animation_duration"] = "Animationsdauer fuer Chat-Empfehlungen",
    ["config.chatbox.recommendations.command_limit"] = "Limit fuer Befehls-Empfehlungen im Chat",
    ["config.chatbox.recommendations.voice_limit"] = "Limit fuer Sprach-Empfehlungen im Chat",
    ["config.chatbox.recommendations.wrap_cycle"] = "Zyklisches Wechseln durch Chat-Empfehlungen",
})
