//
//  XPCHelper.m
//  xpc
//
//  Created by Sam Rothenberg on 8/10/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "TodayScripts.h"
#import "XPCHelper.h"
#include <util.h>


@implementation XPCHelper
{
    // The dictionary of environment variables for spawned tasks.
    NSMutableDictionary *environment;
    // Queue for performing asynchonous tasks.
    dispatch_queue_t queue;

    // A dictionary of the active tasks.
    NSMutableDictionary *tasks;
}

- (id)init
{
    if (! (self = super.init)) return nil;

    // Create an environment for tasks based on our own, and add the details of
    // our "terminal."
    environment = NSProcessInfo.processInfo.environment.mutableCopy;
    environment[@"TERM"   ] = @"ansi";
    environment[@"COLUMNS"] = @"40";
    environment[@"PAGER"  ] = @"/bin/cat";

    // We will perform asynchronous tasks on the default background queue.
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // Set up the dictionary to keep records of our tasks.
    tasks = [[NSMutableDictionary alloc] init];

    return self;
}

- (void)launchScript:(NSDictionary *)script forUUID:(NSString *)UUID handler:(XPCHandler)handler;
{
//    NSURL *programURL = [NSURL URLWithString:script[TodayScriptProgramKey]];
//    NSUserUnixTask *task = [[NSUserUnixTask alloc] initWithURL:programURL error:nil];

    // Create a new task object and add it to our dictionary.
    NSTask *task = [[NSTask alloc] init];
    tasks[UUID] = task;

    // Set the task's program to the user's shell.
    task.launchPath = script[TodayScriptProgramKey];
    // Set the task's environment as previously determined.
    task.environment = environment;
    // Set our current directory to the user's home directory.
    task.currentDirectoryPath = environment[@"HOME"];

    // Open a 40-character wide pseudo-TTY for this script, getting its file
    // descriptors.
    int master, slave;
    struct winsize size = { .ws_col = 40 };
    openpty(&master, &slave, NULL, NULL, &size);

    // Set up handles for the TTY's file descriptors, such that they close them
    // once we're done.
    NSFileHandle *masterHandle = NSFileHandle.alloc, *slaveHandle = NSFileHandle.alloc;
    masterHandle = [masterHandle initWithFileDescriptor:master closeOnDealloc:YES];
    slaveHandle  = [slaveHandle  initWithFileDescriptor:slave  closeOnDealloc:YES];

    // The script's output will be sent to the pseudo-TTY.
    task.standardOutput = task.standardError = slaveHandle;

    // If we were provided a script, convert it to UTF-8 to pass to the program.
    NSString *scriptString = script[TodayScriptScriptKey];
    if (scriptString.length) {
        // We will be piping the script to the program via its standard input.
        // Write the script to the pipe so that it is ready for the interpreter.
        NSPipe *pipe = NSPipe.pipe;
        task.standardInput = pipe.fileHandleForReading;
        [pipe.fileHandleForWriting writeData:[scriptString dataUsingEncoding:NSUTF8StringEncoding]];
        [pipe.fileHandleForWriting closeFile];
    }

    // Create a data object which can be modified by the TTY reader block, as
    // well as a semaphore which it can use to signal the termination block.
    __block NSData *outputData = nil;
    dispatch_semaphore_t outputSemaphore = dispatch_semaphore_create(0);

    dispatch_async(queue, ^
    {
        // Read the master handle in the background until the TTY is closed.
        outputData = [masterHandle readDataToEndOfFile];
        // After we've set the data object, we may signal the termination block
        // that it is ready.
        dispatch_semaphore_signal(outputSemaphore);
    });

    task.terminationHandler = ^(NSTask *task)
    {
        // If the task did not complete on its own volition, we we be returning
        // an invalid exit status and output.
        NSString *output = nil;
        int status = -1;

        // Close the TTY such that the reader thread stops waiting on it.
        [slaveHandle closeFile];

        // If the task ran to completion on its own volition, we will need to
        // process its results.
        if (task.terminationReason == NSTaskTerminationReasonExit)
        {
            // Wait for the reader thread to set the data object and signal us.
            dispatch_semaphore_wait(outputSemaphore, DISPATCH_TIME_FOREVER);
            // We will return the actual exit status of the process.
            status = task.terminationStatus;
            // Convert the UTF-8 output from the reader block to a string.
            output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        }

        // Return the results to the widget.
        handler(status, output);

        // Remove the task from our records.
        [self->tasks removeObjectForKey:UUID];
    };

    // Launch the task.
    [task launch];
}

- (void)terminateScriptForUUID:(NSString *)UUID {
    [(NSTask *)tasks[UUID] terminate];
}

@end

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
