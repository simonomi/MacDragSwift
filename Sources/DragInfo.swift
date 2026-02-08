import CoreGraphics
import AXSwift

struct DragInfo {
	var initialWindowPosition: CGPoint
	var initialMousePosition: CGPoint
	var initialWindowSize: CGSize
	
	var targetWindow: UIElement
	
	// nil if not resizing
	var resizingFrom: Corner?
}
