--[[
   ReaScript Name: Quantize item start and stretch (nearest grid)
   Author: BIXI DOX & ChatGPT
   Version: 1.0
   About:
     Stretches selected items so their START snaps to the NEAREST grid line.
     Works for both audio and MIDI items (unified logic).
--]]

preserve_pitch = true   -- true = keep pitch, false = stretch pitch

local function stretch_item_to_grid_start(item)
  if not item then return end

  local pos     = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len     = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = pos + len

  -- Snap START to nearest grid
  local grid_snap = reaper.SnapToGrid(0, pos)
  if grid_snap >= end_pos then return end -- avoid invalid length

  local new_len = end_pos - grid_snap
  local take    = reaper.GetActiveTake(item)
  if not take then return end

  -- Stretch rate
  reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", preserve_pitch and 1 or 0)
  local rate     = len / new_len
  local cur_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", cur_rate * rate)

  -- Update start + length
  reaper.SetMediaItemInfo_Value(item, "D_POSITION", grid_snap)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
end

function Main()
  reaper.Undo_BeginBlock()
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    stretch_item_to_grid_start(item)
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Quantize item start and stretch", -1)
end

Main()
