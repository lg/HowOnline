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
	
	func probeResult(text: String, success: Bool) {
		if let button = statusItem.button {
			button.image = imageForStatus(text, percent: 1.0, color: success ? NSColor.greenColor() : NSColor.redColor(), imageSize: button.frame.size)
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
			probeResult("wifi if", success: false)
			return
		}
		
		guard interface.ssid() != nil else {
			probeResult("no wifi", success: false)
			return
		}
		
		guard let ip = getWiFiAddress() else {
			probeResult("no ip", success: false)
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			probeResult("self ip", success: false)
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			probeResult("no gw", success: false)
			return
		}
		
		// TODO: look into a way to make this be synchronous
		
		pinger = LGPinger(hostname: gatewayIP, successCb: { (timeElapsedMs) -> Void in
			self.pinger = LGPinger(hostname: "8.8.8.8", successCb: { (timeElapsedMs) ->	Void in
				
				testResolveHostname("google.com", { (success) -> Void in
					if success {
						
						self.pinger = LGPinger(hostname: "google.com", successCb: {	(timeElapsedMs) -> Void in
							self.probeResult("\(timeElapsedMs)ms", success: true)
							
							}, errorCb: { () -> Void in
								self.probeResult("ping G", success: false)
						})
						self.pinger.ping()
						
					} else {
						self.probeResult("dns", success: false)
					}
				})
				
			}, errorCb: { () -> Void in
				self.probeResult("ping 8.", success: false)
			})
			self.pinger.ping()
			
		}, errorCb: { () -> Void in
			self.probeResult("ping gw", success: false)
		})
		pinger.ping()
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

