-- module requirements for all actions
-- doesn't provide any action by itself, so don't map any shortcut to it or run this action

-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

-- other packages
local smallfolk = require('smallfolk')

-- constants

local activeProjectIndex = 0
local sectionName = "com.timtam.AccessiChord"

-- deferred notes action command ids
local deferredNotesCommandIDs = {
  '_RS7d3c_fe1204a338c449b80d061b385a6beee74578e6e6', -- installed in ReaPack MIDI Editor folder
  '_RS7d3c_cce1aae0b8451f7e28026e4399bf5a0a3a559017', -- installed directly into scripts folder
}

local deserializeTable = smallfolk.loads
local serializeTable = smallfolk.dumps

-- source: stackoverflow (https://stackoverflow.com/questions/11669926/is-there-a-lua-equivalent-of-scalas-map-or-cs-select-function)
local function map(f, t)
  local t1 = {}
  local t_len = #t
  for i = 1, t_len do
    t1[i] = f(t[i])
  end
  return t1
end

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

  if type(message) == "table" then
    message = serializeTable(message)
  end

  reaper.ShowConsoleMsg("AccessiChords: "..tostring(message).."\n")
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

  for _, note in pairs({...}) do

    reaper.StuffMIDIMessage(0, noteOnCommand, note, 96)
  end

end

local function stopNotes(...)

  local notes = {...}
  local noteChannel = getCurrentNoteChannel()
  local noteOffCommand = 0x80 + noteChannel
  local _, midiNote

  if #notes == 0 then

    for midiNote = 0, 127 do

      reaper.StuffMIDIMessage(0, noteOffCommand, midiNote, 0)

    end
  else
  
    for _, midiNote in pairs(notes) do

      reaper.StuffMIDIMessage(0, noteOffCommand, midiNote, 0)

    end

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
          note + 6
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

local function getChordInversion(step, ...)

  local notes = {...}

  if step >= #notes then
    return nil
  end
  
  local i

  for i = 1, step do
    notes[i] = notes[i] + 12
  end

  return notes
end

local function getChordsForNote(note, inversion)

  inversion = inversion or 0
  local chordGenerators = getAllChords()
  
  local chords = {}

  local _, gen, notes

  for _, gen in pairs(chordGenerators) do

    notes = gen.create(note)

    if notesAreValid(table.unpack(notes)) == false then
      notes = {}
    else

      if inversion > 0 then

        notes = getChordInversion(inversion, table.unpack(notes))

        if notes == nil then
          notes = {}
        else

          if notesAreValid(table.unpack(notes)) == false then
            notes = {}
          end

        end

      end

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

local function getChordNamesForNote(note, inversion, mode)

  inversion = inversion or 0
  mode = mode or 0

  local chordGenerators = getAllChords()
  
  local names = {}
  local name

  for _, gen in pairs(chordGenerators) do

    name = getNoteName(note).." "..gen.name

    if inversion > 0 then

      name = name.. " inversion "..tostring(inversion)

    end

    if mode == 1 then
      name = name .. " (broken from lowest to highest)"
    elseif mode == 2 then
      name = name .. " (broken from highest to lowest)"
    end

    table.insert(names, name)

  end

  return names

end

local function getActiveMidiTake()

  local activeMidiEditor = reaper.MIDIEditor_GetActive()

  return reaper.MIDIEditor_GetTake(activeMidiEditor)
end

local function getCursorPosition()
  return reaper.GetCursorPosition()
end

local function getCursorPositionPPQ()
  return reaper.MIDI_GetPPQPosFromProjTime(getActiveMidiTake(), getCursorPosition())
end

local function getActiveMediaItem()
  return reaper.GetMediaItemTake_Item(getActiveMidiTake())
end

local function getMediaItemStartPosition()
  return reaper.GetMediaItemInfo_Value(getActiveMediaItem(), "D_POSITION")
end

local function getMediaItemStartPositionPPQ()
  return reaper.MIDI_GetPPQPosFromProjTime(getActiveMidiTake(), getMediaItemStartPosition())
end

local function getMediaItemStartPositionQN()
  return reaper.MIDI_GetProjQNFromPPQPos(getActiveMidiTake(), getMediaItemStartPositionPPQ())
end

local function getGridUnitLength()

  local gridLengthQN = reaper.MIDI_GetGrid(getActiveMidiTake())
  local mediaItemPlusGridLengthPPQ = reaper.MIDI_GetPPQPosFromProjQN(getActiveMidiTake(), getMediaItemStartPositionQN() + gridLengthQN)
  local mediaItemPlusGridLength = reaper.MIDI_GetProjTimeFromPPQPos(getActiveMidiTake(), mediaItemPlusGridLengthPPQ)
  return mediaItemPlusGridLength - getMediaItemStartPosition()
end

local function getNextNoteLength()

  local activeMidiEditor = reaper.MIDIEditor_GetActive()
  
  if activeMidiEditor == nil then
    return 0
  end
  
  local noteLen = reaper.MIDIEditor_GetSetting_int(activeMidiEditor, "default_note_len")

  if noteLen == 0 then
    return 0
  end

  return reaper.MIDI_GetProjTimeFromPPQPos(getActiveMidiTake(), noteLen)
end

local function getMidiEndPositionPPQ()

  local startPosition = getCursorPosition()
  local startPositionPPQ = getCursorPositionPPQ()

  local noteLength = getNextNoteLength()
  
  if noteLength == 0 then
    noteLength = getGridUnitLength()
  end

  local endPositionPPQ = reaper.MIDI_GetPPQPosFromProjTime(getActiveMidiTake(), startPosition+noteLength)

  return endPositionPPQ
end

local function insertMidiNotes(...)

  local startPositionPPQ = getCursorPositionPPQ()
  local endPositionPPQ = getMidiEndPositionPPQ()

  local channel = getCurrentNoteChannel()
  local take = getActiveMidiTake()
  local velocity = getCurrentVelocity()
  local _, note

  for _, note in pairs({...}) do
    reaper.MIDI_InsertNote(take, false, false, startPositionPPQ, endPositionPPQ, channel, note, velocity, false)
  end

  local endPosition = reaper.MIDI_GetProjTimeFromPPQPos(take, endPositionPPQ)

  reaper.SetEditCurPos(endPosition, true, false)
end

-- duration in defer ticks (ca 33 msec)
local function stopNotesDeferred(duration, ...)

  local notes = {...}
  local noteTable = deserializeTable(getValue('deferred_notes', serializeTable({})))
  local deferCount = tonumber(getValue('deferred_notes_defer_count', 0))

  local _, i, note, found, noteIndex
  
  for _, note in pairs(notes) do

    found = false

    for i = 1, #noteTable do

      if noteTable[i]['note'] == note and noteTable[i]['action'] == 'stop' then
        found = true
        noteIndex = i
        break
      end
    end

    if found == true then
      -- note is already in the list
      -- hence we will set the time to the current defer count + duration
      noteTable[noteIndex]['time'] = deferCount + duration
    else

      -- add the note to the list
      table.insert(noteTable, {
        action = 'stop',
        time = deferCount + duration + 1,
        note = note
      })
  
    end
  end

  setValue('deferred_notes', serializeTable(noteTable))
    
  if deferCount == 0 then

    -- we have to manually launch the action
    local commandID
    
    for i = 1, #deferredNotesCommandIDs do

      found = false

      commandID = reaper.NamedCommandLookup(deferredNotesCommandIDs[i])

      if commandID ~= 0 then
        found = true
        break
      end
      
    end

    if found == true then

      -- to prevent many calls before even the first defer in the action fires, we'll have to set defer count to 1 already
      setValue('deferred_notes_defer_count', 1)

      reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), commandID)

    else
      -- message box informing about missing action
      stopNotes(table.unpack(notes))
      reaper.MB('The action to process notes deferred could not be found. That will cause issues with real-time generated samples. Please make sure to follow the installation instructions which can be found in the documentation', 'AccessiChords - Error', 0)
    end

  end
end

-- delay = defer tick delay after which to play the notes
-- duration in defer ticks
local function playNotesDeferred(delay, duration, ...)

  local notes = {...}
  local noteTable = deserializeTable(getValue('deferred_notes', serializeTable({})))
  local deferCount = tonumber(getValue('deferred_notes_defer_count', 0))

  local _, i, note, found, noteIndex
  
  for _, note in pairs(notes) do

    found = false

    for i = 1, #noteTable do

      if noteTable[i]['note'] == note and noteTable[i]['action'] == 'play' then
        found = true
        noteIndex = i
        break
      end
    end

    if found == true then
      -- note is already in the list
      -- hence we will set the time to the current defer count + delay
      noteTable[noteIndex]['time'] = deferCount + duration
      noteTable[noteIndex]['delay'] = delay
    else

      -- add the note to the list
      table.insert(noteTable, {
        action = 'play',
        time = deferCount + delay + 1,
        note = note,
        duration = duration
      })
  
    end
  end

  setValue('deferred_notes', serializeTable(noteTable))
    
  if deferCount == 0 then

    -- we have to manually launch the action
    local commandID
    
    for i = 1, #deferredNotesCommandIDs do

      found = false

      commandID = reaper.NamedCommandLookup(deferredNotesCommandIDs[i])

      if commandID ~= 0 then
        found = true
        break
      end
      
    end

    if found == true then

      -- to prevent many calls before even the first defer in the action fires, we'll have to set defer count to 1 already
      setValue('deferred_notes_defer_count', 1)

      reaper.MIDIEditor_OnCommand(reaper.MIDIEditor_GetActive(), commandID)

    else
      -- message box informing about missing action
      playNotes(table.unpack(notes))
      reaper.MB('The action to process notes deferred could not be found. That will cause issues with real-time generated samples. Please make sure to follow the installation instructions which can be found in the documentation', 'AccessiChords - Error', 0)
    end

  end
end

-- plays notes according to chord mode (either full, broken or broken from last to first)
-- broken chords will take the current note length into consideration
-- duration in defer ticks (ca 33 msec)
local function playNotesByChordMode(duration, mode, ...)

  local notes = {...}
  
  local lstart, lend, lstep, i
  local offset = 0

  local stepTime = math.floor(reaper.MIDI_GetProjTimeFromPPQPos(getActiveMidiTake(), getMidiEndPositionPPQ() - getCursorPositionPPQ()) * 1000 / 33)

  if mode == 0 then
    playNotes(table.unpack(notes))
    stopNotesDeferred(duration, table.unpack(notes))
    return
  end

  if mode == 1 then 
    lstart = 1
    lend = #notes
    lstep = 1
  elseif mode == 2 then
    lstart = #notes
    lend = 1
    lstep = -1
  end

  for i = lstart, lend, lstep do

    playNotesDeferred(offset, duration, notes[i])
    offset = offset + stepTime

  end

end

local function insertMidiNotesByChordMode(mode, ...)

  local notes = {...}

  if mode == 0 then
    insertMidiNotes(table.unpack(notes))
    return
  end

  local lstart, lend, lstep, i
  
  if mode == 1 then
    lstart = 1
    lend = #notes
    lstep = 1
  elseif mode == 2 then
    lstart = #notes
    lend = 1
    lstep = -1
  end
  
  for i = lstart, lend, lstep do
    insertMidiNotes(notes[i])
  end
end

return {
  deserializeTable = deserializeTable,
  getChordInversion = getChordInversion,
  getChordNamesForNote = getChordNamesForNote,
  getChordsForNote = getChordsForNote,
  getCurrentPitchCursorNote = getCurrentPitchCursorNote,
  getNoteName = getNoteName,
  getValue = getValue,
  getValuePersist = getValuePersist,
  insertMidiNotes = insertMidiNotes,
  insertMidiNotesByChordMode = insertMidiNotesByChordMode,
  map = map,
  playNotes = playNotes,
  playNotesByChordMode = playNotesByChordMode,
  playNotesDeferred = playNotesDeferred,
  print = print,
  serializeTable = serializeTable,
  setValue = setValue,
  setValuePersist = setValuePersist,
  speak = speak,
  stopNotes = stopNotes,
  stopNotesDeferred = stopNotesDeferred
}