//
//  PortTester.swift
//  HowOnline
//
//  Created by Larry Gadea on 3/5/16.
//  Copyright © 2016 Larry Gadea. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class PortTester: GCDAsyncSocketDelegate {
	typealias ResultBlock = (success: Bool) -> ()
	
	var socket: GCDAsyncSocket!
	var resultBlock: ResultBlock!
	
	func testPortOpen(host: String, port: Int, timeoutSeconds: Double, result: ResultBlock) {
		self.resultBlock = result
		self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
		
		do {
			try self.socket.connectToHost(host, onPort: UInt16(port), withTimeout: NSTimeInterval(timeoutSeconds))
		} catch {
			resultBlock(success: false)
		}
	}
	
	@objc
	func socket(socket: GCDAsyncSocket, didConnectToHost: String, port: UInt16) {
		socket.disconnect()
		resultBlock(success: true)
	}
	
	@objc
	func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
		if err != nil {
			resultBlock(success: false)
		}
	}
}
