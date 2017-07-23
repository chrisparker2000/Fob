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
#import "ZoomSwitcher.h"
#import "DoneActionInputController.h"

CurrentAlarms * defaultCurrentDatabase = nil;

@implementation CurrentAlarms

- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSAssert(!defaultCurrentDatabase, @"More than one CurrentAlarms instance awoken from a nib file!");
    defaultCurrentDatabase = self;
    lastSelectedAlarm = nil;

    [presetTable setDoubleAction:@selector(doubleClickPresets:)];
    [presetTable setTarget:self];

    [currentTable setDoubleAction:@selector(doubleClickCurrent:)];
    [currentTable setTarget:self];
    [littleCurrentTable setDoubleAction:@selector(doubleClickCurrent:)];
    [littleCurrentTable setTarget:self];

    // Self listening, and paused collection listening.
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmAdded"
             object:self];
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmRemoved"
             object:self];
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmAdded"
             object:paused];
    [nc addObserver:self
           selector:@selector(handleAlarmsChanged:)
               name:@"FobAlarmRemoved"
             object:paused];
    
    // Table listening.
    [nc addObserver:self
           selector:@selector(handleTableDelete:)
               name:@"FobTableDelete"
             object:currentTable];
    [nc addObserver:self
           selector:@selector(handleTableDelete:)
               name:@"FobTableDelete"
             object:littleCurrentTable];

    // Time view listening.
    /*[nc addObserver:self
           selector:@selector(handleTimeChanged:)
               name:@"FobTimeUserChanged"
             object:timeView];*/
    
    // Alarm listening.
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
    
    [nc addObserver:self
           selector:@selector(handleQuit:)
               name:@"NSApplicationWillTerminateNotification"
             object:nil];
    
    [currentTable reloadData];
    [littleCurrentTable reloadData];
}

- (id)init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSArray *pausedArray = correspondingObjectArray([defaults objectForKey:FobPausedAlarmsKey]);
        NSEnumerator *enumerator = [pausedArray objectEnumerator];
        Alarm *pausedAlarm;
        alarms = [correspondingObjectArray([defaults objectForKey:FobActiveAlarmsKey]) retain];
        [alarms sortUsingSelector:@selector(timeCompare:)];
        paused = [[AlarmCollection alloc] init];
        while (pausedAlarm = [enumerator nextObject])
            [paused add:pausedAlarm];
        oldAlarm = lastSelectedAlarm = nil;
        activeAlarmColor = [[NSColor blackColor] retain];
        pausedAlarmColor = [[NSColor grayColor] retain];
    }
    return self;
}

- (void)dealloc {
    [self reformCurrentDefaults];

    [paused release];
    [activeAlarmColor release];
    [pausedAlarmColor release];
    [super dealloc];
}

/* Fob has the option to display a miniaturized version of itself.  This is accomplished by creating a second, smaller window, with an alternate display.  This returns the "current" alarm table for the present view, whether that present current table is in the big window or in the miniaturized window. */
- (NSTableView *)displayedTableView {
    return [[currentTable window] isVisible] ? currentTable : littleCurrentTable;
}

/* This returns an alarm at a given row within the table of current alarms. */
- (Alarm *)alarmAtRow:(unsigned)row {
    int c = [alarms count];
    return row < c ? [alarms objectAtIndex:row] :
        [[paused alarms] objectAtIndex:row-c];
}

/* Given an alarm, this returns the row that alarm is at.  If the alarm is not present, the results are undefined. */
- (int)rowForAlarm:(Alarm *)alarm {
    int row = [self findEntryForAlarm:alarm];
    return row>=0 ? row : [paused findEntryForAlarm:alarm]+[alarms count];
}

/* This returns an array of those alarms that are selected within the table of current alarms. */
- (NSArray *)selectedAlarms {
    NSTableView *table = [self displayedTableView];
    int toGet = [table numberOfSelectedRows], i;
    NSMutableArray * array = [NSMutableArray arrayWithCapacity:toGet];
    for (i=0; toGet; i++) {
        if ([table isRowSelected:i]) {
            [array addObject:[self alarmAtRow:i]];
            toGet--;
        }
    }
    return array;
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

- (int)add:(Alarm *)alarm {
    [self rawAdd:alarm];
    [self reformCurrentDefaults];
    return 0;
}

- (void)pause:(Alarm *)alarm {
    //NSLog(@"Pausing %@", alarm);
    if (![alarm millisecondsRemaining]) {
        NSBeginAlertSheet(NSLocalizedString(@"PauseZeroTimeTitle", nil),
                          nil, nil, nil, window,
                          nil, nil, nil, nil,
                          NSLocalizedString(@"PauseZeroTimeMessage", nil));
        return;
    }
    [alarm pause];
    if ([paused findEntryForAlarm:alarm] >= 0) return;
    [paused add:alarm];
    NSAssert([self remove:alarm], @"Attempted to pause a paused alarm!");
    //int rowPaused = [paused findEntryForAlarm:alarm];
    //[currentTable deselectRow:rowCurrent];
    //[currentTable selectRow:rowPaused+[alarms count] byExtendingSelection:YES];
}

- (void)unpause:(Alarm *)alarm {
    //NSLog(@"Unpausing %@", alarm);
    if ([self findEntryForAlarm:alarm] >= 0) return;
    [self rawAdd:alarm];
    NSAssert([paused remove:alarm], @"Attempted to unpause an active alarm!");
}

- (void)rewind:(Alarm *)alarm {
    //NSLog(@"Rewinding %@", alarm);
    if ([self findEntryForAlarm:alarm] >= 0) {
        // It's an active alarm.
        [alarm retain];
        NSAssert([self remove:alarm], @"Can't remove the alarm during rewind!");
        [alarm rewind];
        [self rawAdd:alarm];
        [alarm release];
    } else if ([paused findEntryForAlarm:alarm] >= 0) {
        // It's a paused alarm.
        [alarm retain];
        NSAssert([paused remove:alarm], @"Can't remove the paused alarm during rewind!");
        [alarm rewind];
        [paused add:alarm];
        [alarm release];
    }
}

- (void)setTime:(Alarm *)alarm toMilliseconds:(long long)ms {
    //NSLog(@"Setting time for %@ to %ld", alarm, ms);
    ms -= 1000; // For some reason a second is added if there is not an adjustment.
    if ([self findEntryForAlarm:alarm] >= 0) {
        // It's an active alarm.
        NSAssert([self remove:alarm], @"Can't remove the alarm during rewind!");
        [alarm setMillisecondsRemaining:ms];
        [self rawAdd:alarm];
    } else if ([paused findEntryForAlarm:alarm] >= 0) {
        // It's a paused alarm.
        NSAssert([paused remove:alarm], @"Can't remove the paused alarm during rewind!");
        [alarm setMillisecondsRemaining:ms];
        [paused add:alarm];
    }
}

- (void)handleTimeChanged:(NSNotification *)note {
    long long ms = [timeView milliseconds];
    NSArray *selected = [self selectedAlarms];
    NSEnumerator *enumerator = [selected objectEnumerator];
    NSTableView *tv = [self displayedTableView];
    Alarm *alarm;
    while (alarm = [enumerator nextObject])
        [self setTime:alarm toMilliseconds:ms];
    [tv deselectAll:nil];
    enumerator = [selected objectEnumerator];
    while (alarm = [enumerator nextObject])
        [tv selectRow:[self rowForAlarm:alarm] byExtendingSelection:YES];
    [self reformCurrentDefaults];
}

- (NSArray *)pausedAlarms {
    return [paused alarms];
}

// Table methods.

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [alarms count] + [[paused alarms] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(int)rowIndex {
    NSString *identifier = [aTableColumn identifier];
    Alarm *alarm = [self alarmAtRow:rowIndex];
    return [alarm valueForKey:identifier];
}

- (void)tableView:(NSTableView *)aTableView
  willDisplayCell:(id)aCell
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(int)rowIndex {
    NSFont *font = [aCell font];
    NSFontManager *manager = [NSFontManager sharedFontManager];
    if (rowIndex < [alarms count]) {
        font = [manager convertFont:font toNotHaveTrait:NSBoldFontMask];
        [aCell setTextColor:activeAlarmColor];
    } else {
        font = [manager convertFont:font toHaveTrait:NSBoldFontMask];
        [aCell setTextColor:pausedAlarmColor];
    }
    [aCell setFont:font];
}

- (void)handleTableSelection:(NSNotification *)note {
    NSTableView *table = [note object];
    AlarmCollection *collection;
    int selected = [table numberOfSelectedRows];
    if (selected == 0) { // Switch to the other table.  Perhaps it has selections?
        table = table == presetTable ? currentTable : presetTable;
        selected = [table numberOfSelectedRows]; // Try again.
    }
    collection = (table == presetTable) ? (AlarmCollection*) presetAlarms : (AlarmCollection*) self;
    if (selected > 1) return;
    if (selected == 1) {
        // If this is the only item selected, we want the alarm displayed in the clock display.
        int row = [table selectedRow];
        //if (!oldAlarm) oldAlarm = [[inputController displayedAlarm] retain];
        [lastSelectedAlarm autorelease];
        if (collection == self)
            lastSelectedAlarm = [[self alarmAtRow:row] retain];
        else
            lastSelectedAlarm = [[[presetAlarms alarms] objectAtIndex:row] retain];
        [inputController setDisplayedAlarm:lastSelectedAlarm];
        if (table == currentTable)
            [timeView setMilliseconds:[lastSelectedAlarm millisecondsRemaining]+999];
    } else {
        [lastSelectedAlarm autorelease];
        lastSelectedAlarm = [lastSelectedAlarm copy];
        [lastSelectedAlarm pause];
        [inputController setDisplayedAlarm:lastSelectedAlarm];
        /* In an older version of Fob, when you deselected an alarm, the alarm that was displayed before _anything_ was selected was again displayed.  This is perhaps desirable behavior, but in the light of other changes it is incompatible with some other desirable behavior I wish to have, ie the ability to change deleted alarms.  The oldAlarm variable is not really needed anymore.  This is new as of Fob 1.0.2. */
        
        /* if (!oldAlarm) return;
        [inputController setDisplayedAlarm:oldAlarm];
        [oldAlarm release];
        oldAlarm = nil;
        [lastSelectedAlarm release];
        lastSelectedAlarm = nil; */
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
    [[NSUserDefaults standardUserDefaults] setObject:correspondingDataArray([paused alarms])
                                              forKey:FobPausedAlarmsKey];
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
    NSTableView *table = [self displayedTableView];
    int toRemove = [table numberOfSelectedRows], i;
    
    for (i=[table numberOfRows]-1; toRemove; i--) {
        if ([table isRowSelected:i]) {
            [[[self alarmAtRow:i] doneAction] stop]; // Easiest way.
            [table deselectRow:i]; // Jon Zap.
            [self removeAlarmAtIndex:i];
            toRemove--;
        }
    }
    [self reformCurrentDefaults];
}

- (void)removeAlarmAtIndex:(int)index {
    int c = [alarms count];
    [[self alarmAtRow:index] pause];
    if (index < c) [super removeAlarmAtIndex:index];
    else [paused removeAlarmAtIndex:index-c];
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
    Alarm *alarm = [note object];
    if ([alarm repeats]) {
        // This is a repeating alarm.  Rewind it.
        NSArray *selected = [self selectedAlarms];
        NSEnumerator *enumerator = [selected objectEnumerator];
        NSTableView *tv = [self displayedTableView];
        [((DoneAction*)[[alarm doneAction] copy]) play];
        [tv deselectAll:nil];
        [self rewind:alarm];
        enumerator = [selected objectEnumerator];
        while (alarm = [enumerator nextObject])
            [tv selectRow:[self rowForAlarm:alarm] byExtendingSelection:YES];
    }
    [self handleAlarmTick:note];
}

- (IBAction)clearDue:(id)sender {
    while ([alarms count] && [((Alarm*)[alarms objectAtIndex:0]) paused])
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

- (IBAction)pauseSelected:(id)sender {
    NSArray *selected = [self selectedAlarms];
    NSEnumerator *enumerator = [selected objectEnumerator];
    NSTableView *tv = [self displayedTableView];
    Alarm *alarm;
    while (alarm = [enumerator nextObject])
        [self pause:alarm];
    [tv deselectAll:nil];
    enumerator = [selected objectEnumerator];
    while (alarm = [enumerator nextObject])
        [tv selectRow:[self rowForAlarm:alarm] byExtendingSelection:YES];
    [self reformCurrentDefaults];
}

- (IBAction)unpauseSelected:(id)sender {
    NSArray *selected = [self selectedAlarms];
    NSEnumerator *enumerator = [selected objectEnumerator];
    NSTableView *tv = [self displayedTableView];
    Alarm *alarm;
    while (alarm = [enumerator nextObject])
        [self unpause:alarm];
    [tv deselectAll:nil];
    enumerator = [selected objectEnumerator];
    while (alarm = [enumerator nextObject])
        [tv selectRow:[self rowForAlarm:alarm] byExtendingSelection:YES];
    [self reformCurrentDefaults];
}

- (IBAction)rewindLastDue:(id)sender {
    unsigned int i=0;
    for (i=0; i<[alarms count]; i++)
        if (![((Alarm*)[alarms objectAtIndex:i]) paused])
            break;
    if (i-- == 0) return; // No alarm at all is due.
    Alarm *a = ((Alarm*)[alarms objectAtIndex:i]);
    // Get the last due alarm.
    [self rewind:a];
    [self reformCurrentDefaults];
}

- (IBAction)rewindSelected:(id)sender {
    NSArray *selected = [self selectedAlarms];
    if ([selected count]) {
        // We have selected alarms.  Rewind those.
        NSEnumerator *enumerator = [selected objectEnumerator];
        NSTableView *tv = [self displayedTableView];
        Alarm *alarm;
        while (alarm = [enumerator nextObject])
            [self rewind:alarm];
        [tv deselectAll:nil];
        enumerator = [selected objectEnumerator];
        while (alarm = [enumerator nextObject])
            [tv selectRow:[self rowForAlarm:alarm] byExtendingSelection:YES];
        [self reformCurrentDefaults];
    } else {
        // We do not have selected alarms.  Rewind the last due alarm.
        [self rewindLastDue:sender];
    }
}

- (IBAction)doubleClickCurrent:(id)sender {
    int row = [sender clickedRow];
    if (row < [alarms count]) {
        // This must be an active alarm.  Pause it!
        [self pauseSelected:sender];
    } else {
        // This must be a paused alarm.  Reactivate it!
        [self unpauseSelected:sender];
    }
}

/* METHODS FOR ADDING TEXTUAL ALARMS. */

- (IBAction)beginTextAlarmSheet:(id)source {
    Alarm *alarm = [inputController displayedAlarm];
    if ([[textAlarmTime stringValue] length] == 0) {
        NSString *timeString = [alarm timeString];
        if ([timeString compare:NSLocalizedString(@"DoneAlarmDescriber", nil)] == NSOrderedSame)
            timeString = @"0:00";
        [textAlarmTime setStringValue:timeString];
    }
    if ([[textAlarmTitle stringValue] length] == 0) {
        [textAlarmTitle setStringValue:[alarm title]];
    }

    // Show the sheet.
    [NSApp beginSheet:textAlarmWindow
       modalForWindow:[[FobController defaultController] currentWindow]
        modalDelegate:self
       didEndSelector:@selector(textAlarmEnded:returnCode:contextInfo:)
          contextInfo:nil];
    [textAlarmTime lockFocus];
}

- (IBAction)endTextAlarmSheet:(id)sender {
    // Hide the sheet.
    [textAlarmWindow orderOut:sender];
    // Return to normal event handling.
    [NSApp endSheet:textAlarmWindow returnCode:[sender tag]];
}

- (void)textAlarmEnded:(NSWindow *)sheet
             returnCode:(int)returnCode
            contextInfo:(id)contextInfo {
    if (returnCode == 1) {
        // Cancel was selected!
        return;
    }
    
    // Extract the title.
    NSString *title = [textAlarmTitle stringValue];
    if ([title length]==0) title = NSLocalizedString(@"DefaultAlarmLabel", nil);
    
    // Extract the time.
    int time = 0, tempTime = 0;
    NSString *timeString = [[textAlarmTime stringValue] lowercaseString];
    NSScanner *timeScan = [NSScanner localizedScannerWithString:timeString];
    NSCharacterSet *numberSkip =
        [NSCharacterSet characterSetWithCharactersInString:@"0123456789hms"],
        *emptySet = [NSCharacterSet characterSetWithCharactersInString:@""];
    [timeScan setCharactersToBeSkipped:emptySet];
    while (![timeScan isAtEnd]) {
        int timeToken = 0;
        [timeScan scanUpToCharactersFromSet:numberSkip intoString:nil];
        if ([timeScan scanInt:&timeToken]) {
            tempTime *= 60;
            tempTime += timeToken;
        } else {
            if ([timeScan isAtEnd]) break;
            switch ([timeString characterAtIndex:[timeScan scanLocation]]) {
            case 'h':
                tempTime *= 60;
            case 'm':
                tempTime *= 60;
            default:
                time += tempTime;
                tempTime = 0;
            }
            [timeScan setScanLocation:[timeScan scanLocation]+1];
            [timeScan scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet]
                                     intoString:nil];
        }
    }
    time += tempTime;
    if (time <= 0 || time >= 12*3600) {
        NSBeginAlertSheet(NSLocalizedString(@"TimeOutOfRangeTitle", nil),
                          nil, nil, nil, window,
                          nil, nil, nil, nil,
                          NSLocalizedString(@"TimeOutOfRangeMessage", nil));
        return;
    }
    // We are going to make an alarm sort of like the one displayed, except with a
    // different title and time remaining (same done action)
    Alarm *alarm = [Alarm alarmWithTitle:title forSecondDuration:time];
    [alarm setDoneAction:[[[[inputController displayedAlarm] doneAction] copy] autorelease]];
    [self add:alarm];
}

/* INTERFACE VALIDATION METHODS. */

- (BOOL)validateItem:(id)item {
    SEL action = [item action];
    NSTableView *tv = [self displayedTableView];
    if (action == @selector(addToCurrent:)) {
        return [inputController milliseconds] != 0;
    } else if (action == @selector(addSelectedPresets:)) {
        return [presetTable numberOfSelectedRows];
    } else if (action == @selector(pauseSelected:)) {
        switch ([tv numberOfSelectedRows]) {
            case 0:
                // Can't pause anything!
                return NO;
            case 1:
                // Can only pause non-paused ones.
                return [tv selectedRow] < [alarms count];
            default:
                return [[[tv selectedRowEnumerator] nextObject] intValue] < [alarms count];
        }
    } else if (action == @selector(unpauseSelected:)) {
        switch ([tv numberOfSelectedRows]) {
            case 0:
                // Can't unpause anything!
                return NO;
            case 1:
                // Can only unpause paused ones.
                return [tv selectedRow] >= [alarms count];
            default:
                return [[[[tv selectedRowEnumerator] allObjects] lastObject] intValue]
                >= [alarms count];
        }
    } else if (action == @selector(rewindSelected:)) {
        //return [tv numberOfSelectedRows];
        return YES;
    }
    // By default, validate everything as enabled.
    return YES;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    return [self validateItem:anItem];
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)anItem {
    return [self validateItem:anItem];
}

- (void)handleQuit:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:FobClearDueOnQuitKey]) {
        [self clearDue:sender];
    }
}

@end
