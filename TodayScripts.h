//
//  XPCHelper.h
//  xpc
//
//  Created by Sam Rothenberg on 8/10/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSString *TodayScriptLabelKey;
extern const NSString *TodayScriptProgramKey;
extern const NSString *TodayScriptScriptKey;
extern const NSString *TodayScriptAutoRunKey;
extern const NSString *TodayScriptShowStatusKey;

// The protocol that this service will vend as its API. This header file will
// also need to be visible to the process hosting the service. Replace the API
// of this protocol with an API appropriate to the service you are vending.

typedef void (^ XPCHandler )(int status, NSString *output);

@protocol XPCHelping

- (void)launchScript:(NSDictionary *)script forUUID:(NSString *)UUID handler:(XPCHandler)handler;

- (void)terminateScriptForUUID:(NSString *)UUID;

@end
