#import <Kiwi/Kiwi.h>
#import "BRLOptionParser.h"


SPEC_BEGIN(BRLOptionParserSpec)

describe(@"BRLOptionParser", ^{
    __block BRLOptionParser *os;
    __block NSError *error;

    beforeEach(^{
        optind = 1;
        os = [BRLOptionParser new];
        error = nil;
    });

    context(@"parsing", ^{
        context(@"os without arguments", ^{
            __block BOOL flag;
            __block char * argument;

            beforeEach(^{
                flag = NO;
                argument = "-h";
            });

            it(@"calls blocks", ^{
                [os addOpt:NULL flag:'h' desc:nil block:^{
                    flag = YES;
                }];
            });

            it(@"casts boolean values", ^{
                [os addOpt:NULL flag:'h' desc:nil value:&flag];
            });

            context(@"long options", ^{
                beforeEach(^{
                    argument = "--help";
                });

                it(@"calls blocks", ^{
                    [os addOpt:"help" flag:0 desc:nil block:^{
                        flag = YES;
                    }];
                });

                it(@"casts boolean values", ^{
                    [os addOpt:"help" flag:0 desc:nil value:&flag];
                });

                context(@"with short aliases", ^{
                    it(@"calls blocks", ^{
                        [os addOpt:"help" flag:'h' desc:nil block:^{
                            flag = YES;
                        }];
                    });

                    it(@"casts boolean values", ^{
                        [os addOpt:"help" flag:'h' desc:nil value:&flag];
                    });

                    afterEach(^{
                        int argc = 2;
                        const char * argv[] = {"app", "-h", 0};
                        [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
                        [[error should] beNil];
                    });
                });
            });

            afterEach(^{
                int argc = 2;
                const char * argv[] = {"app", argument, 0};
                [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
                [[error should] beNil];
                [[@(flag) should] beYes];
            });
        });

        context(@"os with arguments", ^{
            __block NSString *string;
            __block char * argument;

            beforeEach(^{
                string = nil;
                argument = "-H";
            });

            context(@"that are set", ^{
                it(@"calls blocks with arguments", ^{
                    [os addOpt:NULL flag:'H' desc:nil blockArg:^(NSString *value) {
                        string = value;
                    }];
                });

                it(@"casts string arguments", ^{
                    [os addOpt:NULL flag:'H' desc:nil arg:&string];
                });

                context(@"long options", ^{
                    beforeEach(^{
                        argument = "--hello";
                    });

                    it(@"calls blocks with arguments", ^{
                        [os addOpt:"hello" flag:0 desc:nil blockArg:^(NSString *value) {
                            string = value;
                        }];
                    });

                    it(@"casts string arguments", ^{
                        [os addOpt:"hello" flag:0 desc:nil arg:&string];
                    });

                    context(@"with short aliases", ^{
                        it(@"calls blocks with arguments", ^{
                            [os addOpt:"hello" flag:'H' desc:nil blockArg:^(NSString *value) {
                                string = value;
                            }];
                        });

                        it(@"casts string arguments", ^{
                            [os addOpt:"hello" flag:'H' desc:nil arg:&string];
                        });

                        afterEach(^{
                            int argc = 3;
                            const char * argv[] = {"app", "-H", "world", 0};
                            [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
                            [[error should] beNil];
                        });
                    });
                });

                afterEach(^{
                    int argc = 3;
                    const char * argv[] = {"app", argument, "world", 0};
                    [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
                    [[error should] beNil];
                    [[string should] equal:@"world"];
                });
            });

            context(@"that are missing", ^{
                __block BOOL flag = NO;

                beforeEach(^{
                    [os addOpt:"hello" flag:'H' desc:nil arg:&string];
                    [os addOpt:"verbose" flag:'v' desc:nil value:&flag];
                });

                it(@"fails with a short option", ^{
                    int argc = 2;
                    const char * argv[] = {"app", "-vH", 0};
                    [[@([os parseArgc:argc argv:argv error:&error]) should] beNo];
                    [[error shouldNot] beNil];
                    [[@([error code]) should] equal:@(BRLOptionParserErrorCodeRequired)];
                    [[[error localizedDescription] should] equal:@"option `-H' requires an argument"];
                });

                it(@"fails with a long option", ^{
                    int argc = 3;
                    const char * argv[] = {"app", "--verbose", "--hello", 0};
                    [[@([os parseArgc:argc argv:argv error:&error]) should] beNo];
                    [[error shouldNot] beNil];
                    [[@([error code]) should] equal:@(BRLOptionParserErrorCodeRequired)];
                    [[[error localizedDescription] should] equal:@"option `--hello' requires an argument"];
                });
            });
        });

        context(@"unrecognized arguments", ^{
            it(@"fails with a short option", ^{
                BOOL flag = NO;
                [os addOpt:NULL flag:'h' desc:nil value:&flag];
                int argc = 2;
                const char * argv[] = {"app", "-hi", 0};
                [[@([os parseArgc:argc argv:argv error:&error]) should] beNo];
                [[error shouldNot] beNil];
                [[@([error code]) should] equal:@(BRLOptionParserErrorCodeUnrecognized)];
                [[[error localizedDescription] should] equal:@"unrecognized option `-i'"];
            });

            it(@"fails with a long option", ^{
                int argc = 2;
                const char * argv[] = {"app", "--hello=world", 0};
                [[@([os parseArgc:argc argv:argv error:&error]) should] beNo];
                [[error shouldNot] beNil];
                [[@([error code]) should] equal:@(BRLOptionParserErrorCodeUnrecognized)];
                [[[error localizedDescription] should] equal:@"unrecognized option `--hello'"];
            });
        });

        context(@"long-only", ^{
            beforeEach(^{
                os.longOnly = YES;
            });

            it(@"works", ^{
                BOOL flag = NO;
                [os addOpt:"help" flag:0 desc:nil value:&flag];
                int argc = 2;
                const char * argv[] = {"app", "-help", 0};
                [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
                [[error should] beNil];
                [[@(flag) should] beYes];
            });

            context(@"with arguments", ^{
                it(@"fails with a proper error", ^{
                    NSString *string = nil;
                    [os addOpt:"hello" flag:0 desc:nil arg:&string];
                    int argc = 2;
                    const char * argv[] = {"app", "-hello", 0};
                    [[@([os parseArgc:argc argv:argv error:&error]) should] beNo];
                    [[error shouldNot] beNil];
                    [[@([error code]) should] equal:@(BRLOptionParserErrorCodeRequired)];
                    [[[error localizedDescription] should] equal:@"option `-hello' requires an argument"];
                });
            });
        });

        it(@"works with a separator", ^{
            [os addSeparator];
            int argc = 1;
            const char * argv[] = {"app", 0};
            [[@([os parseArgc:argc argv:argv error:&error]) should] beYes];
            [[error should] beNil];
        });
    });

    context(@"usage", ^{
        context(@"banner", ^{
            it(@"prints by default", ^{
                NSString *usage =
                @"usage: xctest [options]\n";

                [[NSProcessInfo processInfo] stub:@selector(processName) andReturn:@"xctest"];
                [[[os description] should] equal:usage];
            });

            it(@"prints custom overrides", ^{
                NSString *usage = @"usage: expected [OPTIONS]\n";

                [os setValue:@"usage: expected [OPTIONS]" forKey:@"banner"];

                [[os.description should] equal:usage];
            });
        });

        context(@"help", ^{
            beforeEach(^{
                [os setValue:@"usage: app [options]" forKey:@"banner"];
                [os addOpt:"a-really-long-option-that-overflows" flag:0 desc:@"Is described over here" value:NULL];
                [os addOpt:NULL flag:'0' desc:nil value:NULL];
                [os addSeparator];
                [os addSeparator:@"Other options:"];
                [os addOpt:"version" flag:0 desc:@"Show version" value:NULL];
                [os addOpt:"help" flag:'h' desc:@"Show this screen" value:NULL];
            });

            it(@"prints and formats options", ^{
                NSString *usage =
                @"usage: app [options]\n"
                @"        --a-really-long-option-that-overflows\n"
                @"                                     Is described over here\n"
                @"    -0\n"
                @"\n"
                @"Other options:\n"
                @"        --version                    Show version\n"
                @"    -h, --help                       Show this screen\n";

                [[[os description] should] equal:usage];
            });

            context(@"long-only", ^{
                beforeEach(^{
                    os.longOnly = YES;
                });

                it(@"prints and formats long os with a single hyphen", ^{
                    NSString *usage =
                    @"usage: app [options]\n"
                    @"        -a-really-long-option-that-overflows\n"
                    @"                                     Is described over here\n"
                    @"    -0\n"
                    @"\n"
                    @"Other options:\n"
                    @"        -version                    Show version\n"
                    @"    -h, -help                       Show this screen\n";

                    [[[os description] should] equal:usage];
                });
            });
        });
    });
});

SPEC_END
