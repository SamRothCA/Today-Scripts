//
//  ListRowViewController.m
//  Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "ListRowViewController.h"
#import "TodayScript.h"
#import "TodayViewController.h"
#import "EditViewController.h"

@implementation ListRowViewController

- (NSString *)nibName {
    return @"ListRowViewController";
}

- (void)loadView
{
    [super loadView];

    // Make the text cursor for the output view (mostly) invisible.
    self.outputView.insertionPointColor = NSColor.clearColor;
    // Make the edit button dim.
    self.editButton.alphaValue = 0.1;

    // Give the list view a moment to display the content, then reset the focus.
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC);
    dispatch_after(delay, dispatch_get_main_queue(), ^{
        [self.view.window makeFirstResponder:todayViewController.view];
    });
}

- (BOOL)textShouldBeginEditing:(NSText *)textObject {
    // Prevent editing of the output field.
    return NO;
}


- (IBAction)startOrStop:(id)sender
{
    // Get the current script we represent.
    TodayScript *script = self.representedObject;
    // Otherwise if the script is not running, we are being asked to run it.
    if (script.running)
        [script terminate];
    // If it is running however, then we are being asked to terminate it.
    else
        [script run];
}

- (IBAction)edit:(id)sender {
    // Get the current script we represent and tell the editor to open it.
    [todayViewController.editViewController editScript:(TodayScript *)self.representedObject];
}

@end



@implementation ListRowLabelButton

- (void)setTitle:(NSString *)title
{
    super.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
        NSForegroundColorAttributeName: NSColor.whiteColor,
        NSFontAttributeName:  [NSFont boldSystemFontOfSize:11]
    }];
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    
    if (![osxMode  isEqual: @"Dark"]) {
        super.attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:@{
            NSForegroundColorAttributeName: NSColor.blackColor,
            NSFontAttributeName:  [NSFont boldSystemFontOfSize:11]}];
    }
}

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If shift and tab were typed, we will be moving to the previous view.
    if (character == NSBackTabCharacter)
    {
        // Get the default previous view.
        NSView *previousKeyView = self.previousValidKeyView;
        // If the default view is an output view's enclosing scroll view, keep
        // going to the output view it contains.
        if ([previousKeyView isKindOfClass:NSScrollView.class])
            previousKeyView = previousKeyView.previousValidKeyView.previousValidKeyView;

        // If the previous view is another output view, select all of its text.
        if ([previousKeyView isKindOfClass:ListRowOutputView.class])
            [previousKeyView selectAll:self];

        // Set the focus to the new view.
        [self.window makeFirstResponder:previousKeyView];
    }

    // Any other keys, pass to the box to handle.
    else
        [super keyDown:theEvent];
}

@end


@implementation ListRowEditButton

- (void)keyDown:(NSEvent *)theEvent
{
    // If just a tab was typed, move on to the show status box.
    if ([theEvent.characters characterAtIndex:0] == NSTabCharacter)
    {
        // Get the default next view.
        NSView *nextKeyView = self.nextValidKeyView;
        // If the default view is an output view's enclosing scroll view, keep
        // going to the output view it contains.
        if ([nextKeyView isKindOfClass:NSScrollView.class])
            nextKeyView = nextKeyView.nextValidKeyView.nextValidKeyView;

        // By now we should have an output view. Select its contents.
        [nextKeyView selectAll:self];

        // Set the focus to the new view.
        [self.window makeFirstResponder:nextKeyView];
    }
//    // If the enter, space, or return keys were typed, save the script.
//    else if (character == NSEnterCharacter || character == ' ' || character == '\r')
//        [self performClick:self];

    // Any other keys, pass to the box to handle.
    else
        [super keyDown:theEvent];
}

@end


@implementation ListRowOutputView

- (BOOL)canBecomeKeyView {
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
    // Get the character that was typed.
    int character = [theEvent.characters characterAtIndex:0];

    // If shift and tab were typed, we will be moving to the previous view.
    if (character == NSBackTabCharacter)
    {
        // Remove our own selection.
        self.selectedRange = NSMakeRange(0, 0);

        // Get the default previous view.
        NSView *previousKeyView = self.previousValidKeyView;
        // If the default view is our enclosing clip view, keep going back to
        // select its enclosing scroll view's previous view.
        if ([previousKeyView isKindOfClass:NSClipView.class])
            previousKeyView = previousKeyView.previousValidKeyView.previousValidKeyView;

        // If the previous view is another output view, select all of its text.
        else if ([previousKeyView isKindOfClass:ListRowOutputView.class])
            [previousKeyView selectAll:self];

        // Set the focus to the new view.
        [self.window makeFirstResponder:previousKeyView];
    }

    // If just tab was typed, we will be selecting the next view.
    else if (character == NSTabCharacter)
    {
        // Remove our own selection.
        self.selectedRange = NSMakeRange(0, 0);

        // Get the default next view.
        NSView *nextKeyView = self.nextValidKeyView;

        // If the next view is another output view, select all of its text.
        if ([nextKeyView isKindOfClass:ListRowOutputView.class])
            [nextKeyView selectAll:self];

        // Set the focus to the new view.
        [self.window makeFirstResponder:nextKeyView];
    }

    // For any other keys, pass them to the text field as normal.
    else
        [super keyDown:theEvent];
}

@end
