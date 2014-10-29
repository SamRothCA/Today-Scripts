//
//  XPCMain.m
//  xpc
//
//  Created by Sam Rothenberg on 8/10/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "XPCMain.h"

@implementation XPCListenerDelegate

- (BOOL)listener:(NSXPCListener *)aListener shouldAcceptNewConnection:(NSXPCConnection *)aConnection
{
    helper = [XPCHelper.alloc init];

    // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    connection = aConnection;

    // Configure the connection.
    // First, set the interface that the exported object implements.
    connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCHelping)];
    
    // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
    connection.exportedObject = helper;
    
    // Resuming the connection allows the system to deliver more incoming messages.
    [connection resume];

    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end

int main()
{
    // Set up the one NSXPCListener for this service. It will handle all incoming connections.
    listener = NSXPCListener.serviceListener;

    // Create the delegate for the service.
    listenerDelegate = [XPCListenerDelegate.alloc init];
    listener.delegate = listenerDelegate;
    
    // Resuming the serviceListener starts this service. This method does not return.
    [listener resume];

    return 0;
}
