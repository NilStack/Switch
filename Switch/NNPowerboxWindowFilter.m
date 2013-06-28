//
//  NNPowerboxWindowFilter.m
//  Switch
//
//  Created by Scott Perry on 06/28/13.
//  Copyright © 2013 Scott Perry.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "NNPowerboxWindowFilter.h"

#import "NNApplication.h"
#import "NNWindow.h"
#import "NNWindow+NNWindowFiltering.h"


static NSString *kNNApplicationNamePowerbox = @"com.apple.security.pboxd";


@implementation NNPowerboxWindowFilter

- (NSString *)applicationName;
{
    return nil;
}

- (NSArray *)filterInvalidWindowsFromArray:(NSArray *)array;
{
    return [array filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, __attribute__((unused)) NSDictionary *bindings) {
        NNWindow *window = evaluatedObject;
        
        // Issue #10: Powerbox names its sheets, which are not valid (they do not respond to AXRaise)
        if ([window.application.name isEqualToString:kNNApplicationNamePowerbox]) {
            return NO;
        }
        
        return YES;
    }]];
}

@end
