//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#include <ifaddrs.h>				// for getting the ip address
#include "SimplePing.h"

NSString* defaultGateway();

typedef void (^ResolveCompleteBlock)(bool success);
void testResolveHostname(NSString* hostName, ResolveCompleteBlock completeBlock);
