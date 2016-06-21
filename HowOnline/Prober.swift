//
//  Prober.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/25/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Foundation
import CoreWLAN

protocol ProberDelegate {
	func probeResult(prober: Prober, result: Prober.ProbeResult)
}

class Prober {
	typealias ProbeResult = (success: Bool, text: String, longText: String)
	
	let delegate: ProberDelegate
	let pinger: Pinger! = Pinger()
	let portTester: PortTester! = PortTester()
	var gatewayIP: String!
	
	var curProbe = 0
	var probing: Bool = false

	var probes: [() -> ()] {
		return [simpleChecks, testGateway, pingEightDotEight, resolveGoogle, pingGoogle]
	}
	
	init(delegate: ProberDelegate) {
		self.delegate = delegate
	}
	
	func probe() {
		if probing {
			print("already probing, ignoring request")
			return
		}
		probing = true
		
		probes[curProbe]()
	}
	
	private func probeResult(result: ProbeResult) {
		probing = false
		
		if result.success {
			// The last probe being successful means we should pass the actual success message
			if curProbe == probes.count - 1 {
				self.delegate.probeResult(self, result: result)
			
			// Otherwise, proceed to the next probe test
			} else {
				curProbe += 1
				probe()
			}
			
		} else {
			curProbe = 0
			self.delegate.probeResult(self, result: result)
		}
	}
	
	private func pingProbe(ip: String, errorText: String, longErrorText: String) {
		pinger.ping(ip) { (timeElapsedMs) -> () in
			if timeElapsedMs == nil {
				self.probeResult(ProbeResult(success: false, text: errorText, longText: longErrorText))
				return
			}
			
			self.probeResult(ProbeResult(success: true, text: "\(timeElapsedMs!)ms", longText: "OK. Ping to Google: \(timeElapsedMs!)ms"))
		}
	}
	
	//////
	
	private func simpleChecks() {
		guard let interface = CWWiFiClient()?.interface() else {
			self.probeResult(ProbeResult(success: false, text: "wifi if", longText: "Couldn't detect a WiFi interface"))
			return
		}
		
		guard interface.powerOn() else {
			self.probeResult(ProbeResult(success: false, text: "wifi off", longText: "Your WiFi is turned off"))
			return
		}
		
		guard interface.ssid() != nil else {
			self.probeResult(ProbeResult(success: false, text: "no ssid", longText: "Not associated to a WiFi network"))
			return
		}
		
		guard let ip = getWiFiAddress() where ip.characters.count > 0 else {
			self.probeResult(ProbeResult(success: false, text: "no ip", longText: "On WiFi, but no IP address assigned"))
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			self.probeResult(ProbeResult(success: false, text: "self ip", longText: "On WiFi, but self-assigned IP"))
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			self.probeResult(ProbeResult(success: false, text: "no gw", longText: "On WiFi, but no internet gateway assigned"))
			return
		}
		self.gatewayIP = gatewayIP
		
		probeResult(ProbeResult(success: true, text: "", longText: ""))
	}
	
	private func testGateway() {
		// Some gateways aren't pingable for whatever unspeakable reason. As such we'll ping
		// it first, and if it fails we'll try a connection to port 22, 80 and
		pinger.ping(self.gatewayIP) { (timeElapsedMs) -> () in
			if timeElapsedMs == nil {
				self.portTester.testPortOpen(self.gatewayIP, port: 80, timeoutSeconds: 2.0) { (success) -> () in
					if success {
						self.probeResult(ProbeResult(success: true, text: "", longText: ""))
						return
					}
					
					self.portTester.testPortOpen(self.gatewayIP, port: 22, timeoutSeconds: 2.0) { (success) -> () in
						if success {
							self.probeResult(ProbeResult(success: true, text: "", longText: ""))
							return
						}
						
						self.portTester.testPortOpen(self.gatewayIP, port: 23, timeoutSeconds: 2.0) { (success) -> () in
							if success {
								self.probeResult(ProbeResult(success: true, text: "", longText: ""))
								return
							}
							
							self.probeResult(ProbeResult(success: false, text: "bad gw", longText: "Gateway wasn't pingable or connectable via HTTP/SSH/Telnet"))
						}
					}
				}
				
				return
			}
			
			self.probeResult(ProbeResult(success: true, text: "", longText: ""))
		}
	}
	
	private func pingEightDotEight() {
		pingProbe("8.8.8.8", errorText: "ping 8.", longErrorText: "Failed to ping 8.8.8.8")
	}
	
	private func resolveGoogle() {
		testResolveHostname("google.com") { (success) -> Void in
			if !success {
				self.probeResult(ProbeResult(success: false, text: "dns", longText: "Failed to do a DNS lookup for google.com"))
				return
			}
			
			self.probeResult(ProbeResult(success: true, text: "", longText: ""))
		}
	}
	
	private func pingGoogle() {
		pingProbe("google.com", errorText: "ping G", longErrorText: "Failed to ping google.com")
	}	
}