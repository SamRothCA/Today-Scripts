//
//  TodayViewController.m
//  Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TodayScript.h"
#import "TodayViewController.h"
#import "EditViewController.h"
#import "ListRowViewController.h"


TodayViewController *todayViewController;


#pragma mark - Widget Implementation


@implementation TodayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    todayViewController = self;
    
    

    // Set up the view controller for adding and editing scripts.
    self.editViewController = [[EditViewController alloc] init];

    // Set up our array controller to manage the array which coordiates with our
    // persistent user defaults.
    self.arrayController = [NSArrayController.alloc initWithContent:TodayScriptArray.sharedScripts];

    // If our user defaults contain no scripts, set up an introductory one.
    if (! TodayScriptArray.sharedScripts.count)
    {
        TodayScript *script = [[TodayScript alloc] init];
        script.label      = @"Welcome";
        script.program    = @"/bin/sh";
        script.script     = @"echo 'Click the Info button above to start adding scripts.'";
        script.autoRun    = YES;
        script.showStatus = YES;
        [self.arrayController addObject:script];
    }

    // Set up the widget list view controller to get its content from our array
    // controller.
    self.listViewController.contents = self.arrayController.arrangedObjects;
}



#pragma mark - Getting and Displaying Updates

// Notification Center calls this method to give us an opportunity to provide
// updates. Refresh the widget's contents in preparation for a snapshot.
- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult result))handler
{
    // Tell the script array to auto run the scripts as necessary, and return
    // the update status it indicates.
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_sync(queue, ^{
        //code here
        handler(TodayScriptArray.sharedScripts.autoRun);
    });
}

- (NSEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(NSEdgeInsets)defaultMarginInset {
    // Override the left margin so that the list view is flush with the edge.
    defaultMarginInset.left = 0;
    defaultMarginInset.right = 0;
    return defaultMarginInset;
}



#pragma mark - Editing the List of Scripts

- (NSViewController *)widgetList:(NCWidgetListViewController *)list viewControllerForRow:(NSUInteger)row
{
    // Return a new view controller subclass for displaying an item of widget
    // content. The NCWidgetListViewController will set the representedObject
    // of this view controller to one of the objects in its contents array.
    return [[ListRowViewController alloc] init];
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldReorderRow:(NSUInteger)row {
    // Return YES to allow the item to be reordered in the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didReorderRow:(NSUInteger)row toRow:(NSUInteger)newIndex {
    // The user has reordered an item in the list.
    TodayScript *script = [self.arrayController.arrangedObjects objectAtIndex:row];
    [self.arrayController removeObjectAtArrangedObjectIndex:row];
    [self.arrayController insertObject:script atArrangedObjectIndex:newIndex];
}

- (BOOL)widgetList:(NCWidgetListViewController *)list shouldRemoveRow:(NSUInteger)row {
    // Return YES to allow the item to be removed from the list by the user.
    return YES;
}

- (void)widgetList:(NCWidgetListViewController *)list didRemoveRow:(NSUInteger)row {
    // The user has removed an item from the list.
    [self.arrayController removeObjectAtArrangedObjectIndex:row];
}

- (void)widgetListPerformAddAction:(NCWidgetListViewController *)list
{
    // The user has clicked the add button in the list view.
    [self.editViewController createScript];
}

- (BOOL)widgetAllowsEditing {
    return YES;
}

- (void)widgetDidBeginEditing {
    // The user has clicked the edit button. Put the list view into edit mode.
    self.listViewController.editing = YES;
}

- (void)widgetDidEndEditing {
    // The user has clicked the Done button, begun editing another widget, or NC
    // has been closed. Take the list view out of editing mode.
    self.listViewController.contents = self.arrayController.arrangedObjects;
    self.listViewController.editing = NO;
}

@end
