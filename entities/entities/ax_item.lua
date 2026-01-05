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

    function ENT:Use(activator, caller)
        if ( !IsValid(activator) or !activator:IsPlayer() ) then return end

        -- Prevent multiple rapid Use calls on the same entity from creating
        -- concurrent async transfers.
        if ( self:GetTable().axPickupInProgress ) then return end

        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        local character = activator:GetCharacter()
        if ( !istable(character) ) then return end

        local inventory = character:GetInventory()
        if ( !istable(inventory) ) then return end

        self:GetTable().axPickupInProgress = true

        local transferOk, transferReason = ax.item:Transfer(item, 0, inventory, function(didTransfer)
            if ( didTransfer ) then
                ax.util:PrintDebug(color_success, string.format(
                    "Player %s picked up item %s from world inventory to inventory %s.",
                    tostring(activator),
                    tostring(item.id),
                    tostring(inventory.id)
                ))

                -- Mark before running hooks so OnRemove doesn't delete records
                -- if the entity is removed during any hook logic.
                if ( IsValid(self) ) then
                    self:GetTable().axBeingPickedUp = true
                end

                -- Entity may have been removed while waiting on DB callback.
                if ( IsValid(self) ) then
                    hook.Run("OnPlayerItemPickup", activator, self, item)
                    SafeRemoveEntity(self)
                else
                    hook.Run("OnPlayerItemPickup", activator, nil, item)
                end
            else
                ax.util:PrintWarning(string.format(
                    "Player %s failed to pick up item %s from world inventory to inventory %s, due to %s.",
                    tostring(activator),
                    tostring(item.id),
                    tostring(inventory.id),
                    tostring(reason or "Unknown Reason")
                ))

                if ( IsValid(self) ) then
                    self:GetTable().axPickupInProgress = nil
                end
            end
        end)

        if ( transferOk == false ) then
            self:GetTable().axPickupInProgress = nil
            activator:Notify(transferReason or "You cannot pick up this item.")
        end
    end

    function ENT:OnRemove()
        if ( self:GetTable().axBeingPickedUp or self:GetTable().axPickupInProgress ) then return end

        local id = self:GetItemID()
        local item = ax.item.instances[id]
        if ( !istable(item) ) then return end

        local query = mysql:Delete("ax_items")
            query:Where("id", id)
        query:Execute()
    end
end
