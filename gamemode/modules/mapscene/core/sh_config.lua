--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

ax.config:Add("map.scene.fov", ax.type.number, 90, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.fov.help",
    min = 0,
    max = 180,
    decimals = 0
})

ax.config:Add("map.scene.smooth", ax.type.number, 100, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.smooth.help",
    min = 0,
    max = 100,
    decimals = 0
})

ax.config:Add("map.scene.time", ax.type.number, 30, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.time.help",
    min = 0,
    max = 180,
    decimals = 0
})

ax.config:Add("map.scene.snap", ax.type.bool, false, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.snap.help",
})

ax.config:Add("map.scene.linear", ax.type.bool, false, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.linear.help",
})

ax.config:Add("map.scene.input", ax.type.bool, true, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.input.help",
})

ax.config:Add("map.scene.music.path", ax.type.string, "music/hl1_song3.mp3", {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.music.path.help",
})

ax.config:Add("map.scene.music.volume", ax.type.number, 0.5, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.music.volume.help",
    min = 0,
    max = 1,
    decimals = 2
})

ax.config:Add("map.scene.music.loopDelay", ax.type.number, 0, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.music.loopDelay.help",
    min = 0,
    max = 60,
    decimals = 1
})

ax.config:Add("map.scene.music.fadeIn", ax.type.number, 1.5, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.music.fadeIn.help",
    min = 0,
    max = 10,
    decimals = 1
})

ax.config:Add("map.scene.music.fadeOut", ax.type.number, 1.5, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.music.fadeOut.help",
    min = 0,
    max = 10,
    decimals = 1
})

ax.config:Add("map.scene.strength", ax.type.number, 6, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.strength.help",
    min = 0,
    max = 30,
    decimals = 1
})

ax.config:Add("map.scene.roll", ax.type.number, 0, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.roll.help",
    min = 0,
    max = 45,
    decimals = 1
})

ax.config:Add("map.scene.randomize", ax.type.bool, true, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.randomize.help",
})

ax.config:Add("map.scene.order", ax.type.array, "random", {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.order.help",
    choices = {
        ["random"] = "Random",
        ["ordered"] = "Ordered",
        ["weighted"] = "Weighted"
    }
})

ax.config:Add("map.scene.transition", ax.type.array, "lerp", {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.transition.help",
    choices = {
        ["lerp"] = "Lerp",
        ["smoothstep"] = "Smoothstep",
        ["linear"] = "Linear"
    }
})

ax.config:Add("map.scene.max", ax.type.number, 128, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.max.help",
    min = 1,
    max = 2048,
    decimals = 0
})

ax.config:Add("map.scene.scope", ax.type.array, "map", {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.scope.help",
    choices = {
        ["map"] = "Per Map",
        ["project"] = "Project",
        ["global"] = "Global"
    }
})

ax.config:Add("map.scene.tags.allowed", ax.type.table, {}, {
    category = "camera",
    subCategory = "mapscene",
    description = "config.map.scene.tags.allowed.help",
    bNoNetworking = true
})

ax.localization:Register("en", {
    ["category.camera"] = "Camera",
    ["subcategory.mapscene"] = "Map Scenes",

    ["config.map.scene.fov"] = "FOV",
    ["config.map.scene.fov.help"] = "Field of view used for map scenes.",
    ["config.map.scene.smooth"] = "Smoothness",
    ["config.map.scene.smooth.help"] = "Smoothness factor for camera interpolation.",
    ["config.map.scene.time"] = "Transition Time",
    ["config.map.scene.time.help"] = "Time in seconds for scene transitions.",
    ["config.map.scene.snap"] = "Snap Between Scenes",
    ["config.map.scene.snap.help"] = "Snap instantly between scenes instead of smoothing.",
    ["config.map.scene.linear"] = "Linear Movement",
    ["config.map.scene.linear.help"] = "Use linear movement for map scenes instead of lerp.",
    ["config.map.scene.input"] = "Mouse Input",
    ["config.map.scene.input.help"] = "Enable mouse-based camera offset while in map scenes.",
    ["config.map.scene.music.path"] = "Map Scene Music Path",
    ["config.map.scene.music.path.help"] = "Sound path to play while in map scenes (leave blank to disable).",
    ["config.map.scene.music.volume"] = "Map Scene Music Volume",
    ["config.map.scene.music.volume.help"] = "Volume for map scene music (0-1).",
    ["config.map.scene.music.loopDelay"] = "Map Scene Music Loop Delay",
    ["config.map.scene.music.loopDelay.help"] = "Seconds to wait before restarting the track after it ends.",
    ["config.map.scene.music.fadeIn"] = "Map Scene Music Fade In",
    ["config.map.scene.music.fadeIn.help"] = "Seconds to fade in when music starts (0 for instant).",
    ["config.map.scene.music.fadeOut"] = "Map Scene Music Fade Out",
    ["config.map.scene.music.fadeOut.help"] = "Seconds to fade out when music stops (0 for instant).",
    ["config.map.scene.strength"] = "Input Strength",
    ["config.map.scene.strength.help"] = "Strength of mouse-based camera offset.",
    ["config.map.scene.roll"] = "Input Roll",
    ["config.map.scene.roll.help"] = "Max roll applied from mouse offset (0 disables).",
    ["config.map.scene.randomize"] = "Randomize Scene Selection",
    ["config.map.scene.randomize.help"] = "Randomize scene selection when not ordered.",
    ["config.map.scene.order"] = "Scene Order Mode",
    ["config.map.scene.order.help"] = "Scene selection order for map scenes.",
    ["config.map.scene.transition"] = "Transition Mode",
    ["config.map.scene.transition.help"] = "Transition interpolation mode.",
    ["config.map.scene.max"] = "Max Stored Scenes",
    ["config.map.scene.max.help"] = "Maximum allowed map scenes stored on the server.",
    ["config.map.scene.scope"] = "Scene Persistence Scope",
    ["config.map.scene.scope.help"] = "Persistence scope for stored map scenes.",
    ["config.map.scene.tags.allowed"] = "Allowed Scene Tags",
    ["config.map.scene.tags.allowed.help"] = "Optional allowlist for scene tags."
})

ax.localization:Register("tr", {
    ["category.camera"] = "Kamera",
    ["subcategory.mapscene"] = "Harita Sahneleri",

    ["config.map.scene.fov"] = "FOV",
    ["config.map.scene.fov.help"] = "Harita sahnelerinde kullanılan görüş açısı.",
    ["config.map.scene.smooth"] = "Yumuşaklık",
    ["config.map.scene.smooth.help"] = "Kamera enterpolasyonu için yumuşaklık katsayısı.",
    ["config.map.scene.time"] = "Geçiş Süresi",
    ["config.map.scene.time.help"] = "Sahne geçişleri için saniye cinsinden süre.",
    ["config.map.scene.snap"] = "Sahneler Arasında Anlık Geç",
    ["config.map.scene.snap.help"] = "Yumuşatma yerine sahneler arasında anında geç.",
    ["config.map.scene.linear"] = "Doğrusal Hareket",
    ["config.map.scene.linear.help"] = "Harita sahneleri için lerp yerine doğrusal hareket kullan.",
    ["config.map.scene.input"] = "Fare Girdisi",
    ["config.map.scene.input.help"] = "Harita sahnelerindeyken fare tabanlı kamera ofsetini etkinleştir.",
    ["config.map.scene.music.path"] = "Harita Sahnesi Müzik Yolu",
    ["config.map.scene.music.path.help"] = "Harita sahnelerindeyken çalınacak ses yolu (devre dışı bırakmak için boş bırakın).",
    ["config.map.scene.music.volume"] = "Harita Sahnesi Müzik Ses Seviyesi",
    ["config.map.scene.music.volume.help"] = "Harita sahnesi müziği için ses seviyesi (0-1).",
    ["config.map.scene.music.loopDelay"] = "Harita Sahnesi Müzik Döngü Gecikmesi",
    ["config.map.scene.music.loopDelay.help"] = "Parça bittiğinde yeniden başlamadan önce beklenecek saniye.",
    ["config.map.scene.music.fadeIn"] = "Harita Sahnesi Müzik Giriş Solması",
    ["config.map.scene.music.fadeIn.help"] = "Müzik başladığında giriş solması için saniye (anlık için 0).",
    ["config.map.scene.music.fadeOut"] = "Harita Sahnesi Müzik Çıkış Solması",
    ["config.map.scene.music.fadeOut.help"] = "Müzik durduğunda çıkış solması için saniye (anlık için 0).",
    ["config.map.scene.strength"] = "Girdi Gücü",
    ["config.map.scene.strength.help"] = "Fare tabanlı kamera ofsetinin gücü.",
    ["config.map.scene.roll"] = "Girdi Roll",
    ["config.map.scene.roll.help"] = "Fare ofsetinden uygulanan azami roll (0 devre dışı).",
    ["config.map.scene.randomize"] = "Sahne Seçimini Rastgeleleştir",
    ["config.map.scene.randomize.help"] = "Sıralı değilken sahne seçimini rastgele yap.",
    ["config.map.scene.order"] = "Sahne Sıra Modu",
    ["config.map.scene.order.help"] = "Harita sahneleri için sahne seçim sırası.",
    ["config.map.scene.transition"] = "Geçiş Modu",
    ["config.map.scene.transition.help"] = "Geçiş enterpolasyon modu.",
    ["config.map.scene.max"] = "Maksimum Kayıtlı Sahne",
    ["config.map.scene.max.help"] = "Sunucuda saklanabilecek azami harita sahnesi.",
    ["config.map.scene.scope"] = "Sahne Kalıcılık Kapsamı",
    ["config.map.scene.scope.help"] = "Kayıtlı harita sahneleri için kalıcılık kapsamı.",
    ["config.map.scene.tags.allowed"] = "İzin Verilen Sahne Etiketleri",
    ["config.map.scene.tags.allowed.help"] = "Sahne etiketleri için isteğe bağlı izin listesi."
})
