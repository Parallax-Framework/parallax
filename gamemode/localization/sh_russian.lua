-- translated by MrMono for Parallax Framework
ax.localization:Register("ru", {
    -- General
    ["yes"] = "Да",
    ["no"] = "Нет",
    ["ok"] = "ОК",
    ["cancel"] = "Отмена",
    ["apply"] = "Применить",
    ["close"] = "Закрыть",
    ["back"] = "Назад",
    ["next"] = "Далее",

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
    ["tab.scoreboard"] = "Таблица",
    ["tab.settings"] = "Настройки",
    ["tab.characters"] = "Персонажи",

    -- Category Translations
    ["category.chat"] = "Чат",
    ["category.gameplay"] = "Игра",
    ["category.general"] = "Основное",
    ["category.audio"] = "Аудио",
    ["category.interface"] = "Интерфейс",
    ["category.modules"] = "Модули",
    ["category.schema"] = "Схема",

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
    ["config.hands.force.max"] = "Максимальная сила рук",
    ["config.hands.force.max.throw"] = "Максимальная сила броска",
    ["config.hands.max.carry"] = "Максимальный переносимый вес",
    ["config.hands.range.max"] = "Максимальная дистанция досягаемости",

    ---- Inventory
    ["config.inventory.weight.max"] = "Максимальный Вес",
    ["config.inventory.sync.delta"] = "Дельта-синхронизация инвентаря",
    ["config.inventory.sync.debounce"] = "Задержка синхронизации инвентаря",
    ["config.inventory.sync.full_refresh_interval"] = "Интервал полного обновления инвентаря",
    ["config.inventory.action.rate_limit"] = "Ограничение частоты действий с инвентарем",
    ["config.inventory.transfer.rate_limit"] = "Ограничение частоты передачи инвентаря",
    ["config.inventory.pagination.default_page_size"] = "Размер страницы инвентаря по умолчанию",
    ["config.inventory.pagination.max_page_size"] = "Максимальный размер страницы инвентаря",
    ["config.inventory.restore.batch_size"] = "Размер пакета восстановления инвентаря",
    ["config.inventory.sync.delta.help"] = "Включает дельта-синхронизацию инвентаря, чтобы отправлять только измененные предметы.",
    ["config.inventory.sync.debounce.help"] = "Задержка в секундах перед отправкой обновлений синхронизации инвентаря.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Минимальное количество секунд между полными обновлениями, когда дельта-синхронизация включена.",
    ["config.inventory.action.rate_limit.help"] = "Минимальная задержка в секундах между действиями с предметами для каждого игрока.",
    ["config.inventory.transfer.rate_limit.help"] = "Минимальная задержка в секундах между запросами на передачу инвентаря для каждого игрока.",
    ["config.inventory.pagination.default_page_size.help"] = "Количество стеков предметов на странице инвентаря по умолчанию.",
    ["config.inventory.pagination.max_page_size.help"] = "Максимальное количество стеков предметов на одной странице.",
    ["config.inventory.restore.batch_size.help"] = "Количество предметов мирового инвентаря, восстанавливаемых за один пакет синхронизации.",

    ---- Movement
    ["config.jump.power"] = "Сила Прыжка",
    ["config.movement.bunnyhop.reduction"] = "Снижение скорости при баннихопе",
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

    -- Audio
    ["config.proximity"] = "Включить голосовой чат по близости",
    ["config.proximityMaxDistance"] = "Максимальная дистанция близости",
    ["config.proximityMaxTraces"] = "Максимум трассировок близости",
    ["config.proximityMaxVolume"] = "Максимальная громкость близости",
    ["config.proximityMuteVolume"] = "Громкость при заглушении близости",
    ["config.proximityUnMutedDistance"] = "Дистанция восстановления громкости",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Включить звуки чата",
    ["option.chat.timestamps"] = "Время в чате",
    ["option.chat.randomized.verbs"] = "Использование Случайных Эмоутов",
    ["option.chat.randomized.verbs.help"] = "Если включено, в сообщениях чата будут использоваться разные глаголы (восклицает, бормочет, кричит). Если отключено, используются глаголы по умолчанию (говорит, шепчет, кричит).",

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
    ["option.interface.scale"] = "Размер Интерфейса",
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
    ["option.performance.animations"] = "Включить анимацию интерфейса",

    -- Theme Names
    ["theme.dark"] = "Тёмная",
    ["theme.light"] = "Светлая",
    ["theme.blue"] = "Синяя",
    ["theme.purple"] = "Фиолетовая",
    ["theme.green"] = "Зелёная",
    ["theme.red"] = "Красная",

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
    ["option.notification.position"] = "Позиция уведомлений",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Выделение названий категорий",
    ["option.inventory.columns"] = "Число колонок инвентаря",
    ["option.inventory.sort.categories"] = "Режим сортировки категорий инвентаря",
    ["option.inventory.sort.items"] = "Режим сортировки предметов инвентаря",
    ["option.inventory.search.live"] = "Поиск в инвентаре в реальном времени",
    ["option.inventory.categories.collapsible"] = "Сворачиваемые категории инвентаря",
    ["option.inventory.pagination.page_size"] = "Размер страницы инвентаря",
    ["option.inventory.actions.confirm_bulk_drop"] = "Подтверждать массовый выброс",
    ["option.inventory.sort.categories.help"] = "Выберите способ сортировки категорий инвентаря.",
    ["option.inventory.sort.items.help"] = "Выберите способ сортировки предметов внутри каждой категории.",
    ["option.inventory.search.live.help"] = "Обновляет результаты поиска во время ввода.",
    ["option.inventory.categories.collapsible.help"] = "Позволяет сворачивать и разворачивать категории инвентаря.",
    ["option.inventory.pagination.page_size.help"] = "Количество стеков инвентаря на одной странице.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Запрашивает подтверждение перед выбросом нескольких предметов из одного стека.",
    ["inventory.sort.alphabetical"] = "По алфавиту",
    ["inventory.sort.manual"] = "Вручную",
    ["inventory.sort.weight"] = "По весу",
    ["inventory.sort.class"] = "По классу",

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

    ["config.interface.font.antialias"] = "Антиалиасинг шрифтов",
    ["config.interface.font.multiplier"] = "Размер шрифтов",

    ["config.interface.vignette.enabled"] = "Включить эффект виньетки",
    ["config.interface.vignette.enabled.help"] = "Переключите эффект виньетки по краям экрана.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Скажите что-нибудь...",
    ["chatbox.recommendations.no_description"] = "Описание отсутствует.",
    ["chatbox.recommendations.truncated"] = "Показаны первые %d результатов.",
    ["chatbox.menu.close"] = "Закрыть чат",
    ["chatbox.menu.clear_history"] = "Очистить историю чата",
    ["chatbox.menu.reset_position"] = "Сбросить позицию",
    ["chatbox.menu.reset_size"] = "Сбросить размер",
    ["chatbox.menu.confirm_clear_title"] = "Очистка истории чата",
    ["chatbox.menu.confirm_clear_message"] = "Очистить всю историю чата?",

    ["config.chatbox.max_message_length"] = "Максимальная длина сообщения в чате",
    ["config.chatbox.history_size"] = "Размер истории ввода чата",
    ["config.chatbox.chat_type_history"] = "Размер истории типов чата",
    ["config.chatbox.looc_prefix"] = "Префикс LOOC чата",
    ["config.chatbox.recommendations.debounce"] = "Задержка рекомендаций чата",
    ["config.chatbox.recommendations.animation_duration"] = "Длительность анимации рекомендаций чата",
    ["config.chatbox.recommendations.command_limit"] = "Лимит рекомендаций команд чата",
    ["config.chatbox.recommendations.voice_limit"] = "Лимит голосовых рекомендаций чата",
    ["config.chatbox.recommendations.wrap_cycle"] = "Зацикливание рекомендаций чата",

    -- Extra Localization Keys
    ["category.camera"] = "Камера",
    ["subcategory.thirdperson"] = "Третье Лицо",
    ["config.thirdperson"] = "Включить Третье лицо",
    ["config.thirdperson.help"] = "Определяет, разрешена ли на сервере камера от третьего лица.",
    ["option.thirdperson"] = "Включить Третье лицо",
    ["option.thirdperson.help"] = "Переключает режим камеры от третьего лица.",
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
