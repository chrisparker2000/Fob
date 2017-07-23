/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  PreferenceController.m
//  Fob
//
//  Created by Thomas Finley on Sat Jan 18 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "PreferenceController.h"
#import "prefs.h"

@implementation PreferenceController

- (id)init {
    self = [super init];
    return self;
}

- (void)changeFeedbackLabel {
    switch ([feedbackSlider intValue]) {
        case flash:
            [feedbackLabel setStringValue:NSLocalizedString(@"FeedbackLevelFlashOnly", nil)];
            break;
        case beep:
            [feedbackLabel setStringValue:NSLocalizedString(@"FeedbackLevelBeepOnce", nil)];
            break;
        case alwaysBeep:
            [feedbackLabel setStringValue:NSLocalizedString(@"FeedbackLevelBeepAlways", nil)];
            break;
        default:
            NSLog(@"Warning, bad feedback level!");
            break;
    }
}

// This will display the preferences sheet.
- (void)displayPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Store values in case of cancel.
    storedConfirmDelete = [defaults boolForKey:FobConfirmDeleteKey];
    storedFeedbackLevel = [defaults boolForKey:FobFeedbackLevelKey];
    // Change the view to reflect current preferences.
    [confirmDeleteCheckbox setState:storedConfirmDelete ? NSOnState : NSOffState];
    [feedbackSlider setIntValue:storedFeedbackLevel];
    [self changeFeedbackLabel];
    // Show the sheet.
    [NSApp beginSheet:preferenceWindow
       modalForWindow:mainWindow
        modalDelegate:self
       didEndSelector:@selector(preferenceEnded:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)changeConfirmDeletions:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[sender state] == NSOnState
               forKey:FobConfirmDeleteKey];
}

- (IBAction)changeFeedback:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[feedbackSlider intValue]
                  forKey:FobFeedbackLevelKey];
    [self changeFeedbackLabel];
}

- (IBAction)endSheet:(id)sender {
    // Hide the sheed.
    [preferenceWindow orderOut:sender];
    // Return to normal event handling.
    [NSApp endSheet:preferenceWindow returnCode:[sender tag]];
}

- (void)preferenceEnded:(NSWindow *)sheet
             returnCode:(int)returnCode
            contextInfo:(id)contextInfo {
    if (returnCode == 1) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // Cancel was selected!
        // Setting things back as they were.
        [defaults setBool:storedConfirmDelete
                   forKey:FobConfirmDeleteKey];
        [defaults setInteger:storedFeedbackLevel
                      forKey:FobFeedbackLevelKey];
    }
}

@end
