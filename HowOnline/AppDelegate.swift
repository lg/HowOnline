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
	var refreshTimer: NSTimer! = nil
	var probing: Bool = false
	
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		refreshTimer = NSTimer.scheduledTimerWithTimeInterval(5.0, target: self, selector: "probe", userInfo: nil, repeats: true)
		
		probe()
	}
	
	func probeResult(text: String, percent: Double, color: NSColor) {
		// TODO: get rid of percent and just have it be a red bar
		
		if let button = statusItem.button {
			button.image = imageForStatus(text, percent: percent, color: color, imageSize: button.frame.size)
		}
		
		probing = false
	}
	
	func probe() {
		// TODO: trigger this when wifi status changes
		// TODO: go backwards depending on where we are (so were not pinging all the other things so much)
		
		// Sometimes a ping from before could still be running. We wait for it to timeout.
		if probing { return }
		probing = true
		
		guard let interface = CWWiFiClient()?.interface() else {
			probeResult("no wifi", percent: 0.1, color: NSColor.redColor())
			return
		}
		
		guard interface.ssid() != nil else {
			probeResult("no ssid", percent: 0.2, color: NSColor.redColor())
			return
		}
		
		guard let ip = getWiFiAddress() else {
			probeResult("no ip", percent: 0.3, color: NSColor.redColor())
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			probeResult("self ip", percent: 0.4, color: NSColor.redColor())
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			probeResult("no gate", percent: 0.5, color: NSColor.redColor())
			return
		}
		
		// TODO: look into a way to make this be synchronous
		
		pinger = LGPinger(hostname: gatewayIP, successCb: { (timeElapsedMs) -> Void in
			self.pinger = LGPinger(hostname: "8.8.8.8", successCb: { (timeElapsedMs) ->	Void in
				
				testResolveHostname("google.com", { (success) -> Void in
					if success {
						
						self.pinger = LGPinger(hostname: "google.com", successCb: {	(timeElapsedMs) -> Void in
							self.probeResult("\(timeElapsedMs)ms", percent: 1.0, color: NSColor.greenColor())
							
							}, errorCb: { () -> Void in
								self.probeResult("ping G", percent: 0.7, color: NSColor.redColor())
						})
						self.pinger.ping()
						
					} else {
						self.probeResult("dns", percent: 0.6, color: NSColor.redColor())
					}
				})
				
			}, errorCb: { () -> Void in
				self.probeResult("ping 8.", percent: 0.6, color: NSColor.redColor())
			})
			self.pinger.ping()
			
		}, errorCb: { () -> Void in
			self.probeResult("ping gate", percent: 0.5, color: NSColor.redColor())
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

