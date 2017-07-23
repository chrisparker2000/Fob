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

CurrentAlarms * defaultCurrentDatabase = nil;

@implementation CurrentAlarms

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSAssert(!defaultCurrentDatabase, @"More than one CurrentAlarms instance awoken from a nib file!");
    defaultCurrentDatabase = self;

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
    [nc addObserver:self
           selector:@selector(handleTableDelete:)
               name:@"FobTableDelete"
             object:currentTable];

    [nc addObserver:self
           selector:@selector(handleAlarmTick:)
               name:@"FobAlarmTick"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleAlarmTick:)
               name:@"FobAlarmDone"
             object:nil];

    [currentTable reloadData];
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
    int toRemove = [currentTable numberOfSelectedRows], i;
    for (i=[currentTable numberOfRows]-1; toRemove; i--) {
        if ([currentTable isRowSelected:i]) {
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
    [currentTable reloadData];
}

- (void)handleTableDelete:(NSNotification *)note {
    [self removeFromCurrent:note];
}

- (void)handleAlarmTick:(NSNotification *)note {
    [currentTable reloadData];
}

- (IBAction)clearDue:(id)sender {
    while ([alarms count] && [[alarms objectAtIndex:0] paused])
        [self removeAlarmAtIndex:0];
    [AttentionGrabber giveUpAttention];
    [self reformCurrentDefaults];
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
