# Backlog — Post-migration features

> Side quests: new features beyond what's in [MIGRATION-GODOT4.md](./MIGRATION-GODOT4.md)'s scope. Per that spec's Workflow section, these wait until Arc 10 ships — the audited behavior gets rebuilt first, with nothing new mixed in, so scope creep can't stall the migration. Add ideas here as they come up; don't let them leak into an in-flight arc/slice.

## Candidates

- **Middle Earth (LOTR) map.** A new playable map/theme alongside the existing Risk-style world map: new territory set, adjacency graph, art (country/border sprites), and whatever map-selection UI is needed to choose it. Scale reference: the current map is 42 territories across 6 continents (`docs/data/country-scenes.md`) — a Middle Earth map would need its own from-scratch region list, borders, and continent-style bonus groupings, plus new art assets in the same style as `Assets/Graphics/Map/`. Not started; no design work done yet (region list, adjacency, bonus values all TBD). Depends on the Godot 4 rewrite's data layer (Arc 02) being in place first, since the new map should be built on the single-source `CountryMapData` resource design, not by copying the legacy dual-dictionary pattern.
