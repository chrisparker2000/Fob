/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  ToolbarDelegate.m
//  Fob
//
//  Created by Thomas Finley on Mon Jan 13 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "ToolbarDelegate.h"
#import "TimeView.h"
#import "PresetAlarms.h"
#import "CurrentAlarms.h"

@implementation FobController (ToolbarDelegate)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

    if ( [itemIdentifier isEqualToString:@"Start"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarStartLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"start"]];
        [item setToolTip:NSLocalizedString(@"ToolbarStartTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(addToCurrent:)];
    } else if ( [itemIdentifier isEqualToString:@"StoreAsPreset"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarStoreLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"rolodex"]];
        [item setToolTip:NSLocalizedString(@"ToolbarStoreTip", nil)];
        [item setTarget:presetAlarms];
        [item setAction:@selector(addToPresets:)];
    } else if ( [itemIdentifier isEqualToString:@"StartSelectedPresets"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarStartSelectedPresetsLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"selected"]];
        [item setToolTip:NSLocalizedString(@"ToolbarStartSelectedPresetsTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(addSelectedPresets:)];
    } else if ( [itemIdentifier isEqualToString:@"Delete"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarDeleteLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"trash"]];
        [item setToolTip:NSLocalizedString(@"ToolbarDeleteTip", nil)];
        [item setTarget:nil];
        [item setAction:@selector(delete:)];
    } else if ( [itemIdentifier isEqualToString:@"Preferences"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarPreferencesLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"preferences"]];
        [item setToolTip:NSLocalizedString(@"ToolbarPreferencesTip", nil)];
        [item setTarget:self];
        [item setAction:@selector(showPreferences:)];
    } else if ( [itemIdentifier isEqualToString:@"ClearDue"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarClearDueLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"clean"]];
        [item setToolTip:NSLocalizedString(@"ToolbarClearDueTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(clearDue:)];
    } else if ( [itemIdentifier isEqualToString:@"Rewind"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarRewindLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"rewind"]];
        [item setToolTip:NSLocalizedString(@"ToolbarRewindTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(rewindSelected:)];
    } else if ( [itemIdentifier isEqualToString:@"Pause"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarPauseLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"pause"]];
        [item setToolTip:NSLocalizedString(@"ToolbarPauseTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(pauseSelected:)];
    } else if ( [itemIdentifier isEqualToString:@"Unpause"] ) {
        [item setLabel:NSLocalizedString(@"ToolbarUnpauseLabel", nil)];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"unpause"]];
        [item setToolTip:NSLocalizedString(@"ToolbarUnpauseTip", nil)];
        [item setTarget:currentAlarms];
        [item setAction:@selector(unpauseSelected:)];
    }
    
    return [item autorelease];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        @"Start",
        @"StoreAsPreset",
        @"StartSelectedPresets",
        @"Delete",
        @"Preferences",
        @"ClearDue",
        @"Rewind",
        @"Pause",
        @"Unpause",
        NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier,
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:
        @"Start",
        @"StoreAsPreset",
        @"StartSelectedPresets",
        @"Delete",
        @"ClearDue",
        @"Rewind",
        @"Pause",
        @"Unpause",
        NSToolbarFlexibleSpaceItemIdentifier,
        @"Preferences",
        NSToolbarCustomizeToolbarItemIdentifier, nil];
}

- (void)setupToolbar {
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [[timeView window] setToolbar:[toolbar autorelease]];

    //[customizeToolbarItem setTarget:toolbar];
    //[customizeToolbarItem setSelector:@selector(runCustomizationPalette:)];
}

@end
