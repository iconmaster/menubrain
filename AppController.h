//
//  AppController.h
//  MenuBrain
//
//  Created by John Marstall on 10/29/09.
//  Copyright 2009 Alamofire. All rights reserved.
//

#import <Cocoa/Cocoa.h>



@interface AppController : NSObject <NSCoding> {
	
	IBOutlet NSTableView *tableView;
	IBOutlet NSTextField *inputField;
	NSMutableArray *stringArray;
	
	IBOutlet NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSPanel *menuBrainWindow;
	
	int insertionPoint;
	BOOL firstRun;

}

- (IBAction)addString:(id)sender;
- (IBAction)removeString:(id)sender;

- (void)readSelectionFromPasteboard:(NSPasteboard *)pboard 
						   userData:(NSString *)data 
							  error:(NSString **)error;
- (void)addStringViaService:(id)contents;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;

- (void)showEditWindow;
- (void)refreshAll;
- (void)copy:(id)itemString; 

- (NSString *) pathForDataFile;
- (void) saveDataToDisk;
- (void) loadDataFromDisk; 

- (BOOL)isURL:(id)contents;
- (NSString *)truncateMenuTitle:(id)contents;
- (void)rebuildMenuAfterLoad;

@end
