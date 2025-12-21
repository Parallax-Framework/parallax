local color = FindMetaTable( "Color" )

function color:IsDark( minimumThreshold )
    minimumThreshold = minimumThreshold or 186
    return ( self.r * 0.299 + self.g * 0.587 + self.b * 0.114 ) < minimumThreshold
end
