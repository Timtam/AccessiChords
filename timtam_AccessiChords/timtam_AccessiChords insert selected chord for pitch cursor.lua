-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 1))
local chordInversion = tonumber(AccessiChords.getValue('last_chord_inversion', 0))
local chordMode = tonumber(AccessiChords.getValue('last_chord_mode', 0))

local chords = AccessiChords.getChordsForNote(note, chordInversion)

if #chords[chordIndex] == 0 then

  local chordNames = AccessiChords.getChordNamesForNote(note, chordInversion, chordMode)

  AccessiChords.speak(chordNames[chordIndex].." does not exist")

  return

end

AccessiChords.playNotesByChordMode(10, chordMode, table.unpack(chords[chordIndex]))

AccessiChords.insertMidiNotesByChordMode(chordMode, table.unpack(chords[chordIndex]))
