--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Persistence"
MODULE.Description = "Saves and restores specific entity classes across map resets with custom data support."
MODULE.Author = "Riggs"

MODULE.PersistentEntities = {}
MODULE.PersistentEntities["ax_currency"] = {
    Save = function(ent)
        return {
            amount = ent:GetAmount()
        }
    end,
    Load = function(ent, data)
        ent:SetAmount(data.amount)
    end
}

MODULE.PersistentEntities["ax_item"] = {
    Save = function(ent)
        return {
            uniqueID = ent:GetUniqueID(),
            itemID = ent:GetItemID(),
            extra = ent:GetData()
        }
    end,
    Load = function(ent, data)
        ent:SetItem(data.itemID, data.uniqueID)
        ent:SetData(data.extra)
    end
}