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
    TodayScript *script;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.labelField.backgroundColor = NSColor.clearColor;
    self.programField.backgroundColor = NSColor.clearColor;
    self.scriptField.backgroundColor = NSColor.clearColor;

    self.labelField.textColor = NSColor.labelColor;
    self.programField.textColor = NSColor.labelColor;
    self.scriptField.textColor = NSColor.labelColor;

    self.labelField.insertionPointColor = NSColor.labelColor;
    self.programField.insertionPointColor = NSColor.labelColor;
    self.scriptField.insertionPointColor = NSColor.labelColor;

    self.labelField.font = [NSFont boldSystemFontOfSize:11];
    self.programField.font = [NSFont boldSystemFontOfSize:11];
    self.scriptField.font = [NSFont fontWithName:@"Menlo-Bold" size:9.5];

    self.labelField.textContainerInset = NSMakeSize(0, 2);
    self.programField.textContainerInset = NSMakeSize(0, 2);
    self.scriptField.textContainerInset = NSMakeSize(0, 2);

    NSDictionary *buttonAttributes = @{
        NSForegroundColorAttributeName: NSColor.labelColor,
        NSFontAttributeName: [NSFont systemFontOfSize:11]
    };
    self.autoRunButton.attributedTitle = [[NSAttributedString alloc]
        initWithString:self.autoRunButton.title attributes:buttonAttributes];
    self.showStatusButton.attributedTitle = [[NSAttributedString alloc]
        initWithString:self.showStatusButton.title attributes:buttonAttributes];
    self.saveButton.attributedTitle = [[NSAttributedString alloc]
        initWithString:self.saveButton.title attributes:buttonAttributes];

    // Disable all substitutions in the script field.
    self.scriptField.automaticDashSubstitutionEnabled   = NO;
    self.scriptField.automaticQuoteSubstitutionEnabled  = NO;
    self.scriptField.automaticTextReplacementEnabled    = NO;
    self.scriptField.automaticLinkDetectionEnabled      = NO;
    self.scriptField.automaticSpellingCorrectionEnabled = NO;
    self.scriptField.automaticDataDetectionEnabled      = NO;
}

- (void)editScript:(TodayScript *)existingScript
{
    // Show ourselves in the widget.
    [todayViewController presentViewControllerInWidget:self];
    // Set the button's title to designate that we are editing a script.
    self.saveButton.title = @"Save Script";

    // Set our script variable to the script passed to us.
    script = existingScript;

    // Set the values in our form to those of the script.
    self.labelField.string = script.label;
    self.programField.string = script.program;
    self.scriptField.string = script.script;
    self.autoRunButton.state = script.autoRun ? NSOnState : NSOffState;
    self.showStatusButton.state = script.showStatus ? NSOnState : NSOffState;

    // Focus the script field initially.
    [self.view.window makeFirstResponder:self.scriptField];
}

- (void)createScript
{
    // We will not be working with an existing script.
    script = nil;

    // Show ourselves in the widget.
    [todayViewController presentViewControllerInWidget:self];
    // Set the button's title to designate that we are creating a script.
    self.saveButton.title = @"Add Script";

    // Set up our fields with the default values.
    self.labelField.string = @"";
    self.programField.string = NSProcessInfo.processInfo.environment[@"SHELL"];
    self.scriptField.string = @"";
    self.autoRunButton.state = NSOnState;
    self.showStatusButton.state = NSOnState;

    // Focus the label field initially.
    [self.view.window makeFirstResponder:self.labelField];
}

// Method invoked when user presses the "Add Script" button.
- (IBAction)saveScript:(id)sender
{
    // If the interpreter is not a valid executable file, style the text to
    // indicate the error to the user, then abort.
    NSString *programString = self.programField.string;
    if (! [NSFileManager.defaultManager isExecutableFileAtPath:programString]) {
        self.programField.textColor = [NSColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1.0];
        return;
    }

    // If we were not given an existing dictionary to modify, set that up to
    // work with. Otherwise, create a new one.
    TodayScript *newScript = script ?: [[TodayScript alloc] init];

    newScript.program = programString.copy;

    // Set the script to the dictionary if the user provided one. Otherwise,
    // remove any which may have previously existed.
    newScript.script = self.scriptField.string.copy;

    // Set the script's title to the user provided one.
    newScript.label = self.labelField.string.copy;
    // If a title was not provided, use the text of the script, or the name of
    // the program itself if there is no script.
    if (! newScript.label.length)
        newScript.label = newScript.script.length ? newScript.script : newScript.program;

    // If the checkbox wasn't unchecked, this script is to be run automatically.
    newScript.autoRun = (self.autoRunButton.state != NSOffState);

    // If the checkbox wasn't unchecked, this script is to be run automatically.
    newScript.showStatus = (self.showStatusButton.state != NSOffState);

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



@implementation EditViewLabelField

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If it was a tab with the shift key, we will be moving back a field.
    if (character == NSBackTabCharacter)
    {
        // If full keyboard navigation is enabled, move back to the save button.
        if (self.editViewController.saveButton.canBecomeKeyView)
        {
            self.selectedRange = NSMakeRange(0, 0);
            [self.window makeFirstResponder:self.editViewController.saveButton];
        }
        // If it is not, move back to the script field.
        else {
            self.selectedRange = NSMakeRange(0, 0);
            [self.window makeFirstResponder:self.editViewController.scriptField];
        }
    }

    // If it was a tab without the shift key, move on to the script field.
    else if (character == NSTabCharacter)
    {
        self.selectedRange = NSMakeRange(0, 0);
        [self.window makeFirstResponder:self.editViewController.programField];
        [self.editViewController.programField selectAll:self];
    }

    // If the character wasn't a tab, pass it to the text field normally.
    else
        [super keyDown:theEvent];
}

@end


@implementation EditViewProgramField

- (void)didChangeText
{
    [super didChangeText];

    // When the user starts editing the program field, make sure the text color
    // returns to normal in case it was previously changed to indicate an error.
    if ([NSFileManager.defaultManager isExecutableFileAtPath:self.string])
        self.textColor = NSColor.labelColor;

    // If user enters an invalid program in the program field, set its text as
    // red to indicate this.
    else
        self.textColor = [NSColor colorWithRed:1.0 green:0.5 blue:0.5 alpha:1.0];
}

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If the shift and tab were typed, move back to the program field.
    if (character == NSBackTabCharacter)
    {
        self.selectedRange = NSMakeRange(0, 0);
        [self.window makeFirstResponder:self.editViewController.labelField];
        [self.editViewController.labelField selectAll:self];
    }

    // If just a tab was typed, move on to the show status box.
    else if (character == NSTabCharacter)
    {
        self.selectedRange = NSMakeRange(0, 0);
        [self.window makeFirstResponder:self.editViewController.scriptField];
    }

    // For any other keys, pass them to the text field as normal.
    else
        [super keyDown:theEvent];
}

@end


@implementation EditViewScriptView

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If the shift and tab were typed, move back to the program field.
    if (character == NSBackTabCharacter)
    {
        [self.window makeFirstResponder:self.editViewController.programField];
        [self.editViewController.programField selectAll:self];
    }

    // If option and tab were typed, we will be moving forward.
    else if (character == NSTabCharacter && (theEvent.modifierFlags & NSEventModifierFlagOption))
    {
        // If full keyboard navigation is enabled, move on to the auto-run box.
        if (self.editViewController.autoRunButton.canBecomeKeyView)
            [self.window makeFirstResponder:self.editViewController.autoRunButton];
        // If it isn't, move on to the label field.
        else {
            [self.window makeFirstResponder:self.editViewController.labelField];
            [self.editViewController.labelField selectAll:self];
        }
    }
    // For any other keys, pass them to the text field as normal.
    else
        [super keyDown:theEvent];
}

@end


@implementation EditViewAutoRunButton

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If the shift and tab were typed, move back to the script field.
    if (character == NSBackTabCharacter)
        [self.window makeFirstResponder:self.editViewController.scriptField];

    // If just a tab was typed, move on to the show status box.
    else if (character == NSTabCharacter)
        [self.window makeFirstResponder:self.editViewController.showStatusButton];

    // If the space key was typed, toggle our state.
    else if (character == ' ')
        [self performClick:self];

    // Any other keys, pass to the box to handle.
    else
        [super keyDown:theEvent];
}

@end


@implementation EditViewShowStatusButton

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If the shift and tab were typed, move back to the script field.
    if (character == NSBackTabCharacter)
        [self.window makeFirstResponder:self.editViewController.autoRunButton];

    // If just a tab was typed, move on to the show status box.
    else if (character == NSTabCharacter)
        [self.window makeFirstResponder:self.editViewController.saveButton];

    // If the space key was typed, toggle our state.
    else if (character == ' ')
        [self performClick:self];

    // Any other keys, pass to the box to handle.
    else
        [super keyDown:theEvent];
}

@end


@implementation EditViewSaveButton

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If the shift and tab were typed, move back to the script field.
    if (character == NSBackTabCharacter)
        [self.window makeFirstResponder:self.editViewController.showStatusButton];

    // If just a tab was typed, move on to the show status box.
    else if (character == NSTabCharacter)
    {
        [self.window makeFirstResponder:self.editViewController.labelField];
        [self.editViewController.labelField selectAll:self];
    }
    // If the space key was typed, toggle our state.
    else if (character == ' ')
        [self performClick:self];

    // Any other keys, pass to the box to handle.
    else
        [super keyDown:theEvent];
}

@end
