function ents.FindInCube( center, radius )
	if ( !isvector( center ) ) then
		return error( "Invalid argument: 'center' must be a Vector" )
	end

	if ( !isnumber( radius ) or radius <= 0 ) then
		return error( "Invalid argument: 'radius' must be a positive number" )
	end

	local rvec = Vector( radius, radius, radius )
	return ents.FindInBox( center - rvec, center + rvec )
end