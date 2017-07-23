/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  DoneActionInputController.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 25 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "DoneActionInputController.h"
#import "DoneAction.h"
#import "BeepDoneAction.h"
#import "AlertDoneAction.h"
#import "FileDoneAction.h"

enum _DoneActionType {
    beep = 0, alert, file
} DoneActionType;

@implementation DoneActionInputController

- (id)init {
    if (self = [super init]) {
        //filePath = nil;
        toPost = NO;
        [self setFile:nil];
        toPost = YES;
    }
    return self;
}

- (void)postChange {
    if (!toPost) return;
    posted = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobDoneActionChange"
                                                        object:self];
}

- (void)awakeFromNib {
    [self setupAlertPopUp];
}

/* Returns an array of those types of files that are accepted by the done action input. */
+ (NSArray *)fileTypesAccepted {
    return [NSSound soundUnfilteredFileTypes];
}

/* Returns if the file at path is a proper sound file. */
+ (BOOL)isSoundAtPath:(NSString *)path {
    NSArray *types = [DoneActionInputController fileTypesAccepted];
    NSEnumerator *enumerator = [types objectEnumerator];
    NSString *type;
    while (type = [enumerator nextObject]) {
        if ([path hasSuffix:type]) return YES;
    }
    return NO;
}

- (void)setupAlertPopUp {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *userSounds = [fm directoryContentsAtPath:[@"~/Library/Sounds/" stringByExpandingTildeInPath]];
    NSArray *systemSounds = [fm directoryContentsAtPath:@"/System/Library/Sounds/"];
    NSMutableArray *sounds = [NSMutableArray array];
    NSMutableSet *alertNames = [NSMutableSet set];
    NSEnumerator *enumerator;
    NSString *fileName;

    if (userSounds) [sounds addObjectsFromArray:userSounds];
    if (systemSounds) [sounds addObjectsFromArray:systemSounds];

    // Get the alert names.
    enumerator = [sounds objectEnumerator];
    while (fileName = [enumerator nextObject]) {
        if (![fileName hasSuffix:@".aiff"]) continue; // Alerts require this, apparently.
        [alertNames addObject:[fileName substringToIndex:[fileName length]-5]];
    }

    // Sort the fucking sound resource names.
    userSounds = [[alertNames allObjects] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];

    // Put them in the god damned fucking alert fucking choosing popup fucking menu.
    [alertPopUp removeAllItems];
    [alertPopUp addItemsWithTitles:userSounds];

    // Save some time...
    [alertPopUp setAutoenablesItems:NO];
}

- (IBAction)changeAlert:(id)sender {
    NSString *alertName = [alertPopUp titleOfSelectedItem];
    // It's probably good to play the sound.
    [(NSSound*)[NSSound soundNamed:alertName] play];
    [self postChange];
}

- (void)openPanelDidEnd:(NSOpenPanel *)openPanel
             returnCode:(int)returnCode
            contextInfo:(void *)x {
    if (returnCode != NSOKButton) return;
    [self setFile:[openPanel filename]];
}

/* This will set the file to set to display. */
- (void)setFile:(NSString *)path {
    NSString *fileName;
    // Get the new path.
    if (path) {
        [path retain];
        [filePath release];
        filePath = path;
        NSFileWrapper *fw = [[NSFileWrapper alloc] initWithPath:filePath];
        [fileIconDisplay setImage:[fw icon]];
        fileName = [fw filename];
        if (fileName) {
            [fileNameDisplay setTextColor:[NSColor blackColor]];
        } else {
            [fileNameDisplay setTextColor:[NSColor grayColor]];
            [fileIconDisplay setImage:[NSImage imageNamed:@"notfound.png"]];
            fileName = @"Not found";
        }
        [fw release];
    } else {
        [filePath release];
        filePath = path;
        [fileNameDisplay setTextColor:[NSColor grayColor]];
        [fileIconDisplay setImage:[NSImage imageNamed:@"notfound.png"]];
        fileName = @"No file";
    }
    [fileNameDisplay setStringValue:fileName];
    if ([[typeChooseButtons selectedCell] tag] != file) {
        [typeChooseButtons selectCellAtRow:file column:0];
        [self synchronizeView];
    }
    [self postChange];
}

/* This will begin the process of opening up the open file panel. */
- (IBAction)changeFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel beginSheetForDirectory:nil
                             file:nil
                            types:[DoneActionInputController fileTypesAccepted]
                   modalForWindow:mainWindow
                    modalDelegate:self
                   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
                      contextInfo:nil];
}

/* This will set the customized type display to that indicated by the group of radio buttons. */
- (void)synchronizeView {
    NSButton *selected = [typeChooseButtons selectedCell];
    [customizeTypeDisplay selectTabViewItemAtIndex:[selected tag]];
}

- (IBAction)changeType:(id)sender {
    int tag = [[typeChooseButtons selectedCell] tag];
    posted = NO;
    [self synchronizeView];
    if (tag == file) [self changeFile:nil];
    if (!posted) [self postChange];
}

- (DoneAction *)displayedDoneAction {
    switch ([[typeChooseButtons selectedCell] tag]) {
        case beep:
            return [[[BeepDoneAction alloc] init] autorelease];
            break;
        case alert:
            return [[[AlertDoneAction alloc] initWithSoundNamed:
                [alertPopUp titleOfSelectedItem]] autorelease];
            break;
        case file:
            return [[[FileDoneAction alloc] initWithFilePath:filePath] autorelease];
            break;
        default:
            NSLog(@"Error, bad type of done action!");
            return nil;
            break;
    }
}

- (void)setDisplayedDoneAction:(DoneAction *)doneAction {
    toPost = NO;
    if ([doneAction isKindOfClass:[BeepDoneAction class]]) {
        [typeChooseButtons selectCellAtRow:beep column:0];
        [customizeTypeDisplay selectTabViewItemAtIndex:beep];
    } else if ([doneAction isKindOfClass:[AlertDoneAction class]]) {
        [typeChooseButtons selectCellAtRow:alert column:0];
        [alertPopUp selectItemWithTitle:[(AlertDoneAction *) doneAction soundName]];
        [customizeTypeDisplay selectTabViewItemAtIndex:alert];
    } else if ([doneAction isKindOfClass:[FileDoneAction class]]) {
        [typeChooseButtons selectCellAtRow:file column:0];
        [self setFile:[(FileDoneAction *)doneAction filePath]];
        [customizeTypeDisplay selectTabViewItemAtIndex:file];
    } else {
        NSLog(@"Warning, unsupported done action read %@", doneAction);
    }
    toPost = YES;
}

@end
