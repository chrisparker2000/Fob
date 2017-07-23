/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  AttentionGrabber.m
//  Fob
//
//  Created by Thomas Finley on Thu Jan 23 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "AttentionGrabber.h"
#import "prefs.h"

AttentionGrabber *grabber;

@implementation AttentionGrabber

+ (void)initialize {
    grabber = [[[AttentionGrabber alloc] init] retain];
}

- (id)init {
    if (self = [super init]) {
        requestCodes = [[NSMutableArray array] retain];
    }
    return self;
}

- (NSMutableArray *) codes {
    return requestCodes;
}

- (void)dealloc {
    [requestCodes release];
    [super dealloc];
}

+ (void)grabAttention {
    int code;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BounceLevel blevel = [defaults integerForKey:FobBounceLevelKey];
    if (blevel == dont) return; // Who cares?
    
    code = [NSApp requestUserAttention:
        (blevel == once ? NSInformationalRequest : NSCriticalRequest)];
    //NSLog(@"Grabbing attention, code %d.", code);
    [[grabber codes] addObject:[NSNumber numberWithInt:code]];
}

+ (void)giveUpAttention {
    NSEnumerator *enumerator = [[grabber codes] objectEnumerator];
    NSNumber *number;
    while (number = [enumerator nextObject]) {
        int code = [number intValue];
        //NSLog(@"Relinquishing attention, code %d.", code);
        [NSApp cancelUserAttentionRequest:code];
    }
    [[grabber codes] removeObjectsInRange:NSMakeRange(0, [[grabber codes] count])];
}

@end
