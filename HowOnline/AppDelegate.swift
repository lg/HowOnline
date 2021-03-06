//
//  AppDelegate.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Cocoa
import ReachabilitySwift
import StartAtLoginController

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, ProberDelegate {
	@IBOutlet weak var statusMenuItem: NSMenuItem!
	@IBOutlet weak var menu: NSMenu!
	@IBOutlet weak var startAtLoginController: StartAtLoginController!
	
	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
	var refreshTimer: NSTimer! = nil
	var reachability: Reachability?
	var prober: Prober!
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// The menu is defined in interface builder
		statusItem.menu = self.menu
		updateMenu(false, text: "hello", longText: "Hello")
		
		startReachability()
		
		refreshTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: #selector(probe), userInfo: nil, repeats: true)
		prober = Prober(delegate: self)
		probe()
	}
	
	func startReachability() {
		let refreshBlock: (Reachability) -> () = { reachability in
			dispatch_async(dispatch_get_main_queue()) {
				self.probe()
			}
		}
		
		do {
			// We dont need any more sophistication than just checking for a wifi connection
			// since we do our own internet connection checking
			let reachability = try Reachability.reachabilityForLocalWiFi()
			self.reachability = reachability
			
			reachability.whenReachable = refreshBlock
			reachability.whenUnreachable = refreshBlock
			try reachability.startNotifier()
		} catch {
			print("Unable to create Reachability")
			return
		}
	}
	
	func probeResult(prober: Prober, result: Prober.ProbeResult) {
		updateMenu(result.success, text: result.text, longText: result.longText)
	}
	
	func updateMenu(success: Bool, text: String, longText: String) {
		if let button = statusItem.button {
			button.image = imageForStatus(text, filledBar: success, imageSize: button.frame.size)
			statusMenuItem.title = "Status: \(longText)"
			
			// Make the icon black and white, but this will also auto reverse colors in Dark/highlighted mode
			button.image!.template = true
		}
	}
	
	func probe() {
		prober.probe()
	}
	
	func imageForStatus(text: String, filledBar: Bool, imageSize: NSSize) -> NSImage? {
		return NSImage(size: imageSize, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
			NSColor.blackColor().setFill()
			NSColor.blackColor().setStroke()
			
			let progressBarRect = CGRect(x: 2, y: rect.size.height - 4 - 4, width: rect.size.width - 2 - 2, height: 4)
			let path = NSBezierPath(roundedRect: progressBarRect, xRadius: 2, yRadius: 2)
			
			path.stroke()
			if filledBar {
				path.fill()
			}
			
			let textRect = CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height - 9)
			
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