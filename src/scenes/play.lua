local Play = SceneManager:addState("Play")

local PLAYFIELD_X = 8
local PLAYFIELD_Y = 0
local TILE_WIDTH = 16
local TILE_HEIGHT = TILE_WIDTH
local PIECE_START_X = 6
local PIECE_START_Y = 0
local play_map

local horizontal_movement_delay = 30
local horizontal_move_timer = horizontal_movement_delay
local vertical_movement_delay = 120
local vertical_move_timer = vertical_movement_delay

local mx, my, mb = 0, 0, 0
local button_pressed = false
local next_x = 0
local next_y = 0

local function spawn_new_piece()
   local piece = {
      x = PIECE_START_X,
      y = PIECE_START_Y,
      speed_x = 1,
      speed_y = 1,
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

local function reverse_if_colliding(piece)
   next_x = PLAYFIELD_X + piece.x + piece.speed_x * piece.move_dir_x
   next_y = PLAYFIELD_Y + piece.y + piece.speed_y * piece.move_dir_y
   if not can_place(next_x, piece.y) then
      piece.move_dir_x *= -1
      next_x = PLAYFIELD_X + piece.x + piece.speed_x * piece.move_dir_x
   end
end

local function handle_changing_direction(piece)
   if (btn(Game.buttons.x) or btn(Game.buttons.o) or mb == 1 or mb == 2)
      and not button_pressed then
      piece.move_dir_x *= -1
      button_pressed = true
   end
   if not (btn(Game.buttons.x) or btn(Game.buttons.o) or mb ~= 0) then
      button_pressed = false
   end
end

local function handle_moving_horizontally(piece)
   horizontal_move_timer -= 1
   if horizontal_move_timer <= 0 then
      -- we only check horizontally if we are moving horizontally
      if can_place(next_x, piece.y) then
         -- add sound each time we move horizontally
         piece.x += piece.speed_x * piece.move_dir_x
      end
      horizontal_move_timer = horizontal_movement_delay
   end
end

local function handle_moving_vertically(piece)
   vertical_move_timer -= 1
   if vertical_move_timer <= 0 then
      -- we check both horizontally and vertically if we are moving vertically
      if can_place(next_x, next_y) then
         -- add another sound each time we move vertically
         piece.y += piece.speed_y * piece.move_dir_y
      end
      vertical_move_timer = vertical_movement_delay
   end
end

local function test_movement(piece)
   if btnp(Game.buttons.left) then
      piece.speed_x = 1
      piece.move_dir_x = -1
   elseif btnp(Game.buttons.right) then
      piece.speed_x = 1
      piece.move_dir_x = 1
   else
      piece.speed_x = 0
   end
   if btnp(Game.buttons.up) then
      piece.speed_y = 1
      piece.move_dir_y = -1
   elseif btnp(Game.buttons.down) then
      piece.speed_y = 1
      piece.move_dir_y = 1
   else
      piece.speed_y = 0
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   self.piece = spawn_new_piece()
end

function Play:update()
   mx, my, mb = mouse()
   reverse_if_colliding(self.piece)
   -- test_movement(self.piece)
   set_piece(self.piece.x, self.piece.y)
   handle_changing_direction(self.piece)
   handle_moving_horizontally(self.piece)
   handle_moving_vertically(self.piece)
end

function Play:draw()
   cls()
   --- @diagnostic disable-next-line: missing-parameter
   map()
   map(play_map, 0, 0, PLAYFIELD_X * TILE_WIDTH, PLAYFIELD_Y * TILE_HEIGHT)
   print("HMT:"..horizontal_move_timer, 10, 10, 8)
   -- print("PX:"..self.piece.x, 10, 20, 8)
   print("PDIR:"..self.piece.move_dir_x, 10, 30, 8)
   print("nextx:"..mget(next_x, self.piece.y), 10, 40, 8)
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
