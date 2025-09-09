AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Parallax Item"
ENT.Author = "Parallax Team"
ENT.Category = "Parallax"

if SERVER then
    function ENT:Initialize()
        self:SetModel(Model("models/props_junk/gnome.mdl"))
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:PhysWake()
    end

    function ENT:UpdateTransmitState()
        return TRANSMIT_PVS
    end
end
