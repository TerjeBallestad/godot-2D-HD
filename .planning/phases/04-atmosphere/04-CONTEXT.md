# Phase 4: Atmosphere - Context

**Gathered:** 2026-02-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Create the dreamy, atmospheric look characteristic of HD-2D through post-processing effects, volumetric fog, and lighting enhancements. This phase adds bloom/glow, vignette, volumetric fog, and point light character shadows. The tilt-shift depth blur is Phase 5.

</domain>

<decisions>
## Implementation Decisions

### Bloom/Glow
- Subtle diffuse intensity — soft glow, barely noticeable, clean look
- Emissive sources only — only materials marked as emissive trigger bloom (lamps, candles, glowing objects)
- Warm tint — slight orange/yellow warmth for cozy interior feel
- Tight halo radius — small spread, glow stays close to source

### Vignette
- Very subtle darkness — barely noticeable, just guides eye to center
- Slight edge blur — subtle softness at screen edges (complements Phase 5 tilt-shift)
- Rectangular shape — follows screen edges rather than circular/oval
- Warm brown/sepia color — slight vintage warmth at edges

### Volumetric Fog
- Primary purpose: light shafts — visible rays from windows/lamps cutting through air
- Very light density — barely visible, just enough for light rays to show
- Neutral gray/white color — classic dust-in-air look

### Character Shadow (Point Light)
- Soft penumbra — gradual falloff, natural indoor lighting look
- Light/subtle opacity — 30-40%, visible but not harsh
- Complement ambient color — tinted opposite to ambient light for natural contrast
- Keep both shadows — blob shadow for grounding, point light shadow for directional depth

### Claude's Discretion
- Fog placement approach (global uniform vs localized to lights)
- Exact bloom threshold values
- Vignette falloff curve
- Point light positioning and range

</decisions>

<specifics>
## Specific Ideas

- Bloom should enhance emissive objects (lamps, candles) without making bright surfaces glow
- Vignette should feel like a gentle frame, not tunnel vision
- Light shafts are the key fog effect — think dust particles in sunbeams
- Dual shadow approach: blob for pixel-art grounding + directional for 3D lighting depth

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-atmosphere*
*Context gathered: 2026-02-03*
