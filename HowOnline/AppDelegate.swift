//
//  AppDelegate.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Cocoa
import CoreWLAN

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	
	let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
	var pinger: LGPinger! = nil
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		if let button = statusItem.button {
			button.image = imageForStatus("wifi", percent: 0.2, color: NSColor.greenColor(), imageSize: button.frame.size)
		}
		
		probe()
	}
	
	func probe() {
		guard let interface = CWWiFiClient()?.interface() else {
			NSLog("no wifi interface found")
			return
		}
		
		guard interface.ssid() != nil else {
			NSLog("no ssid")
			return
		}
		
		guard let ip = getWiFiAddress() else {
			NSLog("no ip")
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			NSLog("bad ip")
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			NSLog("no gateway")
			return
		}
		
		pinger = LGPinger(hostname: gatewayIP, successCb: { (timeElapsedMs) -> Void in
			self.pinger = LGPinger(hostname: "8.8.8.8", successCb: { (timeElapsedMs) ->	Void in
				self.pinger = LGPinger(hostname: "google.com", successCb: {	(timeElapsedMs) -> Void in
					NSLog("success pinging google.com: %d", timeElapsedMs)
					
					}, errorCb: { () -> Void in
						NSLog("failed pinging google")
				})
				self.pinger.ping()
				}, errorCb: { () -> Void in
					NSLog("no outside ping")
			})
			self.pinger.ping()
			}, errorCb: { () -> Void in
				NSLog("no router")
		})
		pinger.ping()
	}
		
	func imageForStatus(text: String, percent: Float, color: NSColor, imageSize: NSSize) -> NSImage? {
		return NSImage(size: imageSize, flipped: false, drawingHandler: { (rect: NSRect) -> Bool in
			// Use the same algo for both the border and fill of the progress bar
			func genProgressBarRect(percent: CGFloat) -> CGRect {
				let maxProgressBarWidth = rect.size.width - 2 - 2
				return CGRect(x: 2, y: rect.size.height - 4 - 2, width: maxProgressBarWidth * percent, height: 4)
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
			
			let attrs = [
				NSFontAttributeName: NSFont.systemFontOfSize(8),
				NSParagraphStyleAttributeName: paragraphStyle
			]
			
			text.drawWithRect(textRect, options: .UsesLineFragmentOrigin, attributes: attrs, context: nil)
			
			return true
		})
	}
	
	
}

