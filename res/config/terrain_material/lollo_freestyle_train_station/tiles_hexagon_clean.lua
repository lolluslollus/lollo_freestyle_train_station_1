function data()
return {
	name = _("TilesHexagonClean"),
	
	detailColorTexture = "terrain/hexagon_tiles_albedo.dds",
	detailMetalGlossAoHTexture = "terrain/hexagon_tiles_metal_gloss_ao_h.dds",
	detailNormalTexture = "terrain/hexagon_tiles_nrml.dds",
	overlayTexture = "terrain/overlay_0.dds",

	detailSize = 1 / 15,
	overlaySize = 0.05,
	-- overlayStrength = 0.2,
	overlayStrength = 0.0,

	order = -30,
	priority = 1000000
}
end
