ax.localization:Register("tr", {
    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Fraksiyonlar",
    ["mainmenu.category.01_identity"] = "Kimlik",
    ["mainmenu.category.02_appearance"] = "Görünüm",
    ["mainmenu.category.03_other"] = "Diğer",
    ["mainmenu.create"] = "Karakter Oluştur",
    ["mainmenu.disconnect"] = "Bağlantıyı Kes",
    ["mainmenu.load"] = "Karakter Yükle",
    ["mainmenu.options"] = "Seçenekler",
    ["mainmenu.play"] = "Oyna",

    -- Tab Menu Translations
    ["tab.config"] = "Yapılandırma",
    ["tab.help"] = "Yardım",
    ["tab.inventory"] = "Envanter",
    ["tab.scoreboard"] = "Skorbord",
    ["tab.settings"] = "Seçenekler",

    -- Category Translations
    ["category.chat"] = "Sohbet",
    ["category.gameplay"] = "Oynanış",
    ["category.general"] = "Genel",
    ["category.interface"] = "Arayüz",
    ["category.modules"] = "Modüller",

    -- Subcategory Translations
    ["subcategory.basic"] = "Temel",
    ["subcategory.buttons"] = "Butonlar",
    ["subcategory.characters"] = "Karakterler",
    ["subcategory.colors"] = "Renkler",
    ["subcategory.display"] = "Görüntü",
    ["subcategory.distances"] = "Mesafeler",
    ["subcategory.fonts"] = "Yazı Tipleri",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Etkileşim",
    ["subcategory.inventory"] = "Envanter",
    ["subcategory.movement"] = "Hareket",
    ["subcategory.position"] = "Pozisyon",
    ["subcategory.size"] = "Boyut",
    ["subcategory.general"] = "Genel",
    ["subcategory.ooc"] = "OOC",

    -- Store Translations
    ["store.enabled"] = "Etkin",
    ["store.disabled"] = "Devre Dışı",

    -- Config Translations
    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "IC Sohbet Mesafesi",
    ["config.chat.me.distance"] = "ME Sohbet Mesafesi",
    ["config.chat.ooc.distance"] = "OOC Sohbet Mesafesi",
    ["config.chat.yell.distance"] = "YELL Sohbet Mesafesi",
    ["config.chat.ooc.enabled"] = "OOC Sohbetini Etkinleştir",
    ["config.chat.ooc.delay"] = "OOC Mesaj Gecikmesi (saniye)",
    ["config.chat.ooc.rate_limit"] = "10 dakikada OOC Mesaj Sayısı",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Eller Maksimum El Kuvveti",
    ["config.hands.force.max.throw"] = "Eller Maksimum Fırlatma Gücü",
    ["config.hands.max.carry"] = "Eller Maksimum Taşıma Ağırlığı",
    ["config.hands.range.max"] = "Eller Maksimum Uzanma Mesafesi",

    ---- Inventory
    ["config.inventory.weight.max"] = "Envanter Maksimum Ağırlık",

    ---- Movement
    ["config.jump.power"] = "Zıplama Gücü",
    ["config.movement.bunnyhop.reduction"] = "Bunnyhop Hız Azaltma",
    ["config.speed.run"] = "Koşma Hızı",
    ["config.speed.walk"] = "Yürüme Hızı",
    ["config.speed.walk.crouched"] = "Çömelme Yürüme Hızı",
    ["config.speed.walk.slow"] = "Yavaş Yürüme Hızı",

    ---- Misc
    ["respawning"] = "Yeniden Doğuyor...",
    ["command.notvalid"] = "Bu bir komut gibi görünmüyor.",
    ["command.notfound"] = "Böyle bir komut yok. Yazımı kontrol et.",
    ["command.executionfailed"] = "Komut çalıştırılamadı. Tekrar dene.",
    ["command.unknownerror"] = "Bir şeyler ters gitti. Lütfen tekrar dene.",

    --- General
    ---- Basic
    ["config.bot.support"] = "Bot Desteği",
    ["config.language"] = "Dil",

    ---- Characters
    ["config.autosave.interval"] = "Karakteri Otomatik Kaydetme Sıklığı",
    ["config.characters.max"] = "Maksimum Karakter Sayısı",

    --- Interface
    ["config.interface.font.antialias"] = "Yazı Tipi Kenar Yumuşatma",
    ["config.interface.font.multiplier"] = "Yazı Tipi Ölçeği",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.randomized.verbs"] = "Rastgele Sohbet Fiillerini Kullan",
    ["option.chat.randomized.verbs.help"] = "Açık olduğunda, sohbet mesajları farklı fiiller kullanır (bağırır, homurdanır, haykırır). Kapalı olduğunda varsayılan fiilleri kullanır (der, fısıldar, bağırır).",

    ---- Position
    ["option.chat.x"] = "Sohbet Kutusu X Konumu",
    ["option.chat.y"] = "Sohbet Kutusu Y Konumu",

    ---- Size
    ["option.chat.width"] = "Sohbet Kutusu Genişliği",
    ["option.chat.height"] = "Sohbet Kutusu Yüksekliği",

    --- Interface
    ---- Buttons
    ["option.button.delay.click"] = "Buton Tıklama Gecikmesi",

    ---- Display
    ["option.interface.scale"] = "Arayüz Ölçeği",
    ["option.performance.animations"] = "Arayüz Animasyonlarını Etkinleştir",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Genel Yazı Tipi Ölçeği",
    ["option.fontScaleGeneral.help"] = "Genel yazı tipi ölçeği çarpanı.",
    ["option.fontScaleSmall"] = "Küçük Yazı Tipi Ölçeği",
    ["option.fontScaleSmall.help"] = "Küçük yazı tipi ölçeği değiştirici. Daha düşük değerler küçük yazı tiplerini büyütür.",
    ["option.fontScaleBig"] = "Büyük Yazı Tipi Ölçeği",
    ["option.fontScaleBig.help"] = "Büyük yazı tipi ölçeği değiştirici. Daha yüksek değerler büyük yazı tiplerini küçültür.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Zırh Barını Göster",
    ["option.hud.bar.health.show"] = "Sağlık Barını Göster",
    ["option.notification.enabled"] = "Bildirimleri Etkinleştir",
    ["option.notification.length.default"] = "Varsayılan Bildirim Süresi",
    ["option.notification.scale"] = "Bildirim Ölçeği",
    ["option.notification.sounds"] = "Bildirim Seslerini Etkinleştir",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Kategori Adlarını İtalik Yap",
    ["option.inventory.columns"] = "Envanter Sütunlarının Sayısı",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "Bu sunucuda OOC sohbet şu anda devre dışı.",
    ["notify.chat.ooc.wait"] = "Başka bir OOC mesajı göndermeden önce lütfen %d saniye bekleyin.",
    ["notify.chat.ooc.rate_limited"] = "Son %d dakika içinde OOC mesaj limiti (%d) aşıldı.",
})
