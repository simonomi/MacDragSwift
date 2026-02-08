import Cocoa
import AXSwift

extension UIElement {
	static func at(_ position: CGPoint) throws -> UIElement? {
		var result: AXUIElement?
		let error = AXUIElementCopyElementAtPosition(
			AXUIElementCreateSystemWide(),
			Float(position.x),
			Float(position.y),
			&result
		)
		
		if error == .noValue {
			return nil
		}
		
		guard error == .success else {
			throw error
		}
		
		return UIElement(result!)
	}
}
