--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "ar2"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "rpg"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "ar2"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

--- Animation library
-- @module ax.animations

ax.animations = ax.animations or {}

--- Stored animations for model classes
-- @realm shared
-- @table ax.animations.stored
ax.animations.stored = ax.animations.stored or {}

--- Translations cache for model classes
-- @realm shared
-- @table ax.animations.translations
ax.animations.translations = ax.animations.translations or {}

ax.animations.stored["citizen_male"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "meleeattack01",
        ["land"] = "jump_holding_land"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shootp1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_shotgun",
        ["shoot_crouch"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2",
        ["land"] = "jump_holding_land"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_rpg_relaxed", "idle_angry_rpg"}, "idle_rpg_aim"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {{"walk_rpg_relaxed_all", "walk_holding_rpg_all"}, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {"crouch_walk_holding_rpg_all", ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {{"run_rpg_relaxed_all", "run_holding_rpg_all"}, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_rpg",
        ["reload"] = "gesture_reload_ar2",
        ["land"] = "jump_holding_land"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        ["shoot"] = "swing",
        ["land"] = "jump_holding_land"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
        ["shoot"] = "grenthrow_gesture",
        ["land"] = "jump_holding_land"
    },
    ["vehicle"] = {
        prop_vehicle_airboat = {"silo_sit", Vector(10, 0, -18)},
        prop_vehicle_jeep = {"silo_sit", Vector(18, 0, -14)},
        ["models/vehicles/prisoner_pod_inner.mdl"] = {"podpose", Vector(-3.5, 0, -4)},
        chair = {"silo_sit", Vector(8, 0, -22)},
    }
}

ax.animations.stored["citizen_female"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "meleeattack01",
        ["land"] = "jump_holding_land"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        ["shoot"] = "gesture_shootp1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_shotgun",
        ["shoot_crouch"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2",
        ["land"] = "jump_holding_land"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_rpg_relaxed", "idle_angry_rpg"}, "idle_rpg_aim"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {{"walk_rpg_relaxed_all", "walk_holding_rpg_all"}, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {"crouch_walk_holding_rpg_all", ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {{"run_rpg_relaxed_all", "run_holding_rpg_all"}, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["shoot"] = "gesture_shoot_rpg",
        ["reload"] = "gesture_reload_ar2",
        ["land"] = "jump_holding_land"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        ["shoot"] = "swing",
        ["land"] = "jump_holding_land"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        ["shoot"] = ACT_RANGE_ATTACK_THROW
    },
    ["vehicle"] = {
        prop_vehicle_airboat = {"silo_sit", Vector(10, 0, -18)},
        prop_vehicle_jeep = {"silo_sit", Vector(18, 0, -14)},
        ["models/vehicles/prisoner_pod_inner.mdl"] = {"podpose", Vector(-3.5, 0, -4)},
        chair = {"silo_sit", Vector(8, 0, -22)},
    }
}

ax.animations.stored["overwatch"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "melee_gunhit",
        ["land"] = "jump_holding_land"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload",
        ["land"] = "jump_holding_land"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload",
        ["land"] = "jump_holding_land"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
        ["shoot"] = "gesture_shoot_shotgun",
        ["shoot_crouch"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload",
        ["land"] = "jump_holding_land"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload",
        ["land"] = "jump_holding_land"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload",
        ["land"] = "jump_holding_land"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "melee_gunhit",
        ["land"] = "jump_holding_land"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "grenthrow",
        ["land"] = "jump_holding_land"
    },
    ["vehicle"] = {
        prop_vehicle_airboat = {"crouchidle", Vector(0, -2, -10)},
        prop_vehicle_jeep = {"crouchidle", Vector(8, -2, 0)},
        ["models/vehicles/prisoner_pod_inner.mdl"] = {"idle_unarmed", Vector(-7, -1, -4)},
        chair = {"crouchidle", Vector(0, 0, -10)},
    }
}

ax.animations.stored["metrocop"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "swinggesture",
        ["land"] = "jump_holding_land"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
        [ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_pistol",
        ["land"] = "jump_holding_land"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_smg1",
        ["shoot_crouch"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1",
        ["land"] = "jump_holding_land"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "swinggesture",
        ["land"] = "jump_holding_land"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "grenadethrow",
        ["land"] = "jump_holding_land"
    },
    ["vehicle"] = {
        prop_vehicle_airboat = {"crouch_idle_pistol", Vector(10, -2, -10)},
        prop_vehicle_jeep = {"crouch_idle_pistol", Vector(18, -2, 0)},
        ["models/vehicles/prisoner_pod_inner.mdl"] = {"batonidle2", Vector(-4, -1, -4)},
        chair = {"crouch_idle_pistol", Vector(8, -4, -10)},
    }
}

ax.animations.stored["vortigaunt"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        ["shoot"] = {"meleehigh1", "meleehigh2", "meleehigh3"},
        ["land"] = "jump_holding_land"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        ["land"] = "jump_holding_land"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        ["land"] = "jump_holding_land"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK},
        ["land"] = "jump_holding_land"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    }
}

ax.animations.stored["player"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_revolver"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        [ACT_MP_JUMP] = {"jump_revolver", "jump_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "range_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_smg1"},
        [ACT_MP_WALK] = {"walk_passive", "walk_smg1"},
        [ACT_MP_RUN] = {"run_passive", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "range_smg1",
        ["reload"] = {"gesture_reload_smg1", "reload_smg1_alt"}
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_shotgun"},
        [ACT_MP_WALK] = {"walk_passive", "walk_shotgun"},
        [ACT_MP_RUN] = {"run_passive", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "range_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_passive", "walk_ar2"},
        [ACT_MP_RUN] = {"run_passive", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "range_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_rpg"},
        [ACT_MP_WALK] = {"walk_passive", "walk_rpg"},
        [ACT_MP_RUN] = {"run_passive", "run_rpg"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_rpg"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_rpg"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_rpg"},
        ["land"] = "jump_land",
        ["shoot"] = "range_rpg",
        ["reload"] = "gesture_reload_rpg"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_all_01", "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        [ACT_MP_JUMP] = {"jump_grenade", "jump_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

--- Sets a model class translation for a specific model.
-- @param model The model to set the translation for.
-- @param class The class to set the translation to.
function ax.animations:SetModelClass(model, class)
    if ( !model or !class ) then return end

    class = utf8.lower(class)

    if ( !self.stored[class] ) then
        ax.util:PrintError("Animation class '" .. class .. "' does not exist!")
        return false
    end

    model = utf8.lower(model)

    self.translations[model] = class
end

--- Gets the model class for a specific model.
-- @param model The model to get the class for.
-- @return The model class.
function ax.animations:GetModelClass(model)
    if ( !model ) then return end

    model = utf8.lower(model)

    -- Look for a translation
    if ( self.translations[model] ) then
        return self.translations[model]
    end

    -- Otherwise check the model name
    if ( ax.util:FindString(model, "player") or ax.util:FindString(model, "pm") ) then
        return "player"
    elseif ( ax.util:FindString(model, "female") ) then
        return "citizen_female"
    end

    -- If all fails, return citizen_male as it is the most common animation set
    return "citizen_male"
end

--- Resolves an activity entry for the player's current raised state.
-- Weapons can override raised animations by implementing:
-- function SWEP:GetWeaponRaisedActivity(client, act, loweredActivity, raisedActivity, activityData, holdType)
function ax.animations:ResolveWeaponActivity(client, act, activityData)
    if ( !istable(activityData) ) then
        return activityData
    end

    local loweredActivity = activityData[1]
    local raisedActivity = activityData[2] or loweredActivity
    if ( !client:IsWeaponRaised() ) then
        return loweredActivity
    end

    local weapon = client:GetActiveWeapon()
    if ( type(weapon) != "Weapon" ) then
        return raisedActivity
    end

    local holdType = client:GetHoldType()

    if ( isfunction(weapon.GetWeaponRaisedActivity) ) then
        local override = weapon:GetWeaponRaisedActivity(client, act, loweredActivity, raisedActivity, activityData, holdType)
        if ( override != nil ) then
            return override
        end
    end

    local override = hook.Run("GetWeaponRaisedActivity", client, weapon, act, loweredActivity, raisedActivity, activityData, holdType)
    if ( override != nil ) then
        return override
    end

    return raisedActivity
end

-- Default model classes
ax.animations:SetModelClass(Model("models/combine_soldier.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/combine_soldier_prisonguard.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/combine_super_soldier.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/police.mdl"), "metrocop")
ax.animations:SetModelClass(Model("models/vortigaunt.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_blue.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_doctor.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_slave.mdl"), "vortigaunt")
