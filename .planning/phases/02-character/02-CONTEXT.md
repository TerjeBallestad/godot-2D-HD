# Phase 2: Character - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Player character exists as a pixel-art billboard sprite in the 3D scene. Sprite3D with crisp nearest-neighbor filtering, billboarding to face camera, integrated visually with the interior environment. Movement and controls are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Sprite appearance
- Use existing character sprite asset (user will provide)
- Static single frame only — animation comes in Controls phase
- Front-facing sprite, perpendicular to floor (90 degrees from ground plane)
- Stylized slightly smaller than realistic proportions (~95% scale)

### Billboard behavior
- Y-axis billboard only — sprite rotates horizontally to face camera but stays upright
- Smooth continuous rotation as camera orbits (no snapping to directions)
- Pixels can rotate with billboard — no screen-alignment requirement

### Scene placement
- Spawn at center of room (open floor area)
- Sprite origin at bottom — feet touch ground plane directly
- Scale tuned to be subtly smaller than realistic proportions

### Visual integration
- Subtle lighting influence — scene lights affect sprite but muted to keep pixel art readable
- Blob shadow underneath character (simple circular shadow, not real shadow casting)

### Claude's Discretion
- Edge case handling for steep camera angles
- Collision setup (whether to add basic collision shape for later phases)
- Depth sorting approach for proper occlusion with 3D objects
- Post-processing inclusion (bloom, color grading affecting sprite)

</decisions>

<specifics>
## Specific Ideas

- Sprite should stand perpendicular to floor, not tilted with camera angle
- The slightly-smaller-than-realistic scale is intentional but subtle — not chibi, just ~95%
- Blob shadow grounds the character without complex shadow rendering

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-character*
*Context gathered: 2026-02-02*
