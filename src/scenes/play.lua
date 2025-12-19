local Play = SceneManager:addState("Play")

local play_map
local PLAYFIELD_X = 8
local PLAYFIELD_Y = 0
local TILE_WIDTH = 16
local TILE_HEIGHT = TILE_WIDTH

-- Rotation offsets: map coordinates for each orientation (right, down, left, up)
local ROTATION_OFFSETS = {
   {x = 0, y = 18}, -- right (index 1)
   {x = 3, y = 18}, -- down (index 2)
   {x = 6, y = 18}, -- left (index 3)
   {x = 9, y = 18}, -- up (index 4)
}

local current_piece
local PIECE_START_X = 6
local PIECE_START_Y = 0
local PIECE_SPEED_X = 1
local PIECE_SPEED_Y = 1

local HORIZONTAL_MOVEMENT_FRAMES = 30
local VERTICAL_MOVEMENT_FRAMES = 60
local STOP_MOVING_FRAMES = 8
local LOCK_DELAY_FRAMES = 60
local horizontal_move_timer = HORIZONTAL_MOVEMENT_FRAMES
local vertical_move_timer_multiplier = 1
local vertical_move_timer = VERTICAL_MOVEMENT_FRAMES * vertical_move_timer_multiplier
local stop_moving_timer = STOP_MOVING_FRAMES
local lock_delay = LOCK_DELAY_FRAMES

local mx, my, mb = 0, 0, 0
local button_pressed = false

local function spawn_new_piece()
   local piece = {
      x = PIECE_START_X,
      y = PIECE_START_Y,
      speed_x = PIECE_SPEED_X,
      speed_y = PIECE_SPEED_Y,
      orientation = 1, -- 1=right, 2=down, 3=left, 4=up
      move_dir_x = 1,
      move_dir_y = 1,
   }
   return piece
end

-- Get the current rotation offset for the piece
local function get_piece_offset()
   return ROTATION_OFFSETS[current_piece.orientation]
end

-- Rotate the piece (direction: 1 = clockwise, -1 = counter-clockwise)
local function rotate_piece(direction)
   local new_orientation = ((current_piece.orientation - 1 + direction) % 4) + 1
   local new_offset = ROTATION_OFFSETS[new_orientation]

   -- Check if rotation is valid (no collision)
   local px = PLAYFIELD_X + current_piece.x
   local py = PLAYFIELD_Y + current_piece.y
   for x = 0, 2 do
      for y = 0, 2 do
         local tile = mget(new_offset.x + x, new_offset.y + y)
         if tile ~= 0 then
            if mget(px + x, py + y) ~= 0 then
               return false -- Collision, can't rotate
            end
         end
      end
   end

   current_piece.orientation = new_orientation
   return true
end

local function set_piece(px, py)
   play_map = userdata("i16", 32, 32)
   local offset = get_piece_offset()

   for x = 0, 2 do
      for y = 0, 2 do
         local tile = mget(offset.x + x, offset.y + y)
         play_map:set(px + x, py + y, tile)
      end
   end
end

-- Lock piece onto the main map (permanent placement)
local function lock_piece(px, py)
   local offset = get_piece_offset()
   for x = 0, 2 do
      for y = 0, 2 do
         local tile = mget(offset.x + x, offset.y + y)
         if tile ~= 0 then
            -- Set on the main map using absolute coordinates
            mset(PLAYFIELD_X + px + x, PLAYFIELD_Y + py + y, tile)
         end
      end
   end
end


local function can_place(px, py)
   -- Check all tiles in the 3x3 piece
   local offset = get_piece_offset()
   for x = 0, 2 do
      for y = 0, 2 do
         -- Only check collision for non-empty tiles in the piece template
         local piece_tile = mget(offset.x + x, offset.y + y)
         if piece_tile ~= 0 then
            -- Check if the target position on the playfield is occupied
            if mget(px + x, py + y) ~= 0 then
               return false
            end
         end
      end
   end
   return true
end

-- Helper functions to calculate next positions on-demand
local function get_next_x()
   return PLAYFIELD_X + current_piece.x + current_piece.speed_x * current_piece.move_dir_x
end

local function get_next_y()
   return PLAYFIELD_Y + current_piece.y + current_piece.speed_y * current_piece.move_dir_y
end

local function get_current_x()
   return PLAYFIELD_X + current_piece.x
end

local function get_current_y()
   return PLAYFIELD_Y + current_piece.y
end

local function reverse_if_colliding()
   if not can_place(get_next_x(), get_current_y()) then
      current_piece.move_dir_x *= -1
   end
end

local function handle_button_tap()
   if not button_pressed then
      if btn(Game.buttons.x) or mb == 1 then
         -- Rotate clockwise
         rotate_piece(1)
         button_pressed = true
      elseif btn(Game.buttons.o) or mb == 2 then
         -- Rotate counter-clockwise
         rotate_piece(-1)
         button_pressed = true
      end
   end
   if not (btn(Game.buttons.x) or btn(Game.buttons.o) or mb ~= 0) then
      button_pressed = false
   end
end

local function handle_moving_horizontally()
   horizontal_move_timer -= 1
   if horizontal_move_timer <= 0 then
      -- we only check horizontally if we are moving horizontally
      if can_place(get_next_x(), get_current_y()) then
         -- add sound each time we move horizontally
         current_piece.x += current_piece.speed_x * current_piece.move_dir_x
      end
      horizontal_move_timer = HORIZONTAL_MOVEMENT_FRAMES
   end
end

local function handle_moving_vertically()
   local is_grounded = not can_place(get_current_x(), get_next_y())

   if is_grounded then
      -- Piece can't move down, count down lock delay
      lock_delay -= 1
      if lock_delay <= 0 then
         -- Lock piece in place (all tiles)
         lock_piece(current_piece.x, current_piece.y)
         -- Spawn new piece
         current_piece = spawn_new_piece()
         lock_delay = LOCK_DELAY_FRAMES
      end
   else
      -- Piece can still fall, reset lock delay
      lock_delay = LOCK_DELAY_FRAMES

      -- Handle vertical movement timer
      vertical_move_timer -= 1
      if vertical_move_timer <= 0 then
         current_piece.y += current_piece.speed_y * current_piece.move_dir_y
         vertical_move_timer = VERTICAL_MOVEMENT_FRAMES * vertical_move_timer_multiplier
      end
   end
end

local function test_movement()
   if btnp(Game.buttons.left) then
      current_piece.speed_x = PIECE_SPEED_X
      current_piece.move_dir_x = -1
   elseif btnp(Game.buttons.right) then
      current_piece.speed_x = PIECE_SPEED_X
      current_piece.move_dir_x = 1
   else
      current_piece.speed_x = 0
   end
   if btnp(Game.buttons.up) then
      current_piece.speed_y = PIECE_SPEED_Y
      current_piece.move_dir_y = -1
   elseif btnp(Game.buttons.down) then
      current_piece.speed_y = PIECE_SPEED_Y
      current_piece.move_dir_y = 1
   else
      current_piece.speed_y = 0
   end
end

local function handle_button_holding()
   if not button_pressed then
      stop_moving_timer = STOP_MOVING_FRAMES
      current_piece.speed_x = PIECE_SPEED_X
      vertical_move_timer_multiplier = 1
   elseif stop_moving_timer > 0 then
      stop_moving_timer -= 1
      if stop_moving_timer == 0 then
         current_piece.speed_x = 0
         vertical_move_timer_multiplier = 0.25
         vertical_move_timer = 0
      end
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   current_piece = spawn_new_piece()
end

function Play:update()
   mx, my, mb = mouse()
   reverse_if_colliding()
   -- test_movement()
   set_piece(current_piece.x, current_piece.y)
   handle_button_tap()
   handle_button_holding()
   handle_moving_horizontally()
   handle_moving_vertically()
end

function Play:draw()
   cls()
   --- @diagnostic disable-next-line: missing-parameter
   map()
   map(play_map, 0, 0, PLAYFIELD_X * TILE_WIDTH, PLAYFIELD_Y * TILE_HEIGHT)
   print("HMT:"..horizontal_move_timer, 10, 10, 8)
   print("VMT:"..vertical_move_timer, 10, 20, 8)
   print("PDIR:"..current_piece.move_dir_x, 10, 30, 8)
   print("nextx:"..mget(get_next_x(), get_current_y()), 10, 40, 8)
   print("stop moving timer:"..stop_moving_timer, 10, 50, 8)
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
