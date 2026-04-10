--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

	Unironically, Bitwise Operators. For GLua. Done in GLua.

	Rules:
		* Order of operations is subsequent and linear.
		  These constructions are functions, calls, arguments, and returns.

		* Numbers and «incoming» numbers has to be bracketed: (2048); (2) '|' (...)
			* The exception is: comes first and it's a variable: numericalvar '|' (...)

		* '~' has to be bracketed and made into a direct call: ('~')(..)
			* Note that this construction resolves into just a single number.

	https://github.com/noaccessl/glua-collectibles/bitwiseoperators.lua

–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]



--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Functions
--
local band = bit.band
local bor = bit.bor
local bxor = bit.bxor
local bnot = bit.bnot
local lshift = bit.lshift
local rshift = bit.rshift

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Intermediary variable
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local g_number = 0

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	operation_and;
	operation_or;
	operation_xor;
	operation_lshift;
	operation_rshift
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local function operation_and( ... )

	return band( g_number, ... )

end

local function operation_or( ... )

	return bor( g_number, ... )

end

local function operation_xor( num )

	return bxor( g_number, num )

end

local function operation_lshift( bits )

	return lshift( g_number, bits )

end

local function operation_rshift( bits )

	return rshift( g_number, bits )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	CLuaNumber
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local CLuaNumber = FindMetaTable( 'LuaNumber' ) or {}
do

	-- Register the metatable
	RegisterMetaTable( 'LuaNumber', CLuaNumber )

	--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
		__call
	–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
	-- Operator–Operation Lookup Table
	local OperatorOperation = {

		['&'] = operation_and;
		['|'] = operation_or;
		['^'] = operation_xor;
		['<<'] = operation_lshift;
		['>>'] = operation_rshift

	}

	function CLuaNumber:__call( operator )

		-- Save this number
		g_number = self

		-- Return the right operation
		return OperatorOperation[operator]

	end

	--
	-- Fallback scheme
	--
	setmetatable( OperatorOperation, {

		__index = function() assert( false, "unknown operator" ) end

	} )

	-- Set this metatable for all numbers in the runtime
	debug.setmetatable( g_number, CLuaNumber )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Also support for the NOT operation.
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
do

	local pStringMetaTable = getmetatable( "" )

	function pStringMetaTable:__call( number )

		if ( ( self == '~' ) and ( tonumber( number ) ~= nil ) ) then
			return bnot( number )
		end

	end

	--[[ Note
		Why `tonumber( number ) ~= nil` and not `isnumber( number )` is
		because the former should perform generally faster.
		tonumber is JIT-compiled.
	]]

end

--[[ Example

	--
	-- ( MASK_SOLID | CONTENTS_HITBOX ) & ~CONTENTS_GRATE
	--
	print( bit.band( bit.bor( MASK_SOLID, CONTENTS_HITBOX ), bit.bnot( CONTENTS_GRATE ) ) )

	print( ( (MASK_SOLID) '|' (CONTENTS_HITBOX) ) '&' (('~')(CONTENTS_GRATE)) )

	--
	-- Test
	--
	local flags = (1) '|' (2) '|' (4) '|' (8) '|' (16) '|' (32) '|' (64)

	-- However, this would be faster.
	flags = (1) '|' (2, 4, 8, 16, 32, 64)

	if ( flags '&' (1) ~= 0 ) then
		print( "1's in place." )
	end

	if ( flags '&' (64) ~= 0 ) then
		print( "64's in place." )
	end

	if ( flags '&' ((2) '|' (16)) ~= 0 ) then
		print( "2 and 16 are in place." )
	end

	if ( flags '&' (512) == 0 ) then
		print( "there's no 512 in." )
	end

]]

--[[ Output

	1107312643
	1107312643
	1's in place.
	64's in place.
	2 and 16 are in place.
	there's no 512 in.

]]
