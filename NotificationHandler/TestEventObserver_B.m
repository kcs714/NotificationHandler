//
//  TestEventObserver_B.m
//  ViewTest
//
//  Created by wshh on 2018/8/22.
//  Copyright © 2018年 wshh. All rights reserved.
//

#import "TestEventObserver_B.h"

@interface TestEventObserver_B()

@end

@implementation TestEventObserver_B

- (instancetype)init {
    if (self = [super init]) {
        [CSNotificationHandler addEventObserver:self eventType:CSNotificationEventShowTabbar];
        [CSNotificationHandler addEventObserver:self eventType:CSNotificationEventShowNaviBar];
    }
    return self;
}

- (void)dealloc {
    NSLog(@">>>%@ 释放了", self);
}

- (void)receiveEvent:(CSNotificationEventType)eventType param:(id)param {
    NSLog(@"%zd---%@---%@", eventType, param, @"TestEventObserver_B");
}

@end
