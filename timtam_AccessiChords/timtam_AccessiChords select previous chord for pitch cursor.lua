-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local note = AccessiChords.getCurrentPitchCursorNote()
local chordIndex = tonumber(AccessiChords.getValue('last_chord_position', 1))

chordIndex = chordIndex - 1

local chords = AccessiChords.getChordsForNote(note)
local chordNames = AccessiChords.getChordNamesForNote(note)

if chordIndex < 1 then
  chordIndex = 1
end

AccessiChords.setValue('last_chord_position', chordIndex)

if #chords[chordIndex] == 0 then

  AccessiChords.speak(chordNames[chordIndex].." does not exist")

  return

end

AccessiChords.stopNotes()

AccessiChords.playNotes(table.unpack(chords[chordIndex]))

AccessiChords.speak(chordNames[chordIndex])

AccessiChords.stopNotes()
