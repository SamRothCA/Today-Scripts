 //
//  ScriptsArray.m
//  Today Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "TodayScript.h"
#import "AMR_ANSIEscapeHelper.h"

// The queue we will use for asynchronous tasks.
dispatch_queue_t queue;


// The XPC connection.
NSXPCConnection *XPC;
// The XPC proxy object for the helper.
id<XPCHelping> XPCHelper;
// A lock for working with the XPC helper.
NSConditionLock *XPCLock;


// Translater from ANSI-escaped NSStrings to NSAttributedStrings.
AMR_ANSIEscapeHelper *ANSIHelper;

#define PADDING_LEFT 0
#define COLUMN_WIDTH 6.02
#define COLUMN_COUNT 40.0
#define TAB_COLUMNS  8

// Paragraph style describing our tab stops.
NSMutableParagraphStyle *paragraphStyle;
// Characters to be trimmed from the beginning and end of displayed output.
NSCharacterSet *lineBreaks;


@interface TodayScript ()

@property (readwrite) BOOL running;

@property (readwrite) NSNumber *status;

@property (readwrite) NSString *output;
@property (readwrite) NSString *unescapedOutput;
@property (readwrite) NSAttributedString *attributedOutput;

@end
@implementation TodayScript
{
    NSString *UUID;
}

- (id)init
{
    if (! (self = super.init)) return nil;

    // Generate a UUID for consistently identifying this script internally.
    UUID = NSUUID.UUID.UUIDString;

    // Initialize the result-related properties.
    self.status = (id)NSNull.null;
    self.output = @"";

    return self;
}

// When our dictionary version is requested, create one with the relevant items.
- (NSDictionary *)dictionary
{
    return @{
        TodayScriptLabelKey      : self.label,
        TodayScriptProgramKey    : self.program,
        TodayScriptScriptKey     : self.script,
        TodayScriptAutoRunKey    : self.autoRun ? @YES : @NO,
        TodayScriptShowStatusKey : self.showStatus ? @YES : @NO
    };
}
// When we are modeling our values from a dictionary, set the relevant items.
- (void)setDictionary:(NSDictionary *)dictionary
{
    self.label      =  dictionary[ TodayScriptLabelKey      ];
    self.program    =  dictionary[ TodayScriptProgramKey    ];
    self.script     =  dictionary[ TodayScriptScriptKey     ];
    self.autoRun    = [dictionary[ TodayScriptAutoRunKey    ] boolValue];
    self.showStatus = [dictionary[ TodayScriptShowStatusKey ] boolValue];
    // Inititalize our state-related properies as well.
    self.running = NO;
    self.status  = (id)NSNull.null;
    self.output  = @"";
}

- (void)runWithLock:(NSConditionLock *)lock resultPointer:(NSValue *)resultPointer
{
    // If we were passed a pointer for tracking update results, upwrap it.
    NCUpdateResult *updateResult = resultPointer ? resultPointer.pointerValue : NULL;


    // Wait for our turn to influence the XPC connectivity.
    [XPCLock lock];

    // Set to property to indicate that we are now running.
    self.running = YES;

    // Check the value of the lock. If it is 0, then the connection will not
    // currently be active, so we should awaken it.
    if (XPCLock.condition == 0)
        [XPC resume];
    // Regardless of whether it was already active or whether we activated it,
    // increment the value of the lock to indicate our needing the connection.
    [XPCLock unlockWithCondition:XPCLock.condition + 1];

    // Pass ourselves in dictionary form to the XPC helper, with handler block
    // for receiving the script's PID and initiating our observation of it.
    [XPCHelper launchScript:self.dictionary forUUID:UUID handler: ^(int status, NSString *output)
    {
        // Once the process has terminated, we are no longer in need of the
        // XPC connection. Wait for our turn again to influence it.
        [XPCLock lock];

        // Check the value of the lock. If it is 1, then we were the last
        // ones to be using it, so it may now be suspended.
        if (XPCLock.condition == 1)
            [XPC suspend];
        // Either way, decrement the lock's value to indicate our own lack of
        // need for it.
        [XPCLock unlockWithCondition:XPCLock.condition - 1];

        // Unset our running status. Use the main thread so as to emit the
        // proper KVO and UI updates.
        [self performSelectorOnMainThread:
            @selector(setRunning:) withObject:nil waitUntilDone:NO];

        // Create a variable representing whether we have updates to display.
        BOOL newData = NO;

        // If the script was terminated prematurely, we should set our status to
        // to a null object, and no updates will need to be reported.
        if (status < 0)
            [self performSelectorOnMainThread:
                @selector(setStatus:) withObject:NSNull.null waitUntilDone:NO];

        // If the script ran to completion, process its results to see whether
        // they will need to be updated.
        else {
            // If we had not run to completion previously, or if the exit status
            // of the previous run was different than this one, our status is to
            // be updated with the new one.
            if (self.status == (id)NSNull.null || self.status.intValue != status)
            {
                [self performSelectorOnMainThread:
                    @selector(setStatus:) withObject:@(status) waitUntilDone:NO];

                newData = YES;
            }

            // Check whether the raw character output is identical to that of
            // the last completed run.
            if (! [self.output isEqualToString:output])
            {
                // If the raw output has changed, update the property.
                self.output = output;

                // Parsed the ANSI escaped string to an attributed string.
                NSMutableAttributedString *attributedOutput = [ANSIHelper
                    attributedStringWithANSIEscapedString:output].mutableCopy;

                // Get the bare characters from the parsed string.
                NSString *unescapedOutput = attributedOutput.string;

                // Get the unescaped output with excess line breaks trimmed off.
                NSString *trimmedOutput = [unescapedOutput stringByTrimmingCharactersInSet:lineBreaks];

                // If the string is empty after being trimmed of line breaks, we
                // will not be displaying an output field, so keep it simple.
                if ([trimmedOutput isEqualToString:@""]) {
                    attributedOutput = [[NSMutableAttributedString alloc] initWithString:@""];
                    unescapedOutput = @"";
                }

                // If the trimmed output is not empty, format the attributed and
                // unescaped versions of our output. The unescaped one is
                // inserted into a text field which is hidden, but expands with
                // its contents, causing the script's row view to expand with it.
                else {
                    // Determine the range of the untrimmed output, and use it
                    // to trim the line breaks from the attributed version.
                    NSRange trimmedOutputRange = [unescapedOutput rangeOfString:trimmedOutput];
                    attributedOutput = [attributedOutput
                        attributedSubstringFromRange:trimmedOutputRange].mutableCopy;
                    // Apply our tab stops to the formatted string.

                    [attributedOutput addAttribute:NSParagraphStyleAttributeName
                        value:paragraphStyle range:NSMakeRange(0, attributedOutput.length)];

                    // This text field needs two extra line breaks to expand
                    // the row properly.
                    unescapedOutput = [@"\n\n" stringByAppendingString:trimmedOutput];
                }

                // If the final attributed output does not match the one from
                // the previous run, we will need to update our output.
                if (! [attributedOutput isEqualToAttributedString:self.attributedOutput])
                {
                    [self performSelectorOnMainThread:@selector(setAttributedOutput:)
                        withObject:attributedOutput waitUntilDone:NO];

                    [self performSelectorOnMainThread:@selector(setUnescapedOutput:)
                        withObject:unescapedOutput waitUntilDone:NO];

                    newData = YES;
                }
            }
        }

        if (newData) {
            // If we were given a pointer to an update result variable, set it
            // to indicate that there are indeed changes.
            if (updateResult)
                *updateResult = NCUpdateResultNewData;

            // If we were passed a lock for tracking progress, we can now set it
            // to zero since we've already determined there are updates to show.
            if (lock) {
                [lock lock];
                [lock unlockWithCondition:0];
            }
        }
        // If we were passed a lock for tracking progress, we can now decrement
        // it to indicate we no longer need to be waited on.
        else if (lock) {
            [lock lock];
            [lock unlockWithCondition:lock.condition - 1];
        }
    }];
}

- (void)run
{
    // Safely determine whether we are already running. If we are not, go
    // through our run routine, no lock or result pointer required.
    [XPCLock lock];
    BOOL running = self.running;
    [XPCLock unlock];

    if (! running)
        [self runWithLock:nil resultPointer:nil];
}

- (void)terminate
{
    // Safely determine whether we are currently running. If in fact we are not,
    // ask the helper to terminate the process.
    [XPCLock lock];
    BOOL running = self.running;
    [XPCLock unlock];

    if (running)
        [XPCHelper terminateScriptForUUID:UUID];
}

- (oneway void)dealloc {
    [self terminate];
}

@end



@implementation TodayScriptArray
{
    // Backing store for our array.
    NSMutableArray *array;
}

+ (TodayScriptArray *)sharedScripts
{
    static TodayScriptArray *instance = nil;
    if (! instance) instance = [[TodayScriptArray alloc] init];
    return instance;
}

- (id)init
{
    if (! (self = super.init)) return nil;

    // We will use the default priority queue for asynchronous tasks.
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    // Set up the XPC connection to the helper object.
    XPC = [NSXPCConnection.alloc initWithServiceName:@"org.samroth.Today-Scripts.Widget.XPC"];
    XPC.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(XPCHelping)];
    XPCHelper = XPC.remoteObjectProxy;
    XPCLock = [[NSConditionLock alloc] initWithCondition:0];

    // Create the ANSI translator.
    ANSIHelper = [[AMR_ANSIEscapeHelper alloc] init];

    // Define the font to use.
    ANSIHelper.font = [NSFont fontWithName:@"Menlo" size:10];

#define SET_AMR_SGRCode(CODE, RED, GREEN, BLUE, ALPHA) \
    ANSIHelper.ansiColors[ @(AMR_SGRCode##CODE) ] = \
        [NSColor colorWithRed:RED green:GREEN blue:BLUE alpha:ALPHA]

    // Define the standard text colors to use.
    SET_AMR_SGRCode( FgBlack,         0.31764706, 0.31764706, 0.31764706, 1.0 );
    SET_AMR_SGRCode( FgRed,           0.94901961, 0.46666667, 0.47843137, 1.0 );
    SET_AMR_SGRCode( FgGreen,         0.60000000, 0.80000000, 0.60000000, 1.0 );
    SET_AMR_SGRCode( FgYellow,        1.00000000, 0.80000000, 0.40000000, 1.0 );
    SET_AMR_SGRCode( FgBlue,          0.40000000, 0.60000000, 0.80000000, 1.0 );
    SET_AMR_SGRCode( FgMagenta,       0.80000000, 0.60000000, 0.80000000, 1.0 );
    SET_AMR_SGRCode( FgCyan,          0.40000000, 0.80000000, 0.80000000, 1.0 );
    SET_AMR_SGRCode( FgWhite,         0.80000000, 0.80000000, 0.80000000, 1.0 );
    // Background colors are the same as the text colors, but with half opacity.
    SET_AMR_SGRCode( BgBlack,         0.31764706, 0.31764706, 0.31764706, 0.5 );
    SET_AMR_SGRCode( BgRed,           0.94901961, 0.46666667, 0.47843137, 0.5 );
    SET_AMR_SGRCode( BgGreen,         0.60000000, 0.80000000, 0.60000000, 0.5 );
    SET_AMR_SGRCode( BgYellow,        1.00000000, 0.80000000, 0.40000000, 0.5 );
    SET_AMR_SGRCode( BgBlue,          0.40000000, 0.60000000, 0.80000000, 0.5 );
    SET_AMR_SGRCode( BgMagenta,       0.80000000, 0.60000000, 0.80000000, 0.5 );
    SET_AMR_SGRCode( BgCyan,          0.40000000, 0.80000000, 0.80000000, 0.5 );
    SET_AMR_SGRCode( BgWhite,         0.80000000, 0.80000000, 0.80000000, 0.5 );
    // Bright text colors are more vivid than normal text colors.
    SET_AMR_SGRCode( FgBrightBlack,   0.00000000, 0.00000000, 0.00000000, 1.0 );
    SET_AMR_SGRCode( FgBrightRed,     0.86666667, 0.40000000, 0.40000000, 1.0 );
    SET_AMR_SGRCode( FgBrightGreen,   0.72941176, 0.77254902, 0.36470588, 1.0 );
    SET_AMR_SGRCode( FgBrightYellow,  0.92156863, 0.80392157, 0.38039216, 1.0 );
    SET_AMR_SGRCode( FgBrightBlue,    0.55686275, 0.71764706, 0.87450980, 1.0 );
    SET_AMR_SGRCode( FgBrightMagenta, 0.80784314, 0.67450980, 0.87058824, 1.0 );
    SET_AMR_SGRCode( FgBrightCyan,    0.51372549, 0.79215686, 0.74901961, 1.0 );
    SET_AMR_SGRCode( FgBrightWhite,   1.00000000, 1.00000000, 1.00000000, 1.0 );
    // Bright backgrounds are the same as bright text, but with half opacity.
    SET_AMR_SGRCode( BgBrightBlack,   0.00000000, 0.00000000, 0.00000000, 0.5 );
    SET_AMR_SGRCode( BgBrightRed,     0.86666667, 0.40000000, 0.40000000, 0.5 );
    SET_AMR_SGRCode( BgBrightGreen,   0.72941176, 0.77254902, 0.36470588, 0.5 );
    SET_AMR_SGRCode( BgBrightYellow,  0.92156863, 0.80392157, 0.38039216, 0.5 );
    SET_AMR_SGRCode( BgBrightBlue,    0.55686275, 0.71764706, 0.87450980, 0.5 );
    SET_AMR_SGRCode( BgBrightMagenta, 0.80784314, 0.67450980, 0.87058824, 0.5 );
    SET_AMR_SGRCode( BgBrightCyan,    0.51372549, 0.79215686, 0.74901961, 0.5 );
    SET_AMR_SGRCode( BgBrightWhite,   1.00000000, 1.00000000, 1.00000000, 0.5 );

    // Default text color is our non-bright white.
    ANSIHelper.ansiColors[ @(AMR_SGRCodeFgReset) ] = ANSIHelper.defaultStringColor =
        ANSIHelper.ansiColors[ @(AMR_SGRCodeFgWhite) ];
    
    // Enable dark mode in Mojave
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];

    if (![osxMode  isEqual: @"Dark"]) {
        ANSIHelper.ansiColors[ @(AMR_SGRCodeFgReset) ] = ANSIHelper.defaultStringColor = ANSIHelper.ansiColors[ @(AMR_SGRCodeFgBrightBlack) ];
    }

    // Default background is transparent.
    ANSIHelper.ansiColors[@( AMR_SGRCodeBgReset )] = NSColor.clearColor;

    paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.defaultTabInterval = COLUMN_WIDTH * TAB_COLUMNS;

    NSMutableArray *tabStops = [[NSMutableArray alloc] init];
    for (NSUInteger tabIndex = 1; tabIndex < COLUMN_COUNT / TAB_COLUMNS; tabIndex++)
    {
        CGFloat tabLocation = COLUMN_WIDTH * TAB_COLUMNS * tabIndex + PADDING_LEFT;
        [tabStops addObject:[NSTextTab.alloc initWithType:NSLeftTabStopType location:tabLocation]];
    }
    paragraphStyle.tabStops = tabStops;

    // Set up our list of line breaks.
    lineBreaks = [NSCharacterSet characterSetWithCharactersInString:@"\n\r"];



    // Set up the "true" backing array for our live scripts list.
    array = [[NSMutableArray alloc] init];

//    [NSUserDefaults.standardUserDefaults removeObjectForKey:@"Scripts"];

    // Get the list of scripts as stored in our defaults.
    NSArray *defaultsScripts = [NSUserDefaults.standardUserDefaults arrayForKey:@"Scripts"];

    // Iterate through the scripts to translate them to our live representation.
    for (id defaultsScript in defaultsScripts)
    {
        // If the script is not dictionary form, ignore it.
        if (! [defaultsScript isKindOfClass:NSDictionary.class])
            continue;

        TodayScript *script = [[TodayScript alloc] init];
        script.dictionary = defaultsScript;
        [array addObject:script];
    }

    return self;
}

- (NSUInteger)count {
    return array.count;
}
- (id)objectAtIndex:(NSUInteger)index {
    return [array objectAtIndex:index];
}

// All changes to our array should be saved to the array in our user defaults.
// This method does this for each overridden NSMutableArray method.
- (void)saveDefaults
{
    // Create a new array to be copied to our defaults.
    NSMutableArray *defaultsScripts = [[NSMutableArray alloc] init];
    // Iterate through our own script dictionaries in order to add them to it.
    for (TodayScript *script in array)
        [defaultsScripts addObject:script.dictionary];

    // Finally, write the array to our defaults.
    [NSUserDefaults.standardUserDefaults setObject:defaultsScripts forKey:@"Scripts"];
}
- (void)insertObject:(id)anObject atIndex:(NSUInteger)index {
    [array insertObject:anObject atIndex:index];
    [self saveDefaults];
}
- (void)removeObjectAtIndex:(NSUInteger)index {
    [array removeObjectAtIndex:index];
    [self saveDefaults];
}
- (void)addObject:(id)anObject {
    [array addObject:anObject];
    [self saveDefaults];
}
- (void)removeLastObject {
    [array removeLastObject];
    [self saveDefaults];
}
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    [array replaceObjectAtIndex:index withObject:anObject];
    [self saveDefaults];
}

- (NCUpdateResult)autoRun
{
    // Count how many scripts we will need to run.
    NSUInteger count = 0;
    for (TodayScript *script in array)
        if (script.autoRun)
            count++;

    // If there are no scripts to run, stop here, and return an indication that
    // there are no changes to display.
    if (! count)
        return NCUpdateResultNoData;

    // Initialize a lock to use for waiting until each script has decremented it
    // after their completion.
    NSConditionLock *lock = [[NSConditionLock alloc] initWithCondition:count];

    // Create a variable that's modifiable by blocks, to use for tracking
    // whether we will have updates to display in the end.
    __block NCUpdateResult updateResult = NCUpdateResultNoData;
    NSValue *resultPointer = [NSValue valueWithPointer:&updateResult];

    // Run each script that is marked to automatically run.
    for (TodayScript *script in array)
        if (script.autoRun)
            [script runWithLock:lock resultPointer:resultPointer];

    // Set up a timeout routine to dispatch after three seconds.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), queue, ^
    {
        // If we time out, we will tell Notification Center to update the view
        // in order to display the ongoing progress to the user.
        updateResult = NCUpdateResultNewData;
        // Set the value of lock to zero in order to allow us to proceed.
        [lock lock];
        [lock unlockWithCondition:0];
    });

    // Wait on our lock until all of the scripts have decremented it, or until
    // one has updates to display and sets it to zero, or until we've timed out.
    [lock lockWhenCondition:0];
    [lock unlock];

    // Return the final results to Notification Center.
    return updateResult;
}

@end
