//
//  AppController.m
//  MenuBrain
//
//  Created by John Marstall on 10/29/09.
//  Copyright 2009 Alamofire. All rights reserved.
//

#import "AppController.h"
#define GifInfoPasteBoard @"GifInfoPasteBoard"

@implementation AppController 

- (id)init
{
	[super init];
	stringArray = [[NSMutableArray alloc] init];
	statusMenu = [[NSMutableArray alloc] init];
	BOOL firstRun = YES;
	return self;
}

//the copy to pasteboard method
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
	int stringIndex = [statusMenu indexOfItem:sentMenuItem];
	NSString *contents = [stringArray objectAtIndex:stringIndex];
	NSLog(@"%@",contents);
	NSString *contentString = @"";
	NSString *annotationString = @"";
	
	//test for case 1, simple string
	if ([self isURL:contents] == NO) {
		//divide string by colon, if any are present
		NSArray *stringComponents = [contents componentsSeparatedByString:@":"];
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
		NSArray *stringComponents = [contents componentsSeparatedByString:@":"];
		if ([stringComponents count] >= 2) {
			contentString = [stringComponents objectAtIndex:1];
			
			//rejoin non-annotation content divided by colons
			if ([stringComponents count] > 2) {
				int i;
				for (i=2;i<[stringComponents count];i++) {
					contentString = [NSString stringWithFormat:@"%@:%@", contentString, [stringComponents objectAtIndex:i]];
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
		NSArray *stringComponents = [contents componentsSeparatedByString:@":"];
		if ([stringComponents count] >= 2) {
			contentString = [stringComponents objectAtIndex:1];
			
			//rejoin non-annotation content divided by colons
			if ([stringComponents count] > 2) {
				int i;
				for (i=2;i<[stringComponents count];i++) {
					contentString = [NSString stringWithFormat:@"%@:%@", contentString, [stringComponents objectAtIndex:i]];
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
		NSArray *stringComponents = [contents componentsSeparatedByString:@":"];
		if ([stringComponents count] >= 2) {
			contentString = [stringComponents objectAtIndex:1];
			
			//rejoin non-annotation content divided by colons
			if ([stringComponents count] > 2) {
				int i;
				for (i=2;i<[stringComponents count];i++) {
					contentString = [NSString stringWithFormat:@"%@:%@", contentString, [stringComponents objectAtIndex:i]];
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
	
	NSURL *URL = nil;
	
	if ([contents hasPrefix:@"http://"]) {
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


- (void)awakeFromNib
{
	insertionPoint = 0;
	[inputField setStringValue:@""];
	
	//Create the NSStatusBar and set its length
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
			
	//Sets the images in our NSStatusItem
	[statusItem setImage:[NSImage imageNamed:@"brain-menulet"]];
	[statusItem setAlternateImage:[NSImage imageNamed:@"brain-menulet_on"]];
	
	//Tells the NSStatusItem what menu to load
	[statusItem setMenu:statusMenu];
	//Sets the tooptip for our item
	[statusItem setToolTip:@"MenuBrain"];
	//Enables highlighting
	[statusItem setHighlightMode:YES];
	
	
	[tableView registerForDraggedTypes:
	 
	 [NSArray arrayWithObject:GifInfoPasteBoard] ];
	
	//Add the Edit... item
	
	NSMenuItem *editMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Edit..." 
														   action:@selector (showEditWindow)
													keyEquivalent:@""] autorelease];
	[statusMenu addItem:editMenuItem];
	editMenuItem.target = self;
	[editMenuItem setEnabled:YES];
	
	//Add the Quit MenuBrain item
	
	NSMenuItem *quitMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Quit MenuBrain" 
														   action:@selector (terminate:)
													keyEquivalent:@""] autorelease];
	[statusMenu addItem:quitMenuItem];
	quitMenuItem.target = NSApp;
	[quitMenuItem setEnabled:YES];
	
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
		[self rebuildMenuAfterLoad];
	} else {
		NSLog(@"No datafile found.");
		firstRun = YES;
		//If the user is new to MenuBrain, give her a little hint
		NSLog(@"trying to rebuild Get Started menu item.");
		NSMenuItem *getStartedMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Click on Edit... to get started" 
																	 action:@""
															  keyEquivalent:@""] autorelease];
		[statusMenu insertItem:getStartedMenuItem
					   atIndex:0];
		getStartedMenuItem.target = self;
		[getStartedMenuItem setEnabled:NO];
	}
	
	
	[self refreshAll];
								
}

- (void)showEditWindow
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
	[menuBrainWindow makeKeyAndOrderFront:self];
	[inputField selectText:self];
	[[inputField currentEditor] setSelectedRange:NSMakeRange([[inputField stringValue] length], 0)];	

}



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

	[self addMenuBrainMenuItem:newString atIndex:insertionPoint];
	
	insertionPoint++;
	
	[self refreshAll];
}

- (void)addMenuBrainMenuItem:(id)newString atIndex:(int)rowIndex {
	
	NSString *menuString = [self truncateMenuTitle:newString];
	NSMenuItem *newMenuItem = [[[NSMenuItem alloc]initWithTitle:menuString
														 action:@selector (copy:)
												  keyEquivalent:@""] autorelease];
	[statusMenu insertItem:newMenuItem
				   atIndex:rowIndex];
	newMenuItem.target = self;
	[newMenuItem setEnabled:YES];
}



- (IBAction)removeString:(id)sender {
	int row = [tableView selectedRow];
	if (row == -1) {
		NSLog(@"selection changed to row %i", row);
		return;
	} else {
		[stringArray removeObjectAtIndex:row];
		[statusMenu removeItemAtIndex:row];
		[self refreshAll];
	}
	
	insertionPoint--;
	
	
}

//After any edit, update the menu, table view, and save the data

- (void)refreshAll {
	[self saveDataToDisk];
	[tableView reloadData];
}

//Weird code that makes the table view work with NSMutableArray

- (int)numberOfRowsInTableView:(NSTableView *)tv
{
	return [stringArray count];
}

- (id)tableView:(NSTableView *)tv
objectValueForTableColumn:(NSTableColumn *)tableColumn
			row:(int)row
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
	
	[self addMenuBrainMenuItem:anObject atIndex:rowIndex];
	 
	
	[self refreshAll];
	
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	int row = [tableView selectedRow];
	if (row == -1) {
		NSLog(@"selection changed to row %i", row);
		return;
	}
}

//Drag and Drop

static int _moveRow = 0;

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard
{
	int count = [stringArray count];
	int rowCount = [rows count];
	if (count < 2) return NO;
	
	[pboard declareTypes:[NSArray arrayWithObject:GifInfoPasteBoard] owner:self];
	[pboard setPropertyList:rows forType:GifInfoPasteBoard];
	_moveRow = [[rows objectAtIndex:0]intValue];
	return YES;
}

- (unsigned int)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op
{
	if (row != _moveRow) {
		if (op==NSTableViewDropAbove) {
			return NSDragOperationEvery;
		}
		return NSDragOperationNone;
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op
{
	BOOL result = (unsigned char) [self tableView:tableView didDepositRow:_moveRow at:(int)row];
	[self refreshAll];
	return result;
}

// here we actually do the management of the data model:

- (BOOL)tableView:(NSTableView *)tv didDepositRow:(int)rowToMove at:(int)newPosition
{
    if (rowToMove != -1 && newPosition != -1) {
        id object = [stringArray objectAtIndex:rowToMove];
        if (newPosition < [stringArray count] - 1) {
            [stringArray removeObjectAtIndex:rowToMove];
            [stringArray insertObject:object atIndex:newPosition];
			[statusMenu removeItemAtIndex:rowToMove];
			
			[self addMenuBrainMenuItem:object atIndex:newPosition];
			
			
        } else {
            [stringArray removeObjectAtIndex:rowToMove];
            [stringArray addObject:object];
			[statusMenu removeItemAtIndex:rowToMove];
			
			[self addMenuBrainMenuItem:object atIndex:[stringArray count] - 1];
			
		
        }
        return YES;    // ie reload
    }
    return NO;
}

//Saving and Loading

- (NSString *) pathForDataFile 
{ 
	NSFileManager *fileManager = [NSFileManager defaultManager]; 
	NSString *folder = @"~/Library/Application Support/MenuBrain/"; 
	folder = [folder stringByExpandingTildeInPath]; 
	if ([fileManager fileExistsAtPath: folder] == NO) { 
		[fileManager createDirectoryAtPath: folder attributes: nil]; 
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
		int i;
		int rootObjectRowCount = [rootObject count];
		for (i=0; i < rootObjectRowCount; i++) {
			[stringArray insertObject:[rootObject objectAtIndex:i] atIndex:i];
		}
		//NSLog(@"first line is %@",[stringArray objectAtIndex:0]);
		int rowCount = [stringArray count];
		
		NSLog(@"number of rows to rebuild: %i", rowCount);
	}
	

}

- (void)rebuildMenuAfterLoad {
	int rowCount = [stringArray count];	
	int i;
	for (i=0; i < rowCount; i++) {
		//Add string to status menu
		
		NSString *newString = @"";
		newString = [stringArray objectAtIndex:i]; 
		
		[self addMenuBrainMenuItem:newString atIndex:insertionPoint];
		
		
		
		insertionPoint++;
		
		
	}
	[self refreshAll];
}

- (NSString *)truncateMenuTitle:(id)contents {
	
	NSArray *titleComponents = [contents componentsSeparatedByString:@":"];

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
			divider = @":",
			titleFrontEnd = [titleComponents objectAtIndex:0];
			titleBackEnd = [titleComponents objectAtIndex:1];
			if ([titleComponents count] > 2) {
				int i;
				for (i=2;i<[titleComponents count];i++) {
					titleBackEnd = [NSString stringWithFormat:@"%@:%@", titleBackEnd, [titleComponents objectAtIndex:i]];
				}
			}
		} else {
			titleBackEnd = [titleComponents objectAtIndex:0];
		}
	}

	
	
	//split the non-annotation into two segments and connect with ellipsis
		int stringLength = [titleBackEnd length];
		
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
