-- fixing script path for correct require calls
local path = ({reaper.get_action_context()})[2]:match('^.+[\\//]')
package.path = path .. "?.lua"

local AccessiChords = require('timtam_AccessiChords')

local function run()

  local noteTable = AccessiChords.deserializeTable(AccessiChords.getValue('deferred_notes', AccessiChords.serializeTable({})))
  local deferCount = tonumber(AccessiChords.getValue('deferred_notes_defer_count', 0))
  
  if #noteTable == 0 then
    
    AccessiChords.setValue('deferred_notes_defer_count', 0)
    AccessiChords.setValue('deferred_notes', AccessiChords.serializeTable({}))
    return

  end

  deferCount = deferCount + 1

  local i = 1  
  local playNotes = {}
  local stopNotes = {}

  repeat

    if noteTable[i]['time'] <= deferCount then
      if noteTable[i]['action'] == 'stop' then
        table.insert(stopNotes, noteTable[i]['note'])
      elseif noteTable[i]['action'] == 'play' then
        table.insert(playNotes, {
          note = noteTable[i]['note'],
          duration = noteTable[i]['duration']
        })
      end
      table.remove(noteTable, i)
    else
      i = i + 1
    end

  until (i > #noteTable)

  if #stopNotes > 0 then
    AccessiChords.stopNotes(table.unpack(stopNotes))
  end

  if #playNotes > 0 then
  end

  AccessiChords.setValue('deferred_notes', AccessiChords.serializeTable(noteTable))
  AccessiChords.setValue('deferred_notes_defer_count', deferCount)
  
  reaper.defer(run)
  
end

reaper.defer(run)
