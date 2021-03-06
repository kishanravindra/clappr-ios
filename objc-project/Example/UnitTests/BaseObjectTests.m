#import <Clappr/Clappr.h>

SPEC_BEGIN(BaseObject)

describe(@"BaseObject", ^{

    __block CLPBaseObject *baseObject;

    beforeEach(^{
        baseObject = [CLPBaseObject new];
    });

    describe(@"on", ^{

        __block BOOL callbackWasCalled;

        beforeEach(^{
            callbackWasCalled = NO;
        });

        it(@"callback should be called on event trigger", ^{
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beTrue];
        });

        it(@"callback should receive userInfo on trigger with params", ^{
            __block NSString *value = @"foo";
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                value = userInfo[@"new_value"];
            }];

            [baseObject trigger:@"some-event" userInfo:@{@"new_value":@"bar"}];

            [[value should] equal:@"bar"];
        });

        it(@"should not raise an exception if its callback is nil", ^{
            [baseObject on:@"some-event" callback:nil];
            [[theBlock(^{ [baseObject trigger:@"some-event"]; }) shouldNot] raise];
        });

        it(@"callback should be called for every callback registered", ^{
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            __block BOOL anotherCallbackWasCalled = NO;
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                anotherCallbackWasCalled = YES;
            }];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beTrue];
            [[theValue(anotherCallbackWasCalled) should] beTrue];
        });

        it(@"callback should not be called for another event trigger", ^{
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            [baseObject trigger:@"another-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });

        it(@"callback should not be called for another context object", ^{
            CLPBaseObject *anotherObject = [CLPBaseObject new];
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            [anotherObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });

        it(@"callback should not be called when handler is removed", ^{
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject on:@"some-event" callback:callback];
            [baseObject off:@"some-event" callback:callback];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });

    });

    describe(@"once", ^{

        it(@"callback should be called on event trigger", ^{
            __block BOOL callbackWasCalled = NO;
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject once:@"some-event" callback:callback];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beTrue];
        });

        it(@"callback should not be called twice", ^{
            __block BOOL callbackWasCalled = NO;
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject once:@"some-event" callback:callback];
            [baseObject trigger:@"some-event"];

            callbackWasCalled = NO;

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });
    });

    describe(@"listenTo", ^{

        it(@"should fire callback for an event on a given context object", ^{
            CLPBaseObject *contextObject = [CLPBaseObject new];
            __block BOOL callbackWasCalled = NO;
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject listenTo:contextObject eventName:@"some-event" callback:callback];
            [contextObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beTrue];
        });
    });

    describe(@"off", ^{

        CLPBaseObject *contextObject = [CLPBaseObject new];
        __block BOOL callbackWasCalled;

        beforeEach(^{
            callbackWasCalled = NO;
        });

        it(@"callback should not be called if removed", ^{
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject on:@"some-event" callback:callback];
            [baseObject off:@"some-event" callback:callback];
            [contextObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });

        it(@"callback should not be called if removed, but the others should", ^{
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            __block BOOL anotherCallbackWasCalled = NO;
            EventCallback anotherCallback = ^(NSDictionary *userInfo) {
                anotherCallbackWasCalled = YES;
            };

            [baseObject on:@"some-event" callback:callback];
            [baseObject on:@"some-event" callback:anotherCallback];

            [baseObject off:@"some-event" callback:callback];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
            [[theValue(anotherCallbackWasCalled) should] beTrue];
        });

        it(@"should be ok if there is no callback", ^{
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject on:@"some-event" callback:callback];
            [baseObject off:@"some-event" callback:nil];

            [baseObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beTrue];
        });
    });

    describe(@"stopListening", ^{

        it(@"should cancel all event handlers", ^{
            __block BOOL callbackWasCalled = NO;
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            __block BOOL anotherCallbackWasCalled = NO;
            [baseObject on:@"another-event" callback:^(NSDictionary *userInfo) {
                anotherCallbackWasCalled = YES;
            }];

            [baseObject stopListening];

            [baseObject trigger:@"some-event"];
            [baseObject trigger:@"another-event"];

            [[theValue(callbackWasCalled) should] beFalse];
            [[theValue(anotherCallbackWasCalled) should] beFalse];
        });

        it(@"should cancel event handlers only on context object", ^{
            __block BOOL callbackWasCalled = NO;
            [baseObject on:@"some-event" callback:^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            }];

            CLPBaseObject *anotherObject = [CLPBaseObject new];

            __block BOOL anotherCallbackWasCalled = NO;
            [anotherObject on:@"another-event" callback:^(NSDictionary *userInfo) {
                anotherCallbackWasCalled = YES;
            }];

            [baseObject stopListening];

            [baseObject trigger:@"some-event"];
            [anotherObject trigger:@"another-event"];

            [[theValue(callbackWasCalled) should] beFalse];
            [[theValue(anotherCallbackWasCalled) should] beTrue];
        });

        it(@"should cancel handler for an event on a given context object", ^{
            CLPBaseObject *contextObject = [CLPBaseObject new];

            __block BOOL callbackWasCalled = NO;
            EventCallback callback = ^(NSDictionary *userInfo) {
                callbackWasCalled = YES;
            };

            [baseObject listenTo:contextObject eventName:@"some-event" callback:callback];
            [baseObject stopListening:contextObject eventName:@"some-event" callback:callback];

            [contextObject trigger:@"some-event"];

            [[theValue(callbackWasCalled) should] beFalse];
        });
    });

});

SPEC_END
