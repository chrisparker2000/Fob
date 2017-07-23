/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  BeepDoneAction.m
//  Fob
//
//  Created by Thomas Finley on Sun Jan 26 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "BeepDoneAction.h"
#import "time.h"

@implementation BeepDoneAction

- (id)init {
    if (self = [super init]) {
        doneBeepTime = 0;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        doneBeepTime = 0;
    }
    return self;
}

- (void)play {
    if ([self isPlaying]) return; // Should not play before it is done.
    // I am a bad person.
    doneBeepTime = milliseconds() + 500;
    [super play];
    NSBeep();
}

- (BOOL)isPlaying {
    return milliseconds() < doneBeepTime;
}

- (id)copyWithZone:(NSZone *)zone {
    return [BeepDoneAction new];
}

@end
