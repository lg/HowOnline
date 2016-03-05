//
//  Utilities.swift
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

import Foundation

// Return IP address of WiFi interface (en0) as a String, or `nil`
func getWiFiAddress() -> String? {
	var address : String?
	
	// Get list of all interfaces on the local machine:
	var ifaddr : UnsafeMutablePointer<ifaddrs> = nil
	if getifaddrs(&ifaddr) == 0 {
		
		// For each interface ...
		for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
			let interface = ptr.memory
			
			// Check for IPv4 or IPv6 interface:
			let addrFamily = interface.ifa_addr.memory.sa_family
			if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
				
				// Check interface name:
				if let name = String.fromCString(interface.ifa_name) where name.hasPrefix("en") {
					
					// Convert interface address to a human readable string:
					var addr = interface.ifa_addr.memory
					var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
					getnameinfo(&addr, socklen_t(interface.ifa_addr.memory.sa_len),
						&hostname, socklen_t(hostname.count),
						nil, socklen_t(0), NI_NUMERICHOST)
					address = String.fromCString(hostname)
          
          if let checkAddress = address where checkAddress != "" {
            break
          }
				}
			}
		}
		freeifaddrs(ifaddr)
	}
	
	return address
}
