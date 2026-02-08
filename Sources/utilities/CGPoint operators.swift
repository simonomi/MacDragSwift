import CoreGraphics

extension CGPoint {
	static func + (left: Self, right: Self) -> Self {
		CGPoint(
			x: left.x + right.x,
			y: left.y + right.y
		)
	}
	
	static func - (left: Self, right: Self) -> Self {
		CGPoint(
			x: left.x - right.x,
			y: left.y - right.y
		)
	}
}
