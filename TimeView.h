/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  TimeView.h
//  Fob
//
//  Created by Thomas Finley on Sat Jan 04 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Cocoa/Cocoa.h>

// Notifications:
// "FobTimeUserChanged" when the clock is changed by user interaction.
// "FobTimeChanged" when the clock changes.
// "FobTimeStep"

typedef enum _FobTimeUnit {
    none = -1, seconds, minutes, hours
} FobTimeUnit;

@class TimeInputController;

@interface TimeView : NSView {
    long long milliseconds;

    NSRect lastCachedFrame; // Determination of if things have resized recently.
    NSAffineTransform *transform, *invTransform; // Transforms for drawing, and clicking.
    IBOutlet TimeInputController *inputController;
    FobTimeUnit clickedUnit;
}

// These are methods meant to be used by clients.
- (void) setMilliseconds:(long long)mseconds;
// The method if the time is explicitly changed by user action.
- (void) setMillisecondsUser:(long long)mseconds;
- (void) step:(BOOL)forward;
// The following are helper functions.
- (void) reformTransforms;
- (void) drawHands;
- (float) secondPositionForEvent:(NSEvent *)theEvent andDistance:(float *)distance;
// These are convenience methods.
- (int) hours;
- (int) minutes;
- (int) seconds;
- (float) radianOfHand:(FobTimeUnit)hand;
- (long long) milliseconds;

@end
