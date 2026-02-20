ax.localization:Register("bg", {
    -- General
    ["yes"] = "Да",
    ["no"] = "Не",
    ["ok"] = "ОК",
    ["cancel"] = "Отказ",
    ["apply"] = "Приложи",
    ["close"] = "Затвори",
    ["back"] = "Назад",
    ["next"] = "Напред",

    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Фракции",
    ["mainmenu.category.01_identity"] = "Самоличност",
    ["mainmenu.category.02_appearance"] = "Външност",
    ["mainmenu.category.03_other"] = "Друго",
    ["mainmenu.create"] = "Създай Персонаж",
    ["mainmenu.disconnect"] = "Изключи се",
    ["mainmenu.load"] = "Зареди Персонаж",
    ["mainmenu.options"] = "Настройки",
    ["mainmenu.play"] = "Играй",

    -- Tab Menu Translations
    ["tab.config"] = "Конфигурация",
    ["tab.help"] = "Помощ",
    ["tab.help.modules"] = "Модули",
    ["tab.inventory"] = "Инвентар",
    ["tab.scoreboard"] = "Табло",
    ["tab.settings"] = "Настройки",
    ["tab.characters"] = "Персонажи",

    -- Category Translations
    ["category.chat"] = "Чат",
    ["category.gameplay"] = "Геймплей",
    ["category.general"] = "Общи",
    ["category.audio"] = "Аудио",
    ["category.interface"] = "Интерфейс",
    ["category.modules"] = "Модули",
    ["category.schema"] = "Схема",

    -- Subcategory Translations
    ["subcategory.basic"] = "Основни",
    ["subcategory.buttons"] = "Бутони",
    ["subcategory.characters"] = "Персонажи",
    ["subcategory.colors"] = "Цветове",
    ["subcategory.display"] = "Показване",
    ["subcategory.distances"] = "Разстояния",
    ["subcategory.fonts"] = "Шрифтове",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Взаимодействие",
    ["subcategory.inventory"] = "Инвентар",
    ["subcategory.movement"] = "Движение",
    ["subcategory.position"] = "Позиция",
    ["subcategory.size"] = "Размер",
    ["subcategory.general"] = "Общи",
    ["subcategory.ooc"] = "OOC",

    -- Store Translations
    ["store.enabled"] = "Включено",
    ["store.disabled"] = "Изключено",

    -- Config Translations

    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "Разстояние IC Чат",
    ["config.chat.me.distance"] = "Разстояние ME Чат",
    ["config.chat.ooc.distance"] = "Разстояние OOC Чат",
    ["config.chat.yell.distance"] = "Разстояние YELL Чат",
    ["config.chat.ooc.enabled"] = "Включи OOC Чат",
    ["config.chat.ooc.delay"] = "Забавяне на OOC Съобщение (секунди)",
    ["config.chat.ooc.rate_limit"] = "OOC Съобщения на 10 минути",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Максимална Сила на Ръцете",
    ["config.hands.force.max.throw"] = "Максимална Сила за Хвърляне",
    ["config.hands.max.carry"] = "Максимална Носима Тежест",
    ["config.hands.range.max"] = "Максимално Разстояние на Достигане",

    ---- Inventory
    ["config.inventory.weight.max"] = "Максимална Тежест на Инвентара",
    ["config.inventory.sync.delta"] = "Делта синхронизация на инвентара",
    ["config.inventory.sync.debounce"] = "Забавяне на синхронизацията на инвентара",
    ["config.inventory.sync.full_refresh_interval"] = "Интервал за пълно опресняване на инвентара",
    ["config.inventory.action.rate_limit"] = "Ограничение на честотата на действията в инвентара",
    ["config.inventory.transfer.rate_limit"] = "Ограничение на честотата на прехвърляне в инвентара",
    ["config.inventory.pagination.default_page_size"] = "Размер на страницата по подразбиране за инвентара",
    ["config.inventory.pagination.max_page_size"] = "Максимален размер на страницата за инвентара",
    ["config.inventory.restore.batch_size"] = "Размер на партидата за възстановяване на инвентара",
    ["config.inventory.sync.delta.help"] = "Включва делта синхронизация на инвентара, за да се изпращат само променените предмети.",
    ["config.inventory.sync.debounce.help"] = "Забавяне в секунди преди изпращане на обновления за синхронизация на инвентара.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Минимални секунди между пълните опреснявания, когато делта синхронизацията е включена.",
    ["config.inventory.action.rate_limit.help"] = "Минимално забавяне в секунди между действията с предмети за играч.",
    ["config.inventory.transfer.rate_limit.help"] = "Минимално забавяне в секунди между заявките за прехвърляне на инвентар за играч.",
    ["config.inventory.pagination.default_page_size.help"] = "Брой стекове с предмети по подразбиране на страница от инвентара.",
    ["config.inventory.pagination.max_page_size.help"] = "Максимален брой стекове с предмети, позволени на страница.",
    ["config.inventory.restore.batch_size.help"] = "Брой предмети от световния инвентар, възстановявани на партида при синхронизация.",

    ---- Movement
    ["config.jump.power"] = "Сила на Скока",
    ["config.movement.bunnyhop.reduction"] = "Намаление на Скоростта при Bunnyhop",
    ["config.speed.run"] = "Скорост на Бягане",
    ["config.speed.walk"] = "Скорост на Ходене",
    ["config.speed.walk.crouched"] = "Скорост на Ходене Прегърбен",
    ["config.speed.walk.slow"] = "Скорост на Бавно Ходене",

    ---- Misc
    ["respawning"] = "Прераждане...",
    ["command.notvalid"] = "Това не изглежда като команда.",
    ["command.notfound"] = "Няма такава команда. Провери изписването.",
    ["command.executionfailed"] = "Командата не се изпълни. Опитай пак.",
    ["command.unknownerror"] = "Нещо се обърка. Моля, опитай пак.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Поддръжка на Ботове",
    ["config.language"] = "Език",

    ---- Characters
    ["config.autosave.interval"] = "Интервал на Автоматично Запазване",
    ["config.characters.max"] = "Максимален Брой Персонажи",

    -- Audio
    ["config.proximity"] = "Включи гласов чат по близост",
    ["config.proximityMaxDistance"] = "Максимална дистанция на близост",
    ["config.proximityMaxTraces"] = "Максимален брой трасировки за близост",
    ["config.proximityMaxVolume"] = "Максимална сила на звука при близост",
    ["config.proximityMuteVolume"] = "Заглушена сила на звука при близост",
    ["config.proximityUnMutedDistance"] = "Дистанция за възстановяване на звука",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Включи Звуци в Чата",
    ["option.chat.timestamps"] = "Покажи Времеви Печати в Чата",
    ["option.chat.randomized.verbs"] = "Използвай Произволни Глаголи в Чата",
    ["option.chat.randomized.verbs.help"] = "Когато е включено, съобщенията в чата ще използват разнообразни глаголи (възклицава, мърмори, вика). Когато е изключено, използва стандартни глаголи (казва, шепне, вика).",

    ---- Position
    ["option.chat.x"] = "X Позиция на Чата",
    ["option.chat.y"] = "Y Позиция на Чата",

    ---- Size
    ["option.chat.width"] = "Ширина на Чата",
    ["option.chat.height"] = "Височина на Чата",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "Цвят на IC Чат",
    ["config.chat.me.color"] = "Цвят на ME Чат",
    ["config.chat.ooc.color"] = "Цвят на OOC Чат",
    ["config.chat.yell.color"] = "Цвят на YELL Чат",
    ["config.chat.whisper.color"] = "Цвят на WHISPER Чат",

    ---- Buttons
    ["option.button.delay.click"] = "Забавяне при Кликване на Бутон",

    ---- Display
    ["option.interface.scale"] = "Мащаб на Интерфейса",
    ["option.interface.theme"] = "Тема на интерфейса",
    ["option.interface.theme.help"] = "Изберете цветова тема за интерфейса.",
    ["option.interface.glass.roundness"] = "Закръгленост на стъклото",
    ["option.interface.glass.roundness.help"] = "Регулирайте радиуса на ъглите на стъклените елементи на интерфейса.",
    ["option.interface.glass.blur"] = "Интензивност на замъгляването на стъклото",
    ["option.interface.glass.blur.help"] = "Контролирайте силата на замъгляването зад стъклените елементи на интерфейса.",
    ["option.interface.glass.opacity"] = "Непрозрачност на стъклото",
    ["option.interface.glass.opacity.help"] = "Регулирайте непрозрачността на стъклените панели на интерфейса.",
    ["option.interface.glass.borderOpacity"] = "Непрозрачност на границите на стъклото",
    ["option.interface.glass.borderOpacity.help"] = "Контролирайте видимостта на границите на стъклените интерфейси.",
    ["option.interface.glass.gradientOpacity"] = "Непрозрачност на градиента на стъклото",
    ["option.interface.glass.gradientOpacity.help"] = "Регулирайте силата на градиентните наслагвания върху стъклените панели.",
    ["option.performance.animations"] = "Включи Анимации на Интерфейса",

    -- Theme Names
    ["theme.dark"] = "Тъмна",
    ["theme.light"] = "Светла",
    ["theme.blue"] = "Синя",
    ["theme.purple"] = "Лилава",
    ["theme.green"] = "Зелена",
    ["theme.red"] = "Червена",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Общ Мащаб на Шрифта",
    ["option.fontScaleGeneral.help"] = "Общ множител за мащаба на шрифта.",
    ["option.fontScaleSmall"] = "Мащаб на Малкия Шрифт",
    ["option.fontScaleSmall.help"] = "Модификатор на мащаба на малкия шрифт. По-ниски стойности правят малките шрифтове по-големи.",
    ["option.fontScaleBig"] = "Мащаб на Големия Шрифт",
    ["option.fontScaleBig.help"] = "Модификатор на мащаба на големия шрифт. По-високи стойности правят големите шрифтове по-малки.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Покажи Лента за Броня",
    ["option.hud.bar.health.show"] = "Покажи Лента за Здраве",
    ["option.notification.enabled"] = "Включи Известия",
    ["option.notification.length.default"] = "Продължителност на Известията по Подразбиране",
    ["option.notification.scale"] = "Мащаб на Известията",
    ["option.notification.sounds"] = "Включи Звуци за Известия",
    ["option.notification.position"] = "Позиция на известията",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Курсив за Имена на Категории",
    ["option.inventory.columns"] = "Брой Колони в Инвентара",
    ["option.inventory.sort.categories"] = "Режим на сортиране на категориите в инвентара",
    ["option.inventory.sort.items"] = "Режим на сортиране на предметите в инвентара",
    ["option.inventory.search.live"] = "Търсене в инвентара в реално време",
    ["option.inventory.categories.collapsible"] = "Сгъваеми категории в инвентара",
    ["option.inventory.pagination.page_size"] = "Размер на страницата на инвентара",
    ["option.inventory.actions.confirm_bulk_drop"] = "Потвърждение за масово изхвърляне",
    ["option.inventory.sort.categories.help"] = "Изберете как да бъдат подредени категориите в инвентара.",
    ["option.inventory.sort.items.help"] = "Изберете как да бъдат подредени предметите във всяка категория.",
    ["option.inventory.search.live.help"] = "Обновява резултатите от търсене, докато пишете.",
    ["option.inventory.categories.collapsible.help"] = "Позволява категориите в инвентара да се свиват и разгъват.",
    ["option.inventory.pagination.page_size.help"] = "Брой стекове в инвентара, показвани на страница.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Иска потвърждение преди изхвърляне на множество предмети от един стек.",
    ["inventory.sort.alphabetical"] = "Азбучно",
    ["inventory.sort.manual"] = "Ръчно",
    ["inventory.sort.weight"] = "Тегло",
    ["inventory.sort.class"] = "Клас",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "кг",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "OOC чатът в момента е изключен в този сървър.",
    ["notify.chat.ooc.wait"] = "Моля, изчакайте %d секунди преди да изпратите друго OOC съобщение.",
    ["notify.chat.ooc.rate_limited"] = "Достигнахте лимита на OOC съобщения (%d) за последните %d минути.",

    ---- Flags
    ["flag.p.name"] = "Разрешение за Physgun",
    ["flag.p.description"] = "Позволява използването на physgun.",

    ["flag.t.name"] = "Разрешение за Toolgun",
    ["flag.t.description"] = "Позволява използването на toolgun.",

    ["config.interface.font.antialias"] = "Изглаждане на Шрифтове",
    ["config.interface.font.multiplier"] = "Мащаб на Шрифта",

    ["config.interface.vignette.enabled"] = "Включи Ефект Винетка",
    ["config.interface.vignette.enabled.help"] = "Превключва ефекта винетка около ръбовете на екрана.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Кажи нещо...",
    ["chatbox.recommendations.no_description"] = "Няма предоставено описание.",
    ["chatbox.recommendations.truncated"] = "Показани са първите %d резултата.",
    ["chatbox.menu.close"] = "Затвори чата",
    ["chatbox.menu.clear_history"] = "Изчисти историята на чата",
    ["chatbox.menu.reset_position"] = "Нулирай позицията",
    ["chatbox.menu.reset_size"] = "Нулирай размера",
    ["chatbox.menu.confirm_clear_title"] = "Изчистване на историята на чата",
    ["chatbox.menu.confirm_clear_message"] = "Да се изчисти ли цялата история на чата?",

    ["config.chatbox.max_message_length"] = "Максимална дължина на съобщение в чата",
    ["config.chatbox.history_size"] = "Размер на историята на въвеждане в чата",
    ["config.chatbox.chat_type_history"] = "Размер на историята на типовете чат",
    ["config.chatbox.looc_prefix"] = "LOOC префикс на чата",
    ["config.chatbox.recommendations.debounce"] = "Забавяне на препоръките в чата",
    ["config.chatbox.recommendations.animation_duration"] = "Продължителност на анимацията на препоръките в чата",
    ["config.chatbox.recommendations.command_limit"] = "Лимит на командните препоръки в чата",
    ["config.chatbox.recommendations.voice_limit"] = "Лимит на гласовите препоръки в чата",
    ["config.chatbox.recommendations.wrap_cycle"] = "Циклично превъртане на препоръките в чата",
})
