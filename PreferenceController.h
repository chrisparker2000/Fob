/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  PreferenceController.h
//  Fob
//
//  Created by Thomas Finley on Sat Jan 18 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import <Cocoa/Cocoa.h>
#import "prefs.h"

// Notifications:
// "FobStatusItemVisibilityChanged" a status item preference change

@interface PreferenceController : NSObject {
    IBOutlet NSButton *confirmDeleteCheckbox;
    IBOutlet NSButton *keepWindowOpenCheckbox;
    IBOutlet NSButton *statusItemVisibleCheckbox;
    IBOutlet NSButton *statusItemTitleVisibleCheckbox;
    IBOutlet NSButton *scaleDockTimeCheckbox;
    IBOutlet NSButton *disableCommandQCheckbox;
    IBOutlet NSButton *dockMenuSubmenusCheckbox;
    IBOutlet NSButton *clearDueOnQuitCheckbox;
    IBOutlet NSTextField *feedbackLabel;
    IBOutlet NSTextField *bounceLabel;
    IBOutlet NSSlider *feedbackSlider;
    IBOutlet NSSlider *bounceSlider;
    
    IBOutlet NSWindow *preferenceWindow;
    IBOutlet NSWindow *mainWindow;
    IBOutlet NSWindow *miniWindow;
    IBOutlet NSMenuItem *quitItem;

    // Stored keys, in the event of a cancel on the sheet.
    NSDictionary *savedValues;
}
- (void)displayPreferences;
- (IBAction)changeConfirmDeletions:(id)sender;
- (IBAction)changeKeepOpen:(id)sender;
- (IBAction)changeFeedback:(id)sender;
- (IBAction)changeBounce:(id)sender;
- (IBAction)changeStatusVisible:(id)sender;
- (IBAction)changeStatusTitleVisible:(id)sender;
- (IBAction)changeScaleDockTime:(id)sender;
- (IBAction)changeCommandQ:(id)sender;
- (IBAction)changeDockMenuSubmenus:(id)sender;
- (IBAction)changeClearDueOnQuit:(id)sender;
- (IBAction)endSheet:(id)sender;
@end
