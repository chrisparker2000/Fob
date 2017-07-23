/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  AlertDoneAction.h
//  Fob
//
//  Created by Thomas Finley on Tue Jan 28 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <AppKit/AppKit.h>
#import "DoneAction.h"

@interface AlertDoneAction : DoneAction {
    NSSound *alertSound;
    NSString *soundName;
}

- (id)initWithSoundNamed:(NSString *)name;
- (void)loadSound;
- (NSString *)soundName;

@end
