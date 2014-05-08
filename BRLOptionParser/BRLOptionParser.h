// BRLOptionParser.h
//
// Copyright (c) 2013 Stephen Celis (<stephen@stephencelis.com>)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


#import <Foundation/Foundation.h>


typedef void (^BRLOptionParserOptionBlock)();
typedef void (^BRLOptionParserOptionBlockWithArgument)(NSString *value);


static NSString *const BRLOptionParserErrorDomain = @"BRLOptionParserErrorDomain";


typedef NS_ENUM(NSUInteger, BRLOptionParserErrorCode) {
    BRLOptionParserErrorCodeUnrecognized = 1,
    BRLOptionParserErrorCodeRequired
};


@interface BRLOptionParser : NSObject @property  BOOL longOnly;

+ (instancetype) parserWithBanner:(NSString*)banner, ...;

- (void) getOpt:(char*)o flag:(unichar)f desc:(NSString*)d res:(void(^)(id res))res;

- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d block:(BRLOptionParserOptionBlock)b;
- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d blockArg:(BRLOptionParserOptionBlockWithArgument)bArg;

- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d value:(BOOL *)value;
- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d arg:(NSString *__strong *)argument;

- (void) addSeparator;
- (void) addSeparator:(NSString*)s;

- (BOOL) parseArgc:(int)c
              argv:(const char**)v
             error:(NSError**)e;

@end
