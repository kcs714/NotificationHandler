//
//  CSNotificationHandler.h
//  ViewTest
//
//  Created by wshh on 2018/10/11.
//  Copyright © 2018年 wshh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 事件类型枚举
 添加事件枚举时，必须添加，不能插入
 */
typedef NS_ENUM(NSInteger, CSNotificationEventType) {
    CSNotificationEventNone,
    CSNotificationEventShowTabbar,
    CSNotificationEventShowNaviBar,
    CSNotificationEventMax //这是边界值，在该值上面添加事件枚举值
};


/**
 监听事件协议
 */
@protocol CSNotificationEventProtocol<NSObject>

/**
 接受事件
 @param eventType 事件类型
 @param param 回传的参数
 */
- (void)receiveEvent:(CSNotificationEventType)eventType param:(id)param;

@end


/**
 事件分发操作(一对多)
 */
@interface CSNotificationHandler : NSObject

/**
 添加事件监听者
 @param target 事件监听者
 @param eventType 事件类型
 */
+ (void)addEventObserver:(nullable id<CSNotificationEventProtocol>)target eventType:(CSNotificationEventType)eventType;

/**
 移除事件监听者(该方法可以不调用，当事件监听者被释放之后，机制会自动被移除)
 @param target 事件监听者
 @param eventType 事件类型
 */
+ (void)removeEventObserver:(nullable id<CSNotificationEventProtocol>)target eventType:(CSNotificationEventType)eventType;

/**
 发送通知事件(如果要发送新的事件，可以根据事件类型枚举添加新枚举值，然后发送即可)
 @param param 参数
 @param eventType 事件类型
 */
+ (void)sendNotificationWithObject:(nullable id)param eventType:(CSNotificationEventType)eventType;

@end

NS_ASSUME_NONNULL_END
