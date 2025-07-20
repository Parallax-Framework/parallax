ITEM.Name = "Oil Drum"
ITEM.Description = "A large oil drum used for storing and transporting oil."
ITEM.Model = Model("models/props_c17/oildrum001.mdl")
ITEM.Category = "Supplies"
ITEM.Weight = 5
ITEM.Price = 100

ITEM.ShouldStack = true -- Allows this item to stack with others of the same type
ITEM.MaxStack = 10 -- Maximum number of items that can be stacked

ITEM.Camera = {
    pos = Vector(0, 0, 50), -- Position of the camera relative to the item
    ang = Angle(0, 0, 0), -- Angle of the camera
    fov = 70 -- Field of view for the camera
}

ITEM:AddAction({
    Name = "Use",
    Description = "Use this item.",
    Icon = "icon16/accept.png",
    OnUse = function(item, client)
        client:ChatPrint("You have used the item: " .. item.Name)
        return false -- Returning false prevents the item from being removed after use
    end,
    CanUse = function(item, client)
        return true -- Allow the item to be used
    end
})