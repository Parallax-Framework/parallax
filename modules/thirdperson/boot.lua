local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Allows players to view themselves in third person."
MODULE.Author = "Riggs"

ax.option:Register("thirdperson", {
    Name = "option.thirdperson",
    Type = ax.types.bool,
    Default = false,
    Description = "option.thirdperson.enable.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.head", {
    Name = "options.thirdperson.follax.head",
    Type = ax.types.bool,
    Default = false,
    Description = "options.thirdperson.follax.head.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.hit.angles", {
    Name = "options.thirdperson.follax.hit.angles",
    Type = ax.types.bool,
    Default = true,
    Description = "options.thirdperson.follax.hit.angles.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.follax.hit.fov", {
    Name = "options.thirdperson.follax.hit.fov",
    Type = ax.types.bool,
    Default = true,
    Description = "options.thirdperson.follax.hit.fov.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.x", {
    Name = "options.thirdperson.position.x",
    Type = ax.types.number,
    Default = 50,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.x.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.y", {
    Name = "options.thirdperson.position.y",
    Type = ax.types.number,
    Default = 25,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.y.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.option:Register("thirdperson.position.z", {
    Name = "options.thirdperson.position.z",
    Type = ax.types.number,
    Default = 0,
    Min = -100,
    Max = 100,
    Decimals = 0,
    Description = "options.thirdperson.position.z.help",
    NoNetworking = true,
    Category = "category.thirdperson"
})

ax.config:Register("thirdperson.tracecheck", {
    Name = "options.thirdperson.traceplayercheck",
    Type = ax.types.bool,
    Default = false,
    Description = "options.thirdperson.traceplayercheck.help",
    Category = "category.thirdperson"
})

local meta = FindMetaTable("Player")
function meta:InThirdperson()
    return SERVER and ax.option:Get(self, "thirdperson", false) or ax.option:Get("thirdperson", false)
end

if (CLIENT) then
    ax.localization:Register("en", {
        ["category.thirdperson"] = "Third Person",
        ["option.thirdperson"] = "Third Person",
        ["option.thirdperson.enable"] = "Enable Third Person",
        ["option.thirdperson.enable.help"] = "Enable or disable third person view.",
        ["options.thirdperson.follax.head"] = "Follow Head",
        ["options.thirdperson.follax.head.help"] = "Follow the player's head with the third person camera.",
        ["options.thirdperson.follax.hit.angles"] = "Follow Hit Angles",
        ["options.thirdperson.follax.hit.angles.help"] = "Follow the hit angles with the third person camera.",
        ["options.thirdperson.follax.hit.fov"] = "Follow Hit FOV",
        ["options.thirdperson.follax.hit.fov.help"] = "Follow the hit FOV with the third person camera.",
        ["options.thirdperson.position.x"] = "Position X",
        ["options.thirdperson.position.x.help"] = "Set the X position of the third person camera.",
        ["options.thirdperson.position.y"] = "Position Y",
        ["options.thirdperson.position.y.help"] = "Set the Y position of the third person camera.",
        ["options.thirdperson.position.z"] = "Position Z",
        ["options.thirdperson.position.z.help"] = "Set the Z position of the third person camera.",
        ["options.thirdperson.reset"] = "Reset third person camera position.",
        ["options.thirdperson.toggle"] = "Toggle third person view.",
        ["options.thirdperson.traceplayercheck"] = "Trace Player Check",
        ["options.thirdperson.traceplayercheck.help"] = "Draw only the players that the person would see as if they were in firstperson.",
    })

    ax.localization:Register("ru", {
        ["category.thirdperson"] = "Третье лицо",
        ["option.thirdperson"] = "Третье лицо",
        ["option.thirdperson.enable"] = "Включение третьего лицо",
        ["option.thirdperson.enable.help"] = "Должно ли третье лицо быть включено?",
        ["options.thirdperson.follax.head"] = "Следовать за головой",
        ["options.thirdperson.follax.head.help"] = "Должен ли вид от третьего лица следовать за головой игрока?",
        ["options.thirdperson.follax.hit.angles"] = "Следовать за углом удара",
        ["options.thirdperson.follax.hit.angles.help"] = "Должен ли вид от третьего лица следовать за углом удара игрока?",
        ["options.thirdperson.follax.hit.fov"] = "Следовать FOV удара",
        ["options.thirdperson.follax.hit.fov.help"] = "Должен ли вид от третьего лица следовать за FOV удара игрока?",
        ["options.thirdperson.position.x"] = "Позиция по X",
        ["options.thirdperson.position.x.help"] = "Устанавливает позицию по X для вида от третьего лица.",
        ["options.thirdperson.position.y"] = "Позиция по Y",
        ["options.thirdperson.position.y.help"] = "Устанавливает позицию по Y для вида от третьего лица.",
        ["options.thirdperson.position.z"] = "Позиция по Z",
        ["options.thirdperson.position.z.help"] = "Устанавливает позицию по Z для вида от третьего лица.",
        ["options.thirdperson.reset"] = "Сбросить позицию вида от третьего лица.",
        ["options.thirdperson.toggle"] = "Переключить вид от третьего лица.",
        ["options.thirdperson.traceplayercheck"] = "Проверка через трасировку",
        ["options.thirdperson.traceplayercheck.help"] = "Отрисовывать только тех игроков, которых игрок бы мог увидеть в виде от первого лица.",
    })
end