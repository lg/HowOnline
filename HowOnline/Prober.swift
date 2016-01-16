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
	
	var delegate: ProberDelegate
	var pinger: Pinger!
	var gatewayIP: String!
	
	var lastFailure: ProbeResult?
	var curProbe = 0
	var probing: Bool = false

	var probes: [() -> ()] {
		return [simpleChecks, pingGateway, pingEightDotEight, resolveGoogle, pingGoogle]
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
		// TODO: on failure, maybe just reset?
		
		probing = false
		
		if result.success {
			if curProbe == probes.count - 1 {
				self.delegate.probeResult(self, result: result)
			} else {
				if let failure = self.lastFailure {
					self.delegate.probeResult(self, result: failure)
					self.lastFailure = nil
					
				} else {
					curProbe++
					probe()
				}
			}
			
		} else {
			if curProbe == 0 {
				self.delegate.probeResult(self, result: result)
				self.lastFailure = nil
				
			} else {
				self.lastFailure = result
				curProbe--
				probe()
			}
		}
	}
	
	private func pingProbe(ip: String, errorText: String, longErrorText: String) {
		pinger = Pinger()
		pinger.ping(ip) { [unowned self] (timeElapsedMs) -> () in
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
	
	private func pingGateway() {
		pingProbe(self.gatewayIP, errorText: "ping gw", longErrorText: "Failed to ping your internet gateway")
	}
	
	private func pingEightDotEight() {
		pingProbe("8.8.8.8", errorText: "ping 8.", longErrorText: "Failed to ping 8.8.8.8")
	}
	
	private func resolveGoogle() {
		testResolveHostname("google.com") { [unowned self] (success) -> Void in
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