function data()
    local trackUtils = require('lollo_freestyle_train_station.trackHelpers')

    return {
        info = {
            minorVersion = 0,
            severityAdd = 'NONE',
            severityRemove = 'WARNING',
            name = _('NAME'),
            description = _('DESC'),
            tags = {
                'Station',
                'Train Station'
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

            for oldTrackTypeIndex, oldTrackFileName in pairs(trackFileNames) do
                local oldTrack = api.res.trackTypeRep.get(oldTrackTypeIndex)
                if trackUtils.isPlatform2(oldTrack) then
                    oldTrack.yearFrom = 0 -- we just change the value of the existing ref
                    oldTrack.yearTo = 0 -- idem
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
