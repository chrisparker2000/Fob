/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  AlarmCollection.m
//  Fob
//
//  Created by Thomas Finley on Fri Jan 10 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "AlarmCollection.h"

@implementation AlarmCollection

- (id)init {
    if (self = [super init]) {
        alarms = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)dealloc {
    [alarms release];
    [super dealloc];
}

- (NSArray *)alarms {
    return alarms;
}

/* This will return the index of the entry in the preset array with time of milliseconds.  Alternatively, if no such entry exists, this will return -1-n, where n is the location to add the element. */
- (int)findEntryWithTime:(long long)milliseconds {
    int bottom = 0, top = [alarms count]-1;
    while (bottom <= top) {
        int middle = (bottom+top) >> 1;
        long long middleValue = [[alarms objectAtIndex:middle] millisecondsRemaining];
        if (middleValue > milliseconds) top = middle-1;
        else if (middleValue < milliseconds) bottom = middle+1;
        else return middle; // Sire!  It is found!
    }
    return -1-bottom;
}

/* This will find the index at which the alarm is stored.  If the alarm is not stored here, return -1 minus the location at which we should insert the alarm into the collection. */
- (int)findEntryForAlarm:(Alarm *)alarm {
    /*int bottom = 0, top = [alarms count]-1;
    while (bottom <= top) {
        int middle = (bottom+top) >> 1;
        NSComparisonResult result = [alarm compare:[alarms objectAtIndex:middle]];
        if (result == NSOrderedAscending) top = middle-1; // The middle is too high!
        else if (result == NSOrderedDescending) bottom = middle+1;
        else return middle; // Sire!  It is found!
    }
    return -1-bottom;*/
    int bottom = 0, top = [alarms count]-1;
    while (bottom <= top) {
        int middle = (bottom+top) >> 1;
        NSComparisonResult result = [alarm timeCompare:[alarms objectAtIndex:middle]];
        if (result == NSOrderedAscending) top = middle-1; // The middle is too high!
        else if (result == NSOrderedDescending) bottom = middle+1;
        else {
            // Rewind to the beginning of entries with this time.
            while (middle && [alarm timeCompare:[alarms objectAtIndex:middle-1]]==NSOrderedSame) {
                middle--;
            }
            while (middle < [alarms count]) {
                Alarm *currentAlarm = [alarms objectAtIndex:middle];
                if (currentAlarm == alarm) return middle;
                if ([alarm timeCompare:currentAlarm]!=NSOrderedSame) break;
                middle++;
            }
            break;
        }
    }
    return -1-bottom;
}

/* This will add an alarm.  The alarm added must be paused. */
- (int)add:(Alarm *)alarm {
    int toInsert;
    toInsert = [self findEntryForAlarm:alarm];
    if (toInsert < 0) toInsert = -1-toInsert;
    [alarms insertObject:alarm atIndex:toInsert];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobAlarmAdded" object:self];
    return toInsert;
}

- (BOOL)remove:(Alarm *)alarm {
    int index;
    if ((index = [self findEntryForAlarm:alarm]) >= 0 &&
        [[alarms objectAtIndex:index] isEqual:alarm]) {
        [self removeAlarmAtIndex:index];
        return YES;
    }
    return NO;
}

- (void)removeAlarmAtIndex:(int)index {
    [alarms removeObjectAtIndex:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobAlarmRemoved" object:self];
}

@end
