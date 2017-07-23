/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  AlarmCollection.h
//  Fob
//
//  Created by Thomas Finley on Fri Jan 10 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Foundation/Foundation.h>

#import "Alarm.h"

// Notifications:
// "FobAlarmAdded" a preset alarm was added to the database
// "FobAlarmRemoved" a preset alarm was removed from the database

@interface AlarmCollection : NSObject {
    NSMutableArray *alarms;
}

- (NSArray *)alarms;
- (void)add:(Alarm *)alarm;
- (BOOL)remove:(Alarm *)alarm;
- (void)removeAlarmAtIndex:(int)index;
- (int)findEntryWithTime:(long long)milliseconds;
- (int)findEntryForAlarm:(Alarm *)alarm;

@end
