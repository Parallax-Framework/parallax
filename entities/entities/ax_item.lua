AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Parallax Item"
ENT.Author = "Parallax Team"
ENT.Category = "Parallax"

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ItemID")
    self:NetworkVar("String", 0, "ItemClass")
end

function ENT:GetItemTable()
    return ax.item.instances[self:GetItemID()]
end

if ( SERVER ) then
    function ENT:Initialize()
        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        self:SetModel(item:GetModel() or Model("models/props_junk/gnome.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end

    function ENT:Use(activator, caller)
        if ( !IsValid(activator) or !activator:IsPlayer() ) then return end

        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        local character = activator:GetCharacter()
        if ( !istable(character) ) then return end

        local inventory = character:GetInventory()
        if ( !istable(inventory) ) then return end

        if ( inventory:GetWeight() + item:GetWeight() <= inventory:GetMaxWeight() ) then
            local success, reason = ax.item:Transfer(item, 0, inventory, function(success)
                if ( success ) then
                    ax.util:PrintDebug(color_success, string.format(
                        "Player %s picked up item %s from world inventory to inventory %s.",
                        tostring(activator),
                        tostring(item.id),
                        tostring(inventory.id)
                    ))

                    hook.Run("OnPlayerItemPickup", activator, self, item)

                    SafeRemoveEntity(self)
                else
                    ax.util:PrintWarning(string.format(
                        "Player %s failed to pick up item %s from world inventory to inventory %s, due to %s.",
                        tostring(activator),
                        tostring(item.id),
                        tostring(inventory.id),
                        tostring(reason or "Unknown Reason")
                    ))
                end
            end)

            if ( success == false ) then
                activator:Notify(string.format("Failed to pick up item: %s", reason or "Unknown Reason"))
            end
        else
            activator:Notify("You cannot carry any more of this item!")
        end
    end
end