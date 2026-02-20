--[[
    Parallax Framework
    Copyright (c) 2025-2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    self:Dock(FILL)
    self:InvalidateParent(true)
end

function PANEL:Paint(width, height)
end

vgui.Register("ax.tab.help", PANEL, "ax.transition.pages")

-- Clean up existing hook to prevent duplicates on reload
hook.Remove("PopulateTabButtons", "ax.tab.help")

hook.Add("PopulateTabButtons", "ax.tab.help", function(buttons)
    buttons["help"] = {
        Populate = function(this, panel)
            panel:Add("ax.tab.help")
        end,
        Sections = {} -- populated by "PopulateHelpCategories" hook
    }

    local categories = {}
    hook.Run("PopulateHelpCategories", categories)

    for k, v in SortedPairsByMemberValue(categories, "name") do
        buttons["help"].Sections[k] = v
    end
end)

hook.Add("PopulateHelpCategories", "ax.tab.help", function(categories)
    categories["modules"] = {
        Populate = function(this, panel)
            local scroller = panel:Add("ax.scroller.vertical")
            scroller:Dock(FILL)

            local frameworkModules = {}
            local schemaModules = {}

            -- TODO: separate framework and schema modules properly

            for k, v in SortedPairsByMemberValue(ax.module.stored, "name") do
                if ( v.scope == "framework" ) then
                    frameworkModules[k] = v
                else
                    schemaModules[k] = v
                end
            end

            local frameworkLabel = scroller:Add("ax.text")
            frameworkLabel:Dock(TOP)
            frameworkLabel:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(4))
            frameworkLabel:SetFont("ax.huge.bold.italic")
            frameworkLabel:SetText("Framework")

            local function addModule(module)
                local label = scroller:Add("ax.text")
                label:Dock(TOP)
                label:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(4))
                label:SetFont("ax.large.bold.italic")
                label:SetText(module.name or module.uniqueID)

                local description = module.description or "No description available."
                local descriptionWrapped = ax.util:GetWrappedText(description, "ax.regular", panel:GetWide() - ax.util:ScreenScale(64))
                for _, line in ipairs(descriptionWrapped) do
                    local desc = scroller:Add("ax.text")
                    desc:Dock(TOP)
                    desc:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(4))
                    desc:SetText(line)
                end

                local author = scroller:Add("ax.text")
                author:Dock(TOP)
                author:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(4))
                author:SetText("Author: " .. (module.author or "Unknown"))

                local padding = scroller:Add("EditablePanel")
                padding:Dock(TOP)
                padding:SetTall(ax.util:ScreenScaleH(8))
            end

            for k, v in SortedPairsByMemberValue(frameworkModules, "name") do
                addModule(v)
            end

            local schemaLabel = scroller:Add("ax.text")
            schemaLabel:Dock(TOP)
            schemaLabel:DockMargin(0, 0, 0, -ax.util:ScreenScaleH(4))
            schemaLabel:SetFont("ax.huge.bold.italic")
            schemaLabel:SetText("Schema")

            for k, v in SortedPairsByMemberValue(schemaModules, "name") do
                addModule(v)
            end
        end
    }
end)
