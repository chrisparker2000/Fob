/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  DockIconController.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 11 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "DockIconController.h"
#import "CurrentAlarms.h"
#import "prefs.h"
#import "AttentionGrabber.h"
#import "DoneAction.h"
#import "StatusItemKeeper.h"

#define PADDING 5.0f

@implementation DockIconController

- (void)prepareAttributes {
    foregroundText = [NSColor whiteColor];
    backgroundText = [[NSColor colorWithCalibratedWhite:0.0f alpha:0.6f] retain];

    attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSFont fontWithName:@"Helvetica"
                                          size:30]
                   forKey:NSFontAttributeName];
    [attributes setObject:foregroundText
                   forKey:NSForegroundColorAttributeName];

    statusAttributes = [[NSMutableDictionary alloc] init];
    [statusAttributes setObject:[NSFont fontWithName:@"Lucida Grande" size:12]
                         forKey:NSFontAttributeName];
}

/* This will set and return the alarm that last rang, or nil if there are no alarms that have come due.  For the sake of safety, this should probably run every time the status of the alarm list, or alarm doneness is changed. */
- (Alarm *)updateLatestRungAlarm {
    int i=0, max=[[currentAlarms alarms] count];
    Alarm * last = latestRungAlarm;
    while (i<max && ![[[currentAlarms alarms] objectAtIndex:i] millisecondsRemaining]) i++;
    i--;
    latestRungAlarm = i == -1 ? nil : [[[currentAlarms alarms] objectAtIndex:i] retain];
    if (last != latestRungAlarm) {
        [[last doneAction] stop]; // We're no longer the best.  Wah!
        [[latestRungAlarm doneAction] play];
    }
    [last release];
    return latestRungAlarm;
}

- (void)dealloc {
    [statusAttributes release];
    [attributes release];
}

- (Alarm *)latestRungAlarm {
    return latestRungAlarm;
}

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    originalImage = [[NSImage imageNamed: @"NSApplicationIcon"] retain];
    iconState = original;
    doneTimer = nil;
    [self prepareAttributes];

    // Listen for notifications...
    [nc addObserver:self
           selector:@selector(handleAlarmDone:)
               name:@"FobAlarmDone"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleAlarmNote:)
               name:@"FobAlarmTick"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleAlarmCollectionNote:)
               name:@"FobAlarmAdded"
             object:currentAlarms];
    [nc addObserver:self
           selector:@selector(handleAlarmCollectionNote:)
               name:@"FobAlarmRemoved"
             object:currentAlarms];
    [nc addObserver:self
           selector:@selector(handleStatusVisibilityChange:)
               name:@"FobStatusItemVisibilityChanged"
             object:nil];
    
    quitting = NO;
    [nc addObserver:self
           selector:@selector(handleQuitting:)
               name:@"NSApplicationWillTerminateNotification"
             object:nil];

    [self updateLatestRungAlarm];
    [self updateIcon];
}

- (void)updateStatusItem {
    Alarm * first = [self firstAlarm];
    NSAttributedString *as;
    if (!first) {
        [[FobController defaultController] setStatusItemTitleTo:nil];
        return;
    }
    as = [[NSAttributedString alloc] initWithString:[first describe]
                                         attributes:statusAttributes];

    [[FobController defaultController] setStatusItemTitleTo:as];
    [as release];	
}

- (Alarm *)firstAlarm {
    return [[currentAlarms alarms] count] ? [[currentAlarms alarms] objectAtIndex:0] : nil;
}

- (void)handleAlarmNote:(NSNotification *)note {
    Alarm * first = [self firstAlarm];
    if (first != [note object]) return;
    [self updateIcon];
}

- (void)handleAlarmDone:(NSNotification *)note {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:FobFeedbackLevelKey] >= beep)
        [[[self latestRungAlarm] doneAction] play]; // Will play if not playing already.
    [AttentionGrabber grabAttention];
    //[defaults integerForKey:FobBounceLevelKey]
    [self updateLatestRungAlarm];
    [self handleAlarmNote:note];
}

- (void)handleAlarmCollectionNote:(NSNotification *)note {
    [self updateLatestRungAlarm];
    [self updateIcon];
}

- (void)handleQuitting:(NSNotification *)note {
    quitting = true;
    [NSApp setApplicationIconImage:originalImage]; // Set it to the original before quit.
}

- (void)handleStatusVisibilityChange:(NSNotification *)note {
    [self updateStatusItem];
}

- (void)doDoneFlash:(NSTimer*)timer {
    if (quitting) return;
    if (toFlash) {
        NSSize dockIconSize = [originalImage size];
        NSRect dockRect = NSMakeRect(0.0f,0.0f,dockIconSize.width,dockIconSize.height);
        NSImage *newImage = [NSApp applicationIconImage];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        [newImage lockFocus];
        [originalImage drawAtPoint:NSMakePoint(0.0f,0.0f)
                          fromRect:dockRect
                         operation:NSCompositeCopy
                          fraction:1.0f];
        [originalImage drawAtPoint:NSMakePoint(0.0f,0.0f)
                          fromRect:dockRect
                         operation:NSCompositePlusLighter
                          fraction:0.5f];
        [newImage unlockFocus];
        [NSApp setApplicationIconImage:newImage];
        if ([defaults integerForKey:FobFeedbackLevelKey] == alwaysBeep)
            [[[self latestRungAlarm] doneAction] play]; // Will play if not already.
    } else {
        // The not bright flash is just the original image.
        [NSApp setApplicationIconImage:originalImage];
    }
    [self updateStatusItem];
    toFlash = !toFlash; // Next time, do the opposite...
}

- (void)updateIcon {
    Alarm * first = [self firstAlarm];
    DockIconState newState;

    if (quitting) return;
    if (first == nil) newState = original;
    else newState = [first millisecondsRemaining] ? alarmDisplay : doneFlash;
    if (newState != alarmDisplay && newState == iconState) return;

    if (iconState == doneFlash) {
        // We only get here if we've stopping flashing.  Get rid of the done icon timer.
        [doneTimer invalidate];
        doneTimer = nil;
    }

    // Set the icon (or in the case of flashes, the flashing)
    switch (newState) {
        case original:
            [NSApp setApplicationIconImage:originalImage];
            break;
        case alarmDisplay: {
            NSString *timeString = [first timeString];
            // We want to draw the first icon.
            NSSize dockIconSize = [originalImage size],
                timeSize = [timeString sizeWithAttributes:attributes];

            NSImage *newImage = [NSApp applicationIconImage];
            NSRect dockRect = NSMakeRect(0.0f,0.0f,dockIconSize.width,dockIconSize.height);
            NSBezierPath *path = [NSBezierPath bezierPath];

            [newImage lockFocus];
            [originalImage drawAtPoint:NSMakePoint(0.0f,0.0f)
                              fromRect:dockRect
                             operation:NSCompositeCopy
                              fraction:1.0f];
            [path appendBezierPathWithRect:NSMakeRect
                (dockIconSize.width-timeSize.width-PADDING-PADDING,0.0f,
                 timeSize.width+PADDING+PADDING,timeSize.height+PADDING+PADDING)];
            [backgroundText set];
            [path fill];
            [timeString drawAtPoint:NSMakePoint(dockIconSize.width-timeSize.width-PADDING,PADDING)
                     withAttributes:attributes];
            //[timeString drawInRect:NSMakePoint];
            [newImage unlockFocus];
            [NSApp setApplicationIconImage:newImage];
            break;
        } case doneFlash: {
            // We shouldn't get here if the flash icon is on.  We can assume it is off.
            toFlash = YES; // The first one should be bright!
            doneTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self
                                                       selector:@selector(doDoneFlash:)
                                                       userInfo:nil repeats:YES];
            [doneTimer fire]; // Do the first flash!
            break;
        }
    }
    [self updateStatusItem];
    iconState = newState; // Register the new state.
}

@end
