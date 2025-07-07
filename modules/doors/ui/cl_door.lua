local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 4, ScrH() / 1.5)
    self:SetTitle("Door Options")
    self:Center()
    self:MakePopup()

    self:SetDraggable(true)
    self:SetScreenLock(true)
    self:SetBackgroundBlur(true)

    self.door = nil
end

function PANEL:Populate(door)
    self.door = door

    local owner = door:GetRelay("owner")
    local price = door:GetRelay("price") or ax.config:Get("door.price", 5)
    local locked = door:GetRelay("locked", false)
    local mode = door:GetRelay("mode", "player")

    if ( owner == ax.client:EntIndex() ) then
        self.lock = self:Add("ax.button.flat")
        self.lock:Dock(TOP)
        self.lock:SetText(locked and "Unlock Door" or "Lock Door")
        self.lock.DoClick = function()
            if ( IsValid(self.door) ) then
                net.Start("ax.doors.lock")
                    net.WriteEntity(self.door)
                    net.WriteBool(!locked)
                net.SendToServer()

                self:Close()
            end
        end

        self.sell = self:Add("ax.button.flat")
        self.sell:Dock(TOP)
        self.sell:SetText("Sell Door")
        self.sell.DoClick = function()
            if ( IsValid(self.door) ) then
                net.Start("ax.doors.sell")
                    net.WriteEntity(self.door)
                net.SendToServer()

                self:Close()
            end
        end
    end
end

vgui.Register("ax.door", PANEL, "ax.frame")