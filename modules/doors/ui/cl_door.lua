--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 6, ScrH() / 2)
    self:SetTitle("Door Options")
    self:Center()
    self:MakePopup()

    self:SetDraggable(true)
    self:SetScreenLock(true)
    self:SetBackgroundBlur(true)

    self.door = nil
    self.isAdmin = false
end

function PANEL:Populate(door, isAdmin)
    self.door = door
    self.isAdmin = isAdmin or false

    local owner = door:GetRelay("owner", 0)
    local ownerEnt = Entity(owner)
    local price = door:GetRelay("price") or ax.config:Get("door.price", 5)
    local locked = door:GetRelay("locked", false)
    local isOwnable = !door:GetRelay("unownable", false)

    -- Check default config for ownable status
    if ( ax.config:Get("door.defaultUnownable", false) and isOwnable ) then
        isOwnable = false
    end

    -- Admin controls
    if ( self.isAdmin ) then
        if ( isOwnable ) then
            self.setUnownable = self:Add("ax.button.flat")
            self.setUnownable:Dock(TOP)
            self.setUnownable:SetText("Set as Unownable")
            self.setUnownable:SetTextColorProperty(Color(255, 100, 100))
            self.setUnownable.DoClick = function()
                if ( IsValid(self.door) ) then
                    Derma_Query(
                        "Are you sure you want to set this door as unownable?",
                        "Confirm Action",
                        "Yes",
                        function()
                            net.Start("ax.doors.setunownable")
                                net.WriteEntity(self.door)
                            net.SendToServer()
                            self:Close()
                        end,
                        "No"
                    )
                end
            end
        else
            self.setOwnable = self:Add("ax.button.flat")
            self.setOwnable:Dock(TOP)
            self.setOwnable:SetText("Set as Ownable")
            self.setOwnable:SetTextColorProperty(Color(100, 255, 100))
            self.setOwnable.DoClick = function()
                if ( IsValid(self.door) ) then
                    Derma_Query(
                        "Are you sure you want to set this door as ownable?",
                        "Confirm Action",
                        "Yes",
                        function()
                            net.Start("ax.doors.setownable")
                                net.WriteEntity(self.door)
                            net.SendToServer()
                            self:Close()
                        end,
                        "No"
                    )
                end
            end
        end
    end

    -- Owner controls
    if ( IsValid(ownerEnt) and ownerEnt == ax.client ) then
        self.lock = self:Add("ax.button.flat")
        self.lock:Dock(TOP)
        self.lock:SetText(locked and "Unlock Door" or "Lock Door")
        self.lock.DoClick = function()
            if ( IsValid(self.door) ) then
                local action = locked and "unlock" or "lock"
                Derma_Query(
                    "Are you sure you want to " .. action .. " this door?",
                    "Confirm Action",
                    "Yes",
                    function()
                        net.Start("ax.doors.lock")
                            net.WriteEntity(self.door)
                        net.SendToServer()
                        self:Close()
                    end,
                    "No"
                )
            end
        end

        self.sell = self:Add("ax.button.flat")
        self.sell:Dock(TOP)
        self.sell:SetText("Sell Door")
        self.sell.DoClick = function()
            if ( IsValid(self.door) ) then
                Derma_Query(
                    "Are you sure you want to sell this door?",
                    "Confirm Sale",
                    "Yes",
                    function()
                        net.Start("ax.doors.sell")
                            net.WriteEntity(self.door)
                        net.SendToServer()
                        self:Close()
                    end,
                    "No"
                )
            end
        end
    else
        self.buy = self:Add("ax.button.flat")
        self.buy:Dock(TOP)
        self.buy:SetText("Buy Door - $" .. price)
        self.buy.DoClick = function()
            if ( IsValid(self.door) ) then
                Derma_Query(
                    "Are you sure you want to buy this door for $" .. price .. "?",
                    "Confirm Purchase",
                    "Yes",
                    function()
                        net.Start("ax.doors.buy")
                            net.WriteEntity(self.door)
                        net.SendToServer()
                        self:Close()
                    end,
                    "No"
                )
            end
        end
    end
end

vgui.Register("ax.door", PANEL, "ax.frame")