ax.bind = ax.bind or {}
ax.bind.stored = ax.bind.stored or {}
ax.bind.activeButtons = 0

ax.bind.translations = {
    [KEY_NONE] = "NONE",
    [KEY_0] = "0",
    [KEY_1] = "1",
    [KEY_2] = "2",
    [KEY_3] = "3",
    [KEY_4] = "4",
    [KEY_5] = "5",
    [KEY_6] = "6",
    [KEY_7] = "7",
    [KEY_8] = "8",
    [KEY_9] = "9",
    [KEY_A] = "A",
    [KEY_B] = "B",
    [KEY_C] = "C",
    [KEY_D] = "D",
    [KEY_E] = "E",
    [KEY_F] = "F",
    [KEY_G] = "G",
    [KEY_H] = "H",
    [KEY_I] = "I",
    [KEY_J] = "J",
    [KEY_K] = "K",
    [KEY_L] = "L",
    [KEY_M] = "M",
    [KEY_N] = "N",
    [KEY_O] = "O",
    [KEY_P] = "P",
    [KEY_Q] = "Q",
    [KEY_R] = "R",
    [KEY_S] = "S",
    [KEY_T] = "T",
    [KEY_U] = "U",
    [KEY_V] = "V",
    [KEY_W] = "W",
    [KEY_X] = "X",
    [KEY_Y] = "Y",
    [KEY_Z] = "Z",
    [KEY_PAD_0] = "PAD_0",
    [KEY_PAD_1] = "PAD_1",
    [KEY_PAD_2] = "PAD_2",
    [KEY_PAD_3] = "PAD_3",
    [KEY_PAD_4] = "PAD_4",
    [KEY_PAD_5] = "PAD_5",
    [KEY_PAD_6] = "PAD_6",
    [KEY_PAD_7] = "PAD_7",
    [KEY_PAD_8] = "PAD_8",
    [KEY_PAD_9] = "PAD_9",
    [KEY_PAD_DIVIDE] = "PAD_DIVIDE",
    [KEY_PAD_MULTIPLY] = "PAD_MULTIPLY",
    [KEY_PAD_MINUS] = "PAD_MINUS",
    [KEY_PAD_PLUS] = "PAD_PLUS",
    [KEY_PAD_ENTER] = "PAD_ENTER",
    [KEY_PAD_DECIMAL] = "PAD_DECIMAL",
    [KEY_LBRACKET] = "LBRACKET",
    [KEY_RBRACKET] = "RBRACKET",
    [KEY_SEMICOLON] = "SEMICOLON",
    [KEY_APOSTROPHE] = "APOSTROPHE",
    [KEY_BACKQUOTE] = "BACKQUOTE",
    [KEY_COMMA] = "COMMA",
    [KEY_PERIOD] = "PERIOD",
    [KEY_SLASH] = "SLASH",
    [KEY_BACKSLASH] = "BACKSLASH",
    [KEY_MINUS] = "MINUS",
    [KEY_EQUAL] = "EQUAL",
    [KEY_ENTER] = "ENTER",
    [KEY_SPACE] = "SPACE",
    [KEY_BACKSPACE] = "BACKSPACE",
    [KEY_TAB] = "TAB",
    [KEY_CAPSLOCK] = "CAPSLOCK",
    [KEY_NUMLOCK] = "NUMLOCK",
    [KEY_ESCAPE] = "ESCAPE",
    [KEY_SCROLLLOCK] = "SCROLLLOCK",
    [KEY_INSERT] = "INSERT",
    [KEY_DELETE] = "DELETE",
    [KEY_HOME] = "HOME",
    [KEY_END] = "END",
    [KEY_PAGEUP] = "PAGEUP",
    [KEY_PAGEDOWN] = "PAGEDOWN",
    [KEY_BREAK] = "BREAK",
    [KEY_LSHIFT] = "LSHIFT",
    [KEY_RSHIFT] = "RSHIFT",
    [KEY_LALT] = "LALT",
    [KEY_RALT] = "RALT",
    [KEY_LCONTROL] = "LCTRL",
    [KEY_RCONTROL] = "RCTRL",
    [KEY_LWIN] = "LWIN",
    [KEY_RWIN] = "RWIN",
    [KEY_APP] = "APP",
    [KEY_UP] = "UP",
    [KEY_LEFT] = "LEFT",
    [KEY_DOWN] = "DOWN",
    [KEY_RIGHT] = "RIGHT",
    [KEY_F1] = "F1",
    [KEY_F2] = "F2",
    [KEY_F3] = "F3",
    [KEY_F4] = "F4",
    [KEY_F5] = "F5",
    [KEY_F6] = "F6",
    [KEY_F7] = "F7",
    [KEY_F8] = "F8",
    [KEY_F9] = "F9",
    [KEY_F10] = "F10",
    [KEY_F11] = "F11",
    [KEY_F12] = "F12",
    [KEY_CAPSLOCKTOGGLE] = "CAPSLOCKTOGGLE",
    [KEY_NUMLOCKTOGGLE] = "NUMLOCKTOGGLE",
    [KEY_SCROLLLOCKTOGGLE] = "SCROLLLOCKTOGGLE",
    [KEY_XBUTTON_A] = "XBUTTON_A",
    [KEY_XBUTTON_B] = "XBUTTON_B",
    [KEY_XBUTTON_X] = "XBUTTON_X",
    [KEY_XBUTTON_Y] = "XBUTTON_Y",
    [KEY_XBUTTON_LEFT_SHOULDER] = "XBUTTON_LEFT_SHOULDER",
    [KEY_XBUTTON_RIGHT_SHOULDER] = "XBUTTON_RIGHT_SHOULDER",
    [KEY_XBUTTON_BACK] = "XBUTTON_BACK",
    [KEY_XBUTTON_START] = "XBUTTON_START",
    [KEY_XBUTTON_STICK1] = "XBUTTON_STICK1",
    [KEY_XBUTTON_STICK2] = "XBUTTON_STICK2",
    [KEY_XBUTTON_UP] = "XBUTTON_UP",
    [KEY_XBUTTON_RIGHT] = "XBUTTON_RIGHT",
    [KEY_XBUTTON_DOWN] = "XBUTTON_DOWN",
    [KEY_XBUTTON_LEFT] = "XBUTTON_LEFT",
    [KEY_XSTICK1_RIGHT] = "XSTICK1_RIGHT",
    [KEY_XSTICK1_LEFT] = "XSTICK1_LEFT",
    [KEY_XSTICK1_DOWN] = "XSTICK1_DOWN",
    [KEY_XSTICK1_UP] = "XSTICK1_UP",
    [KEY_XBUTTON_LTRIGGER] = "XBUTTON_LTRIGGER",
    [KEY_XBUTTON_RTRIGGER] = "XBUTTON_RTRIGGER",
    [KEY_XSTICK2_RIGHT] = "XSTICK2_RIGHT",
    [KEY_XSTICK2_LEFT] = "XSTICK2_LEFT",
    [KEY_XSTICK2_DOWN] = "XSTICK2_DOWN",
    [KEY_XSTICK2_UP] = "XSTICK2_UP",
}

function ax.bind:Translate( ... )
    local parts = {}

    local keysLength = select( "#", ... )
    if ( keysLength < 1 ) then return "NONE" end

    for i = 1, keysLength do
        local key = select( i, ... )
        local translation = self.translations[ key ] or tostring( key )

        parts[ #parts + 1 ] = translation
    end

    return table.concat( parts, " + " )
end

--- Register a key bind.
-- Triggers when all buttons in `keys` are held and one of them is pressed.
-- @tparam string uclass Unique identifier for this binding.
-- @tparam number keys Bitmask of KEY* constants representing the keys to bind.
-- @tparam function callback Function called as callback(client, key) when fired.
-- @treturn boolean True if the bind was registered; false otherwise.
function ax.bind:Bind( keys, callbackPressed, callbackReleased )
    if ( !isnumber( keys ) or keys <= 0 ) then
        ax.util:PrintError( "Invalid keys provided to ax.bind:Bind()" )
        return false
    end

    if ( istable( self.stored[keys] ) ) then
        ax.util:PrintWarning( "Overwriting existing bind for keys '" .. tostring(keys) .. "'" )
    end

    if ( !isnumber( keys ) or keys <= 0 ) then
        ax.util:PrintError( "Invalid keys provided to ax.bind:Bind()" )
        return false
    end

    if ( !isfunction( callback ) ) then
        ax.util:PrintError( "Invalid callback provided to ax.bind:Bind()" )
        return false
    end

    self.stored[ keys ] = { callbackPressed = callbackPressed, callbackReleased = callbackReleased }
    return true
end

hook.Add( "PlayerButtonDown" , "ax.bind", function(client, key)
    local buttons = bit.bor( ax.bind.activeButtons, key )
    ax.bind.activeButtons = buttons

    local bind = ax.bind.stored[ buttons ]
    if ( istable( bind ) and isfunction( bind.callbackPressed ) ) then
        bind:callbackPressed()
    end
end)

hook.Add( "PlayerButtonUp", "ax.bind", function(client, key)
    local bind = ax.bind.stored[ ax.bind.activeButtons ]
    if ( istable( bind ) and isfunction( bind.callbackReleased ) ) then
        bind:callbackReleased()
    end

    local buttons = bit.band( ax.bind.activeButtons, bit.bnot( key ) )
    ax.bind.activeButtons = buttons
end)
