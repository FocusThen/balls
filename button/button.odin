package button

import rl "vendor:raylib"

// Define button properties
Button :: struct {
	rect:          rl.Rectangle,
	color:         rl.Color, // Used for visual feedback (e.g., pressed state)
	text:          string,
	text_color:    rl.Color,
	// Index of the player who can interact with this button
	interactive_player_index: int,
	is_pressed:              bool, // New: Track if this specific button is pressed
	// Optional: Add a unique ID or type for the button if needed for specific requirements
	// id: int,
	// button_type: ButtonType,
}

// Optional: Enum for different button types if needed for complex logic
// ButtonType :: enum {
//     NORMAL,
//     GATE_OPEN_P1,
//     GATE_OPEN_P2,
//     // ... other types
// }
