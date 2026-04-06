local MODULE = MODULE

function MODULE:PostPlayerLoadout(client)
	client:Give("ax_keys")
end
