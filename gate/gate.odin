package gate

import rl "vendor:raylib"

// Define gate properties
Gate :: struct {
	rect:   rl.Rectangle,
	is_open: bool,
}
