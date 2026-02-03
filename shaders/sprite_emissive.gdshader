shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Emissive sprite shader for HD-2D characters
// Adds subtle self-illumination so characters pop against the environment
// Includes Y-axis billboard to face camera horizontally while staying upright

uniform sampler2D texture_albedo : source_color, filter_nearest;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.3;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

void vertex() {
    // Y-axis billboard: rotate to face camera horizontally, stay upright
    // This replicates Sprite3D billboard = 2 (BILLBOARD_FIXED_Y)

    // Get the model's position in view space
    vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

    // Calculate direction from object to camera (in world space, XZ plane only)
    vec3 cam_pos = INV_VIEW_MATRIX[3].xyz;
    vec3 to_camera = cam_pos - world_pos;
    to_camera.y = 0.0; // Ignore Y for horizontal-only rotation
    to_camera = normalize(to_camera);

    // Build rotation matrix for Y-axis billboard
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, to_camera));

    // Apply billboard rotation to vertex
    vec3 billboard_pos = right * VERTEX.x + up * VERTEX.y + to_camera * VERTEX.z;

    // Transform to clip space
    VERTEX = billboard_pos;
}

void fragment() {
    vec4 albedo_tex = texture(texture_albedo, UV);

    ALBEDO = albedo_tex.rgb;
    ALPHA = albedo_tex.a;

    // Use built-in alpha scissor for proper shadow casting
    ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;

    // Add subtle emission based on the sprite color
    EMISSION = albedo_tex.rgb * emission_strength;
}
