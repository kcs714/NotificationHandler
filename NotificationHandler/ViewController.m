//
//  ViewController.m
//  NotificationHandler
//
//  Created by  kcs on 2018/12/10.
//  Copyright © 2018年 KCS. All rights reserved.
//

#import "ViewController.h"
#import "TestEventObserver_A.h"
#import "TestEventObserver_B.h"
#import "CSNotificationHandler.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    TestEventObserver_A *testA = [TestEventObserver_A new];
    TestEventObserver_B *testB = [TestEventObserver_B new];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CSNotificationHandler sendNotificationWithObject:@"666" eventType:CSNotificationEventShowTabbar];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CSNotificationHandler sendNotificationWithObject:@"888" eventType:CSNotificationEventShowNaviBar];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [testA class];
        [testB class];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CSNotificationHandler sendNotificationWithObject:@"333" eventType:CSNotificationEventShowNaviBar];
    });
}


@end
