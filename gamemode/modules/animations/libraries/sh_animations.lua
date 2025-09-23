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
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_RANGE_ATTACK_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_ATTACK_PISTOL_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        ["attack"] = ACT_RELOAD_PISTOL
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SMG1,
        ["reload"] = ACT_GESTURE_RELOAD_SMG1
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SMG1,
        ["reload"] = ACT_GESTURE_RELOAD_SMG1
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_RIFLE_STIMULATED},
        ["attack"] = ACT_RANGE_ATTACK_THROW
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_MELEE},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        ["attack"] = ACT_MELEE_ATTACK_SWING
    },
    ["glide"] = ACT_GLIDE,
    ["vehicle"] = {
        ["prop_vehicle_prisoner_pod"] = {"podpose", Vector(-3, 0, 0)},
        ["prop_vehicle_jeep"] = {ACT_BUSY_SIT_CHAIR, Vector(14, 0, -14)},
        ["prop_vehicle_airboat"] = {ACT_BUSY_SIT_CHAIR, Vector(8, 0, -20)},
        ["chair"] = {ACT_BUSY_SIT_CHAIR, Vector(1, 0, -23)}
    },
}

ax.animations.stored["citizen_female"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_RIFLE_STIMULATED}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_PISTOL, ACT_IDLE_ANGRY_PISTOL},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_PISTOL,
        ["attack"] = ACT_RELOAD_PISTOL
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SMG1,
        ["attack"] = ACT_GESTURE_RELOAD_SMG1
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SHOTGUN_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SHOTGUN
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1_RELAXED, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE_RELAXED, ACT_WALK_AIM_RIFLE_STIMULATED},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE_RELAXED, ACT_RUN_AIM_RIFLE_STIMULATED},
        ["attack"] = ACT_GESTURE_RANGE_ATTACK_SMG1,
        ["reload"] = ACT_GESTURE_RELOAD_SMG1
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_RANGE_AIM_SMG1_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_PISTOL},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH_AIM_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM_PISTOL},
        ["attack"] = ACT_RANGE_ATTACK_THROW
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_MANNEDGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_LOW, ACT_COVER_LOW},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN},
        ["attack"] = ACT_MELEE_ATTACK_SWING
    },
    ["glide"] = ACT_GLIDE,
    ["vehicle"] = ax.animations.stored["citizen_male"]["vehicle"]
}

ax.animations.stored["overwatch"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_357"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SHOTGUN},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_SHOTGUN},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_SHOTGUN},
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE_SMG1, ACT_IDLE_ANGRY_SMG1},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {ACT_WALK_RIFLE, ACT_WALK_AIM_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_RIFLE, ACT_RUN_AIM_RIFLE},
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["attack"] = "gesture_shoot_357"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", ACT_IDLE_ANGRY},
        [ACT_MP_CROUCH_IDLE] = {ACT_CROUCHIDLE, ACT_CROUCHIDLE},
        [ACT_MP_WALK] = {"walkunarmed_all", ACT_WALK_RIFLE},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH_RIFLE, ACT_WALK_CROUCH_RIFLE},
        [ACT_MP_RUN] = {ACT_RUN_AIM_RIFLE, ACT_RUN_AIM_RIFLE},
        ["attack"] = ACT_MELEE_ATTACK_SWING_GESTURE
    },
    ["glide"] = ACT_GLIDE
}

ax.animations.stored["metrocop"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"unarmedidle1", "unarmedidle1"},
        [ACT_MP_WALK] = {"walk_all_unarmed", "walk_all_unarmed"},
        [ACT_MP_RUN] = {"run_all_unarmed", "run_all_unarmed"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "swinggesture"
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"pistolidle1", "pistolidle2", "pistolidle3"}, "pistolangryidle2"},
        [ACT_MP_WALK] = {"walk_hold_pistol", "walk_aiming_pistol_all"},
        [ACT_MP_RUN] = {"run_hold_pistol", "run_aiming_pistol_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_pistol"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {{"smg1idle1", "smg1idle2"}, "smg1angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_smg1", "walk_aiming_smg1_all"},
        [ACT_MP_RUN] = {"run_hold_smg1", "run_aiming_smg1_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"shotgunidle1", "shotgunangryidle1"},
        [ACT_MP_WALK] = {"walk_hold_shotgun", "walk_aiming_shotgun_all"},
        [ACT_MP_RUN] = {"run_hold_shotgun", "run_aiming_shotgun_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"ar2idle1", "ar2angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_ar2", "walk_aiming_ar2_all"},
        [ACT_MP_RUN] = {"run_hold_ar2", "run_aiming_ar2_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["shoot"] = "swinggesture"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["attack"] = "swinggesture"
    }
}

ax.animations.stored["vortigaunt"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, ACT_IDLE_ANGRY},
        [ACT_MP_WALK] = {ACT_WALK, ACT_WALK_AIM},
        [ACT_MP_RUN] = {ACT_RUN, ACT_RUN_AIM},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {ACT_IDLE, "TCidlecombat"},
        [ACT_MP_WALK] = {ACT_WALK, "Walk_all_TC"},
        [ACT_MP_RUN] = {ACT_RUN, "run_all_TC"},
        [ACT_MP_CROUCH_IDLE] = {"crouchidle", "crouchidle"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK, ACT_WALK}
    },
    ["ar2"] = {
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
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_revolver"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_smg1"},
        [ACT_MP_WALK] = {"walk_passive", "walk_smg1"},
        [ACT_MP_RUN] = {"run_passive", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_shotgun"},
        [ACT_MP_WALK] = {"walk_passive", "walk_shotgun"},
        [ACT_MP_RUN] = {"run_passive", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_passive", "walk_ar2"},
        [ACT_MP_RUN] = {"run_passive", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

ax.animations.stored["player_citizen_male"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_revolver"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_smg1"},
        [ACT_MP_WALK] = {"walk_passive", "walk_smg1"},
        [ACT_MP_RUN] = {"run_passive", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_shotgun"},
        [ACT_MP_WALK] = {"walk_passive", "walk_shotgun"},
        [ACT_MP_RUN] = {"run_passive", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_passive", "walk_ar2"},
        [ACT_MP_RUN] = {"run_passive", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

ax.animations.stored["player_citizen_female"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_revolver"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_smg1"},
        [ACT_MP_WALK] = {"walk_passive", "walk_smg1"},
        [ACT_MP_RUN] = {"run_passive", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_shotgun"},
        [ACT_MP_WALK] = {"walk_passive", "walk_shotgun"},
        [ACT_MP_RUN] = {"run_passive", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle_passive", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_passive", "walk_ar2"},
        [ACT_MP_RUN] = {"run_passive", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

ax.animations.stored["player_overwatch"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_pistol", "combatidle1_pistol"},
        [ACT_MP_WALK] = {"walk_all", "walk_revolver"},
        [ACT_MP_RUN] = {"run_all_01", "run_revolver"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_revolver"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_smg1", "combatidle1_smg1"},
        [ACT_MP_WALK] = {"walk_all_smg1", "walk_aiming_all"},
        [ACT_MP_RUN] = {"runall_smg1", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_sg", "combatidle1_sg"},
        [ACT_MP_WALK] = {"walk_all_sg", "walk_aiming_all_sg"},
        [ACT_MP_RUN] = {"runall_sg", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_ar2", "combatidle1"},
        [ACT_MP_WALK] = {"walk_all_ar2", "walk_aiming_all_ar2"},
        [ACT_MP_RUN] = {"runall_ar2", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        ["land"] = "jump_land",
        ["shoot"] = "range_grenade"
    }
}

ax.animations.stored["player_metrocop"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {"unarmedidle1", "idle_fist"},
        [ACT_MP_WALK] = {"walk_all_unarmed", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_unarmed", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, "cwalk_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"pistolidle1", "pistolidle2", "pistolidle3"}, "pistolangryidle2"},
        [ACT_MP_WALK] = {"walk_hold_pistol", "walk_aiming_pistol_all"},
        [ACT_MP_RUN] = {"run_hold_pistol", "run_aiming_pistol_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_pistol",
        ["reload"] = "gesture_reload_pistol"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {{"smg1idle1", "smg1idle2"}, "smg1angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_smg1", "walk_aiming_smg1_all"},
        [ACT_MP_RUN] = {"run_hold_smg1", "run_aiming_smg1_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_smg1",
        ["reload"] = "gesture_reload_smg1"
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"shotgunidle1", "shotgunangryidle1"},
        [ACT_MP_WALK] = {"walk_hold_shotgun", "walk_aiming_shotgun_all"},
        [ACT_MP_RUN] = {"run_hold_shotgun", "run_aiming_shotgun_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"ar2idle1", "ar2angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_ar2", "walk_aiming_ar2_all"},
        [ACT_MP_RUN] = {"run_hold_ar2", "run_aiming_ar2_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["shoot"] = "gesture_shoot_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["shoot"] = "swinggesture"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_hold_baton_angry"},
        [ACT_MP_RUN] = {"run_all", "run_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        ["land"] = "jump_land",
        ["attack"] = "swinggesture"
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

-- Default model classes
ax.animations:SetModelClass(Model("models/combine_soldier.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/combine_soldier_prisonguard.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/combine_super_soldier.mdl"), "overwatch")
ax.animations:SetModelClass(Model("models/police.mdl"), "metrocop")
ax.animations:SetModelClass(Model("models/vortigaunt.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_blue.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_doctor.mdl"), "vortigaunt")
ax.animations:SetModelClass(Model("models/vortigaunt_slave.mdl"), "vortigaunt")

ax.animations:SetModelClass(Model("models/player/police.mdl"), "player_metrocop")
ax.animations:SetModelClass(Model("models/player/combine_soldier.mdl"), "player_overwatch")
ax.animations:SetModelClass(Model("models/player/combine_soldier_prisonguard.mdl"), "player_overwatch")
ax.animations:SetModelClass(Model("models/player/combine_super_soldier.mdl"), "player_overwatch")

-- Not needed but good to have incase...
ax.animations:SetModelClass(Model("models/player/group01/female_01.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/female_02.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/female_03.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/female_04.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/female_05.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/female_06.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_01.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_02.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_03.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_04.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_05.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_06.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_07.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_08.mdl"), "player")
ax.animations:SetModelClass(Model("models/player/group01/male_09.mdl"), "player")