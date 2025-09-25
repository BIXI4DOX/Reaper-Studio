--[[
   ReaScript Name: Quantize item end and stretch (nearest grid)
   Author: BIXI DOX & ChatGPT
   Version: 2.0
   About:
     Stretches selected items so their END snaps to the NEAREST grid line.
     Works for both audio and MIDI items (unified logic).
--]]

preserve_pitch = true   -- true = keep pitch, false = stretch pitch

local function stretch_item_to_grid_end(item)
  if not item then return end

  local pos     = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len     = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = pos + len

  -- Snap END to nearest grid
  local grid_snap = reaper.SnapToGrid(0, end_pos)
  if grid_snap <= pos then return end -- avoid invalid length

  local new_len = grid_snap - pos
  local take    = reaper.GetActiveTake(item)
  if not take then return end

  -- Universal stretch
  reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", preserve_pitch and 1 or 0)
  local rate     = len / new_len
  local cur_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", cur_rate * rate)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
end

function Main()
  reaper.Undo_BeginBlock()
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    stretch_item_to_grid_end(item)
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Quantize item end and stretch", -1)
end

Main()
