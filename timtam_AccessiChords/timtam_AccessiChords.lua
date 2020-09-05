-- module requirements for all actions
-- doesn't provide any action by itself, so don't map any shortcut to it or run this action

-- constants

local activeProjectIndex = 0
local sectionName = "com.timtam.AccessiChord"

-- variables
local deferCount = 0
local deferTarget = 0

local function setValuePersist(key, value)
  reaper.SetProjExtState(activeProjectIndex, sectionName, key, value)
end

local function getValuePersist(key, defaultValue)

  local valueExists, value = reaper.GetProjExtState(activeProjectIndex, sectionName, key)

  if valueExists == 0 then
    setValuePersist(key, defaultValue)
    return defaultValue
  end

  return value
end

local function setValue(key, value)
  reaper.SetExtState(sectionName, key, value, false)
end

local function getValue(key, defaultValue)

  local valueExists = reaper.HasExtState(sectionName, key)

  if valueExists == false then
    setValue(key, defaultValue)
    return defaultValue
  end

  local value = reaper.GetExtState(sectionName, key)

  return value
end

local function print(message)
  reaper.ShowConsoleMsg("AccessiChords: "..message)
end

local function getCurrentPitchCursorNote()

  local activeMidiEditor = reaper.MIDIEditor_GetActive()

  if activeMidiEditor == nil then
    return
  end

  local currentPitchCursor = reaper.MIDIEditor_GetSetting_int(activeMidiEditor, "active_note_row")

  return currentPitchCursor

end

local function getCurrentNoteChannel()

  local activeMidiEditor = reaper.MIDIEditor_GetActive()

  if activeMidiEditor == nil then
    return
  end

  return reaper.MIDIEditor_GetSetting_int(activeMidiEditor, "default_note_chan")
end

local function getCurrentVelocity()

  local activeMidiEditor = reaper.MIDIEditor_GetActive()

  if activeMidiEditor == nil then
    return 96
  end

  return reaper.MIDIEditor_GetSetting_int(activeMidiEditor, "default_note_vel")
end

local function playNotes(...)

  local noteChannel = getCurrentNoteChannel()

  if noteChannel == nil then
    return
  end

  local noteOnCommand = 0x90 + noteChannel
  local velocity = getCurrentVelocity()

  for _, note in pairs({...}) do

    reaper.StuffMIDIMessage(0, noteOnCommand, note, velocity)
  end

end

local function stopNotes()

  local noteChannel = getCurrentNoteChannel()
  local noteOffCommand = 0x80 + noteChannel

  for midiNote = 0, 127 do

    reaper.StuffMIDIMessage(0, noteOffCommand, midiNote, 0)

  end
end

local function getAllChords()

  return {
    {
      name = 'major',
      create = function(note)
        return {
          note,
          note + 4,
          note + 7
        }
      end
    },
    {
      name = 'minor',
      create = function(note)
        return {
          note,
          note + 3,
          note + 7
        }
      end
    },
    {
      name = 'power',
      create = function(note)
        return {
          note,
          note + 7
        }
      end
    },
    {
      name = 'suspended second',
      create = function(note)
        return {
          note,
          note + 2,
          note + 7
        }
      end
    },
    {
      name = 'suspended fourth',
      create = function(note)
        return {
          note,
          note + 5,
          note + 7
        }
      end
    },
    {
      name = 'diminished',
      create = function(note)
        return {
          note,
          note + 3,
          note + 6
        }
      end
    },
    {
      name = 'augmented',
      create = function(note)
        return {
          note,
          note + 4,
          note + 8
        }
      end
    },
    {
      name = 'major sixth',
      create = function(note)
        return {
          note,
          note + 4,
          note + 7,
          note + 9
        }
      end
    },
    {
      name = 'minor sixth',
      create = function(note)
        return {
          note,
          note + 3,
          note + 7,
          note + 9
        }
      end
    },
    {
      name = 'dominant seventh',
      create = function(note)
        return {
          note,
          note + 4,
          note + 7,
          note + 10
        }
      end
    },
    {
      name = 'major seventh',
      create = function(note)
        return {
          note,
          note + 4,
          note + 7,
          note + 11
        }
      end
    },
    {
      name = 'minor seventh',
      create = function(note)
        return {
          note,
          note + 3,
          note + 7,
          note + 10
        }
      end
    },
    {
      name = 'flat fifth',
      create = function(note)
        return {
          note,
          note + 7
        }
      end
    }
  }
end

local function notesAreValid(...)

  local valid = true
  local _, note

  for _, note in pairs({...}) do

    if note > 127 or note < 0 then
      valid = false
    end
      
  end

  return valid

end

local function getChordsForNote(note)

  local chordGenerators = getAllChords()
  
  local chords = {}

  local _, gen, notes

  for _, gen in pairs(chordGenerators) do

    notes = gen.create(note)

    if notesAreValid(table.unpack(notes)) == true then
      table.insert(chords, notes)
    end

  end

  return chords

end

local function speak(text)
  if reaper.osara_outputMessage ~= nil then
    reaper.osara_outputMessage(text)
  end
end

local function getAllNoteNames()
  return {
    'C',
    'C sharp',
    'D',
    'D sharp',
    'E',
    'F',
    'F sharp',
    'G',
    'G sharp',
    'A',
    'A sharp',
    'B'
  }
end

local function getNoteName(note)

  if notesAreValid(note) == false then
    return 'unknown'
  end

  local noteIndex = (note % 12) + 1
  local octave = math.floor(note/12)-1

  return getAllNoteNames()[noteIndex].." "..tostring(octave)
end

local function getChordNamesForNote(note)

  local chordGenerators = getAllChords()
  
  local names = {}

  for _, gen in pairs(chordGenerators) do

    table.insert(names, getNoteName(note).." "..gen.name)

  end

  return names

end

return {
  getAllChords = getAllChords,
  getAllNoteNames = getAllNoteNames,
  getChordNamesForNote = getChordNamesForNote,
  getChordsForNote = getChordsForNote,
  getCurrentNoteChannel = getCurrentNoteChannel,
  getCurrentPitchCursorNote = getCurrentPitchCursorNote,
  getCurrentVelocity = getCurrentVelocity,
  getNoteName = getNoteName,
  getValue = getValue,
  getValuePersist = getValuePersist,
  notesAreValid = notesAreValid,
  playNotes = playNotes,
  print = print,
  setValue = setValue,
  setValuePersist = setValuePersist,
  speak = speak,
  stopNotes = stopNotes
}