//
//  ListRowViewController.h
//  Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ListRowViewController;


@interface ListRowLabelButton : NSButton
@property IBOutlet ListRowViewController *listRowViewController;
@end

@interface ListRowEditButton : NSButton
@property IBOutlet ListRowViewController *listRowViewController;
@end

@interface ListRowOutputView : NSTextView
@property IBOutlet ListRowViewController *listRowViewController;
@end


@interface ListRowViewController : NSViewController <NSTextViewDelegate>

// Our UI objects.
@property IBOutlet ListRowLabelButton *labelButton;
@property IBOutlet ListRowEditButton *editButton;
@property IBOutlet ListRowOutputView *outputView;

@end
