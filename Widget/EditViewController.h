//
//  SearchViewController.h
//  Today Scripts
//
//  Created by Sam Rothenberg on 10/21/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "TodayScript.h"

@interface EditViewController : NCWidgetSearchViewController

- (void)editScript:(TodayScript *)script;
- (void)createScript;
- (void)cancelScript;

@end

@interface EditViewProgramField : NSTextField @end
