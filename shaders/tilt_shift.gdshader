shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled;

// Screen and depth textures
uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture;

// Focal point in VIEW SPACE (updated by controller script)
uniform vec3 focal_point_view = vec3(0.0, 0.0, -5.0);

// Note: Using built-in INV_PROJECTION_MATRIX to reconstruct view-space position

// Blur parameters
uniform float focus_distance : hint_range(0.1, 3.0) = 0.5;  // Tight focus around character
uniform float blur_max : hint_range(0.0, 4.0) = 2.0;  // Subtle blur cap
uniform float blur_transition : hint_range(0.2, 3.0) = 1.0;  // Gradual falloff

// Toggle for A/B comparison
uniform bool enabled = true;

// Debug mode: 0=off, 1=distance, 2=raw_depth, 3=view_X, 4=view_Y, 5=linear_depth
uniform int debug_mode : hint_range(0, 5) = 0;


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
		// Sample depth and reconstruct VIEW-SPACE position
		float depth_raw = texture(depth_texture, SCREEN_UV).x;
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
		vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		position_view.xyz /= position_view.w;
		vec3 view_position = position_view.xyz;

		// Spherical distance from focal point in view space
		float dist_to_focal = distance(view_position, focal_point_view);

		// Smooth ease falloff (user decision: slow start, accelerates)
		float blur_factor = smoothstep(focus_distance, focus_distance + blur_transition, dist_to_focal);
		float blur_amount = blur_factor * blur_max;

		// Reduce blur at screen edges (user decision: soften effect near boundaries)
		vec2 edge_dist = min(SCREEN_UV, 1.0 - SCREEN_UV);
		float edge_factor = smoothstep(0.0, 0.1, min(edge_dist.x, edge_dist.y));
		blur_amount *= edge_factor;

		// Sample with mipmap blur
		color = textureLod(screen_texture, SCREEN_UV, blur_amount).rgb;

		// Linear depth (view-space Z, positive distance from camera)
		float linear_depth = -view_position.z;

		// Debug visualizations
		if (debug_mode == 1) {
			// Show distance from focal point as color (green = close, red = far)
			color = vec3(blur_factor, 1.0 - blur_factor, 0.0);
		} else if (debug_mode == 2) {
			// Show raw depth buffer value
			color = vec3(depth_raw);
		} else if (debug_mode == 3) {
			// Show view-space X (red = positive, cyan = negative)
			float vx = view_position.x * 0.1 + 0.5;
			color = vec3(vx, 0.5, 1.0 - vx);
		} else if (debug_mode == 4) {
			// Show view-space Y (red = positive, cyan = negative)
			float vy = view_position.y * 0.1 + 0.5;
			color = vec3(vy, 0.5, 1.0 - vy);
		} else if (debug_mode == 5) {
			// Show linear depth (normalized to 0-10 range)
			color = vec3(linear_depth / 10.0);
		}
	}

	ALBEDO = color;
}
