shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled;

// Screen and depth textures
uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture;

// Focal point control (updated by controller script)
uniform vec3 focal_point = vec3(0.0, 0.5, 0.0);

// Camera matrices (passed from GDScript since we bypass normal projection)
uniform mat4 inv_proj_matrix;
uniform mat4 inv_view_matrix;

// Blur parameters
uniform float focus_distance : hint_range(0.5, 5.0) = 1.5;  // Wide focus zone
uniform float blur_max : hint_range(0.0, 4.0) = 2.0;  // Subtle blur cap
uniform float blur_transition : hint_range(0.5, 5.0) = 2.0;  // Smooth gradient

// Toggle for A/B comparison
uniform bool enabled = true;

// Debug mode: 0=off, 1=show distance as color, 2=show depth
uniform int debug_mode : hint_range(0, 2) = 0;


void vertex() {
	// Fullscreen quad positioning
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}


void fragment() {
	vec3 color;

	if (!enabled) {
		// Pass through unblurred screen when disabled
		color = texture(screen_texture, SCREEN_UV).rgb;
	} else {
		// Sample depth and reconstruct world position using camera matrices
		float depth_raw = texture(depth_texture, SCREEN_UV).x;
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
		vec4 position_view = inv_proj_matrix * vec4(ndc, 1.0);
		position_view.xyz /= position_view.w;
		vec4 world = inv_view_matrix * position_view;
		vec3 world_position = world.xyz / world.w;

		// Spherical distance from focal point (user decision: spherical shape)
		float dist_to_focal = distance(world_position, focal_point);

		// Smooth ease falloff (user decision: slow start, accelerates)
		float blur_factor = smoothstep(focus_distance, focus_distance + blur_transition, dist_to_focal);
		float blur_amount = blur_factor * blur_max;

		// Reduce blur at screen edges (user decision: soften effect near boundaries)
		vec2 edge_dist = min(SCREEN_UV, 1.0 - SCREEN_UV);
		float edge_factor = smoothstep(0.0, 0.1, min(edge_dist.x, edge_dist.y));
		blur_amount *= edge_factor;

		// Sample with mipmap blur
		color = textureLod(screen_texture, SCREEN_UV, blur_amount).rgb;

		// Debug visualizations
		if (debug_mode == 1) {
			// Show distance from focal point as color (green = close, red = far)
			color = vec3(blur_factor, 1.0 - blur_factor, 0.0);
		} else if (debug_mode == 2) {
			// Show raw depth
			color = vec3(depth_raw);
		}
	}

	ALBEDO = color;
}
