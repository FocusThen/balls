package game

import "core:fmt"
import rl "vendor:raylib"

// Define screen dimensions (can be moved to game package if preferred)
SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 450

main :: proc() {
	// Initialization
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Odin Raylib Organized Demo")
	rl.SetTargetFPS(60) // Cap rendering FPS, but game logic runs on fixed timestep

	game_init() // Initialize the game state from the game package

	// Game loop
	for !rl.WindowShouldClose() {
		// Calculate delta time for rendering
		delta_time := rl.GetFrameTime()

		// Update game state (handled by the game package)
		game_update(delta_time)

		// Drawing (handled by the game package)
		game_draw()
	}

	// De-initialization
	rl.CloseWindow()
}

