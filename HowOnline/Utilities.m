//
//  Utilities.m
//  HowOnline
//
//  Created by Larry Gadea on 12/22/15.
//  Copyright © 2015 Larry Gadea. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <net/route.h>
#import <arpa/inet.h>

int getdefaultgateway(in_addr_t * addr);		// in getgateway.c

NSString* defaultGateway() {
	struct in_addr gatewayaddr;
	
	if (getdefaultgateway(&(gatewayaddr.s_addr)) >= 0) {
		return [NSString stringWithFormat: @"%s", inet_ntoa(gatewayaddr)];
	}
	
	return nil;
}

typedef void (^ResolveCompleteBlock)(bool success);

// Callback from DNS resolver
static void HostResolveCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info) {
	ResolveCompleteBlock block = (__bridge_transfer ResolveCompleteBlock) info;

	if ((error != NULL) && (error->domain != 0)) {
		block(false);
	} else {
		block(true);
	}
}

void testResolveHostname(NSString* hostName, ResolveCompleteBlock completeBlock) {
	CFHostRef cfHostName;
	CFHostClientContext context = {0, (__bridge_retained void *)(completeBlock), NULL, NULL, NULL};
	CFStreamError streamError;

	cfHostName = CFHostCreateWithName(NULL, (__bridge_retained CFStringRef) hostName);
	CFHostSetClient(cfHostName, HostResolveCallback, &context);

	CFHostScheduleWithRunLoop(cfHostName, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	
	if (!CFHostStartInfoResolution(cfHostName, kCFHostAddresses, &streamError)) {
		completeBlock(true);
		CFRelease((__bridge CFTypeRef)(completeBlock));
	}
}

