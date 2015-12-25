//
//  AppDelegate.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ProberDelegate {

	@IBOutlet weak var window: NSWindow!
	
	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
	var refreshTimer: NSTimer! = nil
	var prober: Prober!
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		refreshTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "probe", userInfo: nil, repeats: true)
		prober = Prober(delegate: self)
		probe()
	}
	
	func probeResult(prober: Prober, result: Prober.ProbeResult) {
		if let button = statusItem.button {
			switch result {
			case .Success(let text):
				button.image = imageForStatus(text!, percent: 1.0, color: NSColor.greenColor(), imageSize: button.frame.size)
			case let .Failure(text):
				button.image = imageForStatus(text, percent: 1.0, color: NSColor.redColor(), imageSize: button.frame.size)
			}
		}
	}
	
	func probe() {
		prober.probe()
	}
	
	func imageForStatus(text: String, percent: Double, color: NSColor, imageSize: NSSize) -> NSImage? {
		return NSImage(size: imageSize, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
			// Use the same algo for both the border and fill of the progress bar
			func genProgressBarRect(percent: CGFloat) -> CGRect {
				let maxProgressBarWidth = rect.size.width - 2 - 2
				return CGRect(x: 2, y: rect.size.height - 4 - 4, width: maxProgressBarWidth * percent, height: 4)
			}
		
			// Fill first, then draw border on top
			color.setFill()
			NSBezierPath(roundedRect: genProgressBarRect(CGFloat(percent)), xRadius: 2, yRadius: 2).fill()
			
			NSColor.blackColor().setStroke()
			NSBezierPath(roundedRect: genProgressBarRect(1.0), xRadius: 2, yRadius: 2).stroke()
			
			let textRect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height - 8)
			
			// The text needs to be really small to fit
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .Center
			paragraphStyle.lineBreakMode = .ByClipping
			
			let attrs = [
				NSFontAttributeName: NSFont.systemFontOfSize(8),
				NSParagraphStyleAttributeName: paragraphStyle
			]
			
			text.drawWithRect(textRect, options: .UsesLineFragmentOrigin, attributes: attrs, context: nil)
			
			return true
		})
	}
}