local PANEL = {}

--[[
net.Start("ax.character.load")
    net.WriteUInt(1, 32)
net.SendToServer()
]]

function PANEL:Init()
    local parent = self:GetParent()

    self:SetPos(0, 0)
    self:SetSize(ScrW(), ScrH())

    self:CreateNavigation(self, "back", function()
        self:SlideDown()
        parent.splash:SlideToFront()
    end)

    local characterList = self:Add("ax.scroller.vertical")
    characterList:Dock(FILL)
    characterList:DockMargin(ScreenScale(128), ScreenScaleH(32), ScreenScale(128), ScreenScaleH(32))
    characterList:InvalidateParent(true)
    characterList:GetVBar():SetWide(0)
    characterList.Paint = nil

    local clientTable = ax.client:GetTable()
    local characters = clientTable.axCharacters or {}

    if ( #characters == 0 ) then
        local label = characterList:Add("ax.text")
        label:Dock(TOP)
        label:SetFont("ax.huge.bold")
        label:SetText("No characters found.")
        label:SetContentAlignment(5)

        local createButton = characterList:Add("ax.button.flat")
        createButton:Dock(TOP)
        createButton:SetText("create")
        createButton.DoClick = function()
            self:SlideDown()
            parent.create:SlideToFront()
        end

        return
    end

    for k, v in pairs(characters) do
        local button = characterList:Add("ax.button.flat")
        button:Dock(TOP)
        button:DockMargin(0, 0, 0, ScreenScaleH(4))
        button:SetText("", true, true, true)
        button:SetTall(characterList:GetWide() / 8)

        button.DoClick = function()
            net.Start("ax.character.load")
                net.WriteUInt(v.id, 32)
            net.SendToServer()
        end

        local banner = hook.Run("GetCharacterBanner", v.id) or "gamepadui/hl2/chapter14"
        if ( type(banner) == "string" ) then
            banner = ax.util:GetMaterial(banner)
        end

        local image = button:Add("DPanel")
        image:Dock(LEFT)
        image:DockMargin(0, 0, ScreenScale(8), 0)
        image:SetSize(button:GetTall() * 1.75, button:GetTall())
        image.Paint = function(this, width, height)
            surface.SetDrawColor(ax.color:Get("white"))
            surface.SetMaterial(banner)
            surface.DrawTexturedRect(0, 0, width, height)
        end

        -- local deleteButton = button:Add("ax.button.flat")
        -- deleteButton:Dock(RIGHT)
        -- deleteButton:DockMargin(ScreenScale(8), 0, 0, 0)
        -- deleteButton:SetText("X")
        -- deleteButton:SetTextColorProperty(ax.config:Get("color.error"))
        -- deleteButton:SetSize(0, button:GetTall())
        -- deleteButton:SetContentAlignment(5)
        -- deleteButton.baseTextColorTarget = ax.color:Get("black")
        -- deleteButton.backgroundColor = ax.config:Get("color.error")
        -- deleteButton.width = 0
        -- deleteButton.DoClick = function()
        --     self:PopulateDelete(v.id)
        -- end

        -- Sorry for this pyramid of code, but eon wanted me to make the delete button extend when hovered over the character button.
        -- local isDeleteButtonExtended = false
        -- button.OnThink = function()
        --     if ( button:IsHovered() or deleteButton:IsHovered() ) then
        --         if ( !isDeleteButtonExtended ) then
        --             isDeleteButtonExtended = true
        --             deleteButton:Motion(0.2, {
        --                 Target = {width = button:GetTall()},
        --                 Easing = "OutQuad",
        --                 Think = function(this)
        --                     deleteButton:SetWide(this.width)
        --                 end
        --             })
        --         end
        --     else
        --         if ( isDeleteButtonExtended ) then
        --             isDeleteButtonExtended = false
        --             deleteButton:Motion(0.2, {
        --                 Target = {width = 0},
        --                 Easing = "OutQuad",
        --                 Think = function(this)
        --                     deleteButton:SetWide(this.width)
        --                 end
        --             })
        --         end
        --     end
        -- end

        local name = button:Add("ax.text")
        name:Dock(TOP)
        name:SetFont("ax.huge.bold")
        name:SetText(v:GetName():upper())
        name.Think = function(this)
            this:SetTextColor(button:GetTextColor())
        end

        -- local lastPlayed = button:Add("ax.text")
        -- lastPlayed:Dock(BOTTOM)
        -- lastPlayed:DockMargin(0, 0, 0, ScreenScaleH(8))
        -- lastPlayed:SetFont("ax.large")
        -- lastPlayed:SetText(os.date("%a %b %d %H:%M:%S %Y", v:GetLastPlayed()), true)
        -- lastPlayed.Think = function(this)
        --     this:SetTextColor(button:GetTextColor())
        -- end
    end
end

vgui.Register("ax.main.load", PANEL, "ax.transition")