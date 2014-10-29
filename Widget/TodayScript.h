//
//  ScriptsArray.h
//  Today Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NotificationCenter/NotificationCenter.h>

#import "TodayScripts.h"


@interface TodayScriptArray : NSMutableArray

+ (TodayScriptArray *)sharedScripts;

- (void)saveDefaults;

- (NCUpdateResult)autoRun;

@end


@interface TodayScript : NSObject

// The user-defined settings for the script.
@property NSString *label;
@property NSString *program;
@property NSString *script;
@property BOOL autoRun;
@property BOOL showStatus;

// The above properties, represented by a dictionary. The dictionary's keys are
// TodayScriptLabelKey, TodayScriptProgramKey, etcetera. Setting this dictionary
// also sets the corresponding properties.
@property NSDictionary *dictionary;

// Keep track of whether we are running or not.
@property (readonly) BOOL running;

// The exit status and TTY output of the script. Setting the value output string
// also causes the attributed output string to update accordingly.
@property (readonly) NSNumber *status;

@property (readonly) NSString *output;
@property (readonly) NSString *unescapedOutput;
@property (readonly) NSAttributedString *attributedOutput;

- (void)run;
- (void)terminate;

@end
