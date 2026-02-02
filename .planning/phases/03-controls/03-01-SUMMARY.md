---
phase: 03-controls
plan: 01
subsystem: controls
tags: [navigation, pathfinding, click-to-move, NavigationAgent3D, NavigationRegion3D, eased-motion]

# Dependency graph
requires:
  - phase: 02-character
    provides: PlayerCharacter CharacterBody3D with collision and blob shadow
  - phase: 01-foundation
    provides: Interior scene with floor collider and furniture models
provides:
  - NavigationRegion3D with baked navigation mesh
  - Click-to-move character controller with eased motion
  - Pathfinding around furniture obstacles
affects: [03-02-keyboard-controls, 03-03-animation, 04-camera]

# Tech tracking
tech-stack:
  added: []
  patterns: [NavigationAgent3D pathfinding, raycast mouse-to-world conversion, velocity_computed signal pattern]

key-files:
  created: []
  modified:
    - scenes/interior/interior_scene.tscn
    - scenes/interior/interior_scene.gd
    - scenes/character/player_character.tscn
    - scenes/character/player_character.gd

key-decisions:
  - "Use _unhandled_input for click handling to avoid blocking UI"
  - "Await physics_frame before connecting navigation signals"
  - "Raycast with collision_mask=1 to hit floor only"

patterns-established:
  - "NavigationAgent3D setup: path_desired_distance=0.3, avoidance_enabled=false"
  - "Eased motion: ACCELERATION=3.0, DECELERATION=4.0, MAX_SPEED=1.5"
  - "NavMesh baking: geometry_parsed_geometry_type=1 (STATIC_COLLIDERS)"

# Metrics
duration: 1min
completed: 2026-02-02
---

# Phase 03 Plan 01: Click-to-Move Navigation Summary

**NavigationAgent3D pathfinding with eased acceleration/deceleration for click-to-move character movement**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-02T21:41:48Z
- **Completed:** 2026-02-02T21:42:54Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- NavigationRegion3D with NavigationMesh configured for floor pathfinding
- Click-to-move input handling with mouse-to-world raycast conversion
- Eased motion with smooth acceleration at start and deceleration near destination
- Immediate path redirection when clicking new destination while moving

## Task Commits

Each task was committed atomically:

1. **Task 1: Set up NavigationRegion3D and bake navigation mesh** - `e122129` (feat)
2. **Task 2: Implement click-to-move with NavigationAgent3D and eased motion** - `0cd39fe` (feat)

## Files Created/Modified
- `scenes/interior/interior_scene.tscn` - Added NavigationRegion3D with NavigationMesh resource
- `scenes/interior/interior_scene.gd` - Added navmesh baking on _ready()
- `scenes/character/player_character.tscn` - Added NavigationAgent3D node
- `scenes/character/player_character.gd` - Rewrote with click-to-move and eased motion logic

## Decisions Made
- Used `_unhandled_input()` instead of `_input()` to avoid blocking UI interactions
- Await `get_tree().physics_frame` before connecting navigation signals to avoid first-frame issues
- Raycast uses `collision_mask = 1` to only detect floor, ignoring furniture and character
- Eased motion uses kinematic equations for smooth deceleration distance calculation

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Click-to-move navigation complete and functional
- Ready for keyboard controls (03-02) as alternative input method
- Ready for animation integration (03-03) to show walk cycle during movement

---
*Phase: 03-controls*
*Completed: 2026-02-02*
