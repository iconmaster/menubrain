//
//  MenuBrainAppDelegate.h
//  MenuBrain
//
//  Created by John Marstall on 10/29/09.
//  Copyright 2009 Alamofire. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if (MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_5)
@interface MenuBrainAppDelegate : NSObject {
	 NSWindow *window;
	
}
#else
@interface MenuBrainAppDelegate : NSObject <NSApplicationDelegate> {
	 NSWindow *window;
}


#endif


@property (nonatomic,retain) IBOutlet NSWindow *window;



@end
