-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

AccessiChords.prepareValues()

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 0))

chordIndex = chordIndex - 1

local chords = AccessiChords.getChordsForNote(note)
local chordNames = AccessiChords.getChordNamesForNote(note)

if chords[chordIndex] == nil then
  chordIndex = 1
end

AccessiChords.setValue('last_chord_position', chordIndex)

AccessiChords.stopNotes()

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.speak(chordNames[chordIndex])

AccessiChords.stopNotes()
