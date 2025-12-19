local Play = SceneManager:addState("Play")

local mx, my, mb = 0, 0, 0
local button_pressed = false
local PIECE_START_X = 200
local PIECE_START_Y = 8
local PIECE_SPEED_X = 1
local PIECE_SPEED_Y = 4
local lock_delay = 30
local mymap = userdata("i16", 30, 17) -- placeholder for map data

local function spawn_new_piece(piece)
   -- For now, just reset the piece to the top
   -- In the future, we would randomize the piece type
   -- and set its initial position accordingly
   piece.x = PIECE_START_X
   piece.y = PIECE_START_Y
   piece.speed_x = PIECE_SPEED_X
   piece.speed_y = 0
end

local function lock_piece(piece)
   local hitbox = piece.hitboxes[piece.hitbox + 1]
   piece.y = SCREEN_HEIGHT - BOTTOM_HEIGHT - (hitbox.y + hitbox.h)
   piece.speed_x = 0
   spawn_new_piece(piece)
   lock_delay = 30
end

local function wall_collision(piece, next_hitbox, wall)
   return wall == "left" and piece.x < PLAYING_FIELD_LEFT - next_hitbox.x
      or wall == "right" and piece.x > PLAYING_FIELD_RIGHT - (next_hitbox.x + next_hitbox.w)
      or false
end

local function landed_piece(piece)
   local hitbox = piece.hitboxes[piece.hitbox + 1]
   return piece.y + hitbox.y + hitbox.h >= SCREEN_HEIGHT - BOTTOM_HEIGHT
end

local function can_rotate(piece, rotation_direction)
   if rotation_direction == 0 then return true end
   local orientation = piece.orientations[piece.orientation + 1]
   local wall = ({
      down = {[1] = "left", [-1] = "right"},
      up   = {[1] = "right", [-1] = "left"}
   })[orientation] and ({
      down = {[1] = "left", [-1] = "right"},
      up   = {[1] = "right", [-1] = "left"}
   })[orientation][rotation_direction] or nil

   local next_hitbox = piece.hitboxes[(piece.hitbox + rotation_direction) % 4 + 1]

   -- Check for wall collision if needed
   if wall and wall_collision(piece, next_hitbox, wall) then
      return false
   end

   -- Check for collision with well bottom
   local next_y = piece.y
   if next_y + next_hitbox.y + next_hitbox.h > SCREEN_HEIGHT - BOTTOM_HEIGHT then
      return false
   end

   return true
end

local function handle_rotation(piece)
   local rotation_direction = 0
   if (btn(Game.buttons.x) or mb == 1) and not button_pressed then
      rotation_direction = 1
      button_pressed = true
   elseif (btn(Game.buttons.o) or mb == 2) and not button_pressed then
      rotation_direction = -1
      button_pressed = true
   end
   if not (btn(Game.buttons.x) or btn(Game.buttons.o) or mb ~= 0) then
      button_pressed = false
   end
   if can_rotate(piece, rotation_direction) then
      piece.sprite = (piece.sprite + rotation_direction) % 4 + 8
      piece.hitbox = (piece.hitbox + rotation_direction) % 4
      piece.orientation = (piece.orientation + rotation_direction) % 4
   end
end

local function handle_moving_horizontally(piece)
   local hitbox = piece.hitboxes[piece.hitbox + 1]
   if piece.x > PLAYING_FIELD_RIGHT - (hitbox.x + hitbox.w) or piece.x < PLAYING_FIELD_LEFT - hitbox.x then
      piece.move_dir_x *= -1
   end
end

local function handle_moving_down(piece)
   if btn(Game.buttons.o) and btn(Game.buttons.x) or mb == 3 then
      piece.speed_y = PIECE_SPEED_Y
      piece.speed_x = 0
   else
      piece.speed_x = PIECE_SPEED_X
      piece.speed_y = 0
   end
   if landed_piece(piece) then
      piece.speed_y = 0
      lock_delay -= 1
   end
end

local function handle_locking(piece)
   if lock_delay <= 0 then
      lock_piece(piece)
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   self.piece = {
      sprite = 8,
      x = PIECE_START_X,
      y = PIECE_START_Y,
      width = 51,
      height = 51,
      orientation = 0,
      hitbox = 0,
      hitboxes = {
         {x = 17, y = 17, w = 32, h = 15}, -- right
         {x = 17, y = 17, w = 15, h = 32}, -- down
         {x = 0, y = 17, w = 32, h = 15}, -- left
         {x = 17, y = 0, w = 15, h = 32}, -- up
      },
      orientations = {
         "right",
         "down",
         "left",
         "up",
      },
      move_dir_x = 1,
      speed_x = 1,
      speed_y = 0,
   }
   mymap = map()
end

function Play:update()
   mx, my, mb = mouse()
   handle_rotation(self.piece)
   handle_moving_horizontally(self.piece)
   handle_moving_down(self.piece)
   handle_locking(self.piece)
   self.piece.x += self.piece.speed_x * self.piece.move_dir_x
   self.piece.y += self.piece.speed_y
end

function Play:draw()
   cls(0)
   map()

   spr(self.piece.sprite, self.piece.x, self.piece.y)
   print("pspd_x: " .. self.piece.speed_x, 10, 10, 8)
   print("pspd_y: " .. self.piece.speed_y, 10, 20, 8)
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
