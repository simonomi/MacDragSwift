import Cocoa
import AXSwift

let edgeSnappingDistance: CGFloat = 50

var dragInfo: DragInfo?

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
		if !event.flags.contains(.maskControl) || event.flags.contains(.maskShift) {
			dragInfo = nil
			return .passUnretained(event)
		}
		
		// tap alt while dragging to focus window
		if type == .flagsChanged,
		   event.flags.contains(.maskAlternate),
		   let dragInfo
		{
			dragInfo.targetWindow.focus()
			return .passUnretained(event)
		}
		
		let mousePosition = event.location
		
		// mouse down
		if type == .leftMouseDown || type == .rightMouseDown,
		   let element = try? UIElement(at: mousePosition),
		   let window = element.window()
		{
			guard var windowPosition = try? window.position(),
				  let windowSize = try? window.size()
			else {
				return .passUnretained(event)
			}
			
			let corner: Corner? = if type == .rightMouseDown {
				Corner(
					closestTo: mousePosition - windowPosition,
					in: windowSize
				)
			} else {
				nil
			}
			
			// if past a screen edge, tweak the initial position to
			// offset the effects of edge snapping
			let distancePastLeftEdge = screenBounds.minX - windowPosition.x
			
			let windowRightEdgeX = windowPosition.x + windowSize.width
			let distancePastRightEdge = windowRightEdgeX - screenBounds.maxX
			
			let windowBottomEdgeY = windowPosition.y + windowSize.height
			let distancePastBottomEdge = windowBottomEdgeY - screenBounds.maxY
			
			if distancePastLeftEdge > 0 {
				windowPosition.x -= edgeSnappingDistance
			}
			
			if distancePastRightEdge > 0 {
				windowPosition.x += edgeSnappingDistance
			}
			
			if distancePastBottomEdge > 0 {
				windowPosition.y += edgeSnappingDistance
			}
			
			dragInfo = DragInfo(
				initialWindowPosition: windowPosition,
				initialMousePosition: mousePosition,
				initialWindowSize: windowSize,
				targetWindow: window,
				resizingFrom: corner
			)
			
			// eat the click
			return nil
		}
		
		// dragging/resizing
		if let dragInfo {
			let mousePositionChange = mousePosition - dragInfo.initialMousePosition
			
			var newWindowPosition: CGPoint
			
			if let resizingFrom = dragInfo.resizingFrom {
				let xChange: CGFloat = resizingFrom.left ? mousePositionChange.x : 0
				let yChange: CGFloat = resizingFrom.top ? mousePositionChange.y : 0
				
				let widthChange: CGFloat = if resizingFrom.left {
					-mousePositionChange.x
				} else {
					mousePositionChange.x
				}
				
				let heighChange: CGFloat = if resizingFrom.top {
					-mousePositionChange.y
				} else {
					mousePositionChange.y
				}
				
				let newWindowSize = CGSize(
					width: dragInfo.initialWindowSize.width + widthChange,
					height: dragInfo.initialWindowSize.height + heighChange
				)
				
				try! dragInfo.targetWindow.setAttribute(.size, value: newWindowSize)
				
				newWindowPosition = dragInfo.initialWindowPosition + CGPoint(
					x: xChange,
					y: yChange
				)
			} else {
				newWindowPosition = dragInfo.initialWindowPosition + mousePositionChange
				
				let distancePastLeftEdge = screenBounds.minX - newWindowPosition.x
				
				if distancePastLeftEdge > edgeSnappingDistance {
					newWindowPosition.x += edgeSnappingDistance
				} else if distancePastLeftEdge > 0 {
					newWindowPosition.x = screenBounds.minX
				}
				
				let windowRightEdgeX = newWindowPosition.x + dragInfo.initialWindowSize.width
				let distancePastRightEdge = windowRightEdgeX - screenBounds.maxX
				
				if distancePastRightEdge > edgeSnappingDistance {
					newWindowPosition.x -= edgeSnappingDistance
				} else if distancePastRightEdge > 0 {
					newWindowPosition.x = screenBounds.maxX - dragInfo.initialWindowSize.width
				}
				
				let windowBottomEdgeY = newWindowPosition.y + dragInfo.initialWindowSize.height
				let distancePastBottomEdge = windowBottomEdgeY - screenBounds.maxY
				
				if distancePastBottomEdge > edgeSnappingDistance {
					newWindowPosition.y -= edgeSnappingDistance
				} else if distancePastBottomEdge > 0 {
					newWindowPosition.y = screenBounds.maxY - dragInfo.initialWindowSize.height
				}
			}
			
			try! dragInfo.targetWindow.setAttribute(.position, value: newWindowPosition)
			
			if type != .leftMouseUp, type != .rightMouseUp {
				return nil
			}
		}
		
		// mouse up
		if type == .leftMouseUp || type == .rightMouseUp, dragInfo != nil {
			dragInfo = nil
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
