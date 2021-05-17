//
//  AppController.m
//  MenuBrain
//
//  Created by John Marstall on 10/29/09.
//  Copyright © 2020 John Marstall. All rights reserved.
//

#import "AppController.h"

@interface AppController () <NSTableViewDelegate, NSTableViewDataSource>
@end

@implementation AppController 

- (id)init
{
    if (!(self = [super init])) return nil;
    stringArray = [[NSMutableArray alloc] init];
    statusMenu = [[NSMenu alloc] init];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ @"Separator": @":"}];
    
    return self;
}

- (NSString *)annotationSeparator {
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"Separator"];
}

- (void)awakeFromNib
{
    [inputField setStringValue:@""];
    
    //Create the NSStatusBar and set its length
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:[NSImage imageNamed:@"menubarIcon"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"menubarIconActive"]];
    
    //Tells the NSStatusItem what menu to load
    [statusItem setMenu:statusMenu];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"MenuBrain"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
    
    
    [tableView registerForDraggedTypes: [NSArray arrayWithObject:NSStringPboardType] ];
    
    //Determine if a MenuBrain file already exists
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = @"~/Library/Application Support/MenuBrain/";
    folder = [folder stringByExpandingTildeInPath];
    NSString *fileName = @"MenuBrain.menubraindata";
    NSString *filePath = [folder stringByAppendingPathComponent: fileName];
    if ([fileManager fileExistsAtPath: filePath] == YES) {
        NSLog(@"Looks like there's a datafile to load.");
        firstRun = NO;
        [self loadDataFromDisk];
    } else {
        NSLog(@"No datafile found.");
        firstRun = YES;
        //If the user is new to MenuBrain, give her a little hint
        NSLog(@"trying to rebuild Get Started menu item.");
        NSMenuItem *getStartedMenuItem = [[NSMenuItem alloc] initWithTitle:@"Click on Edit... to get started" action:NULL keyEquivalent:@""];
        
        [statusMenu insertItem:getStartedMenuItem
                       atIndex:0];
        getStartedMenuItem.target = self;
        [getStartedMenuItem setEnabled:NO];
    }
    
    
    [self rebuildMenuAfterLoad];
    
}

- (void)showEditWindow
{
    [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
    [menuBrainWindow makeKeyAndOrderFront:self];
    [inputField selectText:self];
    [[inputField currentEditor] setSelectedRange:NSMakeRange([[inputField stringValue] length], 0)];
    [tableView sizeLastColumnToFit];
    
}

// Truncating long titles for display
- (NSString *)truncateMenuTitle:(id)contents {
    NSArray *titleComponents = [contents componentsSeparatedByString:self.annotationSeparator];
    
    NSString *titleFrontEnd = @"";
    NSString *titleBackEnd = @"";
    NSString *titleBackEndOne = @"";
    NSString *titleBackEndTwo = @"";
    NSString *finalBackEnd = @"";
    NSString *divider = @"";
    
    //URLs aren't annotations
    if ([self isURL:contents] == YES) {
        titleBackEnd = contents;
    } else {
        //is this an annotation?
        if ([titleComponents count] >= 2) {
            divider = self.annotationSeparator;
            titleFrontEnd = [titleComponents objectAtIndex:0];
            titleBackEnd = [titleComponents objectAtIndex:1];
            if ([titleComponents count] > 2) {
                int i;
                for (i=2;i<[titleComponents count];i++) {
                    titleBackEnd = [NSString stringWithFormat:@"%@%@%@", titleBackEnd, self.annotationSeparator, [titleComponents objectAtIndex:i]];
                }
            }
        } else {
            titleBackEnd = [titleComponents objectAtIndex:0];
        }
    }
    
    
    
    //split the non-annotation into two segments and connect with ellipsis
    NSInteger stringLength = [titleBackEnd length];
    
    if (stringLength > 60) {
        titleBackEndOne = [titleBackEnd substringWithRange:NSMakeRange(0, 30)];
        titleBackEndTwo = [titleBackEnd substringWithRange:NSMakeRange(stringLength - 30, 30)];
        finalBackEnd = [NSString stringWithFormat:@"%@ … %@", titleBackEndOne, titleBackEndTwo];
    } else {
        finalBackEnd = titleBackEnd;
    }
    
    
    
    NSString *completeTitle = [NSString stringWithFormat:@"%@%@%@", titleFrontEnd, divider, finalBackEnd];
    
    return completeTitle;
}

// The copy to pasteboard method.
- (void)copy:(id)sender {
    
    //MenuBrain responds differently depending on the data selected. There are 6 possible cases:
    //1. ordinary string
    //2. string with annotation
    //3. URL that can be launched in a browser
    //4. other URL that cannot be launched (e.g., ftp)
    //5. other URL with annotation
    //6. web URL with annotation
    //URLs that can be launched should be. Other strings are copied to pasteboard. Annotations are ignored.
    
    //first, collect entire string that corresponds to menu selection
    NSMenuItem *sentMenuItem = (NSMenuItem *)sender;
    NSInteger stringIndex = [statusMenu indexOfItem:sentMenuItem];
    NSString *contents = [stringArray objectAtIndex:stringIndex];
    NSLog(@"%@",contents);
    NSString *contentString = @"";
    
    //test for case 1, simple string
    if ([self isURL:contents] == NO) {
        //divide string by colon, if any are present
        NSArray *stringComponents = [contents componentsSeparatedByString:self.annotationSeparator];
        if ([stringComponents count] == 1) {
            //we're done. this is a simple string.
            NSLog(@"this is a simple string");
            contentString = contents;
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pasteboard setString:contentString forType:NSStringPboardType];
            return;
        }
    }
    
    //test for case 2, string with annotation
    if ([self isURL:contents] == NO) {
        //divide string by colon, if any are present
        NSArray *stringComponents = [contents componentsSeparatedByString:self.annotationSeparator];
        if ([stringComponents count] >= 2) {
            contentString = [stringComponents objectAtIndex:1];
            
            //rejoin non-annotation content divided by colons
            if ([stringComponents count] > 2) {
                int i;
                for (i=2;i<[stringComponents count];i++) {
                    contentString = [NSString stringWithFormat:@"%@%@%@", contentString, self.annotationSeparator, [stringComponents objectAtIndex:i]];
                }
            }
            
            //check contentString for URL
            
            //shave leading space
            if ([contentString hasPrefix:@" "]) {
                contentString = [contentString substringWithRange:NSMakeRange(1, [contentString length] - 1)];
            }
            if ([self isURL:contentString] == NO) {
                NSLog(@"this is a simple string with annotation");
                NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
                [pasteboard setString:contentString forType:NSStringPboardType];
                return;
            }
        }
    }
    
    //test for case 4, non-launching URL
    if ([self isURL:contents] == YES) {
        if ([contents hasPrefix:@"ftp://"] == YES) {
            NSLog(@"this is a non-launching URL");
            NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
            [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
            [pasteboard setString:contents forType:NSStringPboardType];
            return;
        }
    }
    
    //test for case 5, non-launching URL with annotation
    if ([self isURL:contents] == YES) {
        //divide string by colon, if any are present
        NSArray *stringComponents = [contents componentsSeparatedByString:self.annotationSeparator];
        if ([stringComponents count] >= 2) {
            contentString = [stringComponents objectAtIndex:1];
            
            //rejoin non-annotation content divided by colons
            if ([stringComponents count] > 2) {
                int i;
                for (i=2;i<[stringComponents count];i++) {
                    contentString = [NSString stringWithFormat:@"%@%@%@", contentString, self.annotationSeparator, [stringComponents objectAtIndex:i]];
                }
            }
            
        }
        
        //check contentString for URL
        
        //shave leading space
        if ([contentString hasPrefix:@" "]) {
            contentString = [contentString substringWithRange:NSMakeRange(1, [contentString length] - 1)];
        }
        if ([self isURL:contentString] == YES) {
            //check for FTP address
            if ([contentString hasPrefix:@"ftp://"]) {
                NSLog(@"this is an FTP address with annotation");
                NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
                [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
                [pasteboard setString:contentString forType:NSStringPboardType];
                return;
            } else {
                [self sendURL:contentString];
                return;
            }
            
        }
    }
    
    //test for case 6, web URL with annotation
    if ([self isURL:contents] == YES) {
        //divide string by colon, if any are present
        NSArray *stringComponents = [contents componentsSeparatedByString:self.annotationSeparator];
        if ([stringComponents count] >= 2) {
            contentString = [stringComponents objectAtIndex:1];
            
            //rejoin non-annotation content divided by colons
            if ([stringComponents count] > 2) {
                int i;
                for (i=2;i<[stringComponents count];i++) {
                    contentString = [NSString stringWithFormat:@"%@%@%@", contentString, self.annotationSeparator, [stringComponents objectAtIndex:i]];
                }
            }
            
        }
        
        //check contentString for URL
        
        //shave leading space
        if ([contentString hasPrefix:@" "]) {
            contentString = [contentString substringWithRange:NSMakeRange(1, [contentString length] - 1)];
        }
        
        if ([self isURL:contentString] == YES) {
            //rule out FTP addresses
            if ([contentString hasPrefix:@"ftp://"] == NO) {
                [self sendURL:contentString];
                return;
            }
        }
    }
    
    //that leaves case 3, simple web URL
    if ([self isURL:contents] == YES) {
        //rule out FTP addresses
        if ([contents hasPrefix:@"ftp://"] == NO) {
            [self sendURL:contents];
            return;
        }
    }
}

// Handling URLs.
- (BOOL)isURL:(id)contents {
    //account for URLs containing directories
    NSArray *stringComponents = [contents componentsSeparatedByString:@"/"];
    NSString *stringToCheck = @"";
    stringToCheck = [stringComponents objectAtIndex:0];
    if ([self isURLStringCheck:stringToCheck] == YES) {
        return YES;
    }
    if ([stringComponents count] >= 2) {
        stringToCheck = [stringComponents objectAtIndex:1];
        if ([self isURLStringCheck:stringToCheck] == YES) {
            return YES;
        }
        
    }
    if ([stringComponents count] >= 3) {
        stringToCheck = [stringComponents objectAtIndex:2];
        if ([self isURLStringCheck:stringToCheck] == YES) {
            return YES;
        }
        
    }
    return NO;
    
    
}

- (void)sendURL:(id)contents {
    
    NSLog(@"sendURL received: %@", contents);
    
    if ([contents hasPrefix:@"//"]) {
        contents = [contents substringWithRange:NSMakeRange(2, [contents length] - 2)];
    }
    if ([contents hasPrefix:@"/"]) {
        contents = [contents substringWithRange:NSMakeRange(1, [contents length] - 1)];
    }
    
    if ([contents hasPrefix:@"http:///"]) {
        contents = [contents substringWithRange:NSMakeRange(8, [contents length] - 8)];
    }
    
    if ([contents hasPrefix:@"https:///"]) {
        contents = [contents substringWithRange:NSMakeRange(9, [contents length] - 9)];
    }
    
    NSURL *URL = nil;
    
    if ([contents hasPrefix:@"http://"] || [contents hasPrefix:@"https://"]) {
        NSLog(@"this is a web URL: %@", contents);
        URL = [NSURL URLWithString:contents];
    } else {
        NSString *validURL = [NSString stringWithFormat:@"http://%@",contents];
        NSLog(@"made valid URL: %@", validURL);
        URL = [NSURL URLWithString:validURL];
    }
    
    BOOL optionKeyIsDown = ([NSEvent modifierFlags] & NSAlternateKeyMask) == NSAlternateKeyMask;
    if (optionKeyIsDown)
    {
        // Copy to clipboard
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSURLPboardType, nil] owner:nil];
        [pasteboard setString:[URL absoluteString] forType:NSStringPboardType];
        [pasteboard setString:[URL absoluteString] forType:NSURLPboardType];
    }
    else {
        // Send the url
        [[NSWorkspace sharedWorkspace] openURL:URL];
    }
}

- (BOOL)isURLStringCheck:(id)contents {
    //first, test if it's an email address
    NSString *emailRegEx =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    
    NSPredicate *regExPredicate =
    [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    BOOL isEmailAddress = [regExPredicate evaluateWithObject:contents];
    
    if (isEmailAddress == YES) {
        return NO;
        //next, test for common URL prefixes and TLDs
    } else if ([contents hasPrefix:@"http://"]) {
        return YES;
    } else if ([contents hasPrefix:@"https://"]) {
        return YES;
    } else if ([contents hasPrefix:@"ftp://"]) {
        return YES;
    } else if ([contents hasPrefix:@"www."]) {
        return YES;
    } else if ([contents hasSuffix:@".com"]) {
        return YES;
    } else if ([contents hasSuffix:@".edu"]) {
        return YES;
    } else if ([contents hasSuffix:@".org"]) {
        return YES;
    } else if ([contents hasSuffix:@".net"]) {
        return YES;
    } else if ([contents hasSuffix:@".biz"]) {
        return YES;
    } else if ([contents hasSuffix:@".info"]) {
        return YES;
    } else if ([contents hasSuffix:@".name"]) {
        return YES;
    } else if ([contents hasSuffix:@".pro"]) {
        return YES;
    } else if ([contents hasSuffix:@".gov"]) {
        return YES;
    } else if ([contents hasSuffix:@".mil"]) {
        return YES;
    } else if ([contents hasSuffix:@".co.uk"]) {
        return YES;
    } else if ([contents hasSuffix:@".us"]) {
        return YES;
    } else {
        return NO;
    }
}

// addMenuBrainMenuItem is the preferred method for adding data to MenuBrain. For drag and drop, insertMenuBrainItem(atIndex:Int) is needed.
- (void)addMenuBrainMenuItem:(NSString *)newString {
    
    NSString *menuString = [self truncateMenuTitle:newString];
    NSMenuItem *newMenuItem = [[NSMenuItem alloc]initWithTitle:menuString
                                                        action:@selector (copy:)
                                                 keyEquivalent:@""];
    [statusMenu addItem:newMenuItem];
    newMenuItem.target = self;
    [newMenuItem setEnabled:YES];
}

- (void)insertMenuBrainMenuItem:(NSString *)newString atIndex:(NSInteger)rowIndex {
    
    NSString *menuString = [self truncateMenuTitle:newString];
    NSMenuItem *newMenuItem = [[NSMenuItem alloc]initWithTitle:menuString
                                                        action:@selector (copy:)
                                                 keyEquivalent:@""];
    [statusMenu insertItem:newMenuItem
                   atIndex:rowIndex];
    newMenuItem.target = self;
    [newMenuItem setEnabled:YES];
}

// addString is the method called from the Edit window when clicking [+] or hitting Return.
- (IBAction)addString:(id)sender {
    
    NSString *newString = [inputField stringValue];
    if ([newString length] == 0)
    {
        return;
    }
    
    if (firstRun == YES) {
        //need to remove Getting Started item
        NSLog(@"trying to remove Getting Started item");
        [statusMenu removeItemAtIndex:0];
        firstRun = NO;
    } else {
        NSLog(@"not showing as first run.");
    }
    
    [stringArray addObject:newString];
    NSLog(@"added %@", [stringArray lastObject]);
    [inputField setStringValue:@""];
    
    //Add string to status menu
    
    [self addMenuBrainMenuItem:newString];
    
    [self rebuildMenuAfterLoad];
}

// removeString is the method called from the Edit window when hitting Delete.
- (IBAction)removeString:(id)sender {
    NSInteger row = [tableView selectedRow];
    if (row == -1) {
        return;
    } else {
        [stringArray removeObjectAtIndex:row];
        [statusMenu removeItemAtIndex:row];
        
        [self rebuildMenuAfterLoad];
    }
    
}

// I'm not sure this is used.
- (void)removeStringAtIndex:(NSInteger)row {
    [stringArray removeObjectAtIndex:row];
    [statusMenu removeItemAtIndex:row];
    
    [self rebuildMenuAfterLoad];
}

// rebuildMenuAfterLoad is the preferred method for updating after any addition, deletion or edit. Use it liberally. It calls refreshAll and gets it all done.
- (void)rebuildMenuAfterLoad {
    [statusMenu removeAllItems];
    
    NSInteger rowCount = [stringArray count];
    NSInteger i;
    for (i=0; i < rowCount; i++) {
        //Add string to status menu
        NSString *newString = @"";
        newString = [stringArray objectAtIndex:i];
        [self addMenuBrainMenuItem:newString];
    }
    
    [statusMenu addItem:[NSMenuItem separatorItem]];
    
    //Add the Edit... item
    
    NSMenuItem *editMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit..."
                                                          action:@selector (showEditWindow)
                                                   keyEquivalent:@""];
    [statusMenu addItem:editMenuItem];
    editMenuItem.target = self;
    [editMenuItem setEnabled:YES];
    
    //Add the Quit MenuBrain item
    
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit MenuBrain"
                                                          action:@selector (terminate:)
                                                   keyEquivalent:@""];
    [statusMenu addItem:quitMenuItem];
    quitMenuItem.target = NSApp;
    [quitMenuItem setEnabled:YES];
    
    
    [self refreshAll];
}

// After any edit, update the menu, table view, and save the data
- (void)refreshAll {
    [self saveDataToDisk];
    [tableView reloadData];
    NSInteger numberOfRows = [tableView numberOfRows];
    
    if (numberOfRows > 0)
        [tableView scrollRowToVisible:numberOfRows - 1];
}

//Weird code that makes the table view work with NSMutableArray

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tv
{
    return [stringArray count];
}

- (id)tableView:(NSTableView *)tv
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)row
{
    NSString *v = [stringArray objectAtIndex:row];
    return v;
}

- (void)tableView:(NSTableView *)aTableView 
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    
    [stringArray replaceObjectAtIndex:rowIndex withObject:anObject];
    [statusMenu removeItemAtIndex:rowIndex];
    [self insertMenuBrainMenuItem:anObject atIndex:rowIndex];
    
    [self rebuildMenuAfterLoad];
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [tableView selectedRow];
    if (row == -1) {
        NSLog(@"selection changed to row %li", (long)row);
        return;
    }
}

//Drag and Drop

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    // Copy the row numbers to the pasteboard.
    NSData *zNSIndexSetData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    
    
    [pboard setData:zNSIndexSetData forType:NSStringPboardType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id )info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
    if (op == NSTableViewDropAbove) {
        return NSDragOperationEvery;
    }
    return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id )info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    // array safety -- target row index cannot exceed largest index or fall below zero
    if (row < 0) {
        row = 0;
    } else if (row > stringArray.count) {
        row = stringArray.count;
    }
    
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:NSStringPboardType];
    // we need to re-locate where in stringArray this string was
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];
    // dragRow is the former index of the dragged string
    NSString* draggedString = [stringArray objectAtIndex:dragRow];
    if (dragRow < row) { //that is, if we're dragging a row downward
        [stringArray removeObjectAtIndex:dragRow];
        [stringArray insertObject:draggedString atIndex:MAX(0, row-1)];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:MAX(0, row-1)] byExtendingSelection:NO];
    } else { // dragging a row upward
        [stringArray removeObjectAtIndex:dragRow];
        [stringArray insertObject:draggedString atIndex:row];
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    
    
    [self rebuildMenuAfterLoad];
    
    return YES;
}

//End Drag and Drop

//Saving and Loading

- (NSString *) pathForDataFile 
{ 
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folder = @"~/Library/Application Support/MenuBrain/";
    folder = [folder stringByExpandingTildeInPath];
    if ([fileManager fileExistsAtPath: folder] == NO) {
        [fileManager createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:@{} error:nil];
    }
    NSString *fileName = @"MenuBrain.menubraindata";
    return [folder stringByAppendingPathComponent: fileName];
} 

- (void) encodeWithCoder: (NSCoder *)coder 
{ 
    [coder encodeObject:stringArray forKey:@"menubraindata"];
}


- (id) initWithCoder: (NSCoder *)coder 
{ 
    if (self = [super init]) {
        stringArray = [[NSMutableArray alloc] init];
        //stringArray = [coder decodeObjectForKey:@"menubraindata"];
    }
    return self;
} 

- (void)saveDataToDisk { 
    NSString * path = [self pathForDataFile];
    //NSMutableDictionary * rootObject;
    //rootObject = [NSMutableDictionary dictionary];
    //[rootObject setValue: stringArray forKey:@"menubraindata"];
    [NSKeyedArchiver archiveRootObject: stringArray toFile: path];
} 

- (void)loadDataFromDisk {
    if (firstRun == NO) {
        NSString *path = [self pathForDataFile];
        NSMutableArray *rootObject;
        rootObject = [[NSMutableArray alloc] init];
        rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        stringArray = [[NSMutableArray alloc] init];
        //stringArray = [[stringArray arrayByAddingObjectsFromArray:rootObject]retain];
        NSInteger i;
        NSInteger rootObjectRowCount = [rootObject count];
        for (i=0; i < rootObjectRowCount; i++) {
            [stringArray insertObject:[rootObject objectAtIndex:i] atIndex:i];
        }
        //NSLog(@"first line is %@",[stringArray objectAtIndex:0]);
        NSInteger rowCount = [stringArray count];
        
        NSLog(@"number of rows to rebuild: %li", (long)rowCount);
    }
}

//integrate with Services
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // To get service requests to go to the controller...
    [NSApp setServicesProvider:self];
}

- (void)readSelectionFromPasteboard:(NSPasteboard *)pboard 
userData:(NSString *)data error:(NSString **)error {
    NSArray *types = [pboard types];
    NSString *selectionString = @"";
    
    if ([types containsObject:NSStringPboardType]){
        selectionString = [pboard stringForType:NSStringPboardType];
        NSLog(@"%@",selectionString);
        [self addStringViaService:selectionString];
        return;
    } else {
        return;
    }
}

- (void)addStringViaService:(id)contents {
    [self showEditWindow];
    [inputField setStringValue:contents];
}

@end
