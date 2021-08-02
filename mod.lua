function data()
    local trackUtils = require('lollo_freestyle_train_station.trackHelpers')

    return {
        info = {
            minorVersion = 29,
            severityAdd = 'NONE',
            severityRemove = 'WARNING',
            name = _('NAME'),
            description = _('DESC'),
            tags = {
                'Station',
                'Bridge Station',
                'Cargo Station',
                'Elevated Station',
                'Train Station',
                'Underground Station',
            },
            authors = {
                {
                    name = 'Lollus',
                    role = 'CREATOR'
                },
            }
        },

        postRunFn = function(settings, params)
            -- LOLLO NOTE yet another hack.
            -- base_mod.lua has postRunFn and loops over all the tracks it finds,
            -- including my platform-tracks. Then it creates modules for each, with and without catenary.
            -- They will crap up the stock station construction menu,
            -- so I set yearFrom = -1 and yearTo = -1 in the track files to make them invisible
            -- and then I restore them here.
            -- This works because this code always fires after base_mod.lua .
            local trackFileNames = api.res.trackTypeRep.getAll()

            for trackTypeIndex, trackFileName in pairs(trackFileNames) do
                local track = api.res.trackTypeRep.get(trackTypeIndex)
                if trackUtils.isPlatform2(track) then
                    local availability = trackUtils.getTrackAvailability(trackFileName)
                    track.yearFrom = availability.yearFrom -- we just change the value of the existing ref
                    track.yearTo = availability.yearTo -- idem
                    --[[
                        local newTrack = api.type.TrackType.new()
                        -- the api won't allow looping over properties with for key, value in pairs(oldTrack)
                        -- _cloneIntoObjectOmittingFields(oldTrack, newTrack, nil, true)
                        newTrack = oldTrack
                        newTrack.yearFrom = 0 -- we just change the value of the existing ref
                        newTrack.yearTo = 0 -- idem
                    ]]
                end
            end
        end
    }
end
