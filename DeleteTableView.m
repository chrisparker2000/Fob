/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  DeleteTableView.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 11 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "DeleteTableView.h"
#import "prefs.h"

@implementation DeleteTableView

- (IBAction)delete:(id)sender {
    [self confirmDelete];
}

- (void)deleteForward:(id)sender {
    [self confirmDelete];
}

- (void)deleteBackward:(id)sender {
    [self confirmDelete];
}

- (void)keyDown:(NSEvent *)theEvent {
    // This intercepts the backward and forward delete events.
    if ([theEvent keyCode] == 51 || [theEvent keyCode] == 117) [self confirmDelete];
    else [super keyDown:theEvent];
}

- (void)confirmDelete {
    if ([self numberOfSelectedRows] == 0) return; // Who cares?

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:FobConfirmDeleteKey]) {
        [self postDelete];
        return;
    }

    //NSLog(@"We should confirm the delete first!");
    NSBeginAlertSheet(NSLocalizedString(@"ConfirmDeleteTitle", nil),
                      @"Yes", @"No", nil, [self window],
                      self, nil, @selector(sheetDidDismiss:returnCode:contextInfo:), nil,
                      NSLocalizedString([self numberOfSelectedRows] > 1 ?
                                        @"ConfirmDeletePluralMessage" : @"ConfirmDeleteMessage",
                                        nil));
}

- (void)sheetDidDismiss:(NSWindow *)sheet
             returnCode:(int)returnCode
            contextInfo:(id)contextInfo {
    if (!returnCode) return; // Apparently, 0 is "no".  Feh.
    [self postDelete];
}

- (void)postDelete {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobTableDelete" object:self];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [anItem action] != @selector(delete:) || [self numberOfSelectedRows];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)anItem {
    return [anItem action] != @selector(delete:) || [self numberOfSelectedRows];
}

@end
