# ScoZo Arcade — placeholder art notes

All MVP visuals are code-drawn SpriteKit shapes. No texture atlas or 3D pipeline.

## Palette

| Token | Hex | Use |
| --- | --- | --- |
| Teal | `#00C2C7` | Home / STURT, HUD accents, D-pad glow |
| Teal dark | `#067A82` | Home secondary |
| Magenta | `#E21B70` | Away / NORWOOD |
| Magenta dark | `#9A124C` | Away secondary |
| Wood | `#C9A06A` / `#E4C899` / `#8C6840` | Court planks |
| Cream | `#F4EDE0` | Court lines |
| Arena | `#07131C` / `#04090E` | Dark surrounds |
| Warning | `#F5A524` | Held-ball / early meter |
| Success | `#3DDC97` | Sweet-spot meter / goals |

## Layering (`ZLayer`)

1. Arena + vignette
2. SCOZO surround walls
3. Wood court + plank stripes
4. Court lines and circles
5. Contact shadows
6. Players / ball (depth-scaled)
7. Shot trail, dashed trajectory, ground meter
8. HUD and virtual controls
9. Pause / stats overlays

## Intentionally temporary

- Capsule player silhouettes instead of 3D athletes (Phase 2: Mixamo → Blender → USDZ / SceneKit)
- Label wordmarks instead of painted arena boards
- Shape-node hoop and net
- LIVE viewer count is mock presentation data only
