local MODULE = MODULE

MODULE.Name = "Movement"
MODULE.Description = "Restricts player movement to a specific set of rules."
MODULE.Author = "Riggs"

-- Anti-Bunnyhop
function GM:OnPlayerHitGround(client, inWater)
    local vel = client:GetVelocity()
    client:SetVelocity(Vector(-(vel.x / 2), - (vel.y / 2), 0))
end