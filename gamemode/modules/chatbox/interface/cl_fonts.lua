
function MODULE:LoadFonts()
    surface.CreateFont("ax.chatbox.text", {
        font = "Inter", size = ScreenScaleH(8), weight = 500,
        antialias = true, extended = true
    })

    surface.CreateFont("ax.chatbox.text.bold", {
        font = "Inter", size = ScreenScaleH(8), weight = 900,
        antialias = true, extended = true
    })

    surface.CreateFont("ax.chatbox.text.italic", {
        font = "Inter", size = ScreenScaleH(8), weight = 500, italic = true,
        antialias = true, extended = true
    })
end
