/* Copyright © 2003, Leaky Puppy Software, Net Monkey Inc.

This file is part of Fob.

Fob is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

Fob is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with Fob; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA */

//  FileDoneAction.m
//  Fob
//
//  Created by Thomas Finley on Wed Jan 29 2003.
//  Copyright (c) 2003 Leaky Puppy Software, for Net Monkey Inc. All rights reserved.
//  This program is distributed under the terms of the GNU General Public License.

#import "FileDoneAction.h"
#import "DoneActionInputController.h"

@implementation FileDoneAction

- (void)loadSoundFile {
    // A few checks to make sure that all is well.
    BOOL directory;
    [fileSound release];
    fileSound = nil;
    if (!filePath) return;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&directory]) return;
    if (directory) return;
    fileSound = [[NSSound alloc] initWithContentsOfFile:filePath byReference:YES];
}

- (void)loadScriptFile {
    // A few checks to make sure that all is well.
    BOOL directory;
    NSDictionary *errors = nil;
    [fileScript release];
    fileScript = nil;
    if (!filePath) return;
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&directory]) return;
    if (directory) return;
    NSURL *url = [NSURL fileURLWithPath:filePath];
    fileScript = [[NSAppleScript alloc] initWithContentsOfURL:url error:&errors];
    if (errors) {
        NSLog(@"Warning: AppleScript load failed with errors %@", errors);
    }
}

- (void)setFilePath:(NSString*)path {
    [filePath autorelease];
    filePath = [path retain];
    if ([DoneActionInputController isSoundAtPath:filePath])
        [self loadSoundFile];
    if ([DoneActionInputController isScriptAtPath:filePath])
        [self loadScriptFile];
}

-(id)initWithFilePath:(NSString *)path {
    if (self = [super init]) {
        fileSound = nil;
        filePath = nil;
        fileScript = nil;
        opened = NO;
        [self setFilePath:path];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        fileSound = nil;
        filePath = nil;
        fileScript = nil;
        opened = NO;
        [self setFilePath:[coder decodeObject]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:filePath];
}

- (void)dealloc {
    [self stop];
    [filePath release];
    [fileSound release];
    [super dealloc];
}

- (void)play {
    [super play];
    if (fileSound) {
        [fileSound play];
    } else if (!opened && fileScript) {
        NSDictionary *error = nil;
        [fileScript executeAndReturnError:&error];
        opened = YES;
    } else if (!opened && filePath) {
        if ([[NSWorkspace sharedWorkspace] openFile:filePath] == NO) {
            NSLog(@"Could not open file %@.", filePath);
        }
        opened = YES;
    }
}

- (void)stop {
    [fileSound stop];
}

- (BOOL)isPlaying {
    return [fileSound isPlaying];
}

/* Returns the name of the file path that this done action will play. */
- (NSString *)filePath {
    return filePath;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[FileDoneAction alloc] initWithFilePath:[self filePath]];
}

@end
