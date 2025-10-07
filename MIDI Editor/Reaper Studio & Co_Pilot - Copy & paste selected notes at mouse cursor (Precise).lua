--[[
   ReaScript Name: Copy & paste selected notes at mouse cursor (Precise).
   Author: BIXI DOX & CO-PILOT
   Repository: https://github.com/BIXI4DOX/Reaper-Studio
   Version: 1.0
   About:
     Copy and paste selected notes, Anchor snaps their start positions to grid-
     -with mouse cursor as anchor pitch in the piano roll.
--]]

--==========================================================--
local copyData = nil                                        -- persistent in-script copy buffer
--==========================================================--


--==============================================================================================================================--
local function get_active_take()                                                                                                -- Get active take in active MIDI editor (if any)
    local editor = reaper.MIDIEditor_GetActive()                                                                                --
    if not editor then return nil end                                                                                           --
    return reaper.MIDIEditor_GetTake(editor), editor                                                                            --
end                                                                                                                             --
--==============================================================================================================================--

--==============================================================================================================================--
local function collect_selected_notes(take)                                                                                     -- Collect selected notes in the given take and return them as a table
    local notes = {}                                                                                                            -- Also return the startPPQ of the earliest selected note as anchorPitch.
    local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)                                                                      --
    local minStart = nil                                                                                                        --
    for i = 0, noteCount-1 do                                                                                                   --  
        local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)                        --
        if retval and selected then                                                                                             --
            table.insert(notes, {startppq = startppq, endppq = endppq, chan = chan, pitch = pitch, vel = vel, muted = muted})   --
            if not minStart or startppq < minStart then minStart = startppq end                                                 --
        end                                                                                                                     --
    end                                                                                                                         --
    return notes, minStart                                                                                                      --
end                                                                                                                             --
--==============================================================================================================================--


--==========================================================================================================================--
--- Get mouse project position using SWS/BR extension function BR_GetMouseCursorContext_Position                            --
--- This function is more reliable than reaper.GetMousePosition() as it works even if the                                   --
--- mouse is over a MIDI editor or other window.                                                                            --
--- If SWS/BR is not available, the script will return nothing.                                                             --
------------------------------------------------------------------------------------------------------------------------------
local function get_mouse_project_position()                                                                                 -- returns nil if SWS/BR not available                                                                                   
    if not reaper.BR_GetMouseCursorContext_Position then                                                                    -- Require SWS/BR extension (no fallback)
        reaper.MB("This script requires the SWS/BR extension (BR_GetMouseCursorContext_Position).","SWS/BR required", 0)    --
        return nil                                                                                                          --
    end                                                                                                                     --
    return reaper.BR_GetMouseCursorContext_Position()                                                                       -- Use BR_GetMouseCursorContext_Position exclusively
end                                                                                                                         --
--==========================================================================================================================--




--======================================================================================================================--
--            Paste previously copied notes at the mouse cursor position in the active MIDI editor.                     --
--======================================================================================================================--
local function paste_notes_at_mouse()                                                                                   --
    local take, editor = get_active_take()                                                                              --
    if not take then return end                                                                                         --
    if not copyData or not copyData.notes or #copyData.notes == 0 then return end                                       -- nothing to paste_notes_at_mouse.                                                                                                                                                                              
                                                                                                                        --
    local notes, anchor = collect_selected_notes(take)                                                                  -- Copy selected notes (store locally)
    if not notes or #notes == 0 then                                                                                    --
        copyData = nil                                                                                                  -- clear stored copy if nothing selected
        return                                                                                                          --
    end                                                                                                                 --                                            
    copyData = {notes = notes, anchor = anchor, srcTake = take}                                                         -- store copy (overwrite previous)
                                                                                                                        --    
    local mousePos = get_mouse_project_position()                                                                       -- Get mouse project positions
    if not mousePos then return end                                                                                     --
    reaper.SetEditCurPos(mousePos, true, false)                                                                         -- Move edit cursor to mouse position
                                                                                                                        --
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(take, mousePos)                                                  -- Convert mouse project time to PPQ in this take
    if not mousePPQ then return end                                                                                     -- If no mousePPQ, we can't proceed, so we exit here.
                                                                                                                        --
    local anchorPitch = nil                                                                                             --
    for _, n in ipairs(copyData.notes) do                                                                               -- Find pitch of anchor note (if any)                              
        if n.startppq == copyData.anchor then                                                                           --
            anchorPitch = n.pitch                                                                                       --
            break                                                                                                       --
        end                                                                                                             --
    end                                                                                                                 --                              
    if not anchorPitch and #copyData.notes > 0 then                                                                     -- If no anchor note (e.g. all notes start at same time), use first note's pitch
        anchorPitch = copyData.notes[1].pitch                                                                           --
    end                                                                                                                 -- Validate anchorPitch
    if not anchorPitch then return end                                                                                  -- If there's no anchor pitch, we can't proceed, so we exit here. 
                                                                                                                        --                                                                                        
    if not reaper.BR_GetMouseCursorContext_MIDI then                                                                    -- Get MIDI pitch under mouse using SWS BR_GetMouseCursorContext_MIDI (required)
        reaper.MB("This script requires the SWS/BR extension (BR_GetMouseCursorContext_MIDI).","SWS/BR required", 0)    --
        return                                                                                                          --
    end                                                                                                                 -- 
                                                                                                                        --
    local r1, r2, r3, r4, r5 = reaper.BR_GetMouseCursorContext_MIDI()                                                   -- Call the SWS function and try to find a numeric value between 0-127 among its returns
    local mousePitch = nil                                                                                              -- 
    for _, v in ipairs({r1, r2, r3, r4, r5}) do                                                                         -- 
        if type(v) == "number" and v >= 0 and v <= 127 then                                                             --
            mousePitch = math.floor(v + 0.5)                                                                            --
            break                                                                                                       --                                                                                                                                                               --
        end                                                                                                             --
    end                                                                                                                 --
                                                                                                                        --
    if not mousePitch then                                                                                              -- mouse not over piano roll area? exit.
        return                                                                                                          --
    end                                                                                                                 --
                                                                                                                        --
    local transpose = 0                                                                                                 -- Compute transpose (preserve intervals relative to the anchor note)
    if anchorPitch then                                                                                                 --
        transpose = mousePitch - anchorPitch                                                                            --          
    end                                                                                                                 --
                                                                                                                        --=========================================--
    local originals = {}                                                                                                                                           -- Build map of original notes (to unselect later if needed) and insert new notes as SELECTED
    for _, n in ipairs(copyData.notes) do                                                                                                                          -- 
        local key = table.concat({string.format("%.6f", n.startppq), string.format("%.6f", n.endppq), tostring(n.chan), tostring(n.pitch), tostring(n.vel)}, ":")  -- 
        originals[key] = true                                                                                                                                      -- 
    end                                                                                                                                                            -- 
                                                                                                                                                                   -- 
    local inserted = {}                                                                                                                                            -- 
    for _, n in ipairs(copyData.notes) do                                                                                                                          -- 
        local newStart = n.startppq - copyData.anchor + mousePPQ                                                                                                   -- 
        local newEnd   = n.endppq   - copyData.anchor + mousePPQ                                                                                                   -- 
        local newPitch = n.pitch + transpose                                                                                                                       -- 
        if newPitch < 0 then newPitch = 0 end                                                                                                                      -- 
        if newPitch > 127 then newPitch = 127 end                                                                                                                  -- 
                                                                                                                                                                   --                                                                                                                             
        reaper.MIDI_InsertNote(take, true, n.muted, newStart, newEnd, n.chan, newPitch, n.vel, true)                                                               --
        local ik = table.concat({string.format("%.6f", newStart), string.format("%.6f", newEnd), tostring(n.chan), tostring(newPitch), tostring(n.vel)}, ":")      -- Insert as selected so the pasted notes are selected
        inserted[ik] = true                                                                                                                                        --
    end                                                                                                                                                            --
                                                                                                                                                                   --
                                                                                                                                                                   -- Now iterate all notes and adjust selection:
                                                                                                                                                                   -- Unselect notes that match the originals in the source take
                                                                                                                                                                   -- Ensure pasted notes (matching inserted map) are selected
    local _, noteCount, _, _ = reaper.MIDI_CountEvts(take)                                                                                                         --
    for i = 0, noteCount-1 do                                                                                                                                      --
        local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)                                                           --
        if retval then                                                                                                                                             --
            local key = table.concat({string.format("%.6f", startppq), string.format("%.6f", endppq), tostring(chan), tostring(pitch), tostring(vel)}, ":")        --
            if copyData.srcTake == take and originals[key] then                                                                                                    --
                reaper.MIDI_SetNote(take, i, false, muted, startppq, endppq, chan, pitch, vel, true)                                                               -- This is an original note in the source take: unselect it
            elseif inserted[key] then                                                                                                                              --
                reaper.MIDI_SetNote(take, i, true, muted, startppq, endppq, chan, pitch, vel, true)                                                                -- This matches a newly inserted note: ensure it's selected
            end                                                                                                                                                    -- Other notes (not in source take, not newly inserted) are left unchanged                              
        end                                                                                                                                                        --
    end                                                                                                                                                            --
                                                                                                                                                                   -- Runs a MIDI Editor quantize note's start-action on the newly pasted notes.
    local QUANTIZE_NOTE_START = 40469                                                                                                                              -- Quantize notes position to grid
    local QUANTIZE_EDIT_CURSOR = 40440                                                                                                                             -- Navigate: Move edit cursor to start of selected events
                                                                                                                                                                   --
    if editor and QUANTIZE_NOTE_START ~= 0 and QUANTIZE_EDIT_CURSOR ~= 0 then                                                                                      --
        reaper.MIDIEditor_OnCommand(editor, QUANTIZE_NOTE_START)                                                                                                   --
        reaper.MIDIEditor_OnCommand(editor, QUANTIZE_EDIT_CURSOR)                                                                                                  --     
    end                                                                                                                                                            --
    reaper.MIDI_Sort(take)                                                                                                                                         -- Sort MIDI to ensure proper display and functioning.
end                                                                                                                                                                --
--=================================================================================================================================================================--


--======================================================================================--
-- Call this function when you want to perform the copy+paste action.                   --
-- First run paste_notes_at_mouse() after selecting notes to copy and then again        --
-- when you want to paste; or modify to combine copy+paste in one call.                 -- 
------------------------------------------------------------------------------------------  
local function CopySelectedNotesThenPasteAtMouse()                                      --
    local take = select(1, get_active_take())                                           --
    if not take then return end                                                         --
    local notes, anchor = collect_selected_notes(take)                                  --
    if not notes or #notes == 0 then                                                    --
        copyData = nil                                                                  -- clear stored copy if nothing selected.
        return                                                                          --
    end                                                                                 --
    copyData = {notes = notes, anchor = anchor, srcTake = take}                         -- store copy
    paste_notes_at_mouse()                                                              -- Immediately paste at mousePos.
end                                                                                     --
--======================================================================================--

--======================================================--
reaper.Undo_BeginBlock()                                --
reaper.PreventUIRefresh(1)  -- turn UI updates off      --
CopySelectedNotesThenPasteAtMouse()                     --
reaper.PreventUIRefresh(-1) -- turn UI updates back on  --
reaper.Undo_EndBlock("Paste notes at mouse cursor", -1) --
--======================================================--
