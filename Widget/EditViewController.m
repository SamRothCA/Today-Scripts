//
//  SearchViewController.m
//  Today Scripts
//
//  Created by Sam Rothenberg on 10/21/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "EditViewController.h"
#import "TodayViewController.h"

@implementation EditViewController
{
    IBOutlet NSTextField *labelField;
    IBOutlet EditViewProgramField *programField;
    IBOutlet NSTextView *scriptField;
    IBOutlet NSButton *autoRunButton;
    IBOutlet NSButton *showStatusButton;
    IBOutlet NSButton *saveButton;

    NSString *defaultProgram;

    TodayScript *script;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set up the appearence of the script field.
    scriptField.font = [NSFont fontWithName:@"Menlo" size:10];
    scriptField.textColor = [NSColor colorWithWhite:1 alpha:1];
    scriptField.backgroundColor = NSColor.clearColor;
    // Disable all substitutions in the script field.
    scriptField.automaticDashSubstitutionEnabled   = NO;
    scriptField.automaticQuoteSubstitutionEnabled  = NO;
    scriptField.automaticTextReplacementEnabled    = NO;
    scriptField.automaticLinkDetectionEnabled      = NO;
    scriptField.automaticSpellingCorrectionEnabled = NO;
    scriptField.automaticDataDetectionEnabled      = NO;
}

- (void)editScript:(TodayScript *)existingScript
{
    // Show ourselves in the widget.
    [todayViewController presentViewControllerInWidget:self];
    // Set the button's title to designate that we are editing a script.
    saveButton.title = @"Save Script";

    // Set our script variable to the script passed to us.
    script = existingScript;

    // Set the values in our form to those of the script.
    labelField.stringValue = script.label;
    programField.stringValue = script.program;
    scriptField.string = script.script;
    autoRunButton.state = script.autoRun ? NSOnState : NSOffState;
    showStatusButton.state = script.showStatus ? NSOnState : NSOffState;
}

- (void)createScript
{
    // We will not be working with an existing script.
    script = nil;

    // Show ourselves in the widget.
    [todayViewController presentViewControllerInWidget:self];
    // Set the button's title to designate that we are creating a script.
    saveButton.title = @"Add Script";

    // Set up our fields with the default values.
    labelField.stringValue = @"";
    programField.stringValue = NSProcessInfo.processInfo.environment[@"SHELL"];
    scriptField.string = @"";
    autoRunButton.state = NSOnState;
    showStatusButton.state = NSOnState;
}

// Method invoked when user presses the "Add Script" button.
- (IBAction)saveScript:(id)sender
{
    // If the interpreter is not a valid executable file, style the text to
    // indicate the error to the user, then abort.
    NSString *programString = programField.stringValue;
    if (! [NSFileManager.defaultManager isExecutableFileAtPath:programString]) {
        programField.textColor = [NSColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
        return;
    }

    // If we were not given an existing dictionary to modify, set that up to
    // work with. Otherwise, create a new one.
    TodayScript *newScript = script ?: [[TodayScript alloc] init];

    newScript.program = programString.copy;

    // Set the script to the dictionary if the user provided one. Otherwise,
    // remove any which may have previously existed.
    newScript.script = scriptField.string.copy;

    // Set the script's title to the user provided one.
    newScript.label = labelField.stringValue.copy;
    // If a title was not provided, use the text of the script, or the name of
    // the program itself if there is no script.
    if (! newScript.label.length)
        newScript.label = newScript.script.length ? newScript.script : newScript.program;

    // If the checkbox wasn't unchecked, this script is to be run automatically.
    newScript.autoRun = (autoRunButton.state != NSOffState);

    // If the checkbox wasn't unchecked, this script is to be run automatically.
    newScript.showStatus = (showStatusButton.state != NSOffState);

    // If we were given a script to work with, remove it from our form, make
    // sure it it's stopped running, then update our defaults.
    if (script)
    {
        script = nil;
        [newScript terminate];
        [TodayScriptArray.sharedScripts saveDefaults];
    }
    // Otherwise, add the new script to the list array and update our list view.
    else {
        [todayViewController.arrayController addObject:newScript];
        todayViewController.listViewController.contents =
            todayViewController.arrayController.arrangedObjects;
    }
    // Hide ourselves.
    [todayViewController dismissViewController:self];

    // If the newly saved script is set to run automatically, do so now.
    if (newScript.autoRun)
        [newScript run];
}

- (void)cancelScript
{
    script = nil;
    [todayViewController dismissViewController:self];
}

@end


@implementation EditViewProgramField

// When the user starts editing the program field, make sure the text color goes
// back to normal in case it was previously changed to indicate an error.
- (void)textDidBeginEditing:(NSNotification *)notification {
    self.textColor = [NSColor colorWithWhite:1.0 alpha:1.0];
}

// If user enters an invalid program in the program field, set its text as red
// to indicate this.
- (void)textDidEndEditing:(NSNotification *)notification
{
    if (! [NSFileManager.defaultManager isExecutableFileAtPath:self.stringValue])
        self.textColor = [NSColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0];
}

@end
