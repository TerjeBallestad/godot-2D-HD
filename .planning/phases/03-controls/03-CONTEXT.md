# Phase 3: Controls - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Click-to-move player navigation and camera orbit/zoom controls for evaluating the HD-2D scene from different perspectives. Character animation systems and advanced interaction patterns are separate phases.

</domain>

<decisions>
## Implementation Decisions

### Movement Feel
- Eased motion: accelerate at start, decelerate near destination
- Basic pathfinding around furniture using NavigationAgent3D
- Slow/deliberate pace: 3-4 seconds to cross the room
- Immediate redirect: clicking new destination while moving interrupts and reroutes

### Camera Orbit
- Dual input: right-click drag AND Q/E keys for rotation
- Snap to 45° increments (8 fixed positions)
- Animated snap: smooth transition to new angle (~0.3s)
- Right-click drag works anywhere on screen

### Camera Zoom
- Dual input: mouse wheel AND +/- keys
- Continuous zoom (no preset levels)
- Medium close maximum: character fills ~1/3 of screen at closest
- Smooth zoom with easing

### Input Mapping
- Q/E keys: rotate camera left/right (snaps to 45° increments)
- Right-click drag: orbit camera (same snap behavior)
- Mouse wheel: zoom in/out (continuous, smooth)
- +/- keys: zoom in/out
- R key: reset camera to default position/zoom

### Claude's Discretion
- Click-to-move mouse button (left vs right click)
- Camera orbit pivot point (around player vs around room center)

</decisions>

<specifics>
## Specific Ideas

- Movement should feel contemplative, not rushed — this is for evaluating visuals
- Camera snap animation keeps the HD-2D aesthetic feeling polished
- Both mouse and keyboard controls ensure easy evaluation from any angle

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-controls*
*Context gathered: 2026-02-02*
