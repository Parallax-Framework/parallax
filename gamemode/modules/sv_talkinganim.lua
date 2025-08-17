local MODULE = MODULE

MODULE.Name = "Talking Animation"
MODULE.Description = "Adds talking animation functionality to the gamemode."
MODULE.Author = "Riggs"

local gestures = {
    [WOS_DYNABASE.MALE] = {
        idle = {
            "E_g_shrug",
            "G_medurgent_mid",
            "G_righthandheavy",
            "G_righthandroll",
            "Gesture01",
            "Gesture05",
            "Gesture05NP",
            "Gesture06",
            "Gesture06NP",
            "Gesture07",
            "Gesture13",
            "g_palm_out_high_l",
            "g_palm_out_l"
        },
        weapon = {
            "bg_accentUp",
            "bg_up_l",
            "bg_up_r",
            "g_Rifle_Lhand",
            "g_Rifle_Lhand_low",
            "g_palm_out_high_l",
            "g_palm_up_high_l"
        }
    },
    [WOS_DYNABASE.FEMALE] = {
        idle = {
            "A_g_armscrossed",
            "A_g_hflipout",
            "A_g_leftsweepoutbig",
            "A_g_low2side_palmsout",
            "A_g_mid_2hdcutdwn",
            "A_g_mid_2hdcutdwn_rt",
            "A_g_mid_rtcutdwn",
            "A_g_mid_rtfingflareout",
            "A_g_midhigh_arcout",
            "A_g_midhigh_arcout_left",
            "A_g_midhigh_arcout_right",
            "A_g_midrtarcdwnout",
            "A_g_rthdflipout",
            "A_g_rtl_dwnshp",
            "A_g_rtsweepoutbig",
            "A_gesture16",
            "M_g_sweepout"
        },
        weapon = {
            "A_g_midhigh_arcout_left",
            "bg_accentUp",
            "bg_up_l",
            "bg_up_r",
            "g_Rifle_Lhand",
            "g_Rifle_Lhand_low"
        }
    }
}

local idleHoldType = {
    ["camera"] = true,
    ["duel"] = true,
    ["fist"] = true,
    ["grenade"] = true,
    ["knife"] = true,
    ["melee"] = true,
    ["melee2"] = true,
    ["normal"] = true,
    ["physgun"] = true,
    ["slam"] = true
}

function MODULE:PickTalkingAnimation(client)
    local isFemale = client:IsFemale()
    local talkingAnimation = isFemale and gestures[WOS_DYNABASE.FEMALE].weapon or gestures[WOS_DYNABASE.MALE].weapon

    local holdType = client:GetHoldType()
    if ( holdType and idleHoldType[holdType] ) then
        talkingAnimation = isFemale and gestures[WOS_DYNABASE.FEMALE].idle or gestures[WOS_DYNABASE.MALE].idle
    end

    return talkingAnimation[math.random(#talkingAnimation)]
end

function MODULE:PlayTalkingAnimation(client)
    local animation = self:PickTalkingAnimation(client)
    if ( animation ) then
        client:PlayGesture(6, animation)
    end
end

function MODULE:PlayerSay(client, text, teamChat)
    if ( !IsValid(client) or !client:Alive() ) then return end

    -- Check if the player is talking
    if ( string.len(text) > 0 ) then
        self:PlayTalkingAnimation(client)
    end

    print("Player is talking:", text)
end