shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled;

// Screen and depth textures
uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture;

// Focal point control (updated by controller script)
uniform vec3 focal_point = vec3(0.0, 0.5, 0.0);

// Blur parameters
uniform float focus_distance : hint_range(0.5, 5.0) = 1.5;  // Wide focus zone
uniform float blur_max : hint_range(0.0, 4.0) = 2.0;  // Subtle blur cap
uniform float blur_transition : hint_range(0.5, 5.0) = 2.0;  // Smooth gradient

// Toggle for A/B comparison
uniform bool enabled = true;


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
		// Sample depth and reconstruct world position
		float depth_raw = texture(depth_texture, SCREEN_UV).x;
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
		vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		position_view.xyz /= position_view.w;
		vec4 world = INV_VIEW_MATRIX * position_view;
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
	}

	ALBEDO = color;
}
