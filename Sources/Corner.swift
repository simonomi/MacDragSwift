import CoreGraphics

struct Corner {
	var top: Bool
	var left: Bool
	
	init(closestTo target: CGPoint, in bounds: CGSize) {
		top = target.y < bounds.height / 2
		left = target.x < bounds.width / 2
	}
}
