/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  FileAcceptorView.m
//  Fob
//
//  Created by Thomas Finley on Sun Jan 26 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "FileAcceptorView.h"
#import "DoneActionInputController.h"

#define ITUNES @"CorePasteboardFlavorType 0x6974756E"

@implementation FileAcceptorView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code here.
        [self setHighlighted:NO];
        /*[self registerForDraggedTypes:
            [NSArray arrayWithObjects:NSFilenamesPboardType, NSURLPboardType, NSStringPboardType, nil]];*/
        /*[self registerForDraggedTypes:
            [NSAttributedString textPasteboardTypes]];*/
        [self registerForDraggedTypes:
            [NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        // NSFilesPromisePboardType is not in the original system!
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    [super drawRect:rect];
    if (highlighted) {
        float width = [NSBezierPath defaultLineWidth];
        NSRect bounds = [self bounds];
        [[NSColor selectedControlColor] set];
        [NSBezierPath setDefaultLineWidth:10.0f];
        [NSBezierPath strokeRect:bounds];
        [NSBezierPath setDefaultLineWidth:width];
    }
}

- (BOOL)highlighted {
    return highlighted;
}

- (void)setHighlighted:(BOOL) newHighlight {
    highlighted = newHighlight;
    [self setNeedsDisplay:YES];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    //NSLog(@"TYPES %@", [pboard types]);
    if ([sender draggingSource] == self) return NSDragOperationNone;
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationGeneric) {
            NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
            if ([filenames count] != 1) return NSDragOperationNone;
            if (![DoneActionInputController isSoundAtPath:[filenames objectAtIndex:0]])
                return NSDragOperationNone;
            //NSLog(@"DRAGGED: %@", filenames);
            [self setHighlighted:YES];
            return NSDragOperationGeneric;
        }
    }/* else if ([[pboard types] containsObject:NSFilesPromisePboardType]) {
        NSArray *types = [pboard types];
        //NSLog(@"%@", types);
        NSEnumerator *enumerator = [types objectEnumerator];
        NSString *type;
        NSLog(@"PING! %@", NSFilesPromisePboardType);
        while (type = [enumerator nextObject]) {
            NSLog(@"  TYPE \"%@\" has CONTENTS %@", type, [pboard propertyListForType:type]);
        }
    }*/
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>) sender {
    [self setHighlighted:NO];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>) sender {
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>) sender {
    // We have confirmed that the sender has the name of a file drag thingie.
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSArray *filenames = [pboard propertyListForType:NSFilenamesPboardType];
    [doneActionInputController setFile:[filenames objectAtIndex:0]];
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>) sender {
    [self setHighlighted:NO];
}
@end
