/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  SplitDelegate.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 25 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "SplitDelegate.h"


@implementation FobController (SplitDelegate)

- (float)splitView:(NSSplitView *)sender
constrainMaxCoordinate:(float)proposedMax
       ofSubviewAt:(int)offset {
    return sender == mainSplit ? proposedMax-100.0f : proposedMax-60.0f;
}

- (float)splitView:(NSSplitView *)sender
constrainMinCoordinate:(float)proposedMin
       ofSubviewAt:(int)offset {
    return sender == mainSplit ? proposedMin+214.0f : proposedMin+60.0f;
}

- (void)saveSplitView:(NSSplitView *)split withName:(NSString *)preferencesName {
    NSArray *views = [split subviews];
    NSMutableArray *sizes = [NSMutableArray arrayWithCapacity:[views count]];
    BOOL vertical = [split isVertical];
    int i;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (i=0; i<[views count]; i++) {
        int size = vertical ? [[views objectAtIndex:i] frame].size.width :
        [[views objectAtIndex:i] frame].size.height;
        [sizes addObject:[NSNumber numberWithInt:size]];
    }
    [defaults setObject:sizes forKey:preferencesName];
    //NSLog(@"Saved sizes of %@ as %@", preferencesName, sizes);
}

- (void)loadSplitView:(NSSplitView *)split withName:(NSString *)preferencesName {
    NSArray *sizes = [[NSUserDefaults standardUserDefaults] arrayForKey:preferencesName],
    *views = [split subviews];
    BOOL vertical = [split isVertical];
    int i;
    //float dividerWidth = [split dividerThickness];
    if (!sizes) return; // No sizes for the split view sizes saved yet!
    //NSLog(@"Loading sizes of %@ as %@", preferencesName, sizes);
    for (i=0; i<[views count]; i++) {
        int size = [[sizes objectAtIndex:i] intValue];
        NSRect frame = [[views objectAtIndex:i] frame];
        if (vertical) frame.size.width = size;
        else frame.size.height = size;
        [[views objectAtIndex:i] setFrame:frame];
    }
}

@end
