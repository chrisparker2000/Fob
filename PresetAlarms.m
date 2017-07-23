/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  PresetAlarms.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 11 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "Alarm.h"
#import "PresetAlarms.h"
#import "TimeInputController.h"
#import "prefs.h"

PresetAlarms * defaultDatabase = nil;

@implementation PresetAlarms

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSAssert(!defaultDatabase, @"More than one PresetAlarms instance awoken from a nib file!");
    defaultDatabase = self;

    [alarms release];
    alarms = [correspondingObjectArray([defaults objectForKey:FobPresetAlarmsKey]) retain];
    //NSLog(@"Presets read!");
    // In a way, alarms have been added...
    [nc postNotificationName:@"FobAlarmAdded" object:self];
    
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
             object:presetTable];

    // We want to change the view as the table selection changes.
    [nc addObserver:self
           selector:@selector(handleTableSelection:)
               name:@"NSTableViewSelectionIsChangingNotification"
             object:presetTable];

    [presetTable reloadData];
}

- (id)init {
    if (self = [super init]) {
        alarms = [[NSMutableArray array] retain];
    }
    return self;
}

- (void)handleAlarmsChanged:(NSNotification *)note {
    [presetTable reloadData];
}

+ (PresetAlarms *)defaultDatabase {
    return defaultDatabase;
}

- (NSArray *)presets {
    return [super alarms];
}

// This will add an alarm without reforming the defaults.  This is 
- (void)rawAdd:(Alarm *)alarm {
    NSAssert([alarm paused], @"The preset's additional member was not paused!");
    if ([self findEntryForAlarm:alarm] >= 0) {
        NSBeginAlertSheet(NSLocalizedString(@"PresetExistsTitle", nil),
                          nil, nil, nil, window,
                          nil, nil, nil, nil,
                          NSLocalizedString(@"PresetExistsMessage", nil));
        return;
    }
    [super add:alarm];    
}

/* This will add an alarm.  The alarm added must be paused. */
- (void)add:(Alarm *)alarm {
    [self rawAdd:alarm];
    [self reformPresetDefaults];
}

- (Alarm *)getClosestBefore:(long long)milliseconds {
    int index = [self findEntryWithTime:milliseconds];
    if (index < 0) index = -1-index;
    index--;
    return index < 0 ? nil : [alarms objectAtIndex:index];
}

- (Alarm *)getClosestAfter:(long long)milliseconds {
    int index = [self findEntryWithTime:milliseconds];
    if (index < 0) index = -1-index;
    else index++;
    return index >= [[self presets] count] ? nil : [alarms objectAtIndex:index];
}

// Methods for adding and removing on the controller level.

- (void)reformPresetDefaults {
    [[NSUserDefaults standardUserDefaults] setObject:correspondingDataArray(alarms)
                                              forKey:FobPresetAlarmsKey];
}

- (IBAction)addToPresets:(id)source {
    Alarm *alarm = [inputController displayedAlarm];
    [self add:alarm];
}

- (IBAction)removeFromPresets:(id)source {
    int toRemove = [presetTable numberOfSelectedRows], i;
    for (i=[presetTable numberOfRows]-1; toRemove; i--) {
        if ([presetTable isRowSelected:i]) {
            [self removeAlarmAtIndex:i];
            toRemove--;
        }
    }
    [self reformPresetDefaults];
}


// Preset table methods.

- (void)handleTableDelete:(NSNotification *)note {
    [self removeFromPresets:note];
}

- (void)handleTableSelection:(NSNotification *)note {
    static Alarm * oldAlarm;
    int selected = [presetTable numberOfSelectedRows];
    if (selected > 1) return;
    if (selected == 1) {
        int row = [presetTable selectedRow];
        if (!oldAlarm)
            oldAlarm = [[inputController displayedAlarm] retain];
        [inputController setDisplayedAlarm:[alarms objectAtIndex:row]];
    } else {
        [inputController setDisplayedAlarm:oldAlarm];
        [oldAlarm release];
        oldAlarm = nil;
    }
}

- (NSArray *)selectedAlarms {
    int toGet = [presetTable numberOfSelectedRows], i;
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:toGet];
    for (i=0; toGet; i++) {
        if ([presetTable isRowSelected:i]) {
            [array addObject:[alarms objectAtIndex:i]];
            toGet--;
        }
    }
    return array;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self presets] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex {
    NSString *identifier = [aTableColumn identifier];
    Alarm *alarm = [[self presets] objectAtIndex:rowIndex];
    return [alarm valueForKey:identifier];
}

- (BOOL)validateItem:(id)item {
    if ([item action] == @selector(addToPresets:)) {
        return [inputController milliseconds] != 0;
    }
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [self validateItem:anItem];
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)anItem {
    return [self validateItem:anItem];
}

@end
