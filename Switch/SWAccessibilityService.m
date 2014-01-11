//
//  SWAccessibilityService.m
//  Switch
//
//  Created by Scott Perry on 10/20/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "SWAccessibilityService.h"

#import <NNKit/NNService+Protected.h>
#import <Haxcessibility/Haxcessibility.h>
#import <Haxcessibility/HAXElement+Protected.h>

#import "NNAPIEnabledWorker.h"
#import "SWApplication.h"
#import "SWWindow.h"


@interface SWAccessibilityService ()

@property (nonatomic, copy) NSSet *windows;
@property (nonatomic, strong) NNAPIEnabledWorker *worker;
@property (nonatomic, strong, readonly) dispatch_queue_t haxQueue;

@end


@implementation SWAccessibilityService

- (instancetype)init;
{
    if (!(self = [super init])) { return nil; }
    
    _haxQueue = dispatch_queue_create("foo", DISPATCH_QUEUE_SERIAL);
    
    return self;
}

- (NNServiceType)serviceType;
{
    return NNServiceTypePersistent;
}

- (void)startService;
{
    [super startService];
    
    [self checkAPI];
}

- (void)accessibilityAPIAvailabilityChangedNotification:(NSNotification *)notification;
{
    BOOL accessibilityEnabled = [notification.userInfo[NNAXAPIEnabledKey] boolValue];
    
    SWLog(@"Accessibility API is %@abled", accessibilityEnabled ? @"en" : @"dis");
    
    if (accessibilityEnabled) {
        self.worker = nil;
    }
}

- (void)setWorker:(NNAPIEnabledWorker *)worker;
{
    if (worker == _worker) {
        return;
    }
    if (_worker) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NNAPIEnabledWorker.notificationName object:_worker];
    }
    if (worker) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accessibilityAPIAvailabilityChangedNotification:) name:NNAPIEnabledWorker.notificationName object:self.worker];
    }
    _worker = worker;
}

- (void)checkAPI;
{
    if (![NNAPIEnabledWorker isAPIEnabled]) {
        self.worker = [NNAPIEnabledWorker new];
        
        AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)@{ (__bridge NSString *)kAXTrustedCheckOptionPrompt : @YES });
    }
}

- (void)raiseWindow:(SWWindow *)window completion:(void (^)(NSError *))completionBlock;
{
    dispatch_async(self.haxQueue, ^{
        // If sending events to Switch itself, we have to use the main thread!
        if ([window.application isCurrentApplication]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _raiseWindow:window completion:completionBlock];
            });
        } else {
            [self _raiseWindow:window completion:completionBlock];
        }
    });
}

- (void)closeWindow:(SWWindow *)window completion:(void (^)(NSError *))completionBlock;
{
    dispatch_async(self.haxQueue, ^{
        // If sending events to Switch itself, we have to use the main thread!
        if ([window.application isCurrentApplication]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self _closeWindow:window completion:completionBlock];
            });
        } else {
            [self _closeWindow:window completion:completionBlock];
        }
    });
}

#pragma mark - Private

- (void)_raiseWindow:(SWWindow *)window completion:(void (^)(NSError *))completionBlock;
{
    if (!completionBlock) {
        completionBlock = ^(NSError *error){};
    }
    
    if (!window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(nil);
        });
        return;
    }

    HAXWindow *haxWindow = [self _haxWindowForWindow:window];
    Check(haxWindow);
    
    NSDate *start = [NSDate date];
    
    // First, raise the window
    NSError *error = nil;
    if (![haxWindow performAction:(__bridge NSString *)kAXRaiseAction error:&error]) {
        SWLog(@"Raising %@ window %@ failed after %.3fs: %@", window.application.name, window, [[NSDate date] timeIntervalSinceDate:start], error);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(error);
        });
        return;
    }
    
    // Then raise the application (if it's not already topmost)
    if (![window.application isFrontMostApplication]) {
        NSRunningApplication *runningApplication = [NSRunningApplication runningApplicationWithProcessIdentifier:window.application.pid];
        if (![runningApplication activateWithOptions:NSApplicationActivateIgnoringOtherApps]) {
            SWLog(@"Raising application %@ failed.", window.application);
#pragma message "Need a real NSError in here"
            error = [NSError new];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(error);
            });
            return;
        }
    }
    
    SWLog(@"Raising %@ window %@ took %.3fs", window.application.name, window, [[NSDate date] timeIntervalSinceDate:start]);
    dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(nil);
        [haxWindow self];
    });
}

- (void)_closeWindow:(SWWindow *)window completion:(void (^)(NSError *))completionBlock;
{
    if (!completionBlock) {
        completionBlock = ^(NSError *error){};
    }
    
    if (!window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(nil);
        });
        return;
    }

    HAXWindow *haxWindow = [self _haxWindowForWindow:window];
    Check(haxWindow);
    
    NSDate *start = [NSDate date];
    
    NSError *error = nil;
    
    HAXElement *element = [haxWindow elementOfClass:[HAXElement class] forKey:(__bridge NSString *)kAXCloseButtonAttribute error:&error];
    if (!element) {
        SWLog(@"Couldn't get close button for %@ window %@ after %.3fs: %@", window.application.name, window, [[NSDate date] timeIntervalSinceDate:start], error);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(error);
        });
        return;
    }
    
    if (![element performAction:(__bridge NSString *)kAXPressAction error:&error]) {
        SWLog(@"Closing %@ window %@ failed after %.3fs: %@", window.application.name, window, [[NSDate date] timeIntervalSinceDate:start], error);
        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(error);
        });
        return;
    }
    
    SWLog(@"Closing %@ window %@ took %.3fs", window.application.name, self, [[NSDate date] timeIntervalSinceDate:start]);
    dispatch_async(dispatch_get_main_queue(), ^{
        completionBlock(nil);
    });
}

- (HAXWindow *)_haxWindowForWindow:(SWWindow *)window;
{
    HAXWindow *result = nil;
    
    if ([window.application.name isEqualToString:@"Safari"]) {
        Check(window.application.pid == 708);
    }
    
    HAXApplication *haxApplication = [HAXApplication applicationWithPID:window.application.pid];
    BailUnless(haxApplication, result);
    
    NSArray *haxWindows = [haxApplication windows];
    for (HAXWindow *haxWindow in haxWindows) {
        NSString *haxTitle = haxWindow.title;
        BOOL framesMatch = NNNSRectsEqual(window.frame, haxWindow.frame);
        BOOL namesMatch = (window.name.length == 0 && haxTitle.length == 0) || [window.name isEqualToString:haxTitle];
        
        if (framesMatch && namesMatch) {
            Check(!window.name == !haxTitle);
            result = haxWindow;
        }
    }
    
    Check(result);
    return result;
}

@end