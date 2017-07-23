/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  CurrentAlarms.h
//  Fob
//
//  Created by Thomas Finley on Sat Jan 11 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Cocoa/Cocoa.h>
#import "AlarmCollection.h"

@class Alarm, TimeInputController, PresetAlarms, TimeView;

@interface CurrentAlarms : AlarmCollection {
    IBOutlet NSTableView *currentTable, *presetTable, *littleCurrentTable;
    IBOutlet TimeInputController *inputController;
    IBOutlet PresetAlarms *presetAlarms;
    IBOutlet NSWindow *window;
    IBOutlet TimeView *timeView;

    Alarm *lastSelectedAlarm, *oldAlarm;
}

+ (CurrentAlarms *)defaultDatabase;

// The current alarms table.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex;

// Current alarms setting.
- (void)reformCurrentDefaults;
- (IBAction)addToCurrent:(id)source;
- (IBAction)addSelectedPresets:(id)source;
- (IBAction)removeFromCurrent:(id)source;
- (IBAction)clearDue:(id)sender;
- (IBAction)doubleClickPresets:(id)sender;

// Synchronization calls.
- (void)reformCurrentDefaults;

@end
