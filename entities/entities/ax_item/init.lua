-- entities/entities/ax_item/init.lua
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/watermelon01.mdl")
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    self:PhysWake()
end

function ENT:SetItem(itemID, uniqueID)
    local itemDef = ax.item:Get(uniqueID)
    if ( !istable(itemDef) ) then
        ax.util:PrintError("Attempted to set item with an invalid item definition for entity " .. self:EntIndex() .. "!")
        return
    end

    self:SetModel(Model(itemDef.Model))
    self:SetSkin(isfunction(itemDef.GetSkin) and itemDef:GetSkin(self) or (itemDef.Skin or 0))
    self:SetColor(isfunction(itemDef.GetColor) and itemDef:GetColor(self) or (itemDef.Color or ax.color:Get("white")))
    self:SetMaterial(isfunction(itemDef.GetMaterial) and itemDef:GetMaterial(self) or (itemDef.Material or ""))
    self:SetModelScale(isfunction(itemDef.GetScale) and itemDef:GetScale(self) or (itemDef.Scale or 1))
    self:SetHealth(itemDef.Health or 25)

    -- Reinitialize physics due to model change
    self:PhysicsInit(SOLID_VPHYSICS)
    self:PhysWake()

    if ( itemDef.Bodygroups ) then
        for k, v in pairs(itemDef.Bodygroups) do
            local idx = isstring(k) and self:GetBodygroupByName(k) or k
            if ( idx ) then self:SetBodygroup(idx, v) end
        end
    end

    if ( itemDef.SubMaterials ) then
        for k, v in pairs(itemDef.SubMaterials) do
            self:SetSubMaterial(k - 1, v)
        end
    end

    if ( itemDef.OnSpawned ) then
        itemDef:OnSpawned(self)
    end

    self:SetUniqueID(uniqueID)

    if ( !itemID or itemID == 0 ) then
        -- Register world item instance
        ax.item:Add(0, 0, uniqueID, {}, function(newID)
            self:SetItemID(newID)
            local item = ax.item:Get(newID)
            if ( item ) then
                item:SetEntity(self)
                self:SetData(item:GetData() or {})

                -- Notify clients
                ax.net:Start(nil, "item.entity", self, newID)
            end
        end)
    else
        self:SetItemID(itemID)
        local item = ax.item:Get(itemID)
        if ( item ) then
            item:SetEntity(self)
            self:SetData(item:GetData() or {})
        end

        ax.net:Start(nil, "item.entity", self, newID)
    end

    local item = ax.item:Get(itemID)
    if ( item ) then
        item:SetEntity(self)
        self:SetData(item:GetData() or {})
    else
        self:SetData({})
    end

    ax.net:Start(nil, "item.entity", self, newID)
end

function ENT:GetData()
    return self:GetDataVariable("ItemData", {})
end

function ENT:SetData(data)
    self:SetDataVariable("ItemData", data)
end

function ENT:Use(client)
    if ( !IsValid(client) or !client:IsPlayer() ) then return end
    if ( hook.Run("CanPlayerTakeItem", client, self) == false ) then return end

    local itemDef = ax.item:Get(self:GetUniqueID())
    local itemInst = ax.item:Get(self:GetItemID())

    if ( !itemDef or !itemInst ) then return end

    itemInst:SetEntity(self)
    itemInst:SetOwner(client:GetCharacterID())

    self.axPickingUp = CurTime() + 1
    ax.item:PerformAction(itemInst:GetID(), "Take")
end

function ENT:OnRemove()
    local item = ax.item:Get(self:GetItemID())
    if ( item and item.OnRemoved ) then
        item:OnRemoved(self)
    end
end

function ENT:OnTakeDamage(dmg)
    local item = ax.item:Get(self:GetItemID())
    if ( !item ) then return end

    self:SetHealth(self:Health() - dmg:GetDamage())

    if ( self:Health() <= 0 and hook.Run("ItemCanBeDestroyed", self, dmg) != false ) then
        self:EmitSound("physics/cardboard/cardboard_box_break" .. math.random(1, 3) .. ".wav")

        local position = self:LocalToWorld(self:OBBCenter())
        local effect = EffectData()
        effect:SetStart(position)
        effect:SetOrigin(position)
        effect:SetScale(3)
        util.Effect("GlassImpact", effect)

        local itemDef = ax.item:Get(self:GetUniqueID())
        if ( itemDef and itemDef.OnDestroyed ) then
            itemDef:OnDestroyed(self)
        end

        SafeRemoveEntity(self)
    end
end

function ENT:OnRemove()
    if ( self.axPickingUp and self.axPickingUp > CurTime() ) then return end
    if ( ax.shutDown ) then return end

    local item = ax.item:Get(self:GetItemID())
    if ( item and item.OnRemoved ) then
        item:OnRemoved(self)
    end

    ax.database:Delete("ax_items", string.format("id = %s", sql.SQLStr(self:GetItemID())))
end