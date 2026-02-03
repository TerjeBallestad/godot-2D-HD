---
status: diagnosed
trigger: "Diagnose why the blob shadow doesn't appear beneath the character."
created: 2026-02-02T22:00:00Z
updated: 2026-02-02T22:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Both collision properties removed in uncommitted changes
test: git diff shows exact lines removed
expecting: Root cause identified
next_action: return diagnosis

## Symptoms

expected: Blob shadow should appear beneath character on the floor
actual: Blob shadow does not appear during UAT testing
errors: None reported
reproduction: Run the game, observe character - shadow is not visible
started: User reports it still doesn't work despite commit d1ea1ee claiming to fix it

## Eliminated

## Evidence

- timestamp: 2026-02-02T22:00:00Z
  checked: player_character.tscn current state
  found: ShadowCaster ShapeCast3D node exists but has NO collision_mask property set
  implication: ShapeCast3D will use default collision_mask=1, but we need to verify this is the issue

- timestamp: 2026-02-02T22:00:01Z
  checked: commit d1ea1ee diff
  found: The fix commit ADDED "collision_mask = 1" to line 29 of player_character.tscn
  implication: The collision_mask was explicitly set in the fix

- timestamp: 2026-02-02T22:00:02Z
  checked: Current player_character.tscn line 26-29
  found: Lines show ShadowCaster with shape and target_position but NO collision_mask property
  implication: The fix has been reverted or overwritten

- timestamp: 2026-02-02T22:00:03Z
  checked: interior_scene.tscn FloorCollider
  found: FloorCollider at line 158 has collision_mask=0 but NO collision_layer property
  implication: FloorCollider is missing collision_layer=1 that was added in the fix

- timestamp: 2026-02-02T22:00:04Z
  checked: commit d1ea1ee for interior_scene.tscn
  found: The fix commit ADDED "collision_layer = 1" to FloorCollider
  implication: This change was also reverted

- timestamp: 2026-02-02T22:00:05Z
  checked: git status and git diff
  found: Both files have uncommitted modifications that REMOVE the fix lines
  implication: The fix was correct but has been reverted in working directory

- timestamp: 2026-02-02T22:00:06Z
  checked: git diff scenes/character/player_character.tscn
  found: Line removed: "collision_mask = 1" (line 29)
  implication: ShapeCast3D cannot detect floor without this

- timestamp: 2026-02-02T22:00:07Z
  checked: git diff scenes/interior/interior_scene.tscn
  found: Line removed: "collision_layer = 1" (line 158)
  implication: FloorCollider is not on a detectable layer

## Resolution

root_cause: Uncommitted changes in the working directory have removed both critical collision properties added in commit d1ea1ee. Specifically: (1) player_character.tscn line 29 removed "collision_mask = 1" from ShapeCast3D, and (2) interior_scene.tscn line 158 removed "collision_layer = 1" from FloorCollider. These properties are required for collision detection - ShapeCast3D needs collision_mask=1 to detect objects on layer 1, and FloorCollider needs collision_layer=1 to be on that layer. Without both properties, shadow_caster.get_collision_count() returns 0, causing the script to hide the shadow (player_character.gd line 18).

fix:

verification:

files_changed: []
