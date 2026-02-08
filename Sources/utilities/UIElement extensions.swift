import Cocoa
import AXSwift

extension UIElement {
	convenience init?(at position: CGPoint) throws {
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
		
		self.init(result!)
	}
	
	// looks up the chain of parents until a window is reached
	// TODO: use current.attribute(.window) ?
	func window() -> UIElement? {
		// TODO: is ignoring errors correct?
		if (try? role()) == .window {
			return self
		} else {
			// TODO: is ignoring errors correct?
			guard let parent: UIElement = try? attribute(.parent) else {
				return nil
			}
			
			return parent.window()
		}
	}
	
	func focus() {
		try? setAttribute(.main, value: true)
		try? setAttribute(.focused, value: true)
		
		if let pid = try? pid() {
			NSRunningApplication(processIdentifier: pid)?
				.activate(options: .activateAllWindows)
		}
	}
	
	func position() throws -> CGPoint? {
		let value: NSValue? = try attribute(.position)
		return value?.value(of: CGPoint.self)
	}
	
	func size() throws -> CGSize? {
		let value: NSValue? = try attribute(.size)
		return value?.value(of: CGSize.self)
	}
}
