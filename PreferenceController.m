/* Copyright � 2003, Leaky Puppy Software, Net Monkey Inc.

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
#import "FobController.h"
#import "StatusItemKeeper.h"
#import "ZoomSwitcher.h"
#import "prefs.h"

@implementation PreferenceController

- (id)init {
    if (self = [super init]) {
        savedValues = nil;
    }
    return self;
}

- (void)awakeFromNib {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [mainWindow setHidesOnDeactivate:![defaults boolForKey:FobKeepWindowOpenKey]];
    // Status item nonsense.
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_1) {
        // Status items can't be used in "OS X".
        [statusItemVisibleCheckbox setEnabled:NO];
        [bounceSlider setEnabled:NO];
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"FobStatusItemVisibilityChanged"
                      object:self];
    [quitItem setKeyEquivalent:
        ([defaults boolForKey:FobDisableCommandQKey] ? @"" : @"q")];
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

- (void)changeBounceLabel {
    switch ([bounceSlider intValue]) {
        case flash:
            [bounceLabel setStringValue:NSLocalizedString(@"BounceLevelNone", nil)];
            break;
        case beep:
            [bounceLabel setStringValue:NSLocalizedString(@"BounceLevelOnce", nil)];
            break;
        case alwaysBeep:
            [bounceLabel setStringValue:NSLocalizedString(@"BounceLevelAlways", nil)];
            break;
        default:
            NSLog(@"Warning, bad bounce level!");
            break;
    }
}


// This will display the preferences sheet.
- (void)displayPreferences {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Store values in case of cancel.
    savedValues = [[defaults dictionaryRepresentation] retain];
    
    // Change the view to reflect current preferences.
    [confirmDeleteCheckbox setState:[defaults boolForKey:FobConfirmDeleteKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [keepWindowOpenCheckbox setState:[defaults boolForKey:FobKeepWindowOpenKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [statusItemVisibleCheckbox setState:[defaults boolForKey:FobStatusItemVisibleKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [statusItemTitleVisibleCheckbox setState:
        [defaults boolForKey:FobStatusItemTitleVisibleKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [statusItemTitleVisibleCheckbox setEnabled:[defaults boolForKey:FobStatusItemVisibleKey]];
    [scaleDockTimeCheckbox setState:[defaults boolForKey:FobScaleDockTimeKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [disableCommandQCheckbox setState:[defaults boolForKey:FobDisableCommandQKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [dockMenuSubmenusCheckbox setState:[defaults boolForKey:FobDockMenuSubmenusKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [clearDueOnQuitCheckbox setState:[defaults boolForKey:FobClearDueOnQuitKey] ? NSControlStateValueOn : NSControlStateValueOff];
    [feedbackSlider setIntValue:[defaults integerForKey:FobFeedbackLevelKey]];
    [bounceSlider setIntValue:[defaults integerForKey:FobBounceLevelKey]];
    [self changeFeedbackLabel];
    [self changeBounceLabel];
    
    // Show the sheet.
    [NSApp beginSheet:preferenceWindow
       modalForWindow:[[FobController defaultController] currentWindow]
        modalDelegate:self
       didEndSelector:@selector(preferenceEnded:returnCode:contextInfo:)
          contextInfo:nil];
}

- (IBAction)changeConfirmDeletions:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:[confirmDeleteCheckbox state] == NSControlStateValueOn
               forKey:FobConfirmDeleteKey];
}

- (IBAction)changeKeepOpen:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL keepWindowOpen = [keepWindowOpenCheckbox state] == NSControlStateValueOn;
    [defaults setBool:keepWindowOpen
               forKey:FobKeepWindowOpenKey];
    [mainWindow setHidesOnDeactivate:!keepWindowOpen];
}

- (IBAction)changeFeedback:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[feedbackSlider intValue]
                  forKey:FobFeedbackLevelKey];
    [self changeFeedbackLabel];
}

- (IBAction)changeBounce:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:[bounceSlider intValue]
                  forKey:FobBounceLevelKey];
    [self changeBounceLabel];
}

- (IBAction)changeStatusVisible:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL statusVisible = [statusItemVisibleCheckbox state] == NSControlStateValueOn;
    [defaults setBool:statusVisible
               forKey:FobStatusItemVisibleKey];
    [statusItemTitleVisibleCheckbox setEnabled:statusVisible];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FobStatusItemVisibilityChanged"
                                                        object:self];
}

- (IBAction)changeStatusTitleVisible:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL statusTitleVisible = [statusItemTitleVisibleCheckbox state] == NSControlStateValueOn;
    [defaults setBool:statusTitleVisible
               forKey:FobStatusItemTitleVisibleKey];
}

- (IBAction)changeScaleDockTime:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL scaleDockTime = [scaleDockTimeCheckbox state] == NSControlStateValueOn;
    [defaults setBool:scaleDockTime
               forKey:FobScaleDockTimeKey];
}

- (IBAction)changeCommandQ:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL disableQ = [disableCommandQCheckbox state] == NSControlStateValueOn;
    [defaults setBool:disableQ
               forKey:FobDisableCommandQKey];
    [quitItem setKeyEquivalent:(disableQ ? @"" : @"q")];
}

- (IBAction)changeDockMenuSubmenus:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL dms = [dockMenuSubmenusCheckbox state] == NSControlStateValueOn;
    [defaults setBool:dms
               forKey:FobDockMenuSubmenusKey];
}

- (IBAction)changeClearDueOnQuit:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL cdoq = [clearDueOnQuitCheckbox state] == NSControlStateValueOn;
    [defaults setBool:cdoq
               forKey:FobClearDueOnQuitKey];
}

- (IBAction)endSheet:(id)sender {
    // Hide the sheet.
    [preferenceWindow orderOut:sender];
    // Return to normal event handling.
    [NSApp endSheet:preferenceWindow returnCode:[sender tag]];
}

- (void)preferenceEnded:(NSWindow *)sheet
             returnCode:(int)returnCode
            contextInfo:(id)contextInfo {
    if (returnCode == 1) {
        // Notice my comparison test.  I am a bad coder.
        // Cancel was selected!

        // Setting things back as they were.
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *factoryValues = factoryDefaults();
        [factoryValues removeObjectForKey:FobPresetAlarmsKey];
        [factoryValues removeObjectForKey:FobActiveAlarmsKey];
        NSEnumerator *keyEnum = [factoryValues keyEnumerator];
        id key;
        while (key = [keyEnum nextObject]) {
            [defaults setObject:[savedValues objectForKey:key]
                         forKey:key];
        }
        // Some preferences require some action beyond merely setting the default.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"FobStatusItemVisibilityChanged"
                                                            object:self];
        [mainWindow setHidesOnDeactivate:![defaults boolForKey:FobKeepWindowOpenKey]];
        [quitItem setKeyEquivalent:([defaults boolForKey:FobDisableCommandQKey] ? @"" : @"q")];
    }
    [savedValues release];
}

@end
