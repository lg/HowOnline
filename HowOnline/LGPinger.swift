//
//  LGPinger.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Foundation
import QuartzCore

class LGPinger: NSObject, SimplePingDelegate {
	typealias CompletionBlock = (timeElapsedMs: Int?) -> ()
	var completionBlock: CompletionBlock!

	var pinger: SimplePing!
	var timeoutTimer: NSTimer!
	var pingStartTime: CFTimeInterval = 0
	
	func ping(hostname: String, completionBlock: CompletionBlock) {
		self.pinger = SimplePing(hostName: hostname)
		self.completionBlock = completionBlock
		
		pingStartTime = CACurrentMediaTime()
		
		pinger.delegate = self;
		pinger.start()
	}
	
	func stopPinging(success: Bool) {
		pinger.stop()
		if timeoutTimer != nil {
			timeoutTimer.invalidate()
		}
		
		if success {
			let elapsedTime = Int((CACurrentMediaTime() - pingStartTime) * 1000)
			self.completionBlock(timeElapsedMs: elapsedTime)
		} else {
			self.completionBlock(timeElapsedMs: nil)
		}
	}
	
	func timeout() {
		stopPinging(false)
	}
	
	func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
		stopPinging(false)
	}
	
	func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
		stopPinging(false)
	}
	
	func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
		stopPinging(true)
	}
	
	func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
		stopPinging(false)
	}
	
	func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
		timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timeout", userInfo: nil, repeats: false)
		pinger.sendPingWithData(nil)
	}
}