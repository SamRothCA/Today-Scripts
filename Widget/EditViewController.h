//
//  SearchViewController.h
//  Today Scripts
//
//  Created by Sam Rothenberg on 10/21/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "TodayScript.h"

@class EditViewController;


@interface EditViewLabelField : NSTextView
@property IBOutlet EditViewController *editViewController;
@end

@interface EditViewProgramField : NSTextView
@property IBOutlet EditViewController *editViewController;
@end

@interface EditViewScriptView : NSTextView;
@property IBOutlet EditViewController *editViewController;
@end

@interface EditViewAutoRunButton : NSButton
@property IBOutlet EditViewController *editViewController;
@end

@interface EditViewShowStatusButton : NSButton
@property IBOutlet EditViewController *editViewController;
@end

@interface EditViewSaveButton : NSButton
@property IBOutlet EditViewController *editViewController;
@end


@interface EditViewController : NCWidgetSearchViewController

- (void)editScript:(TodayScript *)script;
- (void)createScript;
- (void)cancelScript;

@property IBOutlet EditViewLabelField *labelField;
@property IBOutlet EditViewProgramField *programField;
@property IBOutlet EditViewScriptView *scriptField;
@property IBOutlet EditViewAutoRunButton *autoRunButton;
@property IBOutlet EditViewShowStatusButton *showStatusButton;
@property IBOutlet EditViewSaveButton *saveButton;

@end
