//
//  AppDelegate.swift
//  HowOnlineLauncher
//
//  Created by Larry Gadea on 1/16/16.
//  Copyright © 2016 Larry Gadea. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(aNotification: NSNotification) {
		for app in NSWorkspace.sharedWorkspace().runningApplications {
			if app.bundleIdentifier == "com.lg.HowOnline" {
				NSApp.terminate(nil)
				return
			}
		}
		
		let path = NSBundle.mainBundle().bundlePath as NSString
		var components = path.pathComponents
		components.removeLast()
		components.removeLast()
		components.removeLast()
		components.append("MacOS")
		components.append("HowOnline")
		
		let newPath = NSString.pathWithComponents(components)
		
		NSWorkspace.sharedWorkspace().launchApplication(newPath)
		
		NSApp.terminate(nil)
	}
}

