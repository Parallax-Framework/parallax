----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 --- Made by a transgender queen
 -- Slay queen Riggs
 -- Stay Powerfull against the Patiarchy by a man (Alex Grist) stealing code
 -- #OverwatchFramework #CodeStealingMatters

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Animations"
MODULE.Author = "Riggs"
MODULE.Description = "Handles player animations."

HOLDTYPE_TRANSLATOR = {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "ar2"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["fist"] = "normal"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "normal"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

ax.animations = ax.animations or {}
ax.animations.stored = ax.animations.stored or {}
ax.animations.translations = ax.animations.translations or {}

ax.animations.stored["citizen_male"] = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SHOTGUN,
        reload = ACT_GESTURE_RELOAD_SHOTGUN
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE}
    }
}

ax.animations.stored["citizen_female"] = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SHOTGUN,
        reload = ACT_GESTURE_RELOAD_SHOTGUN
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_ANGRY},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH}
    }
}

ax.animations.stored["overwatch"] = {
    normal = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SHOTGUN,
        reload = ACT_GESTURE_RELOAD_SHOTGUN
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE}
    }
}

ax.animations.stored["metrocop"] = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_WALK] = {ACT_WALK_PISTOL, ACT_WALK_AIM_PISTOL},
        [ACT_MP_RUN] = {ACT_RUN_PISTOL, ACT_RUN_AIM_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        shoot = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        reload = ACT_GESTURE_RELOAD_PISTOL
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        shoot = ACT_GESTURE_RANGE_ATTACK_SHOTGUN,
        reload = ACT_GESTURE_RELOAD_SHOTGUN
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        shoot = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_GESTURE_RELOAD_SMG1
    }
}

ax.animations.stored["vortigaunt"] = {
    normal = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    pistol = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    smg = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    shotgun = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ar2 = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    melee = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    grenade = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "ActionIdle"},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    }
}

function ax.animations:SetModelClass(model, class)
    if ( !model or !class ) then return end

    class = string.lower(class)

    if ( !self.stored[class] ) then
        ax.util:PrintError("Animation class '" .. class .. "' does not exist!")
        return false
    end

    model = string.lower(model)

    self.translations[model] = class
end

function ax.animations:GetModelClass(model)
    if ( !model ) then return end

    model = string.lower(model)

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

ax.animations:SetModelClass("models/combine_soldier.mdl", "overwatch")
ax.animations:SetModelClass("models/combine_soldier_prisonGuard.mdl", "overwatch")
ax.animations:SetModelClass("models/combine_super_soldier.mdl", "overwatch")
ax.animations:SetModelClass("models/police.mdl", "metrocop")
ax.animations:SetModelClass("models/vortigaunt.mdl", "vortigaunt")
ax.animations:SetModelClass("models/vortigaunt_blue.mdl", "vortigaunt")
ax.animations:SetModelClass("models/vortigaunt_doctor.mdl", "vortigaunt")
ax.animations:SetModelClass("models/vortigaunt_slave.mdl", "vortigaunt")

local playerMeta = FindMetaTable("Player")
local _isFemale = playerMeta.IsFemale

function playerMeta:IsFemale()
    local modelClass = ax.animations:GetModelClass(self:GetModel())
    if ( !isstring(modelClass) or modelClass == "" ) then
        return _isFemale(self)
    end

    if ( ax.util:FindString(modelClass, "female") ) then
        return true
    end

    return _isFemale(self)
end

if ( SERVER ) then
    function playerMeta:LeaveSequence()
        local prevent = hook.Run("PrePlayerLeaveSequence", self)
        if ( prevent != nil and prevent == false ) then return end

        ax.net:Start(nil, "sequence.reset", self)

        self:SetRelay("sequence.callback", nil)
        self:SetRelay("sequence.forced", nil)
        self:SetMoveType(MOVETYPE_WALK)

        local callback = self:GetRelay("sequence.callback")
        if ( isfunction(callback) ) then
            callback(self)
        end

        hook.Run("PostPlayerLeaveSequence", self)
    end

    function playerMeta:ForceSequence(sequence, callback, time, noFreeze)
        local prevent = hook.Run("PrePlayerForceSequence", self, sequence, callback, time, noFreeze)
        if ( prevent != nil and prevent == false ) then return end

        if ( sequence == nil ) then
            ax.net:Start(nil, "sequence.reset", self)
            return
        end

        local sequenceID = self:LookupSequence(sequence)
        if ( sequenceID == -1 ) then
            ax.util:PrintError("Invalid sequence \"" .. sequence .. "\"!")
            return
        end

        local sequenceTime = isnumber(time) and time or self:SequenceDuration(sequenceID)

        self:SetCycle(0)
        self:SetPlaybackRate(1)
        self:SetRelay("sequence.forced", sequenceID)
        self:SetRelay("sequence.callback", callback or nil)

        if ( !noFreeze ) then
            self:SetMoveType(MOVETYPE_NONE)
        end

        if ( sequenceTime > 0 ) then
            timer.Create("ax.sequence." .. self:SteamID64(), sequenceTime, 1, function()
                self:LeaveSequence()
            end)

            return sequenceTime
        end

        hook.Run("PostPlayerForceSequence", self, sequence, callback, time, noFreeze)
    end
else
    ax.net:Hook("sequence.set", function(client)
        if ( !IsValid(client) ) then return end

        hook.Run("PostPlayerForceSequence", client)
    end)

    ax.net:Hook("sequence.reset", function(client)
        if ( !IsValid(client) ) then return end

        hook.Run("PostPlayerLeaveSequence", client)
    end)
end