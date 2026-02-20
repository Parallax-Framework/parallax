ax.localization:Register("tr", {
    -- General
    ["yes"] = "Evet",
    ["no"] = "Hayır",
    ["ok"] = "Tamam",
    ["cancel"] = "İptal",
    ["apply"] = "Uygula",
    ["close"] = "Kapat",
    ["back"] = "Geri",
    ["next"] = "İleri",

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
    ["tab.help.modules"] = "Modüller",
    ["tab.inventory"] = "Envanter",
    ["tab.scoreboard"] = "Skorbord",
    ["tab.settings"] = "Seçenekler",
    ["tab.characters"] = "Karakterler",

    -- Category Translations
    ["category.chat"] = "Sohbet",
    ["category.gameplay"] = "Oynanış",
    ["category.general"] = "Genel",
    ["category.audio"] = "Ses",
    ["category.interface"] = "Arayüz",
    ["category.modules"] = "Modüller",
    ["category.schema"] = "Şema",

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
    ["config.hands.force.max"] = "Maksimum El Kuvveti",
    ["config.hands.force.max.throw"] = "Maksimum Fırlatma Kuvveti",
    ["config.hands.max.carry"] = "Maksimum Taşıma Ağırlığı",
    ["config.hands.range.max"] = "Maksimum Uzanma Mesafesi",

    ---- Inventory
    ["config.inventory.weight.max"] = "Envanter Maksimum Ağırlık",
    ["config.inventory.sync.delta"] = "Envanter Delta Senkronizasyonu",
    ["config.inventory.sync.debounce"] = "Envanter Senkronizasyon Gecikmesi",
    ["config.inventory.sync.full_refresh_interval"] = "Envanter Tam Yenileme Aralığı",
    ["config.inventory.action.rate_limit"] = "Envanter Eylem Hız Sınırı",
    ["config.inventory.transfer.rate_limit"] = "Envanter Transfer Hız Sınırı",
    ["config.inventory.pagination.default_page_size"] = "Varsayılan Envanter Sayfa Boyutu",
    ["config.inventory.pagination.max_page_size"] = "Maksimum Envanter Sayfa Boyutu",
    ["config.inventory.restore.batch_size"] = "Envanter Geri Yükleme Toplu İş Boyutu",
    ["config.inventory.sync.delta.help"] = "Yalnızca değişen öğeleri göndermek için envanter delta senkronizasyonunu etkinleştirir.",
    ["config.inventory.sync.debounce.help"] = "Senkronizasyon güncellemeleri gönderilmeden önce saniye cinsinden gecikme.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Delta senkronizasyonu etkinken tam yenilemeler arasındaki minimum saniye.",
    ["config.inventory.action.rate_limit.help"] = "Oyuncu başına öğe eylemleri arasındaki minimum saniye gecikmesi.",
    ["config.inventory.transfer.rate_limit.help"] = "Oyuncu başına envanter transfer istekleri arasındaki minimum saniye gecikmesi.",
    ["config.inventory.pagination.default_page_size.help"] = "Envanter sayfası başına varsayılan öğe yığını sayısı.",
    ["config.inventory.pagination.max_page_size.help"] = "Sayfa başına izin verilen maksimum öğe yığını sayısı.",
    ["config.inventory.restore.batch_size.help"] = "Senkronizasyon başına geri yüklenen dünya envanteri öğe sayısı.",

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

    -- Audio
    ["config.proximity"] = "Yakınlık Sesli Sohbetini Etkinleştir",
    ["config.proximityMaxDistance"] = "Maksimum Yakınlık Mesafesi",
    ["config.proximityMaxTraces"] = "Maksimum Yakınlık İz Sayısı",
    ["config.proximityMaxVolume"] = "Maksimum Yakınlık Ses Seviyesi",
    ["config.proximityMuteVolume"] = "Yakınlık Sessiz Ses Seviyesi",
    ["config.proximityUnMutedDistance"] = "Yakınlık Sesi Açma Mesafesi",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Sohbet Seslerini Etkinleştir",
    ["option.chat.timestamps"] = "Sohbette Zaman Damgalarını Göster",
    ["option.chat.randomized.verbs"] = "Rastgele Sohbet Fiillerini Kullan",
    ["option.chat.randomized.verbs.help"] = "Açık olduğunda, sohbet mesajları farklı fiiller kullanır (bağırır, homurdanır, haykırır). Kapalı olduğunda varsayılan fiilleri kullanır (der, fısıldar, bağırır).",

    ---- Position
    ["option.chat.x"] = "Sohbet Kutusu X Konumu",
    ["option.chat.y"] = "Sohbet Kutusu Y Konumu",

    ---- Size
    ["option.chat.width"] = "Sohbet Kutusu Genişliği",
    ["option.chat.height"] = "Sohbet Kutusu Yüksekliği",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "IC Sohbet Rengi",
    ["config.chat.me.color"] = "ME Sohbet Rengi",
    ["config.chat.ooc.color"] = "OOC Sohbet Rengi",
    ["config.chat.yell.color"] = "YELL Sohbet Rengi",
    ["config.chat.whisper.color"] = "WHISPER Sohbet Rengi",

    ---- Buttons
    ["option.button.delay.click"] = "Buton Tıklama Gecikmesi",

    ---- Display
    ["option.interface.scale"] = "Arayüz Ölçeği",
    ["option.interface.theme"] = "Arayüz Teması",
    ["option.interface.theme.help"] = "Arayüz için renk temasını seçin.",
    ["option.interface.glass.roundness"] = "Cam Yuvarlaklığı",
    ["option.interface.glass.roundness.help"] = "Cam arayüz öğelerinin köşe yarıçapını ayarlayın.",
    ["option.interface.glass.blur"] = "Cam Bulanıklık Yoğunluğu",
    ["option.interface.glass.blur.help"] = "Cam arayüz öğelerinin arkasındaki bulanıklık gücünü kontrol edin.",
    ["option.interface.glass.opacity"] = "Cam Opaklığı",
    ["option.interface.glass.opacity.help"] = "Cam arayüz panellerinin opaklığını ayarlayın.",
    ["option.interface.glass.borderOpacity"] = "Cam Kenarlık Opaklığı",
    ["option.interface.glass.borderOpacity.help"] = "Cam arayüz kenarlıklarının görünürlüğünü kontrol edin.",
    ["option.interface.glass.gradientOpacity"] = "Cam Gradyan Opaklığı",
    ["option.interface.glass.gradientOpacity.help"] = "Cam panellerdeki gradyan katmanlarının gücünü ayarlayın.",
    ["option.performance.animations"] = "Arayüz Animasyonlarını Etkinleştir",

    -- Theme Names
    ["theme.dark"] = "Koyu",
    ["theme.light"] = "Açık",
    ["theme.blue"] = "Mavi",
    ["theme.purple"] = "Mor",
    ["theme.green"] = "Yeşil",
    ["theme.red"] = "Kırmızı",
    ["theme.orange"] = "Turuncu",

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
    ["option.notification.position"] = "Bildirim Konumu",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Kategori Adlarını İtalik Yap",
    ["option.inventory.columns"] = "Envanter Sütunlarının Sayısı",
    ["option.inventory.sort.categories"] = "Envanter Kategori Sıralama Modu",
    ["option.inventory.sort.items"] = "Envanter Öğe Sıralama Modu",
    ["option.inventory.search.live"] = "Canlı Envanter Araması",
    ["option.inventory.categories.collapsible"] = "Daraltılabilir Envanter Kategorileri",
    ["option.inventory.pagination.page_size"] = "Envanter Sayfa Boyutu",
    ["option.inventory.actions.confirm_bulk_drop"] = "Toplu Bırakma İşlemlerini Onayla",
    ["option.inventory.sort.categories.help"] = "Envanter kategorilerinin nasıl sıralanacağını seçin.",
    ["option.inventory.sort.items.help"] = "Öğelerin her kategori içinde nasıl sıralanacağını seçin.",
    ["option.inventory.search.live.help"] = "Yazarken arama sonuçlarını günceller.",
    ["option.inventory.categories.collapsible.help"] = "Envanter kategorilerinin daraltılıp genişletilmesine izin verir.",
    ["option.inventory.pagination.page_size.help"] = "Sayfa başına gösterilen envanter yığını sayısı.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Bir yığından birden fazla öğe bırakmadan önce onay ister.",
    ["inventory.sort.alphabetical"] = "Alfabetik",
    ["inventory.sort.manual"] = "Manuel",
    ["inventory.sort.weight"] = "Ağırlık",
    ["inventory.sort.class"] = "Sınıf",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "Bu sunucuda OOC sohbet şu anda devre dışı.",
    ["notify.chat.ooc.wait"] = "Başka bir OOC mesajı göndermeden önce lütfen %d saniye bekleyin.",
    ["notify.chat.ooc.rate_limited"] = "Son %d dakika içinde OOC mesaj limiti (%d) aşıldı.",

    ---- Flags
    ["flag.p.name"] = "Physgun Yetkisi",
    ["flag.p.description"] = "Physgun kullanımına izin verir.",

    ["flag.t.name"] = "Toolgun Yetkisi",
    ["flag.t.description"] = "Toolgun kullanımına izin verir.",

    ["config.interface.font.antialias"] = "Yazı Tipi Kenar Yumuşatma",
    ["config.interface.font.multiplier"] = "Yazı Tipi Ölçeği",

    ["config.interface.vignette.enabled"] = "Vinyet Efektini Etkinleştir",
    ["config.interface.vignette.enabled.help"] = "Ekran kenarlarındaki vinyet efektini açıp kapatır.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Bir şey söyle...",
    ["chatbox.recommendations.no_description"] = "Açıklama sağlanmadı.",
    ["chatbox.recommendations.truncated"] = "İlk %d sonuç gösteriliyor.",
    ["chatbox.menu.close"] = "Sohbeti Kapat",
    ["chatbox.menu.clear_history"] = "Sohbet Geçmişini Temizle",
    ["chatbox.menu.reset_position"] = "Konumu Sıfırla",
    ["chatbox.menu.reset_size"] = "Boyutu Sıfırla",
    ["chatbox.menu.confirm_clear_title"] = "Sohbet Geçmişini Temizle",
    ["chatbox.menu.confirm_clear_message"] = "Tüm sohbet geçmişi temizlensin mi?",

    ["config.chatbox.max_message_length"] = "Sohbet Kutusu Maksimum Mesaj Uzunluğu",
    ["config.chatbox.history_size"] = "Sohbet Kutusu Girdi Geçmişi Boyutu",
    ["config.chatbox.chat_type_history"] = "Sohbet Kutusu Sohbet Türü Geçmişi Boyutu",
    ["config.chatbox.looc_prefix"] = "Sohbet Kutusu LOOC Ön Eki",
    ["config.chatbox.recommendations.debounce"] = "Sohbet Kutusu Öneri Gecikmesi",
    ["config.chatbox.recommendations.animation_duration"] = "Sohbet Kutusu Öneri Animasyon Süresi",
    ["config.chatbox.recommendations.command_limit"] = "Sohbet Kutusu Komut Öneri Limiti",
    ["config.chatbox.recommendations.voice_limit"] = "Sohbet Kutusu Ses Öneri Limiti",
    ["config.chatbox.recommendations.wrap_cycle"] = "Sohbet Kutusu Öneri Döngü Sarma",
})
