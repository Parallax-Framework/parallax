local MODULE = MODULE

MODULE.Name = "Movement"
MODULE.Description = "Restricts player movement to a specific set of rules."
MODULE.Author = "Riggs"

function MODULE:OnPlayerHitGround(client, inWater)
    local bunnyhopVelocityMultiplier = ax.config:Get("movementBunnyhopReduction", 0.5)
    local velocity = client:GetVelocity()
    local horizontalVelocity = Vector(velocity.x, velocity.y, 0)
    local reducedVelocity = -horizontalVelocity * bunnyhopVelocityMultiplier
    client:SetVelocity(reducedVelocity)
end
