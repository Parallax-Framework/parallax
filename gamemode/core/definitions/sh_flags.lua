ax.flag:Register("t", "flag.toolgun", function(char, has)
    local client = char:GetPlayer()
    if ( !IsValid(client) ) then return end

    if ( has ) then
        client:Give("gmod_tool")
    else
        local wep = client:GetActiveWeapon()
        if ( IsValid(wep) and wep:GetClass() == "gmod_tool" ) then
            client:SelectWeapon("ax_hands")
        end

        client:StripWeapon("gmod_tool")
    end
end)

ax.flag:Register("p", "flag.physgun", function(char, has)
    local client = char:GetPlayer()
    if ( !IsValid(client) ) then return end

    if ( has ) then
        client:Give("weapon_physgun")
    else
        local wep = client:GetActiveWeapon()
        if ( IsValid(wep) and wep:GetClass() == "weapon_physgun" ) then
            client:SelectWeapon("ax_hands")
        end

        client:StripWeapon("weapon_physgun")
    end
end)