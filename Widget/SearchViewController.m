//
//  SearchViewController.m
//  Today Scripts
//
//  Created by Sam Rothenberg on 10/21/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "SearchViewController.h"
#import <Cocoa/Cocoa.h>

@implementation SearchViewController
{
    IBOutlet NSTextField *labelField;
    IBOutlet SearchProgramTextField *programField;
    IBOutlet NSTextView *scriptField;
    IBOutlet NSButton *autorunButton;
    IBOutlet NSButton *saveButton;

    TodayScript *_script;
}

- (TodayScript *)script {
    return _script;
}
- (void)setScript:(TodayScript *)script
{
    // If we are given a script to edit, set up our fields to its values.
    if (script) {
        labelField.stringValue = script.label;
        programField.stringValue = script.program;
        scriptField.string = script.script;
        autorunButton.state = script.autoRun ? NSOnState : NSOffState;
        saveButton.stringValue = @"Save Script";
    }
    // Otherwise, set up our fields with the default values.
    else {
        labelField.stringValue = @"";
        programField.stringValue = NSProcessInfo.processInfo.environment[@"SHELL"];
        scriptField.string = @"";
        autorunButton.state = NSOnState;
        saveButton.stringValue = @"Add Script";
    }

    [self willChangeValueForKey:@"script"];
    _script = script;
    [self didChangeValueForKey:@"script"];
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

// Method invoked when user presses the "Add Script" button.
- (IBAction)resultSelected:(id)sender
{
    // If the interpreter is not a valid executable file, style the text to
    // indicate the error to the user, then abort.
    NSString *programString = programField.stringValue;
    if (! [NSFileManager.defaultManager isExecutableFileAtPath:programString]) {
        programField.textColor = [NSColor colorWithRed:1.0 green:0.25 blue:0.25 alpha:1];
        return;
    }

    // If we were not given an existing dictionary to modify, set that up to
    // work with. Otherwise, create a new one.
    TodayScript *script = self.script ?: [[TodayScript alloc] init];

    script.program = programString;

    // Set the script to the dictionary if the user provided one. Otherwise,
    // remove any which may have previously existed.
    script.script = scriptField.string;

    // Set the script's title to the user provided one.
    script.label = labelField.stringValue;
    if (! script.label.length)
        // If they didn't provide a title, use the text of the script, or the
        // name of the program itself if there is no script.
        script.label = script.script.length
            ? script.script
            : script.program;

    // Set whether the script should run automatically according to the user's
    // specification.
    script.autoRun = (autorunButton.state != NSOffState);

    // Initialize the script's output and status to empty objects.
    script.output = @"";
    script.status = (id)NSNull.null;

    // Send the completed dictionary to the ListViewController.
    [self.delegate widgetSearch:self resultSelected:self.script];
}

@end


@implementation SearchProgramTextField

// When the user starts editing the program field, make sure the text color goes
// back to white if it was changed to indicate an error with the previous input.
- (void)textDidBeginEditing:(NSNotification *)notification {
    self.textColor = [NSColor colorWithWhite:1 alpha:1];
}

@end