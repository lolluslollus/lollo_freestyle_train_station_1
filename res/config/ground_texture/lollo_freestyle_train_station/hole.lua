local tu = require "texutil"
-- LOLLO TODO tried these to see how they handle the hole. they all suck the same.
function data()
return {
	-- texture = tu.makeTextureLinearNearest("res/textures/terrain/material/mat255.tga", true, false,false),
	-- texture = tu.makeTextureLinearClamp("res/textures/terrain/material/mat255.tga", true, false,false),
	-- texture = tu.makeTextureMipmapRepeat("res/textures/terrain/material/mat255.tga", true, false,false),
	-- texture = tu.makeTextureMipmapClamp("res/textures/terrain/material/mat255.tga", true, false,false),
	texture = tu.makeTextureMipmapClampVertical("res/textures/terrain/material/mat255.tga", true, false,false),
	texSize = { 2.0, 2.0 },
	materialIndexMap = {
		[255] = "",
	},
	priority = 5000
}
end
