import Cocoa
import AXSwift

var initialWindowPosition: CGPoint = .zero
var initialMousePosition: CGPoint = .zero
var initialWindowSize: CGSize = .zero

var pendingWindowPosition: CGPoint?
var pendingWindowSize: CGSize?

var targetWindow: UIElement? = nil

var isDragging = false
var isResizing = false

// TODO: ???
var resL = false
var resT = false

print("Started MacDrag.")

let events: [CGEventType] = [
	.leftMouseDown,
	.leftMouseUp,
	.leftMouseDragged,
	.rightMouseDown,
	.rightMouseUp,
	.rightMouseDragged,
	.flagsChanged
]

let eventMask = events
	.map { CGEventMask(1 << $0.rawValue) }
	.reduce(0, |)

let eventTap = CGEvent.tapCreate(
	tap: .cgSessionEventTap,
	place: .headInsertEventTap,
	options: .defaultTap,
	eventsOfInterest: eventMask,
	callback: { _, type, event, _ in
		if !event.flags.contains(.maskAlternate) {
			isDragging = false
			isResizing = false
			
			if targetWindow != nil {
				targetWindow = nil
			}
			
			return .passUnretained(event)
		}
		
		if type == .flagsChanged,
		   isDragging || isResizing,
		   event.flags.contains(.maskControl)
		{
				if let targetWindow {
					focusApp(of: targetWindow)
				}
				
				return .passUnretained(event)
		}
		
		let mousePosition = event.location
		
		// Mouse Down
		if type == .leftMouseDown || type == .rightMouseDown,
		   let element = try? UIElement.at(mousePosition),
		   let window = element.window()
		{
			print("clicked on window")
			
			targetWindow = window
			initialMousePosition = mousePosition
			
			initialWindowPosition = (try? window.position()) ?? .zero
			initialWindowSize = (try? window.size()) ?? .zero
			
			print(initialWindowPosition, initialWindowSize)
			
			if type == .leftMouseDown {
				isDragging = true
			} else {
				isResizing = true
				
				resL = mousePosition.x < initialWindowPosition.x + initialWindowSize.width / 2
				resT = mousePosition.y < initialWindowPosition.y + initialWindowSize.height / 2
			}
			
			return nil
		}
		
		// Dragging / Resizing
		if let targetWindow, isDragging || isResizing {
			let dx = mousePosition.x - initialMousePosition.x
			let dy = mousePosition.y - initialMousePosition.y
			
			if isDragging {
				pendingWindowPosition = CGPoint(
					x: initialWindowPosition.x + dx,
					y: initialWindowPosition.y + dy
				)
			} else {
				// TODO: clean all this up
				let min: CGFloat = 100
				
				let width = max(min, initialWindowSize.width + (resL ? -dx : dx))
				let height = max(min, initialWindowSize.height + (resT ? -dy : dy))
				
				pendingWindowSize = CGSize(width: width, height: height)
				
				pendingWindowPosition = CGPoint(
					x: initialWindowPosition.x + (resL ? (width == min ? initialWindowSize.width - min : dx) : 0),
					y: initialWindowPosition.y + (resT ? (height == min ? initialWindowSize.height - min : dy) : 0)
				)
			}
			
			updateWindowAfter16ms(targetWindow)
			if type != .leftMouseUp, type != .rightMouseUp {
				return nil
			}
		}
		
		// Mouse Up
		if (type == .leftMouseUp && isDragging) || (type == .rightMouseUp && isResizing) {
			isDragging = false
			isResizing = false
			
			updateTimer?.cancel()
			updateTimer = nil
			
			targetWindow = nil
			
			return nil
		}
		
		return .passUnretained(event)
	},
	userInfo: nil
)

var standardError: FileHandle = .standardError

guard let eventTap else {
	print("Failed to create event tap. is Accessibility enabled?", to: &standardError)
	exit(1)
}

let loop = CFMachPortCreateRunLoopSource(
	kCFAllocatorDefault,
	eventTap,
	0
)

CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .commonModes)

CGEvent.tapEnable(tap: eventTap, enable: true)

CFRunLoopRun()
