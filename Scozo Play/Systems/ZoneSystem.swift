import CoreGraphics
import Foundation

struct ZoneSystem {
    func update(context: MatchContext, dt: TimeInterval) {
        let config = context.config
        let geometry = context.geometry
        let pull = 220 * CGFloat(max(0, min(dt, 0.05)))

        for athlete in context.athletes.values {
            var point = geometry.clampToCourt(athlete.courtPosition, radius: config.playerRadius)
            let zone = athlete.id.role.legalZone(in: geometry, team: athlete.id.side)
            if !zone.contains(point) {
                let nearest = geometry.nearestPoint(in: zone, to: point)
                let dx = nearest.x - point.x
                let dy = nearest.y - point.y
                let dist = hypot(dx, dy)
                if dist > 0.01 {
                    let step = min(dist, pull)
                    point.x += dx / dist * step
                    point.y += dy / dist * step
                }
            }

            // C cannot enter either shooting circle. Soft push rather than teleport.
            if athlete.id.role == .c {
                point = pushOutOfCircles(point, geometry: geometry, radius: config.playerRadius + 4, pull: pull)
            } else if athlete.id.role.canShoot {
                let defenceCircle = athlete.id.side.opposing
                if geometry.containsShootingCircle(point, for: defenceCircle) {
                    point = pushOutOfCircle(
                        point,
                        center: geometry.shootingCircleCenter(for: defenceCircle),
                        radius: geometry.shootingCircleRadius + 6,
                        pull: pull
                    )
                }
            } else if athlete.id.role == .gd || athlete.id.role == .gk {
                let attackCircle = athlete.id.side
                if geometry.containsShootingCircle(point, for: attackCircle) {
                    point = pushOutOfCircle(
                        point,
                        center: geometry.shootingCircleCenter(for: attackCircle),
                        radius: geometry.shootingCircleRadius + 6,
                        pull: pull
                    )
                }
            }

            athlete.courtPosition = geometry.clampToCourt(point, radius: config.playerRadius)
        }
        separateOverlaps(context: context, dt: dt)
    }

    private func separateOverlaps(context: MatchContext, dt: TimeInterval) {
        let minDist = Formation.minimumSeparation(playerRadius: context.config.playerRadius) * 0.85
        let push = 160 * CGFloat(max(0, min(dt, 0.05)))
        let athletes = Array(context.athletes.values)
        guard athletes.count > 1 else { return }
        for i in 0..<athletes.count {
            for j in (i + 1)..<athletes.count {
                let a = athletes[i]
                let b = athletes[j]
                let dx = b.courtPosition.x - a.courtPosition.x
                let dy = b.courtPosition.y - a.courtPosition.y
                let dist = hypot(dx, dy)
                if dist >= minDist { continue }
                let nx: CGFloat
                let ny: CGFloat
                if dist < 0.5 {
                    nx = 1
                    ny = 0
                } else {
                    nx = dx / dist
                    ny = dy / dist
                }
                let need = (minDist - max(dist, 0.5)) * 0.5
                let step = min(need, max(push, 4))
                a.courtPosition.x -= nx * step
                a.courtPosition.y -= ny * step
                b.courtPosition.x += nx * step
                b.courtPosition.y += ny * step
                a.courtPosition = context.geometry.clampToCourt(a.courtPosition, radius: context.config.playerRadius)
                b.courtPosition = context.geometry.clampToCourt(b.courtPosition, radius: context.config.playerRadius)
            }
        }
    }

    private func pushOutOfCircles(_ point: CGPoint, geometry: CourtGeometry, radius: CGFloat, pull: CGFloat) -> CGPoint {
        var result = point
        for side in TeamSide.allCases {
            if geometry.containsShootingCircle(result, for: side) {
                result = pushOutOfCircle(
                    result,
                    center: geometry.shootingCircleCenter(for: side),
                    radius: geometry.shootingCircleRadius + radius,
                    pull: pull
                )
            }
        }
        return result
    }

    private func pushOutOfCircle(_ point: CGPoint, center: CGPoint, radius: CGFloat, pull: CGFloat) -> CGPoint {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let dist = hypot(dx, dy)
        if dist >= radius { return point }
        if dist < 0.01 {
            return CGPoint(x: center.x + radius, y: center.y)
        }
        let needed = radius - dist
        let step = min(needed, max(pull, 8))
        return CGPoint(x: point.x + dx / dist * step, y: point.y + dy / dist * step)
    }
}
