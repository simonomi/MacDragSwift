import Cocoa
import AXSwift

func focusApp(of window: UIElement) {
	try? window.setAttribute(.main, value: true)
	try? window.setAttribute(.focused, value: true)
	
	if let pid = try? window.pid() {
		NSRunningApplication(processIdentifier: pid)?
			.activate(options: .activateAllWindows)
	}
}

@MainActor
var updateTimer: Task<(), Never>? = nil

@MainActor
func updateWindowAfter16ms(_ window: UIElement) {
	guard updateTimer == nil else { return }
	
	updateTimer = Task {
		do {
			try await Task.sleep(for: .milliseconds(16))
		} catch is CancellationError {
			return
		} catch {
			fatalError("unreachable")
		}
		
		if let position = pendingWindowPosition {
			try? window.setAttribute(.position, value: position)
			pendingWindowPosition = nil
		}
		
		if let size = pendingWindowSize {
			try? window.setAttribute(.size, value: size)
			pendingWindowSize = nil
		}
		updateTimer = nil
	}
}

extension UIElement {
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
	
	func position() throws -> CGPoint? {
		let value: NSValue? = try attribute(.position)
		return value?.value(of: CGPoint.self)
	}
	
	func size() throws -> CGSize? {
		let value: NSValue? = try attribute(.size)
		return value?.value(of: CGSize.self)
	}
}
