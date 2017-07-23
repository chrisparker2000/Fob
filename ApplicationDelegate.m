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
#import "DockIconController.h"
#import "prefs.h"

#define kFixedDockMenuAppKitVersion 632

@implementation ApplicationDelegate

// This is used by all those items (each for a preset alarm) in the application's dock menu.
- (IBAction)presetItem:(id)sender {
    [currentAlarms add:[[sender representedObject] copy]];
}

- (IBAction)currentItem:(id)sender {
    // Pause it!
    [currentAlarms pause:[sender representedObject]];
    // Clear the icon after a small delay.
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self
                                   selector:@selector(iconUpdateDelay:)
                                   userInfo:nil repeats:NO];
}

- (IBAction)pausedItem:(id)sender {
    // Unpause it!
    [currentAlarms unpause:[sender representedObject]];
    // Clear the icon after a small delay.
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self
                                   selector:@selector(iconUpdateDelay:)
                                   userInfo:nil repeats:NO];
}

/* This is a convenience method for constructing a menu item.  This accounts for a problem in 10.1 that did not allow dock icon menus to work properly. */
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

/* This method is used when you clear from the dock.  When you clear due alarms by right clicking on the dock icon, the dock icon will perform the action in "clear due" which will revert the dock icon, AND THEN revert the dock icon to what it was at the point of the right click.  It is annoying because it does this reset AFTER the Fob code changes the icon -- so the icon may well be wrong, and if nothing else changes the dock icon it will stay wrong.  Unfortunately I don't see a clean way around this... */
- (void)iconUpdateDelay:(id)sender {
    // Activates after a delay.
    [dockIconController updateIcon];
}

- (void)clearDueDock:(id)sender {
    // Perform the normal action.
    [currentAlarms clearDue:sender];
    // Clear the icon after a small delay.
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self
                                   selector:@selector(iconUpdateDelay:)
                                   userInfo:nil repeats:NO];
}

- (void)beginTextAlarmSheetDock:(id)sender {
    // Bring Fob to the front.
    [NSApp activateIgnoringOtherApps:YES];
    // Perform the normal action.
    [currentAlarms beginTextAlarmSheet:sender];
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL submenus = [defaults boolForKey:FobDockMenuSubmenusKey];

    NSMenu * dockMenu = [[[NSMenu alloc] initWithTitle:@"DockMenu"] autorelease];
    NSMenu * currentMenu = submenus ? [[[NSMenu alloc] initWithTitle:@"CurrentAlarms"] autorelease] : dockMenu;
    NSMenu * presetMenu = submenus ? [[[NSMenu alloc] initWithTitle:@"PresetAlarms"] autorelease] : dockMenu;
    NSMenuItem *item;
    NSEnumerator *enumerator;
    Alarm *alarm;
    
    // Set up the current alarm submenu.
    int cac=[[currentAlarms alarms] count], pac=[[currentAlarms pausedAlarms] count];
    if (cac || pac) {
        if (cac) {
            [currentMenu addItemWithTitle:NSLocalizedString(@"DockMenuCurrentActiveShortHeader", nil)
                                   action:nil keyEquivalent:@""];
            enumerator = [[currentAlarms alarms] objectEnumerator];
            while (alarm = [enumerator nextObject]) {
                [currentMenu addItem:[self constructMenuItem:[alarm describe]
                                                      action:@selector(currentItem:)
                                           representedObject:alarm]];
            }
        }
        if (submenus && cac && pac) {
            [currentMenu addItem:[NSMenuItem separatorItem]];
        }
        if (pac) {
            [currentMenu addItemWithTitle:NSLocalizedString(@"DockMenuCurrentPausedShortHeader", nil)
                                   action:nil keyEquivalent:@""];
            enumerator = [[currentAlarms pausedAlarms] objectEnumerator];
            while (alarm = [enumerator nextObject]) {
                [currentMenu addItem:[self constructMenuItem:[alarm describe]
                                                      action:@selector(pausedItem:)
                                           representedObject:alarm]];
            }
        }
        if (submenus) {
            item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DockMenuCurrentSubmenuTitle", nil)
                                               action:nil
                                        keyEquivalent:@""] autorelease];
            [item setSubmenu:currentMenu];
            [dockMenu addItem:item];
        }
    }

    // Set up the preset alarm submenu.
    if ([[presetAlarms alarms] count]) {
        enumerator = [[presetAlarms alarms] objectEnumerator];
        if (!submenus) {
            [currentMenu addItemWithTitle:NSLocalizedString(@"DockMenuPresetShortHeader", nil)
                                   action:nil keyEquivalent:@""];
        }
        while (alarm = [enumerator nextObject]) {
            [presetMenu addItem:[self constructMenuItem:[alarm describe]
                                                 action:@selector(presetItem:)
                                      representedObject:alarm]];
        }
        if (submenus) {
            item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DockMenuPresetSubmenuTitle", nil)
                                               action:nil
                                        keyEquivalent:@""] autorelease];
            [item setSubmenu:presetMenu];
            [item setEnabled:YES];
            [dockMenu addItem:item];
        }
    }

    // Add a separator if the alarms are not in submenus to clearly distinguish alarms from control items.
    if (!submenus) {
        [currentMenu addItem:[NSMenuItem separatorItem]];
    }

    // The items for control.
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"ToolbarStartTextLabel", nil)
                                       action:@selector(beginTextAlarmSheetDock:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [dockMenu addItem:item];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"ToolbarClearDueLabel", nil)
                                       action:@selector(clearDueDock:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [dockMenu addItem:item];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"DockMenuRewindLastDue", nil)
                                       action:@selector(rewindLastDue:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:currentAlarms];
    [dockMenu addItem:item];    
    
    return dockMenu;
}

@end
