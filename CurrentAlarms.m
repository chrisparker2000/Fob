/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  CurrentAlarms.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 11 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "CurrentAlarms.h"
#import "Alarm.h"
#import "TimeInputController.h"
#import "prefs.h"
#import "PresetAlarms.h"
#import "AttentionGrabber.h"
#import "DoneAction.h"

CurrentAlarms * defaultCurrentDatabase = nil;

@implementation CurrentAlarms

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSAssert(!defaultCurrentDatabase, @"More than one CurrentAlarms instance awoken from a nib file!");
    defaultCurrentDatabase = self;
    lastSelectedAlarm = nil;

    [presetTable setDoubleAction:@selector(doubleClickPresets:)];
    [presetTable setTarget:self];
    
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmAdded"
             object:self];
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmRemoved"
             object:self];
    // Table listening.
    [nc addObserver:self
           selector:@selector(handleTableDelete:)
               name:@"FobTableDelete"
             object:currentTable];
    [nc addObserver:self
           selector:@selector(handleTableDelete:)
               name:@"FobTableDelete"
             object:littleCurrentTable];
    
    // Listening to alarms.
    [nc addObserver:self
           selector:@selector(handleAlarmTick:)
               name:@"FobAlarmTick"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleAlarmDone:)
               name:@"FobAlarmDone"
             object:nil];

    // We want to change the view when the table selections change.
    [nc addObserver:self
           selector:@selector(handleTableSelection:)
               name:@"NSTableViewSelectionDidChangeNotification"
             object:nil];

    // We want to change the view when the done action changes.
    [nc addObserver:self
           selector:@selector(handleDoneActionChange:)
               name:@"FobDoneActionChange"
             object:nil];
    
    [currentTable reloadData];
    [littleCurrentTable reloadData];
}

- (id)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        alarms = [correspondingObjectArray([defaults objectForKey:FobActiveAlarmsKey]) retain];
    }
    return self;
}

+ (CurrentAlarms *)defaultDatabase {
    return defaultCurrentDatabase;
}

/* This will add an alarm.  The alarm added must have some time left.. */
- (void)rawAdd:(Alarm *)alarm {
    if (![alarm millisecondsRemaining]) {
        NSBeginAlertSheet(NSLocalizedString(@"CurrentNonzeroTimeTitle", nil),
                          nil, nil, nil, window,
                          nil, nil, nil, nil,
                          NSLocalizedString(@"CurrentNonzeroTimeMessage", nil));
        return;
    }
    [alarm start]; // Make sure it's started!
    [super add:alarm];
}

- (void)add:(Alarm *)alarm {
    [self rawAdd:alarm];
    [self reformCurrentDefaults];
}

// Table methods.

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [alarms count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex {
    NSString *identifier = [aTableColumn identifier];
    Alarm *alarm = [alarms objectAtIndex:rowIndex];
    return [alarm valueForKey:identifier];
}

- (void)handleTableSelection:(NSNotification *)note {
    /*static Alarm * oldAlarm; // The old code from presets.
    int selected = [presetTable numberOfSelectedRows];
    if (selected > 1) return;
    if (selected == 1) {
        int row = [presetTable selectedRow];
        if (!oldAlarm)
            oldAlarm = [[inputController displayedAlarm] retain];
        [inputController setDisplayedAlarm:[[presetAlarms alarms] objectAtIndex:row]];
    } else {
        if (!oldAlarm) return;
        [inputController setDisplayedAlarm:oldAlarm];
        [oldAlarm release];
        oldAlarm = nil;
    }*/

    static Alarm * oldAlarm;
    NSTableView *table = [note object];
    AlarmCollection *collection;
    int selected = [table numberOfSelectedRows];
    if (selected == 0) { // Switch to the other one.
        table = table == presetTable ? currentTable : presetTable;
        selected = [table numberOfSelectedRows]; // Try again.
    }
    collection = table == presetTable ? presetAlarms : self;
    if (selected > 1) return;
    if (selected == 1) {
        int row = [table selectedRow];
        if (!oldAlarm) oldAlarm = [[inputController displayedAlarm] retain];
        lastSelectedAlarm = [[collection alarms] objectAtIndex:row];
        [inputController setDisplayedAlarm:lastSelectedAlarm];
        if (table == currentTable)
            [timeView setMilliseconds:[lastSelectedAlarm millisecondsRemaining]+999];
    } else {
        if (!oldAlarm) return;
        [inputController setDisplayedAlarm:oldAlarm];
        [oldAlarm release];
        oldAlarm = nil;
        lastSelectedAlarm = nil;
    }
}

- (void)handleDoneActionChange:(NSNotification *)note {
    // Is anything being shown?
    if (!lastSelectedAlarm) return;
    // Check if this is a current alarm.
    if ([lastSelectedAlarm millisecondsRemaining] && [lastSelectedAlarm paused]) return;
    [lastSelectedAlarm setDoneAction:[[note object] displayedDoneAction]];
}

// Action methods.

- (void)reformCurrentDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:correspondingDataArray(alarms)
                                              forKey:FobActiveAlarmsKey];
}

- (IBAction)addSelectedPresets:(id)source {
    NSArray * presets = [presetAlarms selectedAlarms];
    int i;
    for (i=0; i<[presets count]; i++)
        [self rawAdd:[[presets objectAtIndex:i] copy]];
    [self reformCurrentDefaults];
}

- (IBAction)addToCurrent:(id)source {
    Alarm *alarm = [inputController displayedAlarm];
    [self add:alarm];
}

- (IBAction)removeFromCurrent:(id)source {
    NSTableView *table = [[currentTable window] isVisible] ? currentTable : littleCurrentTable;
    int toRemove = [table numberOfSelectedRows], i;
    for (i=[table numberOfRows]-1; toRemove; i--) {
        if ([table isRowSelected:i]) {
            [[[alarms objectAtIndex:i] doneAction] stop]; // Easiest way.
            [self removeAlarmAtIndex:i];
            toRemove--;
        }
    }
    [self reformCurrentDefaults];
}

- (void)removeAlarmAtIndex:(int)index {
    Alarm *alarm = [alarms objectAtIndex:index];
    [alarm pause];
    [super removeAlarmAtIndex:index];
}

- (void)handleAlarmsChanged:(NSNotification *)note {
    [littleCurrentTable reloadData];
    [currentTable reloadData];
}

- (void)handleTableDelete:(NSNotification *)note {
    [self removeFromCurrent:[note object]];
}

- (void)handleAlarmTick:(NSNotification *)note {
    [littleCurrentTable reloadData];
    [currentTable reloadData];
    if ([note object] == lastSelectedAlarm) {
        [timeView setMilliseconds:[lastSelectedAlarm millisecondsRemaining]+999];
    }
}

- (void)handleAlarmDone:(NSNotification *)note {
    [self handleAlarmTick:note];
}

- (IBAction)clearDue:(id)sender {
    while ([alarms count] && [[alarms objectAtIndex:0] paused])
        [self removeAlarmAtIndex:0];
    [AttentionGrabber giveUpAttention];
    [self reformCurrentDefaults];
    //[window setLevel:NSScreenSaverWindowLevel];
    //[window setLevel:NSNormalWindowLevel];
}

- (IBAction)doubleClickPresets:(id)sender {
    int row = [sender clickedRow];
    [self add:[[[presetAlarms alarms] objectAtIndex:row] copy]];
}

- (BOOL)validateItem:(id)item {
    if ([item action] == @selector(addToCurrent:)) {
        return [inputController milliseconds] != 0;
    } else if ([item action] == @selector(addSelectedPresets:)) {
        return [presetTable numberOfSelectedRows];
    }/* else if ([item action] == @selector(clearDue:)) {
        return [alarms count] && [[alarms objectAtIndex:0] paused];
    }*/
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [self validateItem:anItem];
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)anItem {
    return [self validateItem:anItem];
}

@end
