/* Copyright (c) 2007, Thomas Fors
 * All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import <UIKit/UIWindow.h>

#import "CalculatorApp.h"
#import "hpcalc.h"

/*
 * Main entry point of application 
 */
int main(int argc, char **argv) {
	int rc = 0;
	bool init = NO;
	bool reset = NO;
	bool gui = NO;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int i;
	for (i=1; i<argc; i++) {
		if (strncasecmp("--init", argv[i], 6) == 0) {
			init = YES;
		} else if (strncasecmp("--reset", argv[i], 7) == 0) {
			reset = YES;
		} else if (strncasecmp("--launchedfromsb", argv[i], 16) == 0) {
			gui = YES;
		}
	}

	if (init) {
		/* Set springboard to hide status bar on launch */
		NSString *path = [NSString stringWithString:@"/System/Library/CoreServices/SpringBoard.app/DefaultApplicationState.plist"];
		NSMutableDictionary *sb = [NSMutableDictionary dictionaryWithContentsOfFile:path];
		NSMutableDictionary *me = [sb objectForKey:[NSString stringWithFormat:@"net.fors.iphone.hp%s", MODEL]];
		if (me == nil) {
			me = [[NSMutableDictionary alloc] init];
			[me setObject:[NSNumber numberWithInt:2] forKey:@"SBDefaultStatusBarModeKey"];
	   		[sb setObject:me forKey:[NSString stringWithFormat:@"net.fors.iphone.hp%s", MODEL]];
			[sb writeToFile:path atomically:YES];
		}     
	} else if (reset) {
		/* Delete persistent memory */
		NSString *path = [NSString stringWithFormat:@"/var/root/Library/net.fors.iphone.hpcalc"];
		NSString *name = [NSString stringWithFormat:@"%@/%s.state", path, MODEL];
     	[[NSFileManager defaultManager] removeFileAtPath:name handler:nil];
     	if ([[[NSFileManager defaultManager] directoryContentsAtPath:path] count] == 0) {
     		[[NSFileManager defaultManager] removeFileAtPath:path handler:nil];
		}
	} else if (gui) {
		rc = UIApplicationMain(argc, argv, [CalculatorApp class]);
	} else {
		HPCalc *calc = [[HPCalc alloc] init];

		while ( ! [calc keyBufferIsEmpty]) {
			// wait for keystroke buffer to empty
			[NSThread sleepForTimeInterval:0.1];
		}

		// Turn on if the calculator was off
		if ([[calc getDisplayString] isEqualToString:@"               "]) {
			[calc playMacro:[NSArray arrayWithObjects:K_ON, nil]];
		}
		while ([[calc getDisplayString] isEqualToString:@"               "]) {
			[NSThread sleepForTimeInterval:0.1];
		}

		int i;
		for (i=1; i<argc; i++) {
			if (strncasecmp("--", argv[i], 2) != 0) {
				// if it's not a command line switch
				[calc computeFromCString:argv[i]];
			}
			
		}
		printf("%s\n", [[calc getDisplayString] cStringUsingEncoding:NSASCIIStringEncoding]);
		
		[calc shutdown];
	}
	
	[pool release];
	return rc;
}