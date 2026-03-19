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

        if ( self:GetTable().axTakeInProgress ) then return end

        local item = self:GetItemTable()
        if ( !istable(item) ) then return end

        ax.item:RunAction(activator, item, "take", {
            entity = self,
            caller = caller,
            source = "entity_use"
        })
    end

    function ENT:OnRemove()
        if ( self:GetTable().axBeingPickedUp or self:GetTable().axTakeInProgress ) then return end

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
