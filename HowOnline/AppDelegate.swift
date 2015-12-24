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
		probe()
	}
	
	func updateStatus(text: String, percent: Double, color: NSColor) {
		if let button = statusItem.button {
			button.image = imageForStatus(text, percent: percent, color: color, imageSize: button.frame.size)
		}
	}
	
	func probe() {
		updateStatus("ping G", percent: 0.7, color: NSColor.redColor())
		
		guard let interface = CWWiFiClient()?.interface() else {
			updateStatus("no wifi", percent: 0.1, color: NSColor.redColor())
			return
		}
		
		guard interface.ssid() != nil else {
			updateStatus("no ssid", percent: 0.2, color: NSColor.redColor())
			return
		}
		
		guard let ip = getWiFiAddress() else {
			updateStatus("no ip", percent: 0.3, color: NSColor.redColor())
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			updateStatus("self ip", percent: 0.4, color: NSColor.redColor())
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			updateStatus("router", percent: 0.5, color: NSColor.redColor())
			return
		}
		
		pinger = LGPinger(hostname: gatewayIP, successCb: { (timeElapsedMs) -> Void in
			self.pinger = LGPinger(hostname: "8.8.8.8", successCb: { (timeElapsedMs) ->	Void in
				
				// TODO: resolve google.com before trying to ping it (for better error messages). test it resolves correctly
				
				self.pinger = LGPinger(hostname: "google.com", successCb: {	(timeElapsedMs) -> Void in
					self.updateStatus("\(timeElapsedMs)ms", percent: 1.0, color: NSColor.greenColor())
					
					}, errorCb: { () -> Void in
						self.updateStatus("ping G", percent: 0.7, color: NSColor.redColor())
				})
				self.pinger.ping()
				}, errorCb: { () -> Void in
					self.updateStatus("ping 8.", percent: 0.6, color: NSColor.redColor())
			})
			self.pinger.ping()
			}, errorCb: { () -> Void in
				self.updateStatus("ping rtr", percent: 0.5, color: NSColor.redColor())
		})
		pinger.ping()
	}
		
	func imageForStatus(text: String, percent: Double, color: NSColor, imageSize: NSSize) -> NSImage? {
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

