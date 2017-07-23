/* Copyright � 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  AlertDoneAction.m
//  Fob
//
//  Created by Thomas Finley on Tue Jan 28 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "AlertDoneAction.h"

@implementation AlertDoneAction

- (void)loadSound {
    if (!soundName) return;
    [alertSound release];
    alertSound = [[NSSound soundNamed:soundName] retain];
}

- (id)initWithSoundNamed:(NSString *)name {
    if (self = [super init]) {
        soundName = [name retain];
        [self loadSound];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        soundName = [coder decodeObject];
        [self loadSound];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:soundName];
}

- (void)dealloc {
    [soundName release];
    [alertSound release];
    [super dealloc];
}

- (void)play {
    [super play];
    [alertSound play];
}

- (void)stop {
    [alertSound stop];
}

- (BOOL)isPlaying {
    return [alertSound isPlaying];
}

/* Returns the name of the sound that this done action will play. */
- (NSString *)soundName {
    return soundName;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[AlertDoneAction alloc] initWithSoundNamed:[self soundName]];
}

@end
