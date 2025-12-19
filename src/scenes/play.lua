local Play = SceneManager:addState("Play")

local play_map
local PLAYFIELD_X = 8
local PLAYFIELD_Y = 0
local TILE_WIDTH = 16
local TILE_HEIGHT = TILE_WIDTH

local current_piece
local PIECE_START_X = 6
local PIECE_START_Y = 0
local PIECE_SPEED_X = 1
local PIECE_SPEED_Y = 1

local HORIZONTAL_MOVEMENT_FRAMES = 30
local VERTICAL_MOVEMENT_FRAMES = 60
local STOP_MOVING_FRAMES = 8
local LOCK_DELAY_FRAMES = 30
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
      move_dir_x = 1,
      move_dir_y = 1,
   }
   return piece
end

local function set_piece(x, y)
   play_map = userdata("i16", 32, 32)
   play_map:set(x, y, 1)
end

local function can_place(x, y)
   if mget(x, y) == 0 then
      return true
   end
   return false
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

local function handle_changing_direction()
   if (btn(Game.buttons.x) or btn(Game.buttons.o) or mb == 1 or mb == 2)
      and not button_pressed then
      current_piece.move_dir_x *= -1
      button_pressed = true
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
   vertical_move_timer -= 1
   if vertical_move_timer <= 0 then
      -- Check collision directly below current position (not diagonal)
      -- Horizontal and vertical movements are independent
      if can_place(get_current_x(), get_next_y()) then
         -- add another sound each time we move vertically
         current_piece.y += current_piece.speed_y * current_piece.move_dir_y
      end
      vertical_move_timer = VERTICAL_MOVEMENT_FRAMES * vertical_move_timer_multiplier
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

local function handle_locking()
   if lock_delay <= 0 then
      -- lock piece in place
      mset(current_piece.x, current_piece.y, 1)
      -- spawn new piece
      current_piece = spawn_new_piece()
      lock_delay = LOCK_DELAY_FRAMES
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
   handle_changing_direction()
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
