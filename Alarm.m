/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  Alarm.m
//  Fob
//
//  Created by Thomas Finley on Mon Jan 06 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "Alarm.h"
#import "time.h"
#import "DoneAction.h"
#import "BeepDoneAction.h"

@implementation Alarm

+ (void)initialize {
    if (self = [Alarm class]) {
        [self setVersion:1];
    }
}

+ (Alarm *)alarmWithTitle:(NSString *)newTitle forSecondDuration:(long long)seconds {
    return [[[Alarm alloc] initWithTitle:newTitle forSecondDuration:seconds] autorelease];
}

- (unsigned)hash {
    return [title hash]; // All other quantities are fluid...
}

- (id)initWithTitle:(NSString *)newTitle forSecondDuration:(long long)seconds {
    if (self = [super init]) {
        [self setDoneAction:[[[BeepDoneAction alloc] init] autorelease]];
        title = [newTitle retain];
        paused = true;
        timeLeft = seconds * 1000;
        lastCheckedMSeconds = -1;
        lastTimeString = lastDescribe = nil;
        cachedValid = NO;
        cachedDescribeValid = NO;
        timer = nil;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        int version = [coder versionForClassName:@"Alarm"];
        [self setTitle:[coder decodeObject]];
        [coder decodeValueOfObjCType:@encode(BOOL) at:&paused];
        [coder decodeValueOfObjCType:@encode(long long) at:&timeLeft];
        [coder decodeValueOfObjCType:@encode(long long) at:&matures];
        lastCheckedMSeconds = -1;
        lastTimeString = lastDescribe = nil;
        cachedValid = NO;
        cachedDescribeValid = NO;
        timer = nil;
        if (version >= 1) { // We will have a done action.
            [self setDoneAction:[coder decodeObject]];
        } else { // We have to make a done action.
            [self setDoneAction:[[BeepDoneAction new] autorelease]];
        }
        if (!paused) {
            [self checkTime]; // Start the timer!
        }
    }
    return self;
}

- (void)dealloc {
    [lastTimeString release];
    [lastDescribe release];
    [title release];
    [timer release];
    [doneAction autorelease];
}

- (BOOL)isEqual:(Alarm *)other {
    return [self compare:other] == NSOrderedSame;
}

- (void)pause {
    if (!paused) {
        timeLeft = matures - milliseconds();
        paused = true;
        [self checkTime];
        [timer invalidate];
        [timer release];
        timer = nil;
    }
}

- (BOOL)paused {
    return paused;
}

- (void)start {
    if (paused) {
        if (timeLeft == 0) return;
        matures = timeLeft + milliseconds();
        paused = false;
        [self checkTime];
    }
}

- (long long) millisecondsRemaining {
    if (paused) return timeLeft;
    long long time = matures-milliseconds();
    if (time < 0) {
        [self pause];
        time = timeLeft = 0;
        cachedValid = NO;
        cachedDescribeValid = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FobAlarmDone"
                                                            object:self];
    }
    return time;
}

/* Returns a string representation of the time left. */
- (NSString *)timeString {
    if (cachedValid) return lastTimeString;
    int time = ([self millisecondsRemaining] + 999) / 1000;
    // This method may be called often, so calling it quickly is essential.
    [lastTimeString release];
    if (time >= 3600)
        lastTimeString = [NSString stringWithFormat:@"%d:%02d:%02d",
            time / 3600, (time / 60) % 60, time % 60];
    else if (time)
        lastTimeString = [NSString stringWithFormat:@"%d:%02d", time / 60, time % 60];
    else
        lastTimeString = NSLocalizedString(@"DoneAlarmDescriber", nil);
    cachedValid = YES;
    return [lastTimeString retain];
}

/* Returns a string representation of the object: the title with the time left. */
- (NSString *)describe {
    if (cachedDescribeValid) return lastDescribe;
    [lastDescribe release];
    lastDescribe = [NSString stringWithFormat:@"%@, %@", title, [self timeString]];
    cachedDescribeValid = YES;
    return [lastDescribe retain];
}

/* Returns the title of the alarm. */
- (NSString *)title {
    return title;
}

- (void)setTitle:(NSString *)newTitle {
    [title release];
    title = [newTitle retain];
}

- (id)copyWithZone:(NSZone *)zone {
    Alarm * na = [[Alarm alloc] initWithTitle:title forSecondDuration:[self millisecondsRemaining]/1000];
    [na setDoneAction:[[[self doneAction] copy] autorelease]];
    if (paused) [na pause];
    else [na start];
    return na;
}

- (long long)matures {
    return matures;
}

- (NSComparisonResult)timeCompare:(Alarm *)object {
    long long diff;
    NSAssert([[object class] isSubclassOfClass:[Alarm class]],
             @"The alarm comparator wasn't passed an alarm instance!");

    if ([object paused] != [self paused])
        NSLog(@"Warning: comparing a paused and unpaused alarm.");
    
    if (![object paused] && ![self paused])
        diff = [object matures] - [self matures];
    else
        diff = [object millisecondsRemaining] - [self millisecondsRemaining];
    if (diff == 0) return NSOrderedSame; // The alarms are set to end at the same time!
    if (diff > 0) return NSOrderedAscending; // We're set to end first!
    return NSOrderedDescending; // The other guy is set to end first!
}

- (NSComparisonResult)compare:(Alarm *)object {
    NSComparisonResult result = [self timeCompare:object];
    if (result != NSOrderedSame) return result;
    return [[self title] compare:[object title]];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:title];
    [coder encodeValueOfObjCType:@encode(BOOL) at:&paused];
    [coder encodeValueOfObjCType:@encode(long long) at:&timeLeft];
    [coder encodeValueOfObjCType:@encode(long long) at:&matures];
    [coder encodeObject:doneAction];
}

/* This will check the time, and start a new timer, if appropriate. */
- (BOOL)checkTime {
    long long checkedMSeconds = [self millisecondsRemaining];
    //long long diff;
    
    if (!paused && !timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:(float)(checkedMSeconds % 1000)/1000.0f+.001f
                        target:self selector:@selector(timerDue:) userInfo:nil repeats:NO];
        [timer retain];
    }
    
    if (lastCheckedMSeconds / 1000 == checkedMSeconds / 1000) return NO;
    lastCheckedMSeconds = checkedMSeconds;
    cachedValid = NO;
    cachedDescribeValid = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobAlarmTick"
                                                        object:self];
    return YES;
}

- (void)timerDue:(id)object {
    [timer release];
    timer = nil;
    if (!paused) [self checkTime];
}

- (DoneAction *)doneAction {
    return doneAction;
}

- (void)setDoneAction:(DoneAction *)newAction {
    [doneAction stop];
    [doneAction release];
    doneAction = [newAction retain];
}

@end
