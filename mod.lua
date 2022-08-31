function data()
    local _constants = require('lollo_freestyle_train_station.constants')
    local _mdlHelpers = require('lollo_freestyle_train_station.mdlHelpers')
    local _stringUtils = require('lollo_freestyle_train_station.stringUtils')
    local _trackHelpers = require('lollo_freestyle_train_station.trackHelpers')

    return {
        info = {
            minorVersion = 82,
            severityAdd = 'NONE',
            severityRemove = 'WARNING',
            name = _('NAME'),
            description = _('DESC'),
            tags = {
                'Station',
                'Bridge Station',
                'Cargo Station',
                'Elevated Station',
                'Elevator',
                'Lift',
                'Stairs',
                'Train Depot',
                'Train Station',
                'Underground Station',
                'Underground Train Depot',
            },
            authors = {
                {
                    name = 'Lollus',
                    role = 'CREATOR'
                },
            }
        },

        -- streetside stations have colliders that annoy the station: get rid of them
        runFn = function(settings)
            addModifier(
                'loadModel',
                function(fileName, data)
                    if not(_stringUtils.stringEndsWith(fileName, '.mdl')) then return end

                    if data and data.metadata and data.metadata.streetTerminal then
                        data.boundingInfo = _mdlHelpers.getVoidBoundingInfo()
                        data.collider = _mdlHelpers.getVoidCollider()
                        -- print('LOLLO bounding reset, filename =', fileName)
                    end
                    return data
                end
            )
        end,

        postRunFn = function(settings, params)
            -- LOLLO NOTE yet another hack.
            -- base_mod.lua has postRunFn and loops over all the tracks it finds,
            -- including my platform-tracks. Then it creates modules for each, with and without catenary.
            -- They will crap up the stock station construction menu,
            -- so I set yearFrom = -1 and yearTo = -1 in the track files to make them invisible
            -- and then I restore them here.
            -- This works because this code always fires after base_mod.lua .
            -- As of version 1.75, platforms never expire.
            -- To keep the track construction menu tidy, we introduce a new category for non-platform tracks.
            local trackFileNames = api.res.trackTypeRep.getAll()

            for trackTypeIndex, trackFileName in pairs(trackFileNames) do
                local track = api.res.trackTypeRep.get(trackTypeIndex)
                if _trackHelpers.isPlatform2(track) then
                    local availability = _trackHelpers.getTrackAvailability(trackFileName)
                    track.yearFrom = availability.yearFrom -- we just change the value of the existing ref
                    -- track.yearTo = availability.yearTo -- idem
                    track.yearTo = 0 -- as of version 1.75, platforms never expire
                else
                    _trackHelpers.addCategory(track, _constants.trainTracksCategory)
                end
            end
        end
    }
end
