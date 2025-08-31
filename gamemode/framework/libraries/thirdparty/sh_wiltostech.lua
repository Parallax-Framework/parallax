if ( !wOS or !wOS.DynaBase ) then return end

hook.Add("InitLoadAnimations", "wOS.DynaBase.CustomMount", function()
    wOS.DynaBase:RegisterSource({
        Name = "Parallax",
        Type = WOS_DYNABASE.REANIMATION,
        Male = "models/humans/male_shared.mdl",
        Female = "models/humans/female_shared.mdl"
    })

    hook.Add("PreLoadAnimations", "wOS.DynaBase.MountCustom", function(gender)
        if ( gender == WOS_DYNABASE.SHARED ) then return end

        if ( gender == WOS_DYNABASE.FEMALE ) then
            IncludeModel("models/alyx_animations.mdl")
            IncludeModel("models/alyx_gest_ep1.mdl")
            IncludeModel("models/alyx_gest_ep2.mdl")
            IncludeModel("models/alyx_gestures.mdl")
            IncludeModel("models/alyx_postures.mdl")
            IncludeModel("models/eli_gestures.mdl")
            IncludeModel("models/eli_postures.mdl")
            IncludeModel("models/mossman_gestures.mdl")
            IncludeModel("models/mossman_postures.mdl")
            IncludeModel("models/humans/female_shared.mdl")
            IncludeModel("models/humans/female_ss.mdl")
            IncludeModel("models/humans/female_gestures.mdl")
            IncludeModel("models/humans/female_postures.mdl")
        elseif ( gender == WOS_DYNABASE.MALE ) then
            IncludeModel("models/barney_gestures.mdl")
            IncludeModel("models/barney_postures.mdl")
            IncludeModel("models/combine_soldier_anims.mdl")
            IncludeModel("models/eli_gestures.mdl")
            IncludeModel("models/eli_postures.mdl")
            IncludeModel("models/police_animations.mdl")
            IncludeModel("models/police_ss.mdl")
            IncludeModel("models/humans/male_shared.mdl")
            IncludeModel("models/humans/male_ss.mdl")
            IncludeModel("models/humans/male_gestures.mdl")
            IncludeModel("models/humans/male_postures.mdl")
        end
    end)
end)