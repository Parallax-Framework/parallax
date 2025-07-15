local MODULE = MODULE

function MODULE:PlayerDeath(client)
    net.Start("ax.weaponselect.deathclose")
    net.Send(client)
end