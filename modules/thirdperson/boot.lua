--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Third Person"
MODULE.Description = "Allows players to view themselves in third person."
MODULE.Author = "Riggs"

local meta = FindMetaTable("Player")
function meta:InThirdperson()
    return SERVER and ax.option:Get(self, "thirdperson", false) or ax.option:Get("thirdperson", false)
end

if ( CLIENT ) then
    ax.localization:Register("en", {
        ["category.thirdperson"] = "Third Person",
        ["option.thirdperson"] = "Third Person",
        ["option.thirdperson.enable"] = "Enable Third Person",
        ["option.thirdperson.enable.help"] = "Enable or disable third person view.",
        ["options.thirdperson.follow.head"] = "Follow Head",
        ["options.thirdperson.follow.head.help"] = "Follow the player's head with the third person camera.",
        ["options.thirdperson.follow.hit.angles"] = "Follow Hit Angles",
        ["options.thirdperson.follow.hit.angles.help"] = "Follow the hit angles with the third person camera.",
        ["options.thirdperson.follow.hit.fov"] = "Follow Hit FOV",
        ["options.thirdperson.follow.hit.fov.help"] = "Follow the hit FOV with the third person camera.",
        ["options.thirdperson.position.x"] = "Position X",
        ["options.thirdperson.position.x.help"] = "Set the X position of the third person camera.",
        ["options.thirdperson.position.y"] = "Position Y",
        ["options.thirdperson.position.y.help"] = "Set the Y position of the third person camera.",
        ["options.thirdperson.position.z"] = "Position Z",
        ["options.thirdperson.position.z.help"] = "Set the Z position of the third person camera.",
        ["options.thirdperson.reset"] = "Reset third person camera position.",
        ["options.thirdperson.traceplayercheck"] = "Trace Player Check",
        ["options.thirdperson.traceplayercheck.help"] = "Draw only the players that the person would see as if they were in firstperson.",
        ["options.thirdperson.toggle"] = "Toggle third person view.",
        ["options.thirdperson.toggle.help"] = "Keybind to toggle third person view.",
    })

    ax.localization:Register("ru", {
        ["category.thirdperson"] = "Третье лицо",
        ["option.thirdperson"] = "Третье лицо",
        ["option.thirdperson.enable"] = "Включение третьего лицо",
        ["option.thirdperson.enable.help"] = "Должно ли третье лицо быть включено?",
        ["options.thirdperson.follow.head"] = "Следовать за головой",
        ["options.thirdperson.follow.head.help"] = "Должен ли вид от третьего лица следовать за головой игрока?",
        ["options.thirdperson.follow.hit.angles"] = "Следовать за углом удара",
        ["options.thirdperson.follow.hit.angles.help"] = "Должен ли вид от третьего лица следовать за углом удара игрока?",
        ["options.thirdperson.follow.hit.fov"] = "Следовать FOV удара",
        ["options.thirdperson.follow.hit.fov.help"] = "Должен ли вид от третьего лица следовать за FOV удара игрока?",
        ["options.thirdperson.position.x"] = "Позиция по X",
        ["options.thirdperson.position.x.help"] = "Устанавливает позицию по X для вида от третьего лица.",
        ["options.thirdperson.position.y"] = "Позиция по Y",
        ["options.thirdperson.position.y.help"] = "Устанавливает позицию по Y для вида от третьего лица.",
        ["options.thirdperson.position.z"] = "Позиция по Z",
        ["options.thirdperson.position.z.help"] = "Устанавливает позицию по Z для вида от третьего лица.",
        ["options.thirdperson.reset"] = "Сбросить позицию вида от третьего лица.",
        ["options.thirdperson.traceplayercheck"] = "Проверка через трасировку",
        ["options.thirdperson.traceplayercheck.help"] = "Отрисовывать только тех игроков, которых игрок бы мог увидеть в виде от первого лица.",
        ["options.thirdperson.toggle"] = "Переключить вид от третьего лица.",
        ["options.thirdperson.toggle.help"] = "Клавиша для переключения вида от третьего лица.",
    })

    ax.localization:Register("es-ES", {
        ["category.thirdperson"] = "Tercera Persona",
        ["option.thirdperson"] = "Tercera Persona",
        ["option.thirdperson.enable"] = "Activar Tercera Persona",
        ["option.thirdperson.enable.help"] = "Activar o desactivar la vista en tercera persona.",
        ["options.thirdperson.follow.head"] = "Seguir Cabeza",
        ["options.thirdperson.follow.head.help"] = "Seguir la cabeza del jugador con la cámara en tercera persona.",
        ["options.thirdperson.follow.hit.angles"] = "Seguir Ángulos de Impacto",
        ["options.thirdperson.follow.hit.angles.help"] = "Seguir los ángulos de impacto con la cámara en tercera persona.",
        ["options.thirdperson.follow.hit.fov"] = "Seguir FOV de Impacto",
        ["options.thirdperson.follow.hit.fov.help"] = "Seguir el campo de visión (FOV) de impacto con la cámara en tercera persona.",
        ["options.thirdperson.position.x"] = "Posición X",
        ["options.thirdperson.position.x.help"] = "Establecer la posición X de la cámara en tercera persona.",
        ["options.thirdperson.position.y"] = "Posición Y",
        ["options.thirdperson.position.y.help"] = "Establecer la posición Y de la cámara en tercera persona.",
        ["options.thirdperson.position.z"] = "Posición Z",
        ["options.thirdperson.position.z.help"] = "Establecer la posición Z de la cámara en tercera persona.",
        ["options.thirdperson.reset"] = "Reiniciar posición de la cámara en tercera persona.",
        ["options.thirdperson.traceplayercheck"] = "Comprobación de Rastreo de Jugadores",
        ["options.thirdperson.traceplayercheck.help"] = "Mostrar solo los jugadores que serían visibles en primera persona.",
        ["options.thirdperson.toggle"] = "Alternar vista en tercera persona.",
        ["options.thirdperson.toggle.help"] = "Tecla para alternar la vista en tercera persona.",
    })
    ax.localization:Register("pt-PT", {
        ["category.thirdperson"] = "Terceira Pessoa",
        ["option.thirdperson"] = "Terceira Pessoa",
        ["option.thirdperson.enable"] = "Ativar Terceira Pessoa",
        ["option.thirdperson.enable.help"] = "Ativar ou desativar a vista em terceira pessoa.",
        ["options.thirdperson.follow.head"] = "Seguir Cabeça",
        ["options.thirdperson.follow.head.help"] = "Seguir a cabeça do jogador com a câmara em terceira pessoa.",
        ["options.thirdperson.follow.hit.angles"] = "Seguir Ângulos de Impacto",
        ["options.thirdperson.follow.hit.angles.help"] = "Seguir os ângulos de impacto com a câmara em terceira pessoa.",
        ["options.thirdperson.follow.hit.fov"] = "Seguir FOV de Impacto",
        ["options.thirdperson.follow.hit.fov.help"] = "Seguir o campo de visão (FOV) de impacto com a câmara em terceira pessoa.",
        ["options.thirdperson.position.x"] = "Posição X",
        ["options.thirdperson.position.x.help"] = "Definir a posição X da câmara em terceira pessoa.",
        ["options.thirdperson.position.y"] = "Posição Y",
        ["options.thirdperson.position.y.help"] = "Definir a posição Y da câmara em terceira pessoa.",
        ["options.thirdperson.position.z"] = "Posição Z",
        ["options.thirdperson.position.z.help"] = "Definir a posição Z da câmara em terceira pessoa.",
        ["options.thirdperson.reset"] = "Repor posição da câmara em terceira pessoa.",
        ["options.thirdperson.traceplayercheck"] = "Verificação de Rastreio de Jogadores",
        ["options.thirdperson.traceplayercheck.help"] = "Mostrar apenas os jogadores que seriam visíveis em primeira pessoa.",
        ["options.thirdperson.toggle"] = "Alternar vista em terceira pessoa.",
        ["options.thirdperson.toggle.help"] = "Tecla para alternar a vista em terceira pessoa.",
    })

    ax.localisation:Register("bg", {
        ["category.thirdperson"] = "Трето лице",
        ["option.thirdperson"] = "Трето лице",
        ["option.thirdperson.enable"] = "Активиране на трето лице",
        ["option.thirdperson.enable.help"] = "Активиране или деактивиране на изглед от трето лице.",
        ["options.thirdperson.follow.head"] = "Следване на главата",
        ["options.thirdperson.follow.head.help"] = "Следва ли изгледът от трето лице главата на играча.",
        ["options.thirdperson.follow.hit.angles"] = "Следване на ъглите на удара",
        ["options.thirdperson.follow.hit.angles.help"] = "Следва ли изгледът от трето лице ъглите на удара на играча.",
        ["options.thirdperson.follow.hit.fov"] = "Следване на FOV на удара",
        ["options.thirdperson.follow.hit.fov.help"] = "Следва ли изгледът от трето лице FOV на удара на играча.",
        ["options.thirdperson.position.x"] = "Позиция X",
        ["options.thirdperson.position.x.help"] = "Задава позицията X за изгледа от трето лице.",
        ["options.thirdperson.position.y"] = "Позиция Y",
        ["options.thirdperson.position.y.help"] = "Задава позицията Y за изгледа от трето лице.",
        ["options.thirdperson.position.z"] = "Позиция Z",
        ["options.thirdperson.position.z.help"] = "Задава позицията Z за изгледа от трето лице.",
        ["options.thirdperson.reset"] = "Нулиране на позицията на изгледа от трето лице.",
        ["options.thirdperson.traceplayercheck"] = "Проверка чрез проследяване на играчи",
        ["options.thirdperson.traceplayercheck.help"] = "Показва само играчите, които биха били видими в първо лице.",
        ["options.thirdperson.toggle"] = "Превключване към изглед от трето лице.",
        ["options.thirdperson.toggle.help"] = "Клавиш за превключване към изглед от трето лице.",
    })
end