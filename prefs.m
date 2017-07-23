/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  prefs.m
//  Fob
//
//  Created by Thomas Finley on Fri Jan 10 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#include "prefs.h"
#include "Alarm.h"

#define SECONDS(H, M, S) (((H)*60+(M))*60+(S))

NSString *FobPresetAlarmsKey = @"Preset Alarms";
NSString *FobActiveAlarmsKey = @"Active Alarms";
NSString *FobConfirmDeleteKey = @"Confirm Delete";
NSString *FobKeepWindowOpenKey = @"Keep Window Open";
NSString *FobFeedbackLevelKey = @"Feedback Level";
NSString *FobBounceLevelKey = @"Bounce Level";

const FeedbackLevel kDefaultFeedbackLevel = beep;
const BounceLevel kDefaultBounceLevel = dont;
const BOOL kDefaultConfirmDelete = YES;
const BOOL kDefaultKeepWindowOpen = NO;

long long alarmTimes[] = {
    SECONDS(0,20,0), SECONDS(0,45,0), 0
};

NSString * alarmNames[] = {
    @"Broil Halibut", @"Soda in Freezer"
};

NSMutableArray * correspondingDataArray(NSArray * array) {
    int i;
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (i=0; i<[array count]; i++)
        [newArray addObject:[NSArchiver archivedDataWithRootObject:[array objectAtIndex:i]]];
    return newArray;
}

NSMutableArray * correspondingObjectArray(NSArray * array) {
    int i;
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:[array count]];
    for (i=0; i<[array count]; i++)
        [newArray addObject:[NSUnarchiver unarchiveObjectWithData:[array objectAtIndex:i]]];
    return newArray;
}

void setFactoryDefaults() {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

    long long *alarmT = alarmTimes;
    NSString **alarmN = alarmNames;
    NSMutableArray *presetArray = [NSMutableArray array];
    while (*alarmT) {
        Alarm *alarm = [Alarm alarmWithTitle:*alarmN forSecondDuration:*alarmT];
        NSData *alarmAsData = [NSArchiver archivedDataWithRootObject:alarm];
        [presetArray addObject:alarmAsData];
        alarmT++;
        alarmN++;
    }
    [defaults setObject:presetArray forKey:FobPresetAlarmsKey];
    [defaults setObject:[NSArray array] forKey:FobActiveAlarmsKey];
    [defaults setObject:[NSNumber numberWithInt:kDefaultFeedbackLevel]
                 forKey:FobFeedbackLevelKey];
    [defaults setObject:[NSNumber numberWithInt:kDefaultBounceLevel]
                 forKey:FobBounceLevelKey];
    [defaults setObject:[NSNumber numberWithBool:kDefaultConfirmDelete]
                 forKey:FobConfirmDeleteKey];
    [defaults setObject:[NSNumber numberWithBool:kDefaultKeepWindowOpen]
                 forKey:FobKeepWindowOpenKey];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    //NSLog(@"Registered defaults!");
}
