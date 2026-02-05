-- translated by MrMono for Parallax Framework
ax.localization:Register("ru", {
    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Фракции",
    ["mainmenu.category.01_identity"] = "О Вас",
    ["mainmenu.category.02_appearance"] = "Внешность",
    ["mainmenu.category.03_other"] = "Другое",
    ["mainmenu.create"] = "Создать Персонажа",
    ["mainmenu.disconnect"] = "Отключиться",
    ["mainmenu.load"] = "Загрузить персонажа",
    ["mainmenu.options"] = "Опции",
    ["mainmenu.play"] = "Играть",

    -- Tab Menu Translations
    ["tab.config"] = "Настройки",
    ["tab.help"] = "Помощь",
    ["tab.inventory"] = "Инвентарь",
    ["tab.scoreboard"] = "Scoreboard",
    ["tab.settings"] = "Settings",

    -- Category Translations
    ["category.chat"] = "Чат",
    ["category.gameplay"] = "Игра",
    ["category.general"] = "Основное",
    ["category.interface"] = "Интерфейс",
    ["category.modules"] = "Модули",

    -- Subcategory Translations
    ["subcategory.basic"] = "База",
    ["subcategory.buttons"] = "Кнопки",
    ["subcategory.characters"] = "Персонажи",
    ["subcategory.colors"] = "Цвета",
    ["subcategory.display"] = "Дисплей",
    ["subcategory.distances"] = "Дистанция",
    ["subcategory.fonts"] = "Шрифты",
    ["subcategory.hud"] = "ХУД",
    ["subcategory.interaction"] = "Взаимодействие",
    ["subcategory.inventory"] = "Инвентарь",
    ["subcategory.movement"] = "Движение",
    ["subcategory.position"] = "Позиция",
    ["subcategory.size"] = "Размер",
    ["subcategory.general"] = "Основное",
    ["subcategory.ooc"] = "OOC",

    -- Store Translations
    ["store.enabled"] = "Вкл",
    ["store.disabled"] = "Выкл",

    -- Config Translations
    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "IC Дистанция",
    ["config.chat.me.distance"] = "ME Дистанция",
    ["config.chat.ooc.distance"] = "OOC Дистанция",
    ["config.chat.yell.distance"] = "YELL Дистанция",
    ["config.chat.ooc.enabled"] = "Включить OOC Чат",
    ["config.chat.ooc.delay"] = "OOC Задержка сообщения (секунды)",
    ["config.chat.ooc.rate_limit"] = "OOC Сообщений за 10 минут",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Максимальная сила удара", -- in future
    ["config.hands.force.max.throw"] = "Максимальная сила броска руками", -- in future
    ["config.hands.max.carry"] = "Максимальный переносимый вес в руках", -- in future
    ["config.hands.range.max"] = "Максимальное расстояние досягаемости рук", -- in future

    ---- Inventory
    ["config.inventory.weight.max"] = "Максимальный Вес",

    ---- Movement
    ["config.jump.power"] = "Сила Прыжка",
    ["config.movement.bunnyhop.reduction"] = "Bunnyhop Speed Reduction",
    ["config.speed.run"] = "Скорость Бега",
    ["config.speed.walk"] = "Скорость Ходьбы",
    ["config.speed.walk.crouched"] = "Скорость В Приседание",
    ["config.speed.walk.slow"] = "Скорость Медленной Ходьбы",

    ---- Misc
    ["respawning"] = "Возрождение...",
    ["command.notvalid"] = "Похоже, это не команда.",
    ["command.notfound"] = "Такой команды нет. Проверьте написание.",
    ["command.executionfailed"] = "Команда не выполнилась. Попробуйте ещё раз.",
    ["command.unknownerror"] = "Что-то пошло не так. Попробуйте ещё раз.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Бот Поддержка",
    ["config.language"] = "Язык",

    ---- Characters
    ["config.autosave.interval"] = "Интервал Сохранения Персонажей",
    ["config.characters.max"] = "Максимально Персонажей",

    --- Interface
    ["config.interface.font.antialias"] = "Антиалиасинг шрифтов",
    ["config.interface.font.multiplier"] = "Размер шрифтов",

    ["config.interface.vignette.enabled"] = "Включить эффект виньетки",
    ["config.interface.vignette.enabled.help"] = "Переключите эффект виньетки по краям экрана.",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Включить звуки чата",
    ["option.chat.timestamps"] = "Время в чате",
    ["option.chat.randomized.verbs"] = "Использование Случайных Эмоутов",
    ["option.chat.randomized.verbs.help"] = "При включении в сообщениях чата будут использоваться различные глаголы (восклицает, бормочет, кричит). При отключении используются глаголы по умолчанию (говорит, шепчет, кричит)..",

    ---- Position
    ["option.chat.x"] = "Позиция чата X",
    ["option.chat.y"] = "Позиция чата Y",

    ---- Size
    ["option.chat.width"] = "Ширина Чата",
    ["option.chat.height"] = "Высота Чата",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "Цвет IC Чата",
    ["config.chat.me.color"] = "Цвет ME Чата",
    ["config.chat.ooc.color"] = "Цвет OOC Чата",
    ["config.chat.yell.color"] = "Цвет YELL Чата",
    ["config.chat.whisper.color"] = "Цвет WHISPER Чата",
    ---- Buttons
    ["option.button.delay.click"] = "Задержка нажатия кнопки",

    ---- Display
    ["option.interface.theme"] = "Тема интерфейса",
    ["option.interface.theme.help"] = "Выберите цветовую тему для интерфейса.",
    ["option.interface.glass.roundness"] = "Округлость стекла",
    ["option.interface.glass.roundness.help"] = "Настройте радиус углов стеклянных элементов интерфейса.",
    ["option.interface.glass.blur"] = "Интенсивность размытия стекла",
    ["option.interface.glass.blur.help"] = "Управляйте силой размытия за стеклянными элементами интерфейса.",
    ["option.interface.glass.opacity"] = "Непрозрачность стекла",
    ["option.interface.glass.opacity.help"] = "Настройте непрозрачность стеклянных панелей интерфейса.",
    ["option.interface.glass.borderOpacity"] = "Непрозрачность границ стекла",
    ["option.interface.glass.borderOpacity.help"] = "Управляйте видимостью границ стеклянного интерфейса.",
    ["option.interface.glass.gradientOpacity"] = "Непрозрачность градиента стекла",
    ["option.interface.glass.gradientOpacity.help"] = "Настройте силу градиентных наложений на стеклянных панелях.",

    -- Theme Names
    ["theme.dark"] = "Тёмная",
    ["theme.light"] = "Светлая",
    ["theme.blue"] = "Синяя",
    ["theme.purple"] = "Фиолетовая",
    ["theme.green"] = "Зелёная",
    ["theme.red"] = "Красная",

    ---- Display
    ["option.interface.scale"] = "Размер Интерфейса",
    ["option.performance.animations"] = "Включить анимацию интерфейса",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Размер основного шрифта",
    ["option.fontScaleGeneral.help"] = "Изменяет стандартный размер основного шрифта.",
    ["option.fontScaleSmall"] = "Размер малого шрифта",
    ["option.fontScaleSmall.help"] = "Изменяет стандартный размер малого шрифта. Меньшие значения увеличивают размер мелкого шрифта.",
    ["option.fontScaleBig"] = "Размер большого шрифта",
    ["option.fontScaleBig.help"] = "Изменяет стандартный размер большого шрифта. Большие значения уменьшает размер большого шрифта.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Показать шкалу Брони",
    ["option.hud.bar.health.show"] = "Показать шкалу Здоровья",
    ["option.notification.enabled"] = "Включить уведомления",
    ["option.notification.length.default"] = "Длина уведомления по умолчанию",
    ["option.notification.scale"] = "Размер уведомления",
    ["option.notification.sounds"] = "Включить звуки уведомлений",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Выделение названий категорий",
    -- ["option.inventory.columns"] = "Number of Inventory Columns",
    ["option.inventory.columns"] = "Число колонок инвентаря",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "кг",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "OOC чат сейчас недоступен на сервере.",
    ["notify.chat.ooc.wait"] = "Пожалуйста подождите %d секунд(ы) перед отправлением OOC сообщения.",
    ["notify.chat.ooc.rate_limited"] = "Вы достигли лимита OOC сообщений (%d) за последние %d минут(ы).",

    ---- Flags
    ["flag.p.name"] = "Physgun Доступ",
    ["flag.p.description"] = "Дает доступ к использованию physgun.",

    ["flag.t.name"] = "Toolgun Доступ",
    ["flag.t.description"] = "Дает доступ к использованию toolgun.",

    ["category.camera"] = "Камера",
    ["subcategory.thirdperson"] = "Третье Лицо",
    ["config.thirdperson"] = "Включить Третье лицо",
    ["config.thirdperson.help"] = "Wether or not the server allows third-person camera functionality.",
    ["option.thirdperson"] = "Включить Третье лицо",
    ["option.thirdperson.help"] = "Toggle third-person camera mode.",
    ["option.thirdperson.x"] = "X Смещение",
    ["option.thirdperson.x.help"] = "X Смещение для камеры Третье лица.",
    ["option.thirdperson.y"] = "Y Смещение",
    ["option.thirdperson.y.help"] = "Y Смещение для камеры Третье лица.",
    ["option.thirdperson.z"] = "Z Смещение",
    ["option.thirdperson.z.help"] = "Z Смещение для камеры Третье лица.",
    ["option.thirdperson.follow.head"] = "Следовать за головой",
    ["option.thirdperson.follow.head.help"] = "Делает так, чтобы камера от третьего лица следовала за движениями головы модели игрока.",
    ["option.thirdperson.follow.angles"] = "Следовать за углами",
    ["option.thirdperson.follow.angles.help"] = "Делает так, чтобы камера от третьего лица следить за направлением прицеливания игрока, а не за углами обзора.",
    ["option.thirdperson.follow.fov"] = "Следовать за полем зрения",
    ["option.thirdperson.follow.fov.help"] = "Делает так, чтобы камера  от третьего лица следить за направлением на основе расстояния от конечной точки трассы до игрока.",
    ["option.thirdperson.desired.lerp.pos"] = "Требуемая скорость интерполяции положения",
    ["option.thirdperson.desired.lerp.pos.help"] = "Скорость интерполяции для желаемого положения камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию.",
    ["option.thirdperson.desired.lerp.angle"] = "Требуемая скорость интерполяции угла",
    ["option.thirdperson.desired.lerp.angle.help"] = "Скорость интерполяции для желаемого ракурса камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию.",
    ["option.thirdperson.desired.lerp.fov"] = "Требуемая скорость интерполяции поля зрения",
    ["option.thirdperson.desired.lerp.fov.help"] = "Скорость интерполяции для желаемого угла обзора камеры от третьего лица. При меньших значениях скорость интерполяции будет более плавной, но и реакция будет медленнее. Установите значение 0, чтобы отключить интерполяцию.",

    ["category.admin"] = "Админы",
    ["option.admin.esp"] = "Админ ESP",
    ["option.admin.esp.help"] = "Включить или отключить админское ESP.",
})
