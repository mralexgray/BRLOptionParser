// BRLOptionParser.m
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


#import "BRLOptionParser.h"
#import <getopt.h>

typedef NS_ENUM(NSUInteger, BRLOptionArgument) { BRLOptionArgumentNone = no_argument, BRLOptionArgumentRequired = required_argument };

@interface         BRLOption : NSObject
@property            unichar   flag;
@property               char * name;
@property           NSString * description;
@property  BRLOptionArgument   argument;
@property (copy)          id   block;
@end


@implementation BRLOption

+ (instancetype) opt:(char*)n flag:(unichar)f desc:(NSString*)d block:(BRLOptionParserOptionBlock)b {
  return [self.alloc initWithName:n flag:f desc:d arg:BRLOptionArgumentNone block:b];
}
+ (instancetype) opt:(char*)n flag:(unichar)f desc:(NSString*)d blockArg:(BRLOptionParserOptionBlockWithArgument)bArg {
  return [self.alloc initWithName:n flag:f desc:d arg:BRLOptionArgumentRequired block:bArg];
}
- (instancetype) initWithName:(char*)n flag:(unichar)f desc:(NSString*)d arg:(BRLOptionArgument)argument block:(id)b {
  return self = super.init ? _argument = argument, _name = n, _flag = f, _block = b, self.description = d, self : nil;
}
@end

@implementation BRLOptionParser { NSMutableArray *opts; NSString * _banner; }

- (void) getOpt:(char*)o flag:(unichar)f desc:(NSString*)d res:(void(^)(id res))resP { }

+ (instancetype) parserWithBanner:(NSString*)b, ... {  id new = self.parser; [new setBanner:b]; return new; }
+ (instancetype) parser         {  return [self new]; }
+ (instancetype) longOnlyParser { return ({ id x = [self parser]; if (x)  [x setLongOnly:YES]; x; }); }
-   (id) init { return self = super.init ?

  [self setBanner:@"usage: %@ [options]", NSProcessInfo.processInfo.processName], opts = @[].mutableCopy, self : nil;
}
- (void) setBanner:(NSString *)b, ... { va_list x; va_start(x, b); _banner = [NSString.alloc initWithFormat:b arguments:x]; va_end(x); }
- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d block:(BRLOptionParserOptionBlock)b {
  [opts addObject:[BRLOption opt:o flag:f desc:d block:b]];
}
- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d blockArg:(BRLOptionParserOptionBlockWithArgument)bWithA {
  [opts addObject:[BRLOption opt:o flag:f desc:d blockArg:bWithA]];
}
- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d value:(BOOL *)value {
  [self addOpt:o flag:f desc:d block:^{  *value = YES; }];
}

- (void) addOpt:(char*)o flag:(unichar)f desc:(NSString*)d arg:(NSString *__strong *)arg {
  [self addOpt:o flag:f desc:d blockArg:^(NSString *value) { *arg = value; }];
}

- (void) addSeparator { [self addSeparator:nil]; }
- (void) addSeparator:(NSString *)s { [opts addObject:!s ? @" " : s]; }
- (BOOL) parseArgc:(int)argc argv:(const char **)argv error:(NSError *__autoreleasing *)error {
  NSMapTable *mapTable = NSCreateMapTable(NSIntegerMapKeyCallBacks, NSNonRetainedObjectMapValueCallBacks, [opts count]);

  NSUInteger i = 0;
  NSUInteger c = 0;

  struct option * long_options = malloc(([opts count] + 1) * sizeof(struct option));
  char * short_options = malloc((([opts count] * 2) + 1) * sizeof(char));

  for (BRLOption *option in opts) { if (![option isKindOfClass:BRLOption.class])  continue;

    if (option.name) {
      NSMapInsert(mapTable, (const void *)option.name, (__bridge void *)option);
      long_options[i++] = (struct option){option.name, option.argument, NULL, option.flag};
    }
    if (option.flag) {
      NSMapInsert(mapTable, (const void *)(NSUInteger)option.flag, (__bridge void *)option);
      short_options[c++] = option.flag;
      if (option.argument == BRLOptionArgumentRequired) {
        short_options[c++] = ':';
      };
    }
  }
  long_options[i] = (struct option){0, 0, 0, 0};
  short_options[c] = '\0';

  int ch = 0;
  int long_options_index = 0;

  opterr = 0;

  int (* getopt_long_method)(int, char * const *, const char *, const struct option *, int *);
  getopt_long_method = self.longOnly ? &getopt_long_only : &getopt_long;

  int cached_optind = optind;
  while ((ch = getopt_long_method(argc, (char **)argv, short_options, long_options, &long_options_index)) != -1) {
    @try {
      BRLOption *option = nil;

      switch (ch) {
        case '?': {
          if (error) {
            // I wish this could be done more cleanly, but getopt doesn't appear to expose the current failing option as originally input.
            NSString *arg = @(argv[cached_optind]);
            if ([arg hasPrefix:[self longPrefix]]) {
              arg = [[arg componentsSeparatedByString:@"="] firstObject];
            } else if (optopt) {
              arg = [NSString stringWithFormat:@"-%c", optopt];
            }

            if (optopt) {
              option = (__bridge BRLOption *)NSMapGet(mapTable, (const void *)(NSUInteger)optopt);
            } else {
              NSString *longOption = [NSString stringWithFormat:@"%@%s", [self longPrefix], long_options[long_options_index].name];
              if ([arg isEqualToString:longOption]) {
                option = (__bridge BRLOption *)NSMapGet(mapTable, (const void *)long_options[long_options_index].name);
              }
            }

            if (option && option.argument == BRLOptionArgumentRequired) {
              *error = [NSError errorWithDomain:BRLOptionParserErrorDomain code:BRLOptionParserErrorCodeRequired userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"option `%@' requires an argument", arg]}];
            } else {
              *error = [NSError errorWithDomain:BRLOptionParserErrorDomain code:BRLOptionParserErrorCodeUnrecognized userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"unrecognized option `%@'", arg]}];
            }
          }
          return NO;
          break;
        }
        case ':':

          break;
        case 0:
          option = (__bridge BRLOption *)NSMapGet(mapTable, (const void *)long_options[long_options_index].name);
          break;
        default: {
          option = (__bridge BRLOption *)NSMapGet(mapTable, (const void *)(NSUInteger)ch);
          break;
        }
      }

      if (option.argument == BRLOptionArgumentRequired) {
        BRLOptionParserOptionBlockWithArgument block = option.block;
        block(@(optarg));
      } else {
        BRLOptionParserOptionBlock block = option.block;
        block();
      }
    } @finally {
      cached_optind = optind;
    }
  }

  return YES;
}

- (NSString*) description {
  NSMutableString *(^trimLine)(NSMutableString *) = ^NSMutableString *(NSMutableString *line) {
    NSRange range = [line rangeOfCharacterFromSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet] options:NSBackwardsSearch];
    if (range.location != NSNotFound) {
      line = [[line substringToIndex:range.location + 1] mutableCopy];
    }
    return line;
  };

  NSMutableArray *description = [NSMutableArray arrayWithObject:_banner];
  for (id each in opts) {
    NSMutableString *line = [NSMutableString string];
    if ([each isKindOfClass:[BRLOption class]]) {
      BRLOption *option = each;
      [line appendString:@"    "];
      if (option.flag) {
        [line appendFormat:@"-%c", option.flag];
        [line appendString:option.name ? @", " : @"  "];
      } else {
        [line appendString:@"    "];
      }
      if (option.name) {
        [line appendFormat:@"%@%-24s   ", [self longPrefix], option.name];
      } else {
        [line appendString:@"                             "];
      }
      if ([line length] > 37) {
        line = trimLine(line);
        [line appendString:@"\n                                     "];
      }
      if (option.description) {
        [line appendString:option.description];
      }
      line = trimLine(line);
    } else {
      [line appendFormat:@"%@", each];
    }
    [description addObject:line];
  }
  return [[description componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];
}
- (NSString*) longPrefix {  return _longOnly ? @"-" : @"--"; }

@end
