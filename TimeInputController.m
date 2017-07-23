/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  TimeInputController.m
//  Fob
//
//  Created by Thomas Finley on Sun Jan 05 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "TimeInputController.h"
#import "Alarm.h"

@implementation TimeInputController

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [self timeChanged:hourField];
    lastStepperValue = [stepper intValue];

    [nc addObserver:self
           selector:@selector(handleTimeChanged:)
               name:@"FobTimeChanged"
             object:timeView];
}

- (IBAction)timeChanged:(id)sender {
    long long hour = [hourField intValue];
    long long minute = [minuteField intValue];
    long long second = [secondField intValue];
    long long msecs = ((hour*60+minute)*60+second)*1000;
    [timeView setMilliseconds:msecs];
}

- (IBAction)timeStepClicked:(id)sender {
    int dv = [stepper intValue] - lastStepperValue;
    [timeView step:(dv == 1 || dv < -1)];
    lastStepperValue = [stepper intValue];
}

/** The text fields will be modified according to the time display. */
- (void)setFieldsAccordingToTimeView {
    [hourField setIntValue:[timeView hours]];
    [minuteField setIntValue:[timeView minutes]];
    [secondField setIntValue:[timeView seconds]];
}

- (void)handleTimeChanged:(NSNotification *)note {
    //NSLog(@"The time was registered as changed!");
    [self setFieldsAccordingToTimeView];
}

- (void)setDisplayedAlarm:(Alarm *)alarm {
    [timeView setMilliseconds:[alarm millisecondsRemaining]];
    [self setFieldsAccordingToTimeView];
    [descriptionField setStringValue:[alarm title]];
}

- (Alarm *)displayedAlarm {
    Alarm * alarm = [[Alarm alloc] initWithTitle:[descriptionField stringValue]
                               forSecondDuration:[timeView milliseconds]/1000];
    [alarm autorelease];
    return alarm;
}

- (long long)milliseconds {
    return [timeView milliseconds];
}

@end
