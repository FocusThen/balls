package button

import rl "vendor:raylib"

// Define button properties
Button :: struct {
	rect:          rl.Rectangle,
	color:         rl.Color,
	text:          string,
	text_color:    rl.Color,
	// Index of the player who can interact with this button
	interactive_player_index: int,
}

// You could add button-specific procedures here later, e.g.:
// draw_button :: proc(button: ^Button) { ... }
// is_clicked :: proc(button: ^Button) -> bool { ... }

