//
//  XPCMain.h
//  Today Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TodayScripts.h"

@interface XPCListenerDelegate : NSObject <NSXPCListenerDelegate> @end
XPCListenerDelegate *listenerDelegate;

NSXPCListener *listener;
NSXPCConnection *connection;

// This object implements the protocol which we have defined. It provides the
// actual behavior for the service. It is 'exported' by the service to make it
// available to the process hosting the service over an NSXPCConnection.
@interface XPCHelper : NSObject <XPCHelping> @end
XPCHelper *helper;
