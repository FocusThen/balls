package game

import "core:fmt"
import "core:strings"
import "core:time" // Import fmt for printing in handle_button_interactions
import rl "vendor:raylib"

import "./button" // Import the 'player' package
import "./gate" // Import the 'gate' package
import "./player" // Import the 'button' package

// Define player movement speed (can be moved to player package)
PLAYER_SPEED :: 300.0 // Pixels per second
BALL_RADIUS :: 10.0
BUTTON_SIZE :: 50.0
GATE_WIDTH :: 20.0
GATE_HEIGHT :: 100.0


// Map definition
MAP_WIDTH :: 21
MAP_HEIGHT :: 11

// Using a 2D array for the map
// 0: Empty space
// 9: Wall
// 1: Player 1
// 2: Player 2
// 3: Button for Player 1
// 4: Button for Player 2
// 8: Gate
map_layout := [MAP_HEIGHT][MAP_WIDTH]int {
	{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
	{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
	{9, 0, 1, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 2, 0, 9},
	{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
	{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
	{9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9},
	{9, 0, 9, 9, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 9, 9, 0, 0, 9},
	{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9},
	{9, 0, 3, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 4, 0, 0, 9},
	{9, 0, 0, 0, 9, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9, 0, 0, 0, 0, 9},
	{9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9},
}


// Define fixed timestep variables
FIXED_DELTA_TIME :: 1.0 / 60.0 // 60 updates per second
accumulator: f64 = 0.0

// Arrays to hold game entities
players: [2]player.Player
buttons: [2]button.Button // We now have two buttons
the_gate: gate.Gate

// Track button pressed states
button_1_pressed: bool = false
button_2_pressed: bool = false

// Slice to hold wall rectangles (dynamic size based on map)
walls: [dynamic]rl.Rectangle

// Calculated tile sizes
tile_width: f32
tile_height: f32

// Initialize the game state
game_init :: proc() {
	// Calculate tile sizes based on screen dimensions and map layout
	tile_width = f32(SCREEN_WIDTH) / f32(MAP_WIDTH)
	tile_height = f32(SCREEN_HEIGHT) / f32(MAP_HEIGHT)

	// Generate the game world (walls, buttons, gate) from the map layout
	generate_world()
}

// Update game state
game_update :: proc(delta_time: f32) {
	accumulator += f64(delta_time)

	// Fixed Timestep Update Loop
	for accumulator >= FIXED_DELTA_TIME {
		// Update game logic with fixed delta time
		update_logic(f32(FIXED_DELTA_TIME))

		// Decrease the accumulator
		accumulator -= FIXED_DELTA_TIME
	}
}

// Game logic update (fixed timestep)
@(private)
update_logic :: proc(dt: f32) {
	// Update each player
	for player_index := 0; player_index < len(players); player_index += 1 {
		player_ptr := &players[player_index] // Get a pointer to the player

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
		player_ptr.position.y += player_ptr.speed.y * dt // Corrected line


		// --- Collision Detection with Walls ---
		for wall_index := 0; wall_index < len(walls); wall_index += 1 {
			wall := walls[wall_index]

			// Check for collision between the player circle (position and radius) and the wall rectangle
			if rl.CheckCollisionCircleRec(player_ptr.position, BALL_RADIUS, wall) {
				// Collision occurred! Revert to the previous position to prevent going through
				player_ptr.position = previous_position
				// Optional: Adjust position slightly away from the wall if desired for smoother collision response
				break // Stop checking against other walls if a collision is found (for simplicity)
			}
		}

		// --- Collision Detection with Closed Gate ---
		if !the_gate.is_open {
			// Check for collision between the player circle (position and radius) and the gate rectangle
			if rl.CheckCollisionCircleRec(player_ptr.position, BALL_RADIUS, the_gate.rect) {
				// Collision occurred with the closed gate! Revert position.
				player_ptr.position = previous_position
				// Optional: Adjust position away from the gate
			}
		}

		// Keep the player within overall screen bounds (optional, might be covered by walls)
		// player_ptr.position.x = rl.Clamp(player_ptr.position.x, BALL_RADIUS, main.SCREEN_WIDTH - BALL_RADIUS)
		// player_ptr.position.y = rl.Clamp(player_ptr.position.y, BALL_RADIUS, main.SCREEN_HEIGHT - BALL_RADIUS)
	}

	// Handle button interactions
	handle_button_interactions()

	// Check if both buttons are pressed and open the gate
	check_and_open_gate()

	// TODO: Add collision detection between the balls if desired
}

// Checks if both buttons are pressed and opens the gate
@(private)
check_and_open_gate :: proc() {
	if button_1_pressed && button_2_pressed {
		if !the_gate.is_open {
			fmt.println("Both buttons pressed! Opening the gate!")
			the_gate.is_open = true
			// Optional: Change gate color or play a sound
		}
	} else {
		// Optional: If you want the gate to close again if a button is "unpressed"
		// (which we don't have logic for yet), you would handle that here.
		// For this example, the gate stays open once triggered.
	}
}

// Generates the game world (walls, buttons, gate) from the map layout
@(private)
generate_world :: proc() {
	// Clear any existing walls
	delete(walls)
	walls = make([dynamic]rl.Rectangle, MAP_WIDTH * MAP_HEIGHT / 2) // Re-make with capacity

	// Keep track of how many buttons we've initialized
	button_count := 0

	for y := 0; y < MAP_HEIGHT; y += 1 {
		for x := 0; x < MAP_WIDTH; x += 1 {
			tile_value := map_layout[y][x]

			switch tile_value {
			case 9:
				// Wall tile
				wall_rect := rl.Rectangle {
					f32(x) * tile_width,
					f32(y) * tile_height,
					tile_width,
					tile_height,
				}
				append(&walls, wall_rect) // Append the wall rectangle

			case 3:
				// Button for Player 1
				if button_count < len(buttons) { 	// Ensure we don't go out of bounds
					buttons[button_count] = button.Button {
						rect                     = {
							f32(x) * tile_width + (tile_width - BUTTON_SIZE) / 2.0, // Center button in tile
							f32(y) * tile_height + (tile_height - BUTTON_SIZE) / 2.0, // Center button in tile
							BUTTON_SIZE,
							BUTTON_SIZE,
						},
						color                    = rl.GRAY,
						text                     = fmt.aprintf("Btn %d (P1)", button_count + 1),
						text_color               = rl.BLACK,
						interactive_player_index = 0, // Player 0 can interact
					}
					button_count += 1
				} else {
					fmt.println(
						"Warning: More Player 1 buttons in map than allocated in 'buttons' array.",
					)
				}

			case 4:
				// Button for Player 2
				if button_count < len(buttons) { 	// Ensure we don't go out of bounds
					buttons[button_count] = button.Button {
						rect                     = {
							f32(x) * tile_width + (tile_width - BUTTON_SIZE) / 2.0, // Center button in tile
							f32(y) * tile_height + (tile_height - BUTTON_SIZE) / 2.0, // Center button in tile
							BUTTON_SIZE,
							BUTTON_SIZE,
						},
						color                    = rl.GRAY,
						text                     = fmt.aprintf("Btn %d (P2)", button_count + 1),
						text_color               = rl.BLACK,
						interactive_player_index = 1, // Player 1 can interact
					}
					button_count += 1
				} else {
					fmt.println(
						"Warning: More Player 2 buttons in map than allocated in 'buttons' array.",
					)
				}

			case 8:
				// Gate tile
				// Position the gate at the center of this tile, considering its size
				the_gate = gate.Gate {
					rect    = {f32(x) * tile_width, f32(y) * tile_height, tile_width, tile_height},
					is_open = false,
				}

			case 1:
				players[0] = player.Player {
					position     = {f32(x) * tile_width, f32(y) * tile_height},
					speed        = {0.0, 0.0},
					color        = rl.MAROON,
					key_up       = .W,
					key_down     = .S,
					key_left     = .A,
					key_right    = .D,
					interact_key = .E,
				}


			case 2:
				players[1] = player.Player {
					position     = {f32(x) * tile_width, f32(y) * tile_height},
					speed        = {0.0, 0.0},
					color        = rl.BLUE,
					key_up       = .UP,
					key_down     = .DOWN,
					key_left     = .LEFT,
					key_right    = .RIGHT,
					interact_key = .J,
				}
			case 0:
				// Empty space - do nothing
				continue
			}
		}
	}
}

// Handles interactions with buttons (called within the fixed timestep)
@(private)
handle_button_interactions :: proc() {
	// We iterate through buttons and check if the *interactive player*
	// is near and has pressed their interaction key.

	for button_index := 0; button_index < len(buttons); button_index += 1 {
		button_ptr := &buttons[button_index]

		// Get the player who can interact with this button
		interactive_player_index := button_ptr.interactive_player_index
		interactive_player := &players[interactive_player_index]

		// Check if the interactive player is near the button
		distance_to_button := rl.Vector2Distance(
			interactive_player.position,
			{
				button_ptr.rect.x + button_ptr.rect.width / 2.0,
				button_ptr.rect.y + button_ptr.rect.height / 2.0,
			},
		)

		// Define a "near" threshold (you can adjust this)
		NEAR_THRESHOLD :: 50.0

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

				// Mark the corresponding button as pressed
				if button_index == 0 {
					button_1_pressed = true
					button_ptr.color = rl.GREEN // Change button color to indicate it's pressed
				} else if button_index == 1 {
					button_2_pressed = true
					button_ptr.color = rl.GREEN // Change button color to indicate it's pressed
				}
			}
		}
	}
}


// Draw the game state
game_draw :: proc() {
	rl.BeginDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	// Draw walls
	for wall_index := 0; wall_index < len(walls); wall_index += 1 {
		wall := walls[wall_index]
		rl.DrawRectangleRec(wall, rl.BROWN) // Draw walls in brown
	}

	// Draw each player
	for player_index := 0; player_index < len(players); player_index += 1 {
		player_ptr := &players[player_index]
		rl.DrawCircleV(player_ptr.position, BALL_RADIUS, player_ptr.color)
	}

	// Draw each button
	for button_index := 0; button_index < len(buttons); button_index += 1 {
		button_ptr := &buttons[button_index]
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

	// Draw the gate (draw it before players so players appear on top)
	if !the_gate.is_open {
		rl.DrawRectangleRec(the_gate.rect, rl.DARKBROWN) // Draw closed gate in dark brown
	}


	// Draw FPS for debugging (this is the rendering FPS)
	rl.DrawFPS(10, 10)

	rl.EndDrawing()
}
