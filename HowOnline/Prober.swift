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
	enum ProbeResult {
		case Success(text: String?)
		case Failure(text: String)
	}
	
	var delegate: ProberDelegate
	var pinger: LGPinger!
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
		
		switch result {
		case .Success(_):
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
			
		case .Failure(_):
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
	
	private func pingProbe(ip: String, errorText: String) {
		pinger = LGPinger()
		pinger.ping(ip) { (timeElapsedMs) -> () in
			if timeElapsedMs == nil {
				self.probeResult(.Failure(text: errorText))
				return
			}
			
			self.probeResult(.Success(text: "\(timeElapsedMs!)ms"))
		}
	}
	
	//////
	
	private func simpleChecks() {
		guard let interface = CWWiFiClient()?.interface() else {
			probeResult(.Failure(text: "wifi if"))
			return
		}
		
		guard interface.powerOn() else {
			probeResult(.Failure(text: "wifi off"))
			return
		}
		
		guard interface.ssid() != nil else {
			probeResult(.Failure(text: "no ssid"))
			return
		}
		
		guard let ip = getWiFiAddress() where ip.characters.count > 0 else {
			probeResult(.Failure(text: "no ip"))
			return
		}
		
		guard !ip.hasPrefix("169.254") && !ip.hasPrefix("0.0") else {
			probeResult(.Failure(text: "self ip"))
			return
		}
		
		guard let gatewayIP = defaultGateway() else {
			probeResult(.Failure(text: "no gw"))
			return
		}
		self.gatewayIP = gatewayIP
		
		probeResult(.Success(text: nil))
	}
	
	private func pingGateway() {
		pingProbe(self.gatewayIP, errorText: "ping gw")
	}
	
	private func pingEightDotEight() {
		pingProbe("8.8.8.8", errorText: "ping 8.")
	}
	
	private func resolveGoogle() {
		testResolveHostname("google.com") { (success) -> Void in
			if !success {
				self.probeResult(.Failure(text: "dns"))
				return
			}
			
			self.probeResult(.Success(text: nil))
		}
	}
	
	private func pingGoogle() {
		pingProbe("google.com", errorText: "ping G")
	}	
}