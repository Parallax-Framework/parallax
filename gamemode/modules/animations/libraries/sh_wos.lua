if ( !wOS or !wOS.DynaBase ) then return false end

function MODULE:TranslateEvent(client, event, data, desired)
    desired = isnumber(desired) and client:GetSequenceName(desired) or desired

    if ( string.StartsWith(desired, "reload_") ) then
        return "gesture_reload_" .. string.sub(desired, 8)
    elseif ( string.StartsWith(desired, "shoot_") ) then
        return "gesture_shoot_" .. string.sub(desired, 7)
    end
end

ax.animations.stored["player_citizen_male"] = {
    ["normal"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_fist"},
        [ACT_MP_WALK] = {"walk_all", "walk_fist"},
        [ACT_MP_RUN] = {"run_all_01", "run_fist"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_fist"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_fist"},
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_revolver"},
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
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        [ACT_MP_JUMP] = {"jump_grenade", "jump_grenade"},
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
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"idle_all_01", "idle_all_02"}, "idle_revolver"},
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
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        [ACT_MP_JUMP] = {"jump_grenade", "jump_grenade"},
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
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_pistol", "combatidle1_pistol"},
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
        [ACT_MP_STAND_IDLE] = {"idle1_smg1", "combatidle1_smg1"},
        [ACT_MP_WALK] = {"walk_all_smg1", "walk_aiming_all"},
        [ACT_MP_RUN] = {"runall_smg1", "run_smg1"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_smg1"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_smg1"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "range_smg1",
        ["reload"] = {"gesture_reload_smg1", "reload_smg1_alt"}
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_sg", "combatidle1_sg"},
        [ACT_MP_WALK] = {"walk_all_sg", "walk_aiming_all_sg"},
        [ACT_MP_RUN] = {"runall_sg", "run_shotgun"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_shotgun"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_shotgun"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "range_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_ar2", "idle_ar2"},
        [ACT_MP_WALK] = {"walk_all_ar2", "walk_ar2"},
        [ACT_MP_RUN] = {"runall_ar2", "run_ar2"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_ar2"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_ar2"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "range_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {"idle1_rpg", "idle_rpg"},
        [ACT_MP_WALK] = {"walk_all_rpg", "walk_rpg"},
        [ACT_MP_RUN] = {"runall_rpg", "run_rpg"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_passive", "cidle_rpg"},
        [ACT_MP_CROUCHWALK] = {"cwalk_passive", "cwalk_rpg"},
        [ACT_MP_JUMP] = {"jump_passive", "jump_rpg"},
        ["land"] = "jump_land",
        ["shoot"] = "range_rpg",
        ["reload"] = "gesture_reload_rpg"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_melee"},
        [ACT_MP_WALK] = {"walk_all", "walk_melee"},
        [ACT_MP_RUN] = {"run_all_01", "run_melee"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_melee"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_melee"},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "range_melee"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {"idle_unarmed", "idle_grenade"},
        [ACT_MP_WALK] = {"walk_all", "walk_grenade"},
        [ACT_MP_RUN] = {"run_all_01", "run_grenade"},
        [ACT_MP_CROUCH_IDLE] = {"cidle_all", "cidle_grenade"},
        [ACT_MP_CROUCHWALK] = {"cwalk_all", "cwalk_grenade"},
        [ACT_MP_JUMP] = {"jump_grenade", "jump_grenade"},
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
        [ACT_MP_JUMP] = {"jump_slam", "jump_fist"},
        ["land"] = "jump_land",
        ["shoot"] = {"range_fists_l", "range_fists_r"}
    },
    ["pistol"] = {
        [ACT_MP_STAND_IDLE] = {{"pistolidle1", "pistolidle2", "pistolidle3"}, "pistolangryidle2"},
        [ACT_MP_WALK] = {"walk_hold_pistol", "walk_aiming_pistol_alert_all"},
        [ACT_MP_RUN] = {"run_hold_pistol", "run_aiming_pistol_alert_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_revolver", "jump_revolver"},
        ["land"] = "jump_land",
        ["shoot"] = "range_pistol",
        ["reload"] = "gesture_reload_357"
    },
    ["smg"] = {
        [ACT_MP_STAND_IDLE] = {{"smg1idle1", "smg1idle2"}, "smg1angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_smg1", "walk_aiming_smg1_all"},
        [ACT_MP_RUN] = {"run_hold_smg1", "run_aiming_smg1_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_passive", "jump_smg1"},
        ["land"] = "jump_land",
        ["shoot"] = "range_smg1",
        ["reload"] = {"gesture_reload_smg1", "reload_smg1_alt"}
    },
    ["shotgun"] = {
        [ACT_MP_STAND_IDLE] = {"shotgunidle1", "shotgunangryidle1"},
        [ACT_MP_WALK] = {"walk_hold_shotgun", "walk_aiming_shotgun_all"},
        [ACT_MP_RUN] = {"run_hold_shotgun", "run_aiming_shotgun_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_passive", "jump_shotgun"},
        ["land"] = "jump_land",
        ["shoot"] = "range_shotgun",
        ["reload"] = "gesture_reload_shotgun"
    },
    ["ar2"] = {
        [ACT_MP_STAND_IDLE] = {"ar2idle1", "ar2angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_ar2", "walk_aiming_ar2_all"},
        [ACT_MP_RUN] = {"run_hold_ar2", "run_aiming_ar2_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_passive", "jump_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "range_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["rpg"] = {
        [ACT_MP_STAND_IDLE] = {"ar2idle1", "ar2angryidle1"},
        [ACT_MP_WALK] = {"walk_hold_ar2", "walk_aiming_ar2_all"},
        [ACT_MP_RUN] = {"run_hold_ar2", "run_aiming_ar2_all"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_SMG1_LOW, ACT_COVER_SMG1_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_passive", "jump_ar2"},
        ["land"] = "jump_land",
        ["shoot"] = "range_ar2",
        ["reload"] = "gesture_reload_ar2"
    },
    ["melee"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all_unarmed", "walk_all_unarmed"},
        [ACT_MP_RUN] = {"run_all_unarmed", "run_all_unarmed"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "swinggesture"
    },
    ["grenade"] = {
        [ACT_MP_STAND_IDLE] = {{"batonidle1", "batonidle2"}, "batonangryidle1"},
        [ACT_MP_WALK] = {"walk_all_unarmed", "walk_all_unarmed"},
        [ACT_MP_RUN] = {"run_all_unarmed", "run_all_unarmed"},
        [ACT_MP_CROUCH_IDLE] = {ACT_COVER_PISTOL_LOW, ACT_COVER_PISTOL_LOW},
        [ACT_MP_CROUCHWALK] = {ACT_WALK_CROUCH, ACT_WALK_CROUCH},
        [ACT_MP_JUMP] = {"jump_melee", "jump_melee"},
        ["land"] = "jump_land",
        ["shoot"] = "swinggesture"
    }
}

ax.animations:SetModelClass(Model("models/player/police.mdl"), "player_metrocop")
ax.animations:SetModelClass(Model("models/player/combine_soldier.mdl"), "player_overwatch")
ax.animations:SetModelClass(Model("models/player/combine_soldier_prisonguard.mdl"), "player_overwatch")
ax.animations:SetModelClass(Model("models/player/combine_super_soldier.mdl"), "player_overwatch")
