local tu = require "texutil"

function data()
return {
	texture = tu.makeTextureLinearNearest("res/textures/terrain/material/mat255.tga", true, false,false),
	texSize = { 2.0, 2.0 },
	materialIndexMap = {
		-- [255] = "shared/asphalt_02.lua",
		-- [255] = "shared/tiles_hexagon.lua",
		[255] = "lollo_freestyle_train_station/tiles_hexagon_clean.lua",
	},
	priority = 12000,
}
end
