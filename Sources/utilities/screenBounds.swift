import Cocoa

// the origin for screen bounds is the bottom left, while the origin for
// window layout is the top right. this has the origin in the top right
// for window layout
//
// unfortunately, the frames don't update when the dock is moved until the
// app has been restarted, so caching this doesn't affect functionality
let screenBounds: NSRect = {
	let fullFrame = NSScreen.main!.frame
	var visibleFrame = NSScreen.main!.visibleFrame
	
	visibleFrame.origin.y = fullFrame.height - visibleFrame.maxY
	
	return visibleFrame
}()
