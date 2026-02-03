shader_type canvas_item;

// Vignette effect for HD-2D atmosphere
// Simple overlay approach - darkens edges without screen sampling
// This works reliably across all Godot rendering modes

// Vignette parameters
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.1, 0.07, 0.03, 1.0);  // Warm brown/sepia

void fragment() {
    // Rectangular vignette calculation
    // Uses UV multiplication trick: corners approach 0, center approaches max
    vec2 uv = UV;
    uv *= 1.0 - uv.yx;  // uv.x * (1-uv.y) and uv.y * (1-uv.x)

    // Calculate vignette factor (higher at center, lower at edges)
    float vig = uv.x * uv.y * 15.0;  // Scale factor for nice falloff
    vig = pow(vig, vignette_intensity);
    vig = clamp(vig, 0.0, 1.0);

    // Edge factor (inverse of vignette - higher at edges)
    float edge_factor = 1.0 - vig;

    // Output vignette color with alpha based on edge factor
    // The alpha controls how much the edges darken
    COLOR.rgb = vignette_color.rgb;
    COLOR.a = edge_factor * vignette_opacity;
}
