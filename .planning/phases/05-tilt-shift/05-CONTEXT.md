# Phase 5: Tilt-Shift - Context

**Gathered:** 2026-02-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Depth-based blur effect that creates the signature HD-2D "miniature/diorama" look. Objects near the character stay sharp, objects far away blur, focal point follows the character as they move. This is the final visual layer that completes the HD-2D evaluation.

</domain>

<decisions>
## Implementation Decisions

### Blur characteristics
- Subtle blur intensity at maximum distance — objects still recognizable, not heavily blurred
- Smooth (ease) falloff curve — slow start, accelerates for natural depth feel
- Subtle bokeh quality on highlights — slight highlight spreading for cinematic look
- Both directions blur — apply blur to objects both nearer and farther than focal plane (true DoF)

### Focal plane behavior
- Wide focus zone — character plus nearby furniture/objects stay sharp
- Soft gradient transition — smooth fade into blur, not hard cutoff
- Spherical distance focal shape — sharp sphere around character (true depth-based, not horizontal slice)
- Fixed zone regardless of zoom — focus width doesn't change with camera distance

### Character tracking
- Smoothly lagged focal point — focal point eases toward character position
- Slight lag amount — just perceptible smoothing, not dramatic rack focus
- Anchor at character center — mid-body focal point balances above and below

### Edge handling
- Reduce blur at scene edges — soften effect near boundaries to avoid artifacts
- Independent from vignette — both effects apply separately, stack as layers
- Add toggle for debugging — easy on/off for A/B comparison during evaluation

### Claude's Discretion
- Stop behavior for focal tracking (settle immediately vs continue easing)
- Screen border handling for depth buffer edge cases
- Exact smoothing/lerp values for focal tracking
- Bokeh implementation approach

</decisions>

<specifics>
## Specific Ideas

- This is the go/no-go evaluation moment — walking through the finished scene to judge if the HD-2D look is achieved
- Should feel like a miniature diorama, not a heavy blur filter
- Subtle is key — enhancement not distraction

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-tilt-shift*
*Context gathered: 2026-02-03*
