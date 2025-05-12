package player

import rl "vendor:raylib"

// Define player properties
Player :: struct {
	position: rl.Vector2,
	speed:    rl.Vector2,
	color:    rl.Color,
	// Input keys for this player
	key_up:    rl.KeyboardKey,
	key_down:  rl.KeyboardKey,
	key_left:  rl.KeyboardKey,
	key_right: rl.KeyboardKey,
  // Interaction key for this player
	interact_key: rl.KeyboardKey,
}

// You could add player-specific procedures here later, e.g.:
// update_movement :: proc(player: ^Player, dt: f32) { ... }
// draw_player :: proc(player: ^Player) { ... }

