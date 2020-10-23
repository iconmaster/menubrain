//
//  AXCVHandler.m
//  MenuBrain
//
//  Created by John Marstall on 11/7/09.
//  Copyright 2009 Alamofire. All rights reserved.
//

#import "AXCVHandler.h"


@implementation AXCVHandler 

- (BOOL)performKeyEquivalent:(NSEvent *)event {
    if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
        // The command key is the ONLY modifier key being pressed.
        if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
            return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
            return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
            return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
        } else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
            return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
            //} else if ([[event charactersIgnoringModifiers] isEqualToString:@"X"]) {
            //			return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
            //		} else if ([[event charactersIgnoringModifiers] isEqualToString:@"C"]) {
            //			return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
            //		} else if ([[event charactersIgnoringModifiers] isEqualToString:@"V"]) {
            //			return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
            //		} else if ([[event charactersIgnoringModifiers] isEqualToString:@"A"]) {
            //			return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
        }
        return [super performKeyEquivalent:event];
    }
    return [super performKeyEquivalent:event];
}

@end
