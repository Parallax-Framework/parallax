ax.localization:Register("es", {
    -- General
    ["yes"] = "Sí",
    ["no"] = "No",
    ["ok"] = "OK",
    ["cancel"] = "Cancelar",
    ["apply"] = "Aplicar",
    ["close"] = "Cerrar",
    ["back"] = "Atrás",
    ["next"] = "Siguiente",

    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Facciones",
    ["mainmenu.category.01_identity"] = "Identidad",
    ["mainmenu.category.02_appearance"] = "Apariencia",
    ["mainmenu.category.03_other"] = "Otros",
    ["mainmenu.create"] = "Crear Personaje",
    ["mainmenu.disconnect"] = "Desconectar",
    ["mainmenu.load"] = "Cargar Personaje",
    ["mainmenu.options"] = "Opciones",
    ["mainmenu.play"] = "Jugar",

    -- Tab Menu Translations
    ["tab.config"] = "Configuración",
    ["tab.help"] = "Ayuda",
    ["tab.inventory"] = "Inventario",
    ["tab.scoreboard"] = "Marcador",
    ["tab.settings"] = "Ajustes",

    -- Category Translations
    ["category.chat"] = "Chat",
    ["category.gameplay"] = "Jugabilidad",
    ["category.general"] = "General",
    ["category.audio"] = "Audio",
    ["category.interface"] = "Interfaz",
    ["category.modules"] = "Módulos",
    ["category.schema"] = "Esquema",

    -- Subcategory Translations
    ["subcategory.basic"] = "Básico",
    ["subcategory.buttons"] = "Botones",
    ["subcategory.characters"] = "Personajes",
    ["subcategory.colors"] = "Colores",
    ["subcategory.display"] = "Pantalla",
    ["subcategory.distances"] = "Distancias",
    ["subcategory.fonts"] = "Fuentes",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Interacción",
    ["subcategory.inventory"] = "Inventario",
    ["subcategory.movement"] = "Movimiento",
    ["subcategory.position"] = "Posición",
    ["subcategory.size"] = "Tamaño",
    ["subcategory.general"] = "General",
    ["subcategory.ooc"] = "OOC",

    -- Store Translations
    ["store.enabled"] = "Habilitado",
    ["store.disabled"] = "Deshabilitado",

    -- Config Translations

    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "Distancia del Chat IC",
    ["config.chat.me.distance"] = "Distancia del Chat ME",
    ["config.chat.ooc.distance"] = "Distancia del Chat OOC",
    ["config.chat.yell.distance"] = "Distancia del Chat YELL",
    ["config.chat.ooc.enabled"] = "Habilitar Chat OOC",
    ["config.chat.ooc.delay"] = "Retraso de Mensajes OOC (segundos)",
    ["config.chat.ooc.rate_limit"] = "Mensajes OOC por 10 minutos",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Fuerza Máxima de las Manos",
    ["config.hands.force.max.throw"] = "Fuerza Máxima de Lanzamiento de las Manos",
    ["config.hands.max.carry"] = "Peso Máximo que las Manos Pueden Transportar",
    ["config.hands.range.max"] = "Distancia Máxima de Alcance de las Manos",

    ---- Inventory
    ["config.inventory.weight.max"] = "Peso Máximo del Inventario",
    ["config.inventory.sync.delta"] = "Sincronización delta del inventario",
    ["config.inventory.sync.debounce"] = "Retardo de sincronización del inventario",
    ["config.inventory.sync.full_refresh_interval"] = "Intervalo de actualización completa del inventario",
    ["config.inventory.action.rate_limit"] = "Límite de frecuencia de acciones de inventario",
    ["config.inventory.transfer.rate_limit"] = "Límite de frecuencia de transferencias de inventario",
    ["config.inventory.pagination.default_page_size"] = "Tamaño de página predeterminado del inventario",
    ["config.inventory.pagination.max_page_size"] = "Tamaño máximo de página del inventario",
    ["config.inventory.restore.batch_size"] = "Tamaño de lote de restauración del inventario",
    ["config.inventory.sync.delta.help"] = "Habilita la sincronización delta del inventario para enviar solo los elementos modificados.",
    ["config.inventory.sync.debounce.help"] = "Retraso en segundos antes de enviar actualizaciones de sincronización del inventario.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Segundos mínimos entre actualizaciones completas cuando la sincronización delta está habilitada.",
    ["config.inventory.action.rate_limit.help"] = "Retraso mínimo en segundos entre acciones de objetos por jugador.",
    ["config.inventory.transfer.rate_limit.help"] = "Retraso mínimo en segundos entre solicitudes de transferencia de inventario por jugador.",
    ["config.inventory.pagination.default_page_size.help"] = "Número predeterminado de pilas de objetos por página de inventario.",
    ["config.inventory.pagination.max_page_size.help"] = "Número máximo de pilas de objetos permitidas por página.",
    ["config.inventory.restore.batch_size.help"] = "Número de objetos de inventario del mundo restaurados por lote de sincronización.",

    ---- Movement
    ["config.jump.power"] = "Potencia de Salto",
    ["config.movement.bunnyhop.reduction"] = "Reducción de Velocidad con Bunnyhop",
    ["config.speed.run"] = "Velocidad de Carrera",
    ["config.speed.walk"] = "Velocidad al Caminar",
    ["config.speed.walk.crouched"] = "Velocidad al Caminar Agachado",
    ["config.speed.walk.slow"] = "Velocidad al Caminar Lentamente",

    ---- Misc
    ["respawning"] = "Reapareciendo...",
    ["command.notvalid"] = "Eso no parece un comando válido.",
    ["command.notfound"] = "No hay ningún comando con ese nombre. Verifica lo escrito.",
    ["command.executionfailed"] = "Ese comando falló al ejecutarse. Intenta de nuevo.",
    ["command.unknownerror"] = "Algo salió mal. Por favor, intenta de nuevo.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Soporte para Bots",
    ["config.language"] = "Idioma",

    ---- Characters
    ["config.autosave.interval"] = "Intervalo de Guardado Automático de Personajes",
    ["config.characters.max"] = "Máximo de Personajes",

    -- Audio
    ["config.proximity"] = "Habilitar sistema de voz por proximidad",
    ["config.proximityMaxDistance"] = "Distancia Máxima de Proximidad",
    ["config.proximityMaxTraces"] = "Máximo de Trazas de Proximidad",
    ["config.proximityMaxVolume"] = "Volumen Máximo de Proximidad",
    ["config.proximityMuteVolume"] = "Volumen al Silenciar Proximidad",
    ["config.proximityUnMutedDistance"] = "Distancia para Restaurar Volumen",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Habilitar Sonidos del Chat",
    ["option.chat.timestamps"] = "Mostrar Tiempos en el Chat",
    ["option.chat.randomized.verbs"] = "Usar Verbos Aleatorios en el Chat",
    ["option.chat.randomized.verbs.help"] = "Cuando está habilitado, los mensajes del chat usarán verbos variados (exclama, murmura, grita). Cuando está deshabilitado, usa los verbos predeterminados (dice, susurra, grita).",

    ---- Position
    ["option.chat.x"] = "Posición X del Chat",
    ["option.chat.y"] = "Posición Y del Chat",

    ---- Size
    ["option.chat.width"] = "Ancho del Chat",
    ["option.chat.height"] = "Altura del Chat",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "Color del Chat IC",
    ["config.chat.me.color"] = "Color del Chat ME",
    ["config.chat.ooc.color"] = "Color del Chat OOC",
    ["config.chat.yell.color"] = "Color del Chat YELL",
    ["config.chat.whisper.color"] = "Color del Chat WHISPER",

    ---- Buttons
    ["option.button.delay.click"] = "Retraso de Clic del Botón",

    ---- Display
    ["option.interface.scale"] = "Escala de la Interfaz",
    ["option.interface.theme"] = "Tema de la Interfaz",
    ["option.interface.theme.help"] = "Elige el tema de color para la interfaz.",
    ["option.interface.glass.roundness"] = "Redondez del Cristal",
    ["option.interface.glass.roundness.help"] = "Ajusta el radio de las esquinas de los elementos de la interfaz de cristal.",
    ["option.interface.glass.blur"] = "Intensidad del Desenfoque del Cristal",
    ["option.interface.glass.blur.help"] = "Controla la intensidad del desenfoque detrás de los elementos de la interfaz de cristal.",
    ["option.interface.glass.opacity"] = "Opacidad del Cristal",
    ["option.interface.glass.opacity.help"] = "Ajusta la opacidad de los paneles de la interfaz de cristal.",
    ["option.interface.glass.borderOpacity"] = "Opacidad del Borde del Cristal",
    ["option.interface.glass.borderOpacity.help"] = "Controla la visibilidad de los bordes de los paneles de cristal.",
    ["option.interface.glass.gradientOpacity"] = "Opacidad del Gradiente del Cristal",
    ["option.interface.glass.gradientOpacity.help"] = "Ajusta la intensidad de las superposiciones de gradiente en los paneles de cristal.",
    ["option.performance.animations"] = "Habilitar Animaciones de la Interfaz",

    -- Theme Names
    ["theme.dark"] = "Oscuro",
    ["theme.light"] = "Claro",
    ["theme.blue"] = "Azul",
    ["theme.purple"] = "Morado",
    ["theme.green"] = "Verde",
    ["theme.red"] = "Rojo",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Escala de Fuente General",
    ["option.fontScaleGeneral.help"] = "Multiplicador de escala de fuente general.",
    ["option.fontScaleSmall"] = "Escala de Fuente Pequeña",
    ["option.fontScaleSmall.help"] = "Modificador de escala de fuente pequeña. Valores más bajos hacen que las fuentes pequeñas sean más grandes.",
    ["option.fontScaleBig"] = "Escala de Fuente Grande",
    ["option.fontScaleBig.help"] = "Modificador de escala de fuente grande. Valores más altos hacen que las fuentes grandes sean más pequeñas.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Mostrar Barra de Armadura",
    ["option.hud.bar.health.show"] = "Mostrar Barra de Salud",
    ["option.notification.enabled"] = "Habilitar Notificaciones",
    ["option.notification.length.default"] = "Duración Predeterminada de Notificaciones",
    ["option.notification.scale"] = "Escala de Notificaciones",
    ["option.notification.sounds"] = "Habilitar Sonidos de Notificaciones",
    ["option.notification.position"] = "Posición de Notificaciones",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Cursiva en Nombres de Categorías",
    ["option.inventory.columns"] = "Número de Columnas del Inventario",
    ["option.inventory.sort.categories"] = "Modo de orden de categorías del inventario",
    ["option.inventory.sort.items"] = "Modo de orden de objetos del inventario",
    ["option.inventory.search.live"] = "Búsqueda en vivo del inventario",
    ["option.inventory.categories.collapsible"] = "Categorías de inventario colapsables",
    ["option.inventory.pagination.page_size"] = "Tamaño de página del inventario",
    ["option.inventory.actions.confirm_bulk_drop"] = "Confirmar acciones de descarte masivo",
    ["option.inventory.sort.categories.help"] = "Elige cómo se ordenan las categorías del inventario.",
    ["option.inventory.sort.items.help"] = "Elige cómo se ordenan los objetos dentro de cada categoría.",
    ["option.inventory.search.live.help"] = "Actualiza los resultados de búsqueda mientras escribes.",
    ["option.inventory.categories.collapsible.help"] = "Permite contraer y expandir las categorías del inventario.",
    ["option.inventory.pagination.page_size.help"] = "Número de pilas de inventario mostradas por página.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Solicita confirmación antes de soltar varios objetos de una pila.",
    ["inventory.sort.alphabetical"] = "Alfabético",
    ["inventory.sort.manual"] = "Manual",
    ["inventory.sort.weight"] = "Peso",
    ["inventory.sort.class"] = "Clase",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "El chat OOC está actualmente deshabilitado en este servidor.",
    ["notify.chat.ooc.wait"] = "Por favor espera %d segundo(s) antes de enviar otro mensaje OOC.",
    ["notify.chat.ooc.rate_limited"] = "Has alcanzado el límite de mensajes OOC (%d) en los últimos %d minutos.",

    ---- Flags
    ["flag.p.name"] = "Permiso de Physgun",
    ["flag.p.description"] = "Permite el uso del physgun.",

    ["flag.t.name"] = "Permiso de Toolgun",
    ["flag.t.description"] = "Permite el uso del toolgun.",

    ["config.interface.font.antialias"] = "Suavizado de Fuente",
    ["config.interface.font.multiplier"] = "Escala de Fuente",

    ["config.interface.vignette.enabled"] = "Habilitar Efecto de Viñeta",
    ["config.interface.vignette.enabled.help"] = "Activa o desactiva el efecto de viñeta alrededor de los bordes de la pantalla.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Escribe algo...",
    ["chatbox.recommendations.no_description"] = "No se proporcionó descripción.",
    ["chatbox.recommendations.truncated"] = "Mostrando los primeros %d resultados.",
    ["chatbox.menu.close"] = "Cerrar Chat",
    ["chatbox.menu.clear_history"] = "Borrar Historial de Chat",
    ["chatbox.menu.reset_position"] = "Restablecer Posición",
    ["chatbox.menu.reset_size"] = "Restablecer Tamaño",
    ["chatbox.menu.confirm_clear_title"] = "Borrar Historial de Chat",
    ["chatbox.menu.confirm_clear_message"] = "¿Borrar todo el historial de chat?",

    ["config.chatbox.max_message_length"] = "Longitud Máxima de Mensaje del Chatbox",
    ["config.chatbox.history_size"] = "Tamaño del Historial de Entrada del Chatbox",
    ["config.chatbox.chat_type_history"] = "Tamaño del Historial de Tipo de Chat del Chatbox",
    ["config.chatbox.looc_prefix"] = "Prefijo LOOC del Chatbox",
    ["config.chatbox.recommendations.debounce"] = "Retardo de Recomendación del Chatbox",
    ["config.chatbox.recommendations.animation_duration"] = "Duración de Animación de Recomendación del Chatbox",
    ["config.chatbox.recommendations.command_limit"] = "Límite de Recomendación de Comandos del Chatbox",
    ["config.chatbox.recommendations.voice_limit"] = "Límite de Recomendación de Voz del Chatbox",
    ["config.chatbox.recommendations.wrap_cycle"] = "Ciclo de Recomendación del Chatbox",
})
