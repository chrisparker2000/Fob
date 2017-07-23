/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  TimeView.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 04 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "TimeView.h"
#import <math.h>
#import "Alarm.h"
#import "PresetAlarms.h"
#import "TimeInputController.h"

#define HOUR_LENGTH 0.3
#define MINUTE_LENGTH 0.4
#define SECOND_LENGTH 0.45
#define DISTANCE_TOLERANCE 2.0f

#define MSECONDS(H, M, S) ((((H)*60+(M))*60+(S))*1000)

// These are data members used to keep track of the clock image.
NSImage * clockImage = nil;
NSRect clockImageRect;
// This is used by several things.
NSRect unitRect;

@implementation TimeView

- (void)setMilliseconds:(long long)mseconds {
    milliseconds = mseconds;
    [self setNeedsDisplay:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobTimeChanged" object:self];
}

- (long long) milliseconds {
    return milliseconds;
}

- (int) hours {
    return milliseconds / 3600000;
}

- (int) minutes {
    return (milliseconds / 60000) % 60;
}

- (int) seconds {
    return (milliseconds / 1000) % 60;
}

- (float) radianOfHand:(FobTimeUnit)hand {
    NSAssert(hand >= seconds && hand <= hours, @"Hand must be seconds, minutes, or hours!");
    switch (hand) {
        case seconds:
            return ((float)(milliseconds % 60000)) / 60.0f * 2.0f * M_PI;
            break;
        case minutes:
            return ((float)(milliseconds % 3600000)) / 60.0f * 2.0f * M_PI;
            break;
        case hours:
            return ((float)milliseconds) / 360000.0f / 12.0f * 2.0f * M_PI;
            break;
        default:
            return 0.0f;
            break;
    }
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (!clockImage) { // This is the first time this class has been loaded...
        // We load the clock image once per run of the application.
        clockImage = [NSImage imageNamed:@"Clock.pdf"];
        clockImageRect.origin = NSMakePoint(0.0f, 0.0f);
        clockImageRect.size = [clockImage size];
        // We use one of these per application run too.
        unitRect = NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f);
        // Count how many step times we have.
    }
    // Initialize the transforms.
    transform = [[NSAffineTransform transform] retain];
    invTransform = [[NSAffineTransform transform] retain];
    [self reformTransforms];
    // Set the time...
    milliseconds = 0;
    // Initialize what unit has been clicked.
    clickedUnit = none;
    return self;
}

- (void)dealloc {
    [transform release];
    [invTransform release];
    [super dealloc];
}

/* This will remake the affine transforms. */
- (void)reformTransforms {
    [transform initWithTransform:[NSAffineTransform transform]];
    lastCachedFrame = [self bounds];
    //frame.origin.x = frame.origin.y = 0.0f;
    // Transform the coordinate system so an appropriate area of the view
    // is in a unit rectangle.
    float difference = lastCachedFrame.size.width - lastCachedFrame.size.height;
    //transform = [NSAffineTransform transform];
    if (difference > 0.0f) { // It is wider than it is high.  Translate in x.
        [transform translateXBy:difference/2.0f yBy:0.0f];
        [transform scaleBy:lastCachedFrame.size.height];
    } else { // It is higher than it is wide (or the same).  Translate in y.
        [transform translateXBy:0.0f yBy:-difference/2.0f];
        [transform scaleBy:lastCachedFrame.size.width];
    }
    // Compute the inverse.
    [invTransform initWithTransform:transform];
    [invTransform invert];
}

/* This will draw the hands of the clock. */
- (void)drawHands {
    // Calculate the times, and the appropriate radians.
    double totalSeconds = (double) (milliseconds / 1000);
    double hours = totalSeconds / 3600.0;
    double minutes = fmod(totalSeconds / 60.0, 60.0);
    double seconds = fmod(totalSeconds, 60);
    hours *= M_PI / 6.0f;
    minutes *= M_PI / 30.0f;
    seconds *= M_PI / 30.0f;

    // Draw the hands based on this information.
    NSBezierPath *path = [NSBezierPath bezierPath];
    // Do the hour.
    [path setLineWidth:0.03];
    [path moveToPoint:NSMakePoint(0.5 - 0.05*sin(hours), 0.5 - 0.05*cos(hours))];
    [path lineToPoint:NSMakePoint(0.5 + HOUR_LENGTH*sin(hours), 0.5 + HOUR_LENGTH*cos(hours))];
    [[NSColor blackColor] set];
    [path stroke];
    // Do the minute.
    path = [NSBezierPath bezierPath];
    [path setLineWidth:0.02];
    [path moveToPoint:NSMakePoint(0.5 - 0.06*sin(minutes), 0.5 - 0.06*cos(minutes))];
    [path lineToPoint:NSMakePoint(0.5 + MINUTE_LENGTH*sin(minutes), 0.5 + MINUTE_LENGTH*cos(minutes))];
    [path stroke];
    // Do the second hand.
    [[NSColor redColor] set];
    path = [NSBezierPath bezierPath];
    [path setLineWidth:0.025];
    [path moveToPoint:NSMakePoint(0.5 - 0.1*sin(seconds), 0.5 - 0.1*cos(seconds))];
    [path lineToPoint:NSMakePoint(0.5 - 0.01*sin(seconds), 0.5 - 0.01*cos(seconds))];
    [path stroke];
    path = [NSBezierPath bezierPath];
    [path setLineWidth:0.01];
    [path moveToPoint:NSMakePoint(0.5 - 0.01*sin(seconds), 0.5 - 0.01*cos(seconds))];
    [path lineToPoint:NSMakePoint(0.5 + SECOND_LENGTH*sin(seconds), 0.5 + SECOND_LENGTH*cos(seconds))];
    [path stroke];
}

- (void)drawRect:(NSRect)aRect {
    [super drawRect:aRect];
    // Apply the transforms.
    NSRect frame = [self bounds];
    if (!NSEqualRects(frame, lastCachedFrame))
        [self reformTransforms];
    [NSGraphicsContext saveGraphicsState]; // Push...
    [transform concat];
    // Draw the background image of the clock.
    [clockImage drawInRect:unitRect fromRect:clockImageRect
                 operation:NSCompositeSourceOver fraction:1.0f];
    // Draw the hands of the clock.
    [self drawHands];
    
    [NSGraphicsContext restoreGraphicsState]; // Pop...
}

/* Given a mouse event, this event will return the angular position of the event in the window; if 16 is returned, for example, that would mean that the user clicked in the portion a little bit beyond 3 o'clock.  A second optional parameter is distance, which, if not nil, will be set to the distance of the mouse event's location from the center of the clock (in the reformed "unit square" coordinates). */
- (float)secondPositionForEvent:(NSEvent *)theEvent andDistance:(float *)distance {
    NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint circleLoc = [invTransform transformPoint:mouseLoc];
    circleLoc.x -= 0.5f;
    circleLoc.y -= 0.5f;
    if (distance) *distance = sqrt(circleLoc.x*circleLoc.x+circleLoc.y*circleLoc.y);
    float seconds = (atan2(circleLoc.x, circleLoc.y) / M_PI)*30.0f;
    if (seconds < 0.0f) return seconds + 60.0f;
    return seconds;
}

- (void)mouseDown:(NSEvent *)theEvent {
    float distance, secondPosition;
    secondPosition = [self secondPositionForEvent:theEvent andDistance:&distance];
    // We've not clicked anything yet.
    clickedUnit = none;
    // Angularly speaking, which hand MIGHT we be on?
    BOOL closeSecond = abs(secondPosition - (float)[self seconds]) < DISTANCE_TOLERANCE ||
        abs(secondPosition - (float)[self seconds]) > (60.0f - DISTANCE_TOLERANCE),
        closeMinute = abs(secondPosition - (float)[self minutes]) < DISTANCE_TOLERANCE ||
        abs(secondPosition - (float)[self minutes]) > (60.0f - DISTANCE_TOLERANCE),
        closeHour = abs(secondPosition - (float)([self hours]*60 + [self minutes])/12.0f) < DISTANCE_TOLERANCE ||
        abs(secondPosition - (float)([self hours]*60 + [self minutes])/12.0f) > (60.0f - DISTANCE_TOLERANCE);
    // Now, distancewise, which hands are we on?  We go for the shortest one we might be on.
    if (closeSecond && distance <= SECOND_LENGTH) clickedUnit = seconds;
    if (closeMinute && distance <= MINUTE_LENGTH) clickedUnit = minutes;
    if (closeHour && distance <= HOUR_LENGTH) clickedUnit = hours;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (clickedUnit == none) return;
    float secondPosition = [self secondPositionForEvent:theEvent andDistance:nil];
    long long newtime = milliseconds;
    switch (clickedUnit) {
        case hours: {
            float hourOffset = (float) (milliseconds % 3600000) / 3600000.0f;
            int closestHour = (((unsigned) ((secondPosition + 2.5f) / 5.0f - hourOffset)) + 12) % 12;
            newtime = milliseconds % 3600000 + closestHour * 3600000;
            break;
        } case minutes:
        case seconds: {
            int closest = ((int) (secondPosition + 0.5f)) % 60,
            old = clickedUnit==minutes?[self minutes]:[self seconds], dt = 0;
            if (old < closest) { // Appears to be forward.
                if (closest - old > 30) // It's REALLY backward!
                    dt = closest - old - 60;
                else
                    dt = closest - old;
            } else { // Appears to be backward.
                if (old - closest > 30) // It's REALLY forward!
                    dt = closest - old + 60;
                else
                    dt = closest - old;
            }
            if (dt == 0) return;
            newtime = (milliseconds + dt*(clickedUnit==minutes?60000:1000) + 12*3600000)
                % (12 * 3600000);
            break;
        } default:
            break;
    }
    if (newtime == milliseconds) return;
    [self setMilliseconds:newtime];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobTimeUserChanged" object:self];
}

- (void)mouseUp:(NSEvent *)theEvent {
    // Reset the time unit we have the mouse down on to nothing.
    clickedUnit = none;
}

/* This will step the user input forward or backward to the precoded times. */
- (void)step:(BOOL)forward {
    Alarm * alarm = forward ? [[PresetAlarms defaultDatabase] getClosestAfter:milliseconds]
    : [[PresetAlarms defaultDatabase] getClosestBefore:milliseconds];
    if (!alarm) {
        alarm = forward ? [Alarm alarmWithTitle:NSLocalizedString(@"MaxTimeLabel", nil)
                              forSecondDuration:MSECONDS(11,59,59)/1000] :
        [Alarm alarmWithTitle:NSLocalizedString(@"MinTimeLabel", nil)
            forSecondDuration:0];
    }
    [inputController setDisplayedAlarm:alarm];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    int change = [theEvent deltaX] + [theEvent deltaY] + [theEvent deltaZ];
    if (change == 0) return;
    [self step:(change > 0)];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobTimeUserChanged" object:self];
}

@end
