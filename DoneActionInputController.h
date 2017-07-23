/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  DoneActionInputController.h
//  Fob
//
//  Created by Thomas Finley on Sat Jan 25 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Cocoa/Cocoa.h>

// Notifications:
// "FobDoneActionChange" when the done action is modified by the user

@class DoneAction;

@interface DoneActionInputController : NSObject {
    IBOutlet NSPopUpButton *alertPopUp;
    IBOutlet NSTabView *customizeTypeDisplay;
    IBOutlet NSImageView *fileIconDisplay;
    IBOutlet NSTextField *fileNameDisplay;
    IBOutlet NSMatrix *typeChooseButtons;
    IBOutlet NSWindow *mainWindow;

    NSString *filePath;
    BOOL posted, toPost;
}
+ (NSArray *)fileTypesAccepted;
+ (NSArray *)soundFileTypesAccepted;
+ (BOOL)isSoundAtPath:(NSString *)path;
+ (BOOL)isScriptAtPath:(NSString *)path;

- (void)setupAlertPopUp;
- (IBAction)changeAlert:(id)sender;
- (IBAction)changeFile:(id)sender;
- (IBAction)changeType:(id)sender;

- (void)setFile:(NSString *)path;
- (void)synchronizeView;

- (DoneAction *)displayedDoneAction;
- (void)setDisplayedDoneAction:(DoneAction *)newAction;

@end
