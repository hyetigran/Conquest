extends GutTest

# First smoke test for the Godot 4 rewrite (Arc 01 / Slice 01-04). Exists to
# prove the GUT -> headless CLI pipeline works end to end; later arcs add
# real coverage for the domain layer (see docs/MIGRATION-GODOT4.md's
# Standards section for the per-arc test expectations).

func test_project_name_is_conquest():
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Conquest")

func test_viewport_size_matches_legacy_project():
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1280)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 720)
