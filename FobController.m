/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  FobController.m
//  Fob
//
//  Created by Thomas Finley on Sun Jan 05 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "FobController.h"
#import "prefs.h"
#import "PreferenceController.h"

#define PADDING 5.0f

FobController *controller;

@implementation FobController

+ (void)initialize {
    setFactoryDefaults();
}

+ (FobController *)defaultController {
    return controller;
}

- (id)init {
    if (self = [super init]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        controller = self;
        [self setWindowFrameAutosaveName:@"MainFobWindow"];

        [nc addObserver:self
               selector:@selector(handleQuitting:)
                   name:@"NSApplicationWillTerminateNotification"
                 object:nil];
    }
    return self;
}

- (void)handleQuitting:(NSNotification *)note {
    // Save the states of the two split views.
    [self saveSplitView:mainSplit withName:@"MainSplitViewSizes"];
    [self saveSplitView:alarmSplit withName:@"AlarmSplitViewSizes"];
}

- (void)awakeFromNib {
    currentWindow = bigWindow;
    [self setupToolbar];

    [self loadSplitView:mainSplit withName:@"MainSplitViewSizes"];
    [self loadSplitView:alarmSplit withName:@"AlarmSplitViewSizes"];
}

- (IBAction)showPreferences:(id)sender {
    [preferenceController displayPreferences];
}

- (IBAction)customizeToolbar:(id)sender {
    [[[self window] toolbar] runCustomizationPalette:sender];
}

@end
