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
{
    // Our UI objects.
    IBOutlet NSTextView *outputView;
    IBOutlet NSButton *editButton;
}

- (NSString *)nibName {
    return @"ListRowViewController";
}

- (void)loadView
{
    [super loadView];

    // Make the text cursor for the output view (mostly) invisible.
    outputView.insertionPointColor = NSColor.clearColor;

    // Make the edit button dim.
    editButton.alphaValue = 0.1;
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
