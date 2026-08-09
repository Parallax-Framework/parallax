ax.localization:Register("fr", {
    -- General
    ["yes"] = "Oui",
    ["no"] = "Non",
    ["ok"] = "OK",
    ["cancel"] = "Annuler",
    ["apply"] = "Appliquer",
    ["close"] = "Fermer",
    ["back"] = "Retour",
    ["next"] = "Suivant",
    ["unknown"] = "Inconnu",

    ["skin"] = "Skin",
    ["model"] = "Modèle",
    ["gender"] = "Genre",
    ["gender.male"] = "Homme",
    ["gender.female"] = "Femme",
    ["name"] = "Nom",
    ["description"] = "Description",

    ["not_enough_money"] = "Vous n'avez pas assez d'argent pour acheter ceci.",
    ["not_enough_money_missing"] = "Vous n'avez pas assez d'argent pour acheter ceci. Il vous manque %s.",

    -- Main Menu Translations
    ["mainmenu.category.00_faction"] = "Factions",
    ["mainmenu.category.01_appearance"] = "Apparence",

    ["mainmenu.category.02_identity"] = "Identité",
    ["mainmenu.category.02_identity.hint_name_1"] = "Utilisez une capitalisation correcte et fournissez un prénom et un nom de famille.",
    ["mainmenu.category.02_identity.hint_name_2"] = "Votre nom doit correspondre au thème du serveur et au cadre de jeu de rôle.",

    ["mainmenu.category.02_identity.hint_description_1"] = "La description du personnage est un bref résumé qui aide les autres à visualiser votre personnage. Elle peut inclure des détails sur son apparence physique, son style vestimentaire ou des traits notables.",
    ["mainmenu.category.02_identity.hint_description_2"] = "Écrivez une brève description de votre apparence physique, de votre style vestimentaire ou de tout trait notable qui aide les autres à visualiser votre personnage.",

    ["mainmenu.category.03_other"] = "Autre",
    ["mainmenu.create"] = "Créer un personnage",
    ["mainmenu.disconnect"] = "Déconnecter",
    ["mainmenu.load"] = "Charger un personnage",
    ["mainmenu.options"] = "Options",
    ["mainmenu.play"] = "Jouer",

    -- Pause Menu Translations
    ["pause.title"] = "En pause",
    ["pause.resume"] = "Reprendre",
    ["pause.characters"] = "Personnages",
    ["pause.options"] = "Options",
    ["pause.disconnect"] = "Déconnecter",
    ["pause.legacy"] = "Menu Legacy",

    -- Tab Menu Translations
    ["tab.config"] = "Configuration",
    ["tab.help"] = "Aide",
    ["tab.help.overview"] = "Aperçu",
    ["tab.help.commands"] = "Commandes",
    ["tab.help.factions"] = "Factions",
    ["tab.help.modules"] = "Modules",
    ["tab.inventory"] = "Inventaire",
    ["tab.scoreboard"] = "Tableau des scores",
    ["tab.settings"] = "Paramètres",
    ["tab.characters"] = "Personnages",

    -- Category Translations
    ["category.chat"] = "Discussion",
    ["category.gameplay"] = "Gameplay",
    ["category.general"] = "Général",
    ["category.audio"] = "Audio",
    ["category.interface"] = "Interface",
    ["category.modules"] = "Modules",
    ["category.recognition"] = "Reconnaissance",
    ["category.schema"] = "Schéma",

    -- Subcategory Translations
    ["subcategory.basic"] = "Basique",
    ["subcategory.buttons"] = "Boutons",
    ["subcategory.characters"] = "Personnages",
    ["subcategory.colors"] = "Couleurs",
    ["subcategory.display"] = "Affichage",
    ["subcategory.appearance"] = "Apparence",
    ["subcategory.animations"] = "Animations",
    ["subcategory.performance"] = "Performance",
    ["subcategory.behavior"] = "Comportement",
    ["subcategory.distances"] = "Distances",
    ["subcategory.effects"] = "Effets",
    ["subcategory.formatting"] = "Formatage",
    ["subcategory.fonts"] = "Polices",
    ["subcategory.hud"] = "HUD",
    ["subcategory.interaction"] = "Interaction",
    ["subcategory.inventory"] = "Inventaire",
    ["subcategory.layout"] = "Disposition",
    ["subcategory.movement"] = "Mouvement",
    ["subcategory.notifications"] = "Notifications",
    ["subcategory.position"] = "Position",
    ["subcategory.size"] = "Taille",
    ["subcategory.typography"] = "Typographie",
    ["subcategory.general"] = "Général",
    ["subcategory.ooc"] = "OOC",
    ["subcategory.audio"] = "Audio",
    ["subcategory.tools"] = "Outils",
    ["subcategory.respawn"] = "Réapparition",

    -- Store Translations
    ["store.enabled"] = "Activé",
    ["store.disabled"] = "Désactivé",
    ["store.default"] = "Par défaut",
    ["store.type.bool"] = "Activer/Désactiver",
    ["store.type.number"] = "Nombre",
    ["store.type.string"] = "Texte",
    ["store.type.color"] = "Couleur",
    ["store.type.array"] = "Choix",
    ["store.type.keybind"] = "Raccourci",

    -- Config Translations

    --- Chat
    ---- Distances
    ["config.chat.ic.distance"] = "Distance de discussion IC",
    ["config.chat.me.distance"] = "Distance de discussion ME",
    ["config.chat.ooc.distance"] = "Distance de discussion OOC",
    ["config.chat.yell.distance"] = "Distance de discussion YELL",
    ["config.chat.ooc.enabled"] = "Activer la discussion OOC",
    ["config.chat.ooc.delay"] = "Délai de message OOC (secondes)",
    ["config.chat.ooc.rate_limit"] = "Messages OOC par 10 minutes",

    --- Gameplay
    ---- Interaction
    ["config.hands.force.max"] = "Force maximale de la main",
    ["config.hands.force.max.throw"] = "Force maximale de lancer",
    ["config.hands.max.carry"] = "Poids maximal de portage",
    ["config.hands.range.max"] = "Distance maximale d'atteinte",

    ---- Inventory
    ["config.inventory.weight.max"] = "Poids maximal de l'inventaire",
    ["config.inventory.sync.delta"] = "Synchronisation delta de l'inventaire",
    ["config.inventory.sync.debounce"] = "Délai de synchronisation de l'inventaire",
    ["config.inventory.sync.full_refresh_interval"] = "Intervalle de rafraîchissement complet de l'inventaire",
    ["config.inventory.action.rate_limit"] = "Limite de taux d'actions d'inventaire",
    ["config.inventory.transfer.rate_limit"] = "Limite de taux de transferts d'inventaire",
    ["config.inventory.pagination.default_page_size"] = "Taille de page par défaut de l'inventaire",
    ["config.inventory.pagination.max_page_size"] = "Taille de page maximale de l'inventaire",
    ["config.inventory.restore.batch_size"] = "Taille de lot de restauration de l'inventaire",
    ["config.inventory.sync.delta.help"] = "Activer la synchronisation delta de l'inventaire pour envoyer uniquement les éléments modifiés.",
    ["config.inventory.sync.debounce.help"] = "Délai en secondes avant d'envoyer les mises à jour de synchronisation de l'inventaire.",
    ["config.inventory.sync.full_refresh_interval.help"] = "Secondes minimales entre les rafraîchissements complets lorsque la synchronisation delta est activée.",
    ["config.inventory.action.rate_limit.help"] = "Délai minimal en secondes entre les actions d'objets par joueur.",
    ["config.inventory.transfer.rate_limit.help"] = "Délai minimal en secondes entre les demandes de transfert d'inventaire par joueur.",
    ["config.inventory.pagination.default_page_size.help"] = "Nombre par défaut de piles d'objets par page d'inventaire.",
    ["config.inventory.pagination.max_page_size.help"] = "Nombre maximal de piles d'objets autorisées par page.",
    ["config.inventory.restore.batch_size.help"] = "Nombre d'objets d'inventaire du monde restaurés par lot de synchronisation.",

    ---- Movement
    ["config.jump.power"] = "Puissance de saut",
    ["config.movement.bunnyhop.reduction"] = "Réduction de vitesse Bunnyhop",
    ["config.speed.run"] = "Vitesse de course",
    ["config.speed.walk"] = "Vitesse de marche",
    ["config.speed.walk.crouched"] = "Vitesse de marche accroupie",
    ["config.speed.walk.slow"] = "Vitesse de marche lente",

    ---- Respawn
    ["config.respawn.delay"] = "Délai de réapparition",
    ["config.respawn.delay.help"] = "Temps en secondes avant qu'un joueur puisse réapparaître après sa mort.",

    ---- Misc
    ["respawning"] = "Réapparition en cours...",
    ["command.notvalid"] = "Cela ne ressemble pas à une vraie commande.",
    ["command.notfound"] = "Aucune commande portant ce nom. Vérifiez l'orthographe.",
    ["command.executionfailed"] = "Cette commande n'a pas pu s'exécuter. Réessayez.",
    ["command.unknownerror"] = "Quelque chose a mal tourné. Veuillez réessayer.",

    ["buildmenu.name.spawn"] = "spawn",
    ["buildmenu.name.context"] = "context",
    ["buildmenu.requires_tools"] = "Vous avez besoin d'outils de construction pour accéder au menu %s.",

    --- General
    ---- Basic
    ["config.language"] = "Langue",

    ---- Characters
    ["config.autosave.interval"] = "Intervalle de sauvegarde automatique des personnages",
    ["config.characters.max"] = "Nombre maximal de personnages",
    ["error.character.max_reached"] = "Vous avez atteint le nombre maximal de personnages.",

    -- Audio
    ["config.proximity"] = "Activer la voix de proximité",
    ["config.proximity.help"] = "Active ou désactive le système de proximité.",
    ["config.proximityMaxDistance"] = "Distance maximale de proximité",
    ["config.proximityMaxDistance.help"] = "Distance maximale pour la réduction complète du volume.",
    ["config.proximityMaxTraces"] = "Nombre maximal de traces de proximité",
    ["config.proximityMaxTraces.help"] = "Nombre maximal de traces à effectuer lors du calcul du volume vocal.",
    ["config.proximityMaxVolume"] = "Volume vocal maximal de proximité",
    ["config.proximityMaxVolume.help"] = "Volume vocal maximal autorisé.",
    ["config.proximityMuteVolume"] = "Volume de sourdine de proximité",
    ["config.proximityMuteVolume.help"] = "Volume à définir lorsqu'un joueur est en sourdine.",
    ["config.proximityUnMutedDistance"] = "Distance de réactivation de la proximité",
    ["config.proximityUnMutedDistance.help"] = "Distance à laquelle un joueur est réactivé.",

    -- Options Translations
    --- Chat
    ---- Basic
    ["option.chat.sounds"] = "Activer les sons de discussion",
    ["option.chat.timestamps"] = "Afficher les horodatages dans le chat",
    ["option.chat.timestamps.24hour"] = "Utiliser le format 24 heures pour les horodatages",
    ["option.chat.randomized.verbs"] = "Utiliser des verbes de discussion aléatoires",
    ["option.chat.randomized.verbs.help"] = "Lorsque activé, les messages utilisent des verbes variés (s'exclame, marmonne, crie). Lorsque désactivé, ils utilisent les verbes par défaut (dit, murmure, hurle).",

    ---- Position
    ["option.chat.x"] = "Position X de la boîte de chat",
    ["option.chat.y"] = "Position Y de la boîte de chat",

    ---- Size
    ["option.chat.width"] = "Largeur de la boîte de chat",
    ["option.chat.height"] = "Hauteur de la boîte de chat",

    --- Interface
    ---- Chat
    ["config.chat.ic.color"] = "Couleur de discussion IC",
    ["config.chat.me.color"] = "Couleur de discussion ME",
    ["config.chat.ooc.color"] = "Couleur de discussion OOC",
    ["config.chat.yell.color"] = "Couleur de discussion YELL",
    ["config.chat.whisper.color"] = "Couleur de discussion WHISPER",

    ---- Buttons
    ["option.button.delay.click"] = "Délai de clic sur les boutons",

    ---- Display
    ["option.interface.scale"] = "Échelle de l'interface",
    ["option.performance.animations"] = "Activer les animations d'interface",
    ["option.performance.animations.help"] = "Activer/désactiver les interpolations et transitions d'animation de l'interface.",
    ["option.performance.blur"] = "Activer le flou d'interface",
    ["option.performance.blur.help"] = "Désactiver les passes de flou d'arrière-plan coûteuses sur les éléments d'interface en verre.",
    ["option.performance.vignette.trace"] = "Activer la trace de proximité du vignettage",
    ["option.performance.vignette.trace.help"] = "Contrôle la trace près des murs utilisée pour ajuster l'intensité du vignettage.",
    ["option.performance.voice.indicators"] = "Activer les indicateurs vocaux",
    ["option.performance.voice.indicators.help"] = "Activer/désactiver les indicateurs HUD et vocaux dans le monde pour les joueurs.",

    ---- Fonts
    ["option.fontScaleGeneral"] = "Échelle de police générale",
    ["option.fontScaleGeneral.help"] = "Multiplicateur d'échelle de police générale.",
    ["option.fontScaleSmall"] = "Échelle de petite police",
    ["option.fontScaleSmall.help"] = "Modificateur d'échelle de petite police. Des valeurs plus basses rendent les petites polices plus grandes.",
    ["option.fontScaleBig"] = "Échelle de grande police",
    ["option.fontScaleBig.help"] = "Modificateur d'échelle de grande police. Des valeurs plus élevées rendent les grandes polices plus petites.",

    ---- HUD
    ["option.hud.bar.armor.show"] = "Afficher la barre d'armure",
    ["option.hud.bar.health.show"] = "Afficher la barre de vie",
    ["option.hud.elements.enabled"] = "Activer les éléments HUD",
    ["option.hud.targetid.enabled"] = "Activer les étiquettes TargetID",
    ["option.hud.targetid.distance"] = "Distance TargetID",
    ["option.hud.targetid.fade_speed_in"] = "Vitesse d'apparition TargetID",
    ["option.hud.targetid.fade_speed_out"] = "Vitesse de disparition TargetID",
    ["option.hud.targetid.position_speed"] = "Vitesse de suivi TargetID",
    ["option.hud.targetid.max_width"] = "Largeur de description TargetID",
    ["option.hud.targetid.line_spacing"] = "Espacement des lignes TargetID",
    ["option.hud.targetid.visible_delay"] = "Délai de visibilité TargetID",
    ["option.hud.targetid.player_offset"] = "Décalage joueur TargetID",
    ["option.hud.targetid.flash_speed"] = "Vitesse de clignotement TargetID",
    ["option.hud.targetid.show_descriptions"] = "Afficher les descriptions TargetID",
    ["option.hud.targetid.show_extras"] = "Afficher les lignes supplémentaires TargetID",
    ["option.hud.elements.enabled.help"] = "Activer ou désactiver tous les éléments HUD du framework.",
    ["option.hud.targetid.enabled.help"] = "Activer ou désactiver les étiquettes TargetID lors du regard sur des entités.",
    ["option.hud.targetid.distance.help"] = "Distance à laquelle les étiquettes TargetID peuvent détecter les entités.",
    ["option.hud.targetid.fade_speed_in.help"] = "Vitesse à laquelle les étiquettes TargetID apparaissent.",
    ["option.hud.targetid.fade_speed_out.help"] = "Vitesse à laquelle les étiquettes TargetID disparaissent.",
    ["option.hud.targetid.position_speed.help"] = "Vitesse à laquelle les étiquettes TargetID suivent les entités en mouvement.",
    ["option.hud.targetid.max_width.help"] = "Largeur maximale de la description TargetID avant le retour à la ligne.",
    ["option.hud.targetid.line_spacing.help"] = "Espacement vertical entre les lignes de description TargetID.",
    ["option.hud.targetid.visible_delay.help"] = "Durée pendant laquelle les étiquettes TargetID restent entièrement visibles après avoir perdu la visée directe.",
    ["option.hud.targetid.player_offset.help"] = "Décalage vertical des étiquettes TargetID pour les joueurs et les ragdolls.",
    ["option.hud.targetid.flash_speed.help"] = "Vitesse à laquelle les étiquettes TargetID clignotantes pulsent.",
    ["option.hud.targetid.show_descriptions.help"] = "Afficher les descriptions par défaut des objets et personnages sous les étiquettes TargetID.",
    ["option.hud.targetid.show_extras.help"] = "Afficher les lignes de description supplémentaires TargetID fournies par les entités.",
    ["option.notification.enabled"] = "Activer les notifications",
    ["option.notification.length.default"] = "Durée par défaut des notifications",
    ["option.notification.scale"] = "Échelle des notifications",
    ["option.notification.sounds"] = "Activer les sons de notification",
    ["option.notification.position"] = "Position des notifications",

    ---- Inventory
    ["option.inventory.categories.italic"] = "Mettre les noms de catégories en italique",
    ["option.inventory.columns"] = "Nombre de colonnes d'inventaire",
    ["option.store.columns"] = "Nombre de colonnes du magasin",
    ["option.inventory.sort.categories"] = "Mode de tri des catégories d'inventaire",
    ["option.inventory.sort.items"] = "Mode de tri des objets d'inventaire",
    ["option.inventory.search.live"] = "Recherche d'inventaire en direct",
    ["option.inventory.categories.collapsible"] = "Catégories d'inventaire repliables",
    ["option.inventory.pagination.page_size"] = "Taille de page de l'inventaire",
    ["option.inventory.actions.confirm_bulk_drop"] = "Confirmer les actions de dépôt en masse",
    ["option.inventory.sort.categories.help"] = "Choisissez comment les catégories d'inventaire sont ordonnées.",
    ["option.inventory.sort.items.help"] = "Choisissez comment les objets sont ordonnés à l'intérieur de chaque catégorie.",
    ["option.store.columns.help"] = "Définissez le nombre de colonnes utilisées dans la grille du magasin de paramètres.",
    ["option.inventory.search.live.help"] = "Mettre à jour les résultats de recherche pendant la saisie.",
    ["option.inventory.categories.collapsible.help"] = "Autoriser le repliement et le développement des catégories d'inventaire.",
    ["option.inventory.pagination.page_size.help"] = "Nombre de piles d'inventaire affichées par page.",
    ["option.inventory.actions.confirm_bulk_drop.help"] = "Demander une confirmation avant de déposer plusieurs objets d'une pile.",
    ["inventory.sort.alphabetical"] = "Alphabétique",
    ["inventory.sort.manual"] = "Manuel",
    ["inventory.sort.weight"] = "Poids",
    ["inventory.sort.class"] = "Classe",

    -- Inventory Translations
    ["inventory.weight.abbreviation"] = "kg",
    ["inventory.reason.no_space"] = "Il n'y a pas d'espace pour cet objet.",
    ["inventory.reason.wrong_slot"] = "Cet objet ne peut pas aller dans cet emplacement.",
    ["inventory.reason.no_access"] = "Vous n'avez pas accès à cet inventaire.",
    ["inventory.reason.locked"] = "Cet inventaire est verrouillé.",
    ["inventory.reason.nesting"] = "Vous ne pouvez pas placer cet objet ici.",
    ["inventory.reason.too_far"] = "Vous êtes trop loin.",
    ["inventory.reason.invalid"] = "Cette action est invalide.",

    -- OOC / Notification Translations
    ["notify.chat.ooc.disabled"] = "La discussion OOC est actuellement désactivée sur ce serveur.",
    ["notify.chat.ooc.wait"] = "Veuillez attendre %d seconde(s) avant d'envoyer un autre message OOC.",
    ["notify.chat.ooc.rate_limited"] = "Vous avez atteint la limite de messages OOC (%d) pour les %d dernières minutes.",
    ["error.ragdolled.action"] = "Vous ne pouvez pas effectuer d'actions pendant que vous êtes ragdollé.",
    ["error.ragdolled.inventory"] = "Vous ne pouvez pas déplacer des objets d'inventaire pendant que vous êtes ragdollé.",
    ["error.ragdolled.item_interact"] = "Vous ne pouvez pas utiliser d'objets pendant que vous êtes ragdollé.",
    ["error.ragdolled.use"] = "Vous ne pouvez pas utiliser d'entités pendant que vous êtes ragdollé.",
    ["error.ragdolled.vehicle_enter"] = "Vous ne pouvez pas entrer dans des véhicules pendant que vous êtes ragdollé.",

    ---- Flags
    ["flag.p.name"] = "Permission Physgun",
    ["flag.p.description"] = "Permet l'utilisation du physgun.",

    ["flag.t.name"] = "Permission Toolgun",
    ["flag.t.description"] = "Permet l'utilisation du toolgun.",

    ["config.interface.font.antialias"] = "Anticrénelage des polices",
    ["config.interface.font.multiplier"] = "Échelle des polices",

    ["config.interface.vignette.enabled"] = "Activer l'effet de vignettage",
    ["config.interface.vignette.enabled.help"] = "Activer/désactiver l'effet de vignettage autour des bords de l'écran.",

    ["config.interface.buildmenu.requires_tools"] = "Exiger des outils de construction pour les menus Spawn/Context",
    ["config.interface.buildmenu.requires_tools.help"] = "Bloquer les menus spawn et contextuels sauf si le joueur tient un outil de construction.",
    ["config.interface.buildmenu.notify_attempts"] = "Tentatives de notification pour menus bloqués",
    ["config.interface.buildmenu.notify_attempts.help"] = "Nombre de pressions sur menu bloquées nécessaires avant d'afficher une notification.",
    ["config.interface.buildmenu.notify_reset_delay"] = "Délai de réinitialisation des notifications de menus bloqués",
    ["config.interface.buildmenu.notify_reset_delay.help"] = "Secondes avant la réinitialisation du compteur de pressions sur menu bloquées.",

    -- Chatbox
    ["chatbox.entry.placeholder"] = "Dites quelque chose...",
    ["chatbox.recommendations.no_description"] = "Aucune description fournie.",
    ["chatbox.recommendations.truncated"] = "Affichage des %d premiers résultats.",
    ["chatbox.menu.close"] = "Fermer le chat",
    ["chatbox.menu.clear_history"] = "Effacer l'historique du chat",
    ["chatbox.menu.reset_position"] = "Réinitialiser la position",
    ["chatbox.menu.reset_size"] = "Réinitialiser la taille",
    ["chatbox.menu.confirm_clear_title"] = "Effacer l'historique du chat",
    ["chatbox.menu.confirm_clear_message"] = "Effacer tout l'historique du chat ?",

    ["config.chatbox.max_message_length"] = "Longueur maximale des messages de la boîte de chat",
    ["config.chatbox.history_size"] = "Taille de l'historique de saisie de la boîte de chat",
    ["config.chatbox.chat_type_history"] = "Taille de l'historique des types de chat de la boîte de chat",
    ["config.chatbox.looc_prefix"] = "Préfixe LOOC de la boîte de chat",
    ["config.chatbox.recommendations.debounce"] = "Délai de recommandations de la boîte de chat",
    ["config.chatbox.recommendations.animation_duration"] = "Durée d'animation des recommandations de la boîte de chat",
    ["config.chatbox.recommendations.command_limit"] = "Limite de recommandations de commandes de la boîte de chat",
    ["config.chatbox.recommendations.voice_limit"] = "Limite de recommandations vocales de la boîte de chat",
    ["config.chatbox.recommendations.wrap_cycle"] = "Cycle de retour des recommandations de la boîte de chat",

    ["scoreboard.context.copy_steamid"] = "Copier le SteamID",
    ["scoreboard.context.view_profile"] = "Voir le profil"
})