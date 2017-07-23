/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  Alarm.h
//  Fob
//
//  Created by Thomas Finley on Mon Jan 06 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Foundation/Foundation.h>

// Notifications:
// "FobAlarmDone" when the alarm is detected as finished.
// "FobAlarmTick" when the alarm changes on the boundary between 

@interface Alarm : NSObject <NSCopying, NSCoding> {
    NSString *title, *lastTimeString, *lastDescribe;
    long long timeLeft, matures, lastCheckedMSeconds;
    NSTimer *timer;
    BOOL paused, cachedValid, cachedDescribeValid;
}

+ (Alarm *)alarmWithTitle:(NSString *)title forSecondDuration:(long long)seconds;

- (id)initWithTitle:(NSString *)title forSecondDuration:(long long)seconds;
- (void)pause;
- (void)start;
- (NSString *)describe;
- (NSString *)timeString;
- (NSString *)title;
- (void)setTitle:(NSString *)newTitle;
- (long long) millisecondsRemaining;
- (BOOL)paused;
- (NSComparisonResult)timeCompare:(Alarm *)object;
- (NSComparisonResult)compare:(Alarm *)object;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (BOOL)checkTime;

@end
