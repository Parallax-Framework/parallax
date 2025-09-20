ax.flag:Create("p", {
    OnTaken = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and client:HasWeapon("weapon_physgun")  ) then
            client:StripWeapon("weapon_physgun")
            client:Notify("You have lost your permission to use the physgun.")
        end
    end,
    OnGiven = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and !client:HasWeapon("weapon_physgun")  ) then
            client:Give("weapon_physgun")
            client:Notify("You have been granted permission to use the physgun.")
        end
    end
})

ax.flag:Create("t", {
    OnTaken = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and client:HasWeapon("gmod_tool") ) then
            client:StripWeapon("gmod_tool")
            client:Notify("You have lost your permission to use the toolgun.")
        end
    end,
    OnGiven = function(this, character)
        local client = character:GetOwner()
        if ( IsValid(client) and !client:HasWeapon("gmod_tool") ) then
            client:Give("gmod_tool")
            client:Notify("You have been granted permission to use the toolgun.")
        end
    end
})
