//
//  SWTweetbotTests.m
//  Switch
//
//  Created by Scott Perry on 10/11/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWWindowListServiceTestSuperclass.h"


@interface SWTweetbotTests : SWWindowListServiceTestSuperclass

@end


@implementation SWTweetbotTests

- (NSDictionary *)mainWindowInfoDict;
{
    return @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 636,
            .size.width = 480,
            .origin.x = 293,
            .origin.y = 74
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1710196,
        NNWindowName : @"Main Window",
        NNWindowNumber : @85208,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @9258,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
}

- (NSArray *)mainWindowsInfoList;
{
    return @[
        @{
            NNWindowAlpha : @1,
            NNWindowBounds : DICT_FROM_RECT(((CGRect){
                .size.height = 30,
                .size.width = 412,
                .origin.x = 360,
                .origin.y = 110
            })),
            NNWindowIsOnscreen : @1,
            NNWindowLayer : @0,
            NNWindowMemoryUsage : @62748,
            NNWindowName : @"",
            NNWindowNumber : @114910,
            NNWindowOwnerName : @"Tweetbot",
            NNWindowOwnerPID : @9258,
            NNWindowSharingState : @1,
            NNWindowStoreType : @2,
        },
        [self mainWindowInfoDict]
    ];
}

- (NSDictionary *)imageWindowInfoDict;
{
    return @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 379,
            .size.width = 1002,
            .origin.x = 124,
            .origin.y = 300
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @2541364,
        NNWindowName : @"",
        NNWindowNumber : @117515,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @9258,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
}

// https://github.com/numist/Switch/issues/2
- (void)testFilterUnreadBanner;
{
    NSDictionary *windowDescription = self.mainWindowInfoDict;
    NSArray *infoList = self.mainWindowsInfoList;

    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 1, @"");
    XCTAssertEqual(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).windows.count, infoList.count, @"");
    XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, windowDescription, @"");
}

// https://github.com/numist/Switch/issues/2
- (void)testFilterWithImageWindow;
{
    NSMutableArray *infoList = [self.mainWindowsInfoList mutableCopy];
    [infoList addObject:self.imageWindowInfoDict];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 2, @"");
    if (self.listService.windows.count == 2) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, self.mainWindowInfoDict, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, self.imageWindowInfoDict, @"");
    }

    [infoList removeObjectAtIndex:(infoList.count - 1)];
    [infoList insertObject:self.imageWindowInfoDict atIndex:0];
    
    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 2, @"");
    if (self.listService.windows.count == 2) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, self.imageWindowInfoDict, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, self.mainWindowInfoDict, @"");
    }
}

// No ticket, verify that the frame of an image window doesn't cause it to be coalesced into the main window (image windows are unnamed and could be positioned within the frame of the main window)
- (void)testImageInsideAndAboveMainWindow;
{
    NSDictionary *imageWindowInfo = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 244,
            .size.width = 464,
            .origin.x = 880,
            .origin.y = 287
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @664916,
        NNWindowName : @"",
        NNWindowNumber : @54150,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @90385,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSDictionary *mainWindowInfo = @{
        NNWindowAlpha : @1,
        NNWindowBounds : DICT_FROM_RECT(((CGRect){
            .size.height = 636,
            .size.width = 480,
            .origin.x = 872,
            .origin.y = 73
        })),
        NNWindowIsOnscreen : @1,
        NNWindowLayer : @0,
        NNWindowMemoryUsage : @1226068,
        NNWindowName : @"Main Window",
        NNWindowNumber : @52387,
        NNWindowOwnerName : @"Tweetbot",
        NNWindowOwnerPID : @90385,
        NNWindowSharingState : @1,
        NNWindowStoreType : @2,
    };
    NSArray *infoList = @[imageWindowInfo, mainWindowInfo];

    [self updateListServiceWithInfoList:infoList];
    
    XCTAssertEqual(self.listService.windows.count, 2, @"");
    if (self.listService.windows.count == 2) {
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:0]).mainWindow.windowDescription, imageWindowInfo, @"");
        XCTAssertEqualObjects(((SWWindowGroup *)[self.listService.windows objectAtIndex:1]).mainWindow.windowDescription, mainWindowInfo, @"");
    }
}

@end
