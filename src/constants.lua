SCREEN_WIDTH = 480
SCREEN_HEIGHT = 270
UI_HEIGHT = 48
GRID_SIZE = 16
STARTING_SEEDS = 10
PLAYING_FIELD_LEFT = 137
PLAYING_FIELD_RIGHT = 343
BOTTOM_HEIGHT = 8
Game = {
   title = "OBP",
   score = {
   },
   debug = {
      show_hitboxes = false,
      show_attributes = false,
   },
   cheats = {
      noclip = false,
      godmode = false,
   },
   buttons = {
      -- first stick
      left = 0,
      right = 1,
      up = 2,
      down = 3,
      o = 4,
      x = 5,
      menu = 6,
      reserved = 7,
      -- second stick
      left2 = 8,
      right2 = 9,
      up2 = 10,
      down2 = 11,
      o2 = 12,
      x2 = 13,
      sl2 = 14,
      sr2 = 15,
   }
}

Keys = {
   show_attributes = "f2",
   show_hitboxes = "f3",
   godmode = "f4",
   noclip = "f5",
   debug = "f6",
}