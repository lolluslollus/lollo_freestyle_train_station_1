local soundsetutil = require "soundsetutil"

local randomEventNames = {
    -- "car_idle.wav",
    "lorry_whip.wav",
    "mimmo-1.wav",
    "mimmo-2.wav",
    "mimmo-3.wav",
    "selected_bus.wav",
    -- "selected_busdepot3.wav",
    -- "selected_bus_depot.wav",
    -- "selected_cargotruckstation2.wav",
    "selected_industrial.wav",
}

function data()

local data = soundsetutil.makeSoundSet()

-- soundsetutil.addTrackParam01(data, "car_horn.wav", 25.0,
-- 		{ { .0, .5 } }, { { .0, 0.7 } }, "cargo01")
		
soundsetutil.addEventParam01(data, "random32", randomEventNames, 25.0,
		{ { 0.33, 1.0 }, { 0.34, 0.0 } }, { { 0.0, 1.0 } }, "cargo01")
		
soundsetutil.addEventParam01(data, "random16", randomEventNames, 25.0,
		{ { 0.33, 0.0 }, { 0.34, 1.0 }, { 0.66, 1.0 }, { 0.67, 0.0 } }, { { 0.0, 1.0 } }, "cargo01")
		
soundsetutil.addEventParam01(data, "random8", randomEventNames, 25.0,
		{ { 0.66, 0.0 }, { 0.67, 1.0 } }, { { 0.0, 1.0 } }, "cargo01")

return data

end
