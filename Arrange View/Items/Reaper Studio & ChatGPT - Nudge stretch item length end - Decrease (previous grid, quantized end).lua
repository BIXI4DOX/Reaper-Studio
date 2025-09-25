--[[
   ReaScript Name: Nudge stretch item length end - Decrease (previous grid, quantized end)
   Author: BIXI DOX & ChatGPT
   Version: 2.0
   About:
     Stretches selected items so their END snaps to the NEXT grid line.
     Works for both audio and MIDI items (unified logic).
--]]

preserve_pitch = true   -- true = keep pitch, false = stretch pitch

local function stretch_item(item, direction)
  if not item then return end

  local pos     = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
  local len     = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
  local end_pos = pos + len

  -- Snap end to next/prev grid
  local grid_snap = reaper.SnapToGrid(0, end_pos)
  local _, grid   = reaper.GetSetProjectGrid(0, false)

  if direction > 0 and grid_snap <= end_pos then
    grid_snap = grid_snap + grid
  elseif direction < 0 and grid_snap >= end_pos then
    grid_snap = grid_snap - grid
  end

  if grid_snap <= pos then return end -- avoid invalid length

  local new_len = grid_snap - pos
  local take    = reaper.GetActiveTake(item)
  if not take then return end

  -- Universal stretch: affects both Audio & MIDI
  reaper.SetMediaItemTakeInfo_Value(take, "B_PPITCH", preserve_pitch and 1 or 0)
  local rate     = len / new_len
  local cur_rate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
  reaper.SetMediaItemTakeInfo_Value(take, "D_PLAYRATE", cur_rate * rate)
  reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_len)
end

function Main(direction)
  reaper.Undo_BeginBlock()
  for i = 0, reaper.CountSelectedMediaItems(0) - 1 do
    local item = reaper.GetSelectedMediaItem(0, i)
    stretch_item(item, direction)
  end
  reaper.UpdateArrange()
  reaper.Undo_EndBlock("Nudge stretch item length (quantized end)", -1)
end

Main(-1) -- Decrease (previous grid)


