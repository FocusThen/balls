package game

import "core:fmt"
import "core:math"
import "core:strings"
import "core:time"
import rl "vendor:raylib"

import "./button"
import "./gate"
import "./player"

// Define player movement speed
PLAYER_SPEED :: 300.0 // Pixels per second
// BALL_RADIUS will be set relative to TILE_SIZE
BUTTON_SIZE :: 40.0 // Size of the button rectangle
// GATE_SIZE will be based on TILE_SIZE

// Map dimensions (assuming all maps have the same dimensions for simplicity)
MAP_WIDTH :: 21
MAP_HEIGHT :: 11

// Map definitions for different levels
// 0: Empty space, 9: Wall, 1: Player 1 Start, 2: Player 2 Start,
// 3: Button P1, 4: Button P2, 8: Gate, 7: Exit Area
level_maps := [][MAP_HEIGHT][MAP_WIDTH]int {
	// Level 1 Map
	{
		{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 0, 1, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 2, 0, 9},
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 7, 9, 7, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 0, 0, 0, 0, 0, 3, 0, 0, 7, 8, 7, 0, 0, 0, 4, 0, 0, 0, 0, 9}, // Buttons and Gate in this row
		{9, 0, 9, 9, 9, 0, 0, 0, 0, 7, 9, 7, 0, 0, 0, 9, 9, 9, 0, 0, 9},
		{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9},
		{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9},
		{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9}, // Exit Area
		{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
	},
	// Level 2 Map (Example - Different Layout, Exit in different location)
	{
		{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
		{9, 7, 7, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9}, // Exit Area
		{9, 0, 0, 0, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 0, 2, 0, 9},
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 9},
		{9, 0, 0, 0, 9, 3, 0, 0, 0, 0, 8, 0, 0, 0, 0, 4, 9, 0, 0, 0, 9}, // Buttons and Gate
		{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 9},
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 0, 1, 0, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 0, 0, 0, 9}, // Player 1 Start
		{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
		{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
	},
}

// Enum for different game states
GameStateType :: enum {
	MAIN_MENU,
	LEVEL_SELECT,
	IN_GAME,
	// Add other states like GAME_OVER, WIN_SCREEN
}

// Structures for managing game and level state
@(private)
LevelState :: struct {
	walls:                  [dynamic]rl.Rectangle,
	buttons:                [dynamic]button.Button,
	the_gate:               gate.Gate,
	player_start_positions: [2]rl.Vector2,
	exit_area:              rl.Rectangle,
	// New: Required button indices to open the gate for this level
	gate_open_requirements: [dynamic]int,
	// Add other level-specific entities here (e.g., enemies, collectibles)
}

@(private)
GameState :: struct {
	current_game_state: GameStateType,
	current_level:      int,
	level_state:        LevelState,
	players:            [2]player.Player, // Players can persist across levels
	completed_levels:   [dynamic]bool, // Track completed levels
	// Add other global game state here (e.g., score, lives)
}

// Global game state instance
game_state: GameState

// Define fixed timestep variables
FIXED_DELTA_TIME :: 1.0 / 60.0 // 60 updates per second
accumulator: f64 = 0.0

// Calculated tile sizes
tile_width: f32
tile_height: f32

// Calculated ball radius (relative to tile size)
BALL_RADIUS: f32

// Calculated near threshold for button interaction (runtime variable)
NEAR_THRESHOLD: f32

// UI related variables
MAIN_MENU_START_BUTTON_RECT: rl.Rectangle
LEVEL_SELECT_BUTTON_RECTS: [dynamic]rl.Rectangle // Rectangles for each level select button


// Initialize the game state
game_init :: proc() {
	// Calculate tile sizes based on screen dimensions and map layout (using the first level for initial calculation)
	tile_width = f32(SCREEN_WIDTH) / f32(MAP_WIDTH)
	tile_height = f32(SCREEN_HEIGHT) / f32(MAP_HEIGHT)

	// Calculate ball radius (make it slightly smaller than half a tile)
	BALL_RADIUS = math.min(tile_width, tile_height) / 2.0 - 2.0 // Subtract a small gap

	// Initialize the near threshold for button interaction
	NEAR_THRESHOLD = tile_width * 0.8


	// Initialize players once (they persist)
	game_state.players[0] = player.Player {
		position     = {0.0, 0.0}, // Initial dummy position
		speed        = {0.0, 0.0},
		color        = rl.MAROON,
		key_up       = .W,
		key_down     = .S,
		key_left     = .A,
		key_right    = .D,
		interact_key = .E,
	}
	game_state.players[1] = player.Player {
		position     = {0.0, 0.0}, // Initial dummy position
		speed        = {0.0, 0.0},
		color        = rl.BLUE,
		key_up       = .I,
		key_down     = .K,
		key_left     = .J,
		key_right    = .L,
		interact_key = .U,
	}

	// Initialize completed levels slice
	game_state.completed_levels = make([dynamic]bool, len(level_maps)) // One boolean per level

	// Initialize UI elements (Main Menu and Level Select buttons)
	init_ui_elements()

	// Start in the main menu
	game_state.current_game_state = .MAIN_MENU
}

// Initializes UI elements like buttons for main menu and level select
@(private)
init_ui_elements :: proc() {
	// Main Menu Start Button
	MAIN_MENU_START_BUTTON_RECT = {
		SCREEN_WIDTH / 2.0 - 100.0,
		SCREEN_HEIGHT / 2.0 - 25.0,
		200.0,
		50.0,
	}

	// Level Select Buttons
	// Clear existing level select buttons
	delete(LEVEL_SELECT_BUTTON_RECTS)
	LEVEL_SELECT_BUTTON_RECTS = make([dynamic]rl.Rectangle, len(level_maps))

	button_width :: 100.0
	button_height :: 50.0
	start_x: f32
	total_buttons_width := f32(len(level_maps)) * button_width + f32(len(level_maps) - 1) * gap
	start_x = SCREEN_WIDTH / 2.0 - total_buttons_width / 2.0
	start_y :: SCREEN_HEIGHT / 2.0 - button_height / 2.0
	gap :: 10.0

	for i := 0; i < len(level_maps); i += 1 {
		LEVEL_SELECT_BUTTON_RECTS[i] = {
			start_x + f32(i) * (button_width + gap),
			start_y,
			button_width,
			button_height,
		}
	}
}


// Loads the data for a specific level
load_level :: proc(level_index: int) {
	if level_index < 0 || level_index >= len(level_maps) {
		fmt.println("Error: Invalid level index:", level_index)
		// Handle game over or looping back to level 1
		return
	}

	game_state.current_level = level_index
	current_map := level_maps[level_index]

	// Generate the game world for this level
	generate_world(current_map)

	// Set player positions based on the loaded level's start positions
	game_state.players[0].position = game_state.level_state.player_start_positions[0]
	game_state.players[1].position = game_state.level_state.player_start_positions[1]

	// Reset button pressed states for the new level (by resetting their color to GRAY)
	for i := 0; i < len(game_state.level_state.buttons); i += 1 {
		game_state.level_state.buttons[i].is_pressed = false // Reset the new 'is_pressed' field
		game_state.level_state.buttons[i].color = rl.GRAY // Reset color
	}

	// Reset the gate state for the new level
	game_state.level_state.the_gate.is_open = false

	// Change game state to IN_GAME
	game_state.current_game_state = .IN_GAME
}

// Update game state
game_update :: proc(delta_time: f32) {
	// Handle input and update based on the current game state
	switch game_state.current_game_state {
	case .MAIN_MENU:
		update_main_menu()
	case .LEVEL_SELECT:
		update_level_select()
	case .IN_GAME:
		update_in_game(delta_time)
	// Add cases for other game states
	}
}

// Update logic for the Main Menu state
@(private)
update_main_menu :: proc() {
	// Check for mouse click on the Start button
	if rl.IsMouseButtonPressed(.LEFT) {
		mouse_position := rl.GetMousePosition()
		if rl.CheckCollisionPointRec(mouse_position, MAIN_MENU_START_BUTTON_RECT) {
			// Clicked the Start button, change to Level Select state
			game_state.current_game_state = .LEVEL_SELECT
		}
	}
}

// Update logic for the Level Select state
@(private)
update_level_select :: proc() {
	// Check for mouse clicks on level buttons
	if rl.IsMouseButtonPressed(.LEFT) {
		mouse_position := rl.GetMousePosition()

		for i := 0; i < len(LEVEL_SELECT_BUTTON_RECTS); i += 1 {
			button_rect := LEVEL_SELECT_BUTTON_RECTS[i]
			if rl.CheckCollisionPointRec(mouse_position, button_rect) {
				// Check if the level is unlocked
				if i == 0 || (i > 0 && game_state.completed_levels[i - 1]) {
					// Clicked an unlocked level, load it
					load_level(i)
				} else {
					fmt.println("Level", i + 1, "is locked!")
				}
				break // Only interact with one button per click
			}
		}
	}
}

// Update logic for the In-Game state
@(private)
update_in_game :: proc(delta_time: f32) {
	accumulator += f64(delta_time)

	// Fixed Timestep Update Loop
	for accumulator >= FIXED_DELTA_TIME {
		update_logic(f32(FIXED_DELTA_TIME))
		accumulator -= FIXED_DELTA_TIME
	}
}


// Game logic update (fixed timestep) - Only runs in IN_GAME state
@(private)
update_logic :: proc(dt: f32) {
	// Update each player
	for player_index := 0; player_index < len(game_state.players); player_index += 1 {
		player_ptr := &game_state.players[player_index]

		// Store the previous position before updating
		previous_position := player_ptr.position

		// Reset player speed before checking input
		player_ptr.speed = {0.0, 0.0}

		// Check for input keys and update player speed
		if rl.IsKeyDown(player_ptr.key_up) {
			player_ptr.speed.y = -PLAYER_SPEED
		}
		if rl.IsKeyDown(player_ptr.key_down) {
			player_ptr.speed.y = PLAYER_SPEED
		}
		if rl.IsKeyDown(player_ptr.key_left) {
			player_ptr.speed.x = -PLAYER_SPEED
		}
		if rl.IsKeyDown(player_ptr.key_right) {
			player_ptr.speed.x = PLAYER_SPEED
		}

		// Normalize diagonal movement (optional)
		speed_magnitude := rl.Vector2Length(player_ptr.speed)
		if speed_magnitude > PLAYER_SPEED {
			player_ptr.speed = rl.Vector2Normalize(player_ptr.speed) * PLAYER_SPEED
		}

		// Move the player based on their speed and the fixed delta time
		player_ptr.position.x += player_ptr.speed.x * dt
		player_ptr.position.y += player_ptr.speed.y * dt


		// --- Collision Detection with Walls ---
		for wall_index := 0; wall_index < len(game_state.level_state.walls); wall_index += 1 {
			wall := game_state.level_state.walls[wall_index]

			// Check for collision between the player circle (position and radius) and the wall rectangle
			if rl.CheckCollisionCircleRec(player_ptr.position, BALL_RADIUS, wall) {
				// Collision occurred! Revert to the previous position to prevent going through
				player_ptr.position = previous_position
				// Optional: Adjust position slightly away from the wall if desired for smoother collision response
				break // Stop checking against other walls if a collision is found (for simplicity)
			}
		}

		// --- Collision Detection with Closed Gate ---
		// The gate is now a rectangle in the map
		if !game_state.level_state.the_gate.is_open {
			// Check for collision between the player circle (position and radius) and the gate rectangle
			if rl.CheckCollisionCircleRec(
				player_ptr.position,
				BALL_RADIUS,
				game_state.level_state.the_gate.rect,
			) {
				// Collision occurred with the closed gate! Revert position.
				player_ptr.position = previous_position
				// Optional: Adjust position away from the gate
			}
		}

		// Check for level completion condition
		check_level_completion()
	}

	// Handle button interactions
	handle_button_interactions()

	// Check if the gate open condition is met for the current level
	check_gate_open_condition()

	// TODO: Add collision detection between the balls if desired
}

// Checks for level completion condition - Only runs in IN_GAME state
@(private)
check_level_completion :: proc() {
	// Only check level completion while in-game
	if game_state.current_game_state != .IN_GAME {
		return
	}

	// Level is complete if the gate is open AND both players are in the exit area
	if game_state.level_state.the_gate.is_open {
		player1_in_exit := rl.CheckCollisionCircleRec(
			game_state.players[0].position,
			BALL_RADIUS,
			game_state.level_state.exit_area,
		)
		player2_in_exit := rl.CheckCollisionCircleRec(
			game_state.players[1].position,
			BALL_RADIUS,
			game_state.level_state.exit_area,
		)

		if player1_in_exit && player2_in_exit {
			fmt.println("Level", game_state.current_level + 1, "completed!")

			// Mark the current level as completed
			if game_state.current_level < len(game_state.completed_levels) {
				game_state.completed_levels[game_state.current_level] = true
			}

			// Load the next level or transition to a win screen
			if game_state.current_level + 1 < len(level_maps) {
				load_level(game_state.current_level + 1)
			} else {
				fmt.println("All levels completed! Game Over (Win)!")
				// Transition to a win screen or main menu
				game_state.current_game_state = .MAIN_MENU // Example: loop back to main menu
			}
		}
	}
}


// Handles interactions with buttons for the current level - Only runs in IN_GAME state
@(private)
handle_button_interactions :: proc() {
	// Only handle button interactions while in-game
	if game_state.current_game_state != .IN_GAME {
		return
	}

	// Iterate through buttons in the current level state
	for button_index := 0; button_index < len(game_state.level_state.buttons); button_index += 1 {
		button_ptr := &game_state.level_state.buttons[button_index]

		// Get the player who can interact with this button
		interactive_player_index := button_ptr.interactive_player_index
		interactive_player := &game_state.players[interactive_player_index] // Access player from game_state

		// Check if the interactive player is near the button
		distance_to_button := rl.Vector2Distance(
			interactive_player.position,
			{
				button_ptr.rect.x + button_ptr.rect.width / 2.0,
				button_ptr.rect.y + button_ptr.rect.height / 2.0,
			},
		)

		// Check distance against the calculated NEAR_THRESHOLD
		if distance_to_button <= (BALL_RADIUS + NEAR_THRESHOLD) {
			// Player is near, now check if they pressed their interaction key
			if rl.IsKeyPressed(interactive_player.interact_key) {
				// The interactive player pressed their interaction key while near the button!
				fmt.println(
					"Player",
					interactive_player_index + 1,
					"interacted with button",
					button_index + 1,
					"!",
				)

				// Mark the specific button as pressed
				button_ptr.is_pressed = true // Set the 'is_pressed' field
				button_ptr.color = rl.GREEN // Indicate this button is pressed visually

				// Note: If you wanted buttons to only be pressable once,
				// you would add a check here: if !button_ptr.is_pressed { ... }
			}
		}
	}
}

// Checks the gate open condition for the current level - Only runs in IN_GAME state
@(private)
check_gate_open_condition :: proc() {
	// Only check gate condition while in-game
	if game_state.current_game_state != .IN_GAME {
		return
	}

	// Check if all required buttons for this level's gate are pressed
	// This is now more flexible using the 'gate_open_requirements' slice in LevelState.
	all_required_pressed := true
	for required_button_index := 0;
	    required_button_index < len(game_state.level_state.gate_open_requirements);
	    required_button_index += 1 {
		button_index := game_state.level_state.gate_open_requirements[required_button_index]
		// Ensure the required button index is valid
		if button_index < 0 || button_index >= len(game_state.level_state.buttons) {
			fmt.println(
				"Error: Invalid required button index in gate_open_requirements:",
				button_index,
			)
			all_required_pressed = false
			break // Stop checking if an invalid requirement is found
		}
		button_ptr := &game_state.level_state.buttons[button_index]
		if !button_ptr.is_pressed {
			all_required_pressed = false // If any required button is NOT pressed, the condition is not met
			break
		}
	}


	if all_required_pressed {
		if !game_state.level_state.the_gate.is_open {
			fmt.println("Required buttons pressed! Opening the gate!")
			game_state.level_state.the_gate.is_open = true
			// Optional: Change gate color or play a sound
		}
	} else {
		// Optional: If the gate should close when buttons are no longer pressed
		// (Requires buttons to have a way to become unpressed)
		// if game_state.level_state.the_gate.is_open {
		//     fmt.println("Gate closing!")
		//     game_state.level_state.the_gate.is_open = false
		// }
	}
}

// Generates the game world (walls, buttons, gate, players, exit area) from the map layout
@(private)
generate_world :: proc(current_map: [MAP_HEIGHT][MAP_WIDTH]int) {
	// Clear existing entities before generating
	delete(game_state.level_state.walls)
	game_state.level_state.walls = make([dynamic]rl.Rectangle, 0, MAP_WIDTH * MAP_HEIGHT) // Use 0 initial length and capacity

	delete(game_state.level_state.buttons)
	game_state.level_state.buttons = make([dynamic]button.Button, 0, 5) // Initial capacity for buttons (adjust as needed)

	// Reset the gate state (handled in load_level)
	// game_state.level_state.the_gate.is_open = false

	// Temporary storage for player start positions found in map
	player_start_positions: [2]rl.Vector2
	// Temporary storage for exit area coordinates
	exit_min_x: f32 = f32(SCREEN_WIDTH) // Initialize with a value larger than any possible x
	exit_min_y: f32 = f32(SCREEN_HEIGHT) // Initialize with a value larger than any possible y
	exit_max_x: f32 = 0.0 // Initialize with a value smaller than any possible x
	exit_max_y: f32 = 0.0 // Initialize with a value smaller than any possible y

	// Flag to ensure exit area tiles are found
	exit_tiles_found := false


	for y := 0; y < MAP_HEIGHT; y += 1 {
		for x := 0; x < MAP_WIDTH; x += 1 {
			tile_value := current_map[y][x]

			// Calculate the top-left corner position of the current tile
			tile_pos_x := f32(x) * tile_width
			tile_pos_y := f32(y) * tile_height

			// Calculate the center position of the current tile
			tile_center_x := tile_pos_x + tile_width / 2.0
			tile_center_y := tile_pos_y + tile_height / 2.0


			switch tile_value {
			case 9:
				// Wall tile
				wall_rect := rl.Rectangle{tile_pos_x, tile_pos_y, tile_width, tile_height}
				append(&game_state.level_state.walls, wall_rect) // Append to level_state walls

			case 1:
				// Player 1 Start
				player_start_positions[0] = {tile_center_x, tile_center_y} // Store center of tile

			case 2:
				// Player 2 Start
				player_start_positions[1] = {tile_center_x, tile_center_y} // Store center of tile

			case 3:
				// Button for Player 1
				button_rect_size := BUTTON_SIZE
				// Ensure button is smaller than the tile
				if button_rect_size > f64(tile_width) || button_rect_size > f64(tile_height) {
					button_rect_size = f64(math.min(tile_width, tile_height)) * 0.8 // Make button 80% of the smallest tile dimension
				}
				button_to_append := button.Button {
					rect                     = {
						f32(f64(tile_center_x) - button_rect_size / 2.0), // Center button in tile
						f32(f64(tile_center_y) - button_rect_size / 2.0), // Center button in tile
						f32(button_rect_size),
						f32(button_rect_size),
					},
					color                    = rl.GRAY,
					text                     = fmt.aprintf(
						"P1 Btn %d",
						len(game_state.level_state.buttons) + 1,
					), // Use current number of buttons + 1 for text
					text_color               = rl.BLACK,
					interactive_player_index = 0, // Player 0 can interact
					is_pressed               = false, // Initialize is_pressed to false
				}
				// Check if this button is required for the gate based on the current level and tile value
				if game_state.current_level == 0 { 	// Level 1 Requirements
					if tile_value == 3 { 	// The P1 button in Level 1 is required (tile 3)
						// Append the index *where this button will be* in the buttons slice
						append(
							&game_state.level_state.gate_open_requirements,
							len(game_state.level_state.buttons),
						)
					}
				} else if game_state.current_level == 1 { 	// Level 2 Requirements
					// For Level 2, let's say the P1 button at tile (5,5) and the P1 button at tile (2,8) are required (both tile 3)
					// This is still a bit based on map structure, a more generic way would be to have different tile types like 'REQUIRED_BUTTON_P1_GATE'
					// For now, based on the map layout provided:
					if (x == 5 && y == 5) || (x == 2 && y == 8) { 	// Check the coordinates of the required P1 buttons in Level 2 map
						append(
							&game_state.level_state.gate_open_requirements,
							len(game_state.level_state.buttons),
						)
					}
				}
				append(&game_state.level_state.buttons, button_to_append) // Append to level_state buttons


			case 4:
				// Button for Player 2
				button_rect_size := BUTTON_SIZE
				// Ensure button is smaller than the tile
				if button_rect_size > f64(tile_width) || button_rect_size > f64(tile_height) {
					button_rect_size = f64(math.min(tile_width, tile_height)) * 0.8 // Make button 80% of the smallest tile dimension
				}
				button_to_append := button.Button {
					rect                     = {
						f32(f64(tile_center_x) - button_rect_size / 2.0), // Center button in tile
						f32(f64(tile_center_y) - button_rect_size / 2.0), // Center button in tile
						f32(button_rect_size),
						f32(button_rect_size),
					},
					color                    = rl.GRAY,
					text                     = fmt.aprintf(
						"P2 Btn %d",
						len(game_state.level_state.buttons) + 1,
					), // Use current number of buttons + 1 for text
					text_color               = rl.BLACK,
					interactive_player_index = 1, // Player 1 can interact
				}
				// Check if this button is required for the gate based on the current level and tile value
				if game_state.current_level == 0 { 	// Level 1 Requirements
					if tile_value == 4 { 	// The P2 button in Level 1 is required (tile 4)
						// Append the index *where this button will be* in the buttons slice
						append(
							&game_state.level_state.gate_open_requirements,
							len(game_state.level_state.buttons),
						)
					}
				} else if game_state.current_level == 1 { 	// Level 2 Requirements
					// For Level 2, let's say the P2 button at tile (16,5) is required (tile 4)
					if x == 16 && y == 5 { 	// Check the coordinates of the required P2 button in Level 2 map
						append(
							&game_state.level_state.gate_open_requirements,
							len(game_state.level_state.buttons),
						)
					}
				}
				append(&game_state.level_state.buttons, button_to_append) // Append to level_state buttons


			case 8:
				// Gate tile
				// Position the gate to cover the full tile it's placed on
				game_state.level_state.the_gate = gate.Gate { 	// Initialize gate in level_state
					rect    = {tile_pos_x, tile_pos_y, tile_width, tile_height},
					is_open = false,
				}

			case 7:
				// Exit Area tile - Assuming a contiguous exit area, combine adjacent tiles
				// Track the min/max coordinates of all exit area tiles
				exit_min_x = math.min(exit_min_x, tile_pos_x)
				exit_min_y = math.min(exit_min_y, tile_pos_y)
				exit_max_x = math.max(exit_max_x, tile_pos_x + tile_width)
				exit_max_y = math.max(exit_max_y, tile_pos_y + tile_height)
				exit_tiles_found = true // Mark that at least one exit tile was found


			case 0:
				// Empty space - do nothing
				continue
			}
		}
	}

	// After iterating through the map, calculate the final exit area rectangle
	if exit_tiles_found {
		game_state.level_state.exit_area = {
			exit_min_x,
			exit_min_y,
			exit_max_x - exit_min_x, // Width
			exit_max_y - exit_min_y, // Height
		}
	} else {
		// If no exit tiles were found, set the exit area to an invalid rectangle
		// This will prevent accidental level completion.
		game_state.level_state.exit_area = {0.0, 0.0, 0.0, 0.0}
		fmt.println(
			"Warning: Level",
			game_state.current_level + 1,
			"has no exit area defined (tile 7). Level cannot be completed.",
		)
	}


	// Store player start positions in the level state
	game_state.level_state.player_start_positions = player_start_positions
}


// Draw the game state
game_draw :: proc() {
	rl.BeginDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	// Draw based on the current game state
	switch game_state.current_game_state {
	case .MAIN_MENU:
		draw_main_menu()
	case .LEVEL_SELECT:
		draw_level_select()
	case .IN_GAME:
		draw_in_game()
	// Add cases for other game states
	}


	// Draw FPS for debugging (this is the rendering FPS)
	rl.DrawFPS(10, 10)

	rl.EndDrawing()
}

// Draws the main menu UI
@(private)
draw_main_menu :: proc() {
	rl.DrawText(
		"Co-Op Game",
		SCREEN_WIDTH / 2 - rl.MeasureText("Co-Op Game", 40) / 2,
		SCREEN_HEIGHT / 4,
		40,
		rl.BLACK,
	)
	rl.DrawRectangleRec(MAIN_MENU_START_BUTTON_RECT, rl.BLUE)
	button_text := "Start Game"
	text_width := rl.MeasureText(strings.unsafe_string_to_cstring(button_text), 20)
	rl.DrawText(
		strings.unsafe_string_to_cstring(button_text),
		i32(
			MAIN_MENU_START_BUTTON_RECT.x +
			(MAIN_MENU_START_BUTTON_RECT.width - f32(text_width)) / 2.0,
		),
		i32(MAIN_MENU_START_BUTTON_RECT.y + (MAIN_MENU_START_BUTTON_RECT.height - 20) / 2.0),
		20,
		rl.WHITE,
	)
}

// Draws the level select UI
@(private)
draw_level_select :: proc() {
	rl.DrawText(
		"Select Level",
		SCREEN_WIDTH / 2 - rl.MeasureText("Select Level", 30) / 2,
		SCREEN_HEIGHT / 4,
		30,
		rl.BLACK,
	)

	for i := 0; i < len(LEVEL_SELECT_BUTTON_RECTS); i += 1 {
		button_rect := LEVEL_SELECT_BUTTON_RECTS[i]
		button_text := fmt.aprintf("Level %d", i + 1)
		text_width := rl.MeasureText(strings.unsafe_string_to_cstring(button_text), 20)

		button_color := rl.GRAY // Default color

		// Check if the level is completed or unlocked
		if i == 0 || (i > 0 && game_state.completed_levels[i - 1]) {
			button_color = rl.GREEN // Unlocked levels are green
			// Check if the level is already completed
			if game_state.completed_levels[i] {
				button_color = rl.GOLD // Completed levels are gold
			}
		} else {
			button_color = rl.RED // Locked levels are red
		}

		rl.DrawRectangleRec(button_rect, button_color)
		rl.DrawText(
			strings.unsafe_string_to_cstring(button_text),
			i32(button_rect.x + (button_rect.width - f32(text_width)) / 2.0),
			i32(button_rect.y + (button_rect.height - 20) / 2.0),
			20,
			rl.BLACK,
		)
	}
}

// Draws the in-game state (level entities and players)
@(private)
draw_in_game :: proc() {
	// Draw walls from the current level state
	for wall_index := 0; wall_index < len(game_state.level_state.walls); wall_index += 1 {
		wall := game_state.level_state.walls[wall_index]
		rl.DrawRectangleRec(wall, rl.BROWN) // Draw walls in brown
	}

	// Draw the gate from the current level state (draw it after walls but before players)
	if !game_state.level_state.the_gate.is_open {
		rl.DrawRectangleRec(game_state.level_state.the_gate.rect, rl.DARKBROWN) // Draw closed gate in dark brown
	}

	// Draw each player
	for player_index := 0; player_index < len(game_state.players); player_index += 1 {
		player_ptr := &game_state.players[player_index]
		rl.DrawCircleV(player_ptr.position, BALL_RADIUS, player_ptr.color)
	}

	// Draw each button from the current level state
	for button_index := 0; button_index < len(game_state.level_state.buttons); button_index += 1 {
		button_ptr := &game_state.level_state.buttons[button_index]
		rl.DrawRectangleRec(button_ptr.rect, button_ptr.color)

		// Draw button text
		text_width := rl.MeasureText(strings.unsafe_string_to_cstring(button_ptr.text), 10)
		rl.DrawText(
			strings.unsafe_string_to_cstring(button_ptr.text),
			i32(button_ptr.rect.x + (button_ptr.rect.width - f32(text_width)) / 2.0),
			i32(button_ptr.rect.y + (button_ptr.rect.height - 10) / 2.0),
			10,
			button_ptr.text_color,
		)
	}

  // Draw the exit area (draw it after other entities so it's on top)
  if game_state.level_state.the_gate.is_open {
		rl.DrawRectangleRec(game_state.level_state.exit_area, rl.LIME) // Example: Draw exit area in lime green
	}
}
