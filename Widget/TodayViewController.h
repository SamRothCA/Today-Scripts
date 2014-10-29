//
//  TodayViewController.h
//  Scripts
//
//  Created by Sam Rothenberg on 8/14/14.
//  Copyright (c) 2014 Sam Rothenberg. All rights reserved.
//

#import "TodayScript.h"
#import "EditViewController.h"


@interface TodayViewController : NSViewController <NCWidgetProviding, NCWidgetListViewDelegate>

@property (strong) IBOutlet NCWidgetListViewController *listViewController;
@property (strong) EditViewController *editViewController;
@property (strong) NSArrayController *arrayController;

@end

extern TodayViewController *todayViewController;
