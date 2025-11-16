# Twenty Second Slam - AI Coding Agent Instructions

## Project Overview
**Twenty Second Slam** is a Godot 4.2 arcade game with a 20-second time limit where players punch enemies to score points. Built for a game jam with Purple Token leaderboard integration.

## Architecture & Key Patterns

### Singleton Autoload System
Three global managers control game state (defined in `project.godot` autoloads):
- **GameManager**: 20-second timer, damage score tracking, game lifecycle signals
- **LeaderboardManager**: Purple Token API integration (GET/POST with SHA-256 auth)
- **SettingsManager**: Audio volume and fullscreen settings

Access these from any script: `GameManager.add_damage(5)`, `LeaderboardManager.submit_score("Player", 100)`

### Entity Inheritance Pattern
All enemies inherit from `BaseEnemy` class (`scripts/entities/base_enemy.gd`) which implements:
- State machine with enum states: `SPAWNING, IDLE, PATROL, CHASE, ATTACK, HIT_STUNNED, FLYING, DEAD`
- Override `handle_*_state(delta)` methods for custom behavior
- Visual feedback system: flashing ColorRect overlay + shake on hit
- Signal-based death notification: `enemy_died(enemy_position)`

Example: `enemy_small.gd` extends `BaseEnemy` and customizes chase/flying states.

### Player Movement System
Player (`scripts/entities/player.gd`) uses zone-based movement:
- `can_move_vertically` flag controlled by `VerticalZone` Area2D nodes
- Supports both keyboard (WASD/arrows) and gamepad input with custom deadzone (0.15)
- Punch system: asynchronous flashing hitbox (10Hz toggle) independent of movement state
- Dash mechanic: 0.19s burst in current input direction

**Critical**: Player camera is programmatically added in `_ready()`, not in scene file.

### Score & Damage System
Damage scoring flow:
1. Enemy hit by punch → `BaseEnemy.take_hit()` → state change to `HIT_STUNNED`
2. On death → `GameManager.add_damage(5)` for kill bonus
3. Timer hits 20s → `GameManager.game_ended` signal → transition to `game_over.tscn`
4. Game over scene submits score to Purple Token API

## External Dependencies

### Purple Token API Integration
Leaderboard uses custom authentication (NOT standard OAuth):
```gdscript
# 1. Encode params as URL string, then base64
# 2. Append SECRET_PHRASE (from .env)
# 3. SHA-256 hash the combined string
# 4. Send as ?payload=<base64>&sig=<hash>
```

**Environment Configuration**: Create `.env` file (gitignored) with:
```
PURPLE_TOKEN_GAME_KEY=your_key_here
PURPLE_TOKEN_SECRET=your_secret_here
```
Use `EnvReader.load_env_file(".env")` to access credentials.

## Development Workflows

### Running the Game
- **Main scene**: `scenes/ui/main_menu.tscn` (set in project.godot)
- **Test level**: `scenes/levels/test_level.tscn` starts game immediately
- Press F5 in Godot editor or run: `godot --path . res://scenes/ui/main_menu.tscn`

### Scene Structure Conventions
UI scenes use specific node naming for script references:
- Labels: `ScoreLabel`, `TimerLabel`, `FinalScoreLabel`
- Buttons: `PlayAgainButton`, `LeaderboardButton`, `MainMenuButton`
- Containers: `GameOverContainer`, `ButtonContainer`

These names match `@onready var` declarations in corresponding `.gd` files.

### Input Action System
Custom input actions in `project.godot`:
- `punch` = E key / Joypad B button (context-dependent: punch OR accept in UI)
- `jump` = Space / Joypad A (dash mechanic)
- `move_left/right/up/down` = WASD + Arrow keys + Joypad stick
- `pause` = ESC or P / Joypad Start button

## Project-Specific Conventions

### GDScript Patterns
1. **Signal connections**: Always use `.connect()` syntax, not editor connections
   ```gdscript
   GameManager.game_ended.connect(_on_game_ended)
   ```

2. **Node references**: Use `@onready var` with `$NodePath` for scene children:
   ```gdscript
   @onready var punch_area: Area2D = $PunchHitBox
   ```

3. **Deferred initialization**: Use `call_deferred()` for cross-scene references:
   ```gdscript
   call_deferred("_find_player_deferred")
   ```

4. **State management**: Always emit signals on state changes for loose coupling

### File Organization
- Entity logic: `scripts/entities/` (player, enemies, zones)
- Manager singletons: `scripts/managers/` (game, leaderboard, settings, pause)
- UI controllers: `scripts/ui/` (menus, HUD)
- Scene files: Match script name (e.g., `player.gd` → `scenes/player/player.tscn`)

### Debugging & Testing
- Use `print()` liberally - existing code has detailed logging (see `GameManager`, `LeaderboardManager`)
- Test API integration via `tests/api_test.tscn` scene
- Enemy spawning currently disabled in `test_level.gd` (see commented sections)

## Critical Implementation Notes

1. **Visual Feedback Timing**: Flash duration = 0.1s, shake duration = 0.2s, punch flash = 10Hz
2. **Collision Layers**: Player punch hitbox (`PunchHitBox`) must overlap with enemy `HitBox` Area2D
3. **Scene Transitions**: Use `get_tree().change_scene_to_file("res://path/to/scene.tscn")`
4. **Timer System**: GameManager uses `_process(delta)` not Timer nodes for precision
5. **Vertical Movement**: Player is ALWAYS in free movement (walls created by `VerticalZone`)

## Common Tasks

**Adding new enemy type**:
1. Extend `BaseEnemy` class
2. Override `initialize_enemy()` for stats
3. Override `handle_chase_state()` / `handle_attack_state()` for AI
4. Create scene with enemy body ColorRect + flash overlay ColorRect + HitBox Area2D

**Modifying score calculation**:
- Edit `GameManager.add_damage()` calls in enemy death handlers
- Adjust `game_duration` constant in `GameManager` (default: 20.0 seconds)

**API troubleshooting**:
- Check Godot console for `LeaderboardManager:` prefixed logs
- Verify `.env` file exists and has correct credentials
- Test signature generation with known values

### Player Punch Hitbox Configuration
var punch_duration = 0.4  # Matches animation length (10 frames ÷ 25 FPS)
var punch_hitbox_start = 0.12  # Hitbox starts at frame 3 (when fist extends)
var punch_hitbox_end = 0.28   # Hitbox ends at frame 7 (before retract)
