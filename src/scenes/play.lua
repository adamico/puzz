local Play = SceneManager:addState("Play")

local mx, my = 0, 0

local function wall_collision(piece, next_hitbox, wall)
   return wall == "left" and piece.x < PLAYING_FIELD_LEFT - next_hitbox.x
      or wall == "right" and piece.x > PLAYING_FIELD_RIGHT - (next_hitbox.x + next_hitbox.w)
      or false
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
   if not wall then return true end
   local next_hitbox = piece.hitboxes[(piece.hitbox + rotation_direction) % 4 + 1]
   return not wall_collision(piece, next_hitbox, wall)
end

local function handle_rotation(piece)
   local rotation_direction = 0
   if btnp(Game.controls.turn_clockwise) then
      rotation_direction = 1
   elseif btnp(Game.controls.turn_counterclockwise) then
      rotation_direction = -1
   end
   if can_rotate(piece, rotation_direction) then
      piece.sprite = (piece.sprite + rotation_direction) % 4 + 8
      piece.hitbox = (piece.hitbox + rotation_direction) % 4
      piece.orientation = (piece.orientation + rotation_direction) % 4
   end
end

local function auto_move(piece)
   piece.x += piece.move_dir_x
   local hitbox = piece.hitboxes[piece.hitbox + 1]
   if piece.x > PLAYING_FIELD_RIGHT - (hitbox.x + hitbox.w) or piece.x < PLAYING_FIELD_LEFT - hitbox.x then
      piece.move_dir_x *= -1
   end
end

function Play:enteredState()
   Log.trace("Entered Play scene")
   self.piece = {
      sprite = 8,
      x = 200,
      y = 20,
      width = 51,
      height = 51,
      move_dir_x = 1,
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
      }

   }
end

function Play:update()
   handle_rotation(self.piece)
   auto_move(self.piece)
   mx, my = mouse()
end

function Play:draw()
   cls(0)
   map()

   spr(self.piece.sprite, self.piece.x, self.piece.y)
   print("mx:"..mx.." my:"..my, 0, 120, 7)
end

function Play:exitedState()
   Log.trace("Exited Play scene")
end

return Play
