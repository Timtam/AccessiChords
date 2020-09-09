-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

AccessiChords.prepareValues()

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 1))

local chords = AccessiChords.getChordsForNote(note)

AccessiChords.stopNotes()

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.insertMidiNotes(table.unpack(chords[chordIndex]))

AccessiChords.stopNotes()
