shader_type canvas_item;

// Vignette effect for HD-2D atmosphere
// Rectangular shape following screen edges with warm tint and subtle edge blur

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Vignette parameters
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.3;
uniform vec4 vignette_color : source_color = vec4(0.15, 0.1, 0.05, 1.0);  // Warm brown/sepia

// Edge blur parameters (complements Phase 5 tilt-shift)
uniform float edge_blur_strength : hint_range(0.0, 1.0) = 0.3;
uniform float edge_blur_size : hint_range(0.0, 4.0) = 1.5;

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);

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

    // Apply subtle edge blur using LOD sampling
    // Higher LOD = more blur, scaled by edge_factor for gradual transition
    float blur_lod = edge_factor * edge_blur_strength * edge_blur_size;
    vec4 blurred_color = textureLod(screen_texture, SCREEN_UV, blur_lod);

    // Blend between sharp and blurred based on edge factor
    vec3 color_with_blur = mix(screen_color.rgb, blurred_color.rgb, edge_factor * edge_blur_strength);

    // Apply vignette color tint at edges
    vec3 tinted_color = mix(color_with_blur, vignette_color.rgb, edge_factor * vignette_opacity);

    // Final output
    COLOR.rgb = tinted_color;
    COLOR.a = 1.0;
}
