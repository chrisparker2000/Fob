/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  ApplicationDelegate.m
//  Fob
//
//  Created by Thomas Finley on Sun Jan 05 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "ApplicationDelegate.h"
#import "CurrentAlarms.h"
#import "PresetAlarms.h"

#define kFixedDockMenuAppKitVersion 632

@implementation ApplicationDelegate

// This is used by all those items (each for a preset alarm) in the application's dock menu.
- (IBAction)presetItem:(id)sender {
    [currentAlarms add:[[sender representedObject] copy]];
}

- (IBAction)currentItem:(id)sender {
    // Pause it!
    [currentAlarms pause:[sender representedObject]];
}

- (IBAction)pausedItem:(id)sender {
    // Unpause it!
    [currentAlarms unpause:[sender representedObject]];
}

- (NSMenuItem *) constructMenuItem:(NSString *)title
                            action:(SEL)aSelector
                 representedObject:(id)represented {
    NSMenuItem *item;

    if (NSAppKitVersionNumber>=kFixedDockMenuAppKitVersion) {
        item =
        [[NSMenuItem alloc] initWithTitle:title
                                   action:aSelector
                            keyEquivalent:@""];
        [item setTarget:self];
        [item autorelease];
    } else {
        NSInvocation *myInv= [NSInvocation invocationWithMethodSignature:
            [self methodSignatureForSelector:aSelector]];
        item =
            [[NSMenuItem alloc] initWithTitle:title
                                       action:@selector(invoke)
                                keyEquivalent:@""];
        [myInv setTarget:self];
        [myInv setSelector:aSelector];
        [myInv setArgument:&item atIndex:2];
        [item setTarget:[myInv retain]];
    }
    [item setEnabled:YES];
    [item setRepresentedObject:represented];
    return item;
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    NSMenu * dockMenu = [[[NSMenu alloc] initWithTitle:@"DockMenu"] autorelease];
    NSMenu * currentMenu = [[[NSMenu alloc] initWithTitle:@"CurrentAlarms"] autorelease];
    NSMenu * presetMenu = [[[NSMenu alloc] initWithTitle:@"PresetAlarms"] autorelease];
    NSMenuItem *item;
    NSEnumerator *enumerator;
    Alarm *alarm;

    // The items for control.
    item = [[[NSMenuItem alloc] initWithTitle:@"Clear Due"
                                       action:@selector(clearDue:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:currentAlarms];
    [dockMenu addItem:item];
    
    // Set up the preset alarm submenu.
    if ([[presetAlarms alarms] count]) {
        enumerator = [[presetAlarms alarms] objectEnumerator];
        while (alarm = [enumerator nextObject]) {
            [presetMenu addItem:[self constructMenuItem:[alarm describe]
                                                 action:@selector(presetItem:)
                                      representedObject:alarm]];
        }
        item = [[[NSMenuItem alloc] initWithTitle:@"Preset Alarms"
                                           action:nil
                                    keyEquivalent:@""] autorelease];
        [item setSubmenu:presetMenu];
        [item setEnabled:YES];
        [dockMenu addItem:item];
    }

    // Set up the current alarm submenu.
    int cac=[[currentAlarms alarms] count], pac=[[currentAlarms pausedAlarms] count];
    if (cac || pac) {
        if (cac) {
            [currentMenu addItemWithTitle:@"Active:" action:nil keyEquivalent:@""];
            enumerator = [[currentAlarms alarms] objectEnumerator];
            while (alarm = [enumerator nextObject]) {
                [currentMenu addItem:[self constructMenuItem:[alarm describe]
                                                      action:@selector(currentItem:)
                                           representedObject:alarm]];
            }
        }
        if (cac && pac) {
            [currentMenu addItem:[NSMenuItem separatorItem]];
        }
        if (pac) {
            [currentMenu addItemWithTitle:@"Paused:" action:nil keyEquivalent:@""];
            enumerator = [[currentAlarms pausedAlarms] objectEnumerator];
            while (alarm = [enumerator nextObject]) {
                [currentMenu addItem:[self constructMenuItem:[alarm describe]
                                                      action:@selector(pausedItem:)
                                           representedObject:alarm]];
            }
        }        

        item = [[[NSMenuItem alloc] initWithTitle:@"Current Alarms"
                                           action:nil
                                    keyEquivalent:@""] autorelease];
        [item setSubmenu:currentMenu];
        [dockMenu addItem:item];
    }
    
    return dockMenu;
}

@end
