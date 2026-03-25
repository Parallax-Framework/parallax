--[[
    Parallax Framework
    Copyright (c) 2026 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

ax.net:Hook("container.password.prompt", function(entity)
	if ( !IsValid(entity) or entity:GetClass() != "ax_container" ) then
		return
	end

	Derma_StringRequest(ax.localization:GetPhrase("container.password.title"), ax.localization:GetPhrase("container.password.prompt"), "", function(text)
		ax.net:Start("container.password.submit", entity, string.Trim(text or ""))
	end)
end)

ax.net:Hook("container.open", function(entity, inventoryID, displayName, searchTime, money, maxWeight)
	if ( IsValid(ax.container.panel) ) then
		ax.container.panel:Remove()
	end

	local panel = vgui.Create("ax.container.storage")
	panel:SetContainer(entity, inventoryID, displayName, searchTime, money, maxWeight)

	ax.container.panel = panel
end)
