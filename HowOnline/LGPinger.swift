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
	let pinger: SimplePing
	let successCb: (timeElapsedMs: Int) -> Void
	let errorCb: () -> Void
	var timeoutTimer: NSTimer!
	var pingStartTime: CFTimeInterval = 0
	
	init(hostname: String, successCb: (timeElapsedMs: Int) -> Void, errorCb: () -> Void) {
		self.pinger = SimplePing(hostName: hostname)
		self.successCb = successCb
		self.errorCb = errorCb
	}
	
	func ping() {
		pingStartTime = CACurrentMediaTime()
		pinger.delegate = self;
		pinger.start()
	}
	
	func stopPinging() {
		pinger.stop()
		if timeoutTimer != nil {
			timeoutTimer.invalidate()
		}
	}
	
	func timeout() {
		stopPinging()
		self.errorCb()
	}
	
	func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
		stopPinging()
		self.errorCb()
	}
	
	func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
		stopPinging()
		self.errorCb()
	}
	
	func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
		stopPinging()
		self.successCb(timeElapsedMs: Int((CACurrentMediaTime() - pingStartTime) * 1000))
	}
	
	func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
		stopPinging()
		self.errorCb()
	}
	
	func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
		pinger.sendPingWithData(nil)
		
		timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(3.0, target: self, selector: "timeout", userInfo: nil, repeats: false)
	}
}