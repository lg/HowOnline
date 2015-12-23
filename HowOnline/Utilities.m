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
