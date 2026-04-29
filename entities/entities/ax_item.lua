AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Parallax Item"
ENT.Author = "Parallax Team"
ENT.Category = "Parallax"
ENT.Spawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "ItemID")
    self:NetworkVar("String", 0, "ItemClass")
end

function ENT:GetItemTable()
    return ax.item.instances[self:GetItemID()]
end

if ( SERVER ) then
    function ENT:UpdateTransmitState()
        return TRANSMIT_ALWAYS
    end

    function ENT:Initialize()
        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        self:SetModel(item:GetModel() or Model("models/props_junk/gnome.mdl"))
        item:ApplyAppearance(self)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end

    function ENT:Use(activator, caller)
        if ( !ax.util:IsValidPlayer(activator) ) then return end

        local entTable = self:GetTable()
        if ( entTable.axTakeInProgress or entTable.axPickupPending ) then return end

        local trace = util.TraceLine({
            start = activator:GetShootPos(),
            endpos = activator:GetShootPos() + activator:GetAimVector() * 96,
            filter = activator
        })

        if ( trace.Entity != self ) then return end

        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        local ent = self
        entTable.axPickupPending = true

        local function cancelPickup()
            entTable.axPickupPending = nil
            activator:RemoveTimer("ax.item.pickup.monitor")
        end

        activator:PerformAction("Picking up...", 1, function()
            cancelPickup()

            ax.item:RunAction(activator, item, "take", {
                entity = ent,
                caller = caller,
                source = "entity_use"
            })
        end, cancelPickup)

        activator:Timer("ax.item.pickup.monitor", 0.1, 0, function(client)
            if ( !client:KeyDown(IN_USE) ) then
                client:PerformAction()
            end

            local trace = util.TraceLine({
                start = client:GetShootPos(),
                endpos = client:GetShootPos() + client:GetAimVector() * 96,
                filter = client
            })

            if ( trace.Entity != ent ) then
                client:PerformAction()
            end
        end)
    end

    function ENT:OnRemove()
        if ( self:GetTable().axTakeInProgress ) then return end

        local id = self:GetItemID()
        local item = ax.item.instances[id]
        if ( !istable(item) ) then return end

        local query = mysql:Delete("ax_items")
            query:Where("id", id)
        query:Execute()
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_PVS
end
