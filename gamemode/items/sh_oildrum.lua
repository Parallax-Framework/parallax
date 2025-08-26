ITEM.name = "Oil Drum"
ITEM.description = "A large oil drum used for storing and transporting oil."
ITEM.model = Model("models/props_c17/oildrum001.mdl")
ITEM.category = "Supplies"
ITEM.weight = 5
ITEM.price = 100

ITEM.shouldStack = true -- Allows this item to stack with others of the same type
ITEM.maxStack = 10 -- Maximum number of items that can be stacked

ITEM.camera = {
    pos = Vector(0, 0, 50), -- Position of the camera relative to the item
    ang = Angle(0, 0, 0), -- Angle of the camera
    fov = 70 -- Field of view for the camera
}

ITEM:AddAction({
    name = "Use",
    description = "Use this item.",
    icon = "icon16/accept.png",
    OnUse = function(item, client)
        client:ChatPrint("You have used the item: " .. item.name)
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(item, client)
        return true -- Allow the item to be used
    end
})