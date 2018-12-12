//
//  CSNotificationHandler.m
//  ViewTest
//
//  Created by wshh on 2018/10/11.
//  Copyright © 2018年 wshh. All rights reserved.
//

#import "CSNotificationHandler.h"

#define force_inline __inline__ __attribute__((always_inline))

/**
 中间对象
 */
@interface _CSNotificationObject : NSObject

@property (weak, nonatomic) id<CSNotificationEventProtocol>targetObj;
@property (copy, nonatomic) NSString *targetKey;
@property (strong, nonatomic) NSMutableArray<NSString *> *eventKeyArr;

@end

@implementation _CSNotificationObject

- (instancetype)init {
    self = [super init];
    _eventKeyArr = [NSMutableArray new];
    return self;
}

@end


static dispatch_semaphore_t CSNotification_lock;
static NSMutableDictionary *CSNotification_Event_DicM;
static NSMutableDictionary *CSNotification_Observers_DicM;

//获取中间对象
static force_inline _CSNotificationObject * CSNotification_getObserver(NSString *targetKey, BOOL isRemove) {
    _CSNotificationObject *eventObj = nil;
    if ([CSNotification_Observers_DicM.allKeys containsObject:targetKey]) {
        eventObj = [CSNotification_Observers_DicM objectForKey:targetKey];
    } else {
        eventObj = [_CSNotificationObject new];
        [CSNotification_Observers_DicM setObject:eventObj forKey:targetKey];
    }
    if (isRemove) {
        [CSNotification_Observers_DicM removeObjectForKey:targetKey];
    }
    return eventObj;
}

//从事件字典中获取观察者字典
static force_inline NSMutableDictionary *CSNotification_getObserverDictionary(NSString *eventKey) {
    NSMutableDictionary * tempArr = nil;
    if ([CSNotification_Event_DicM.allKeys containsObject:eventKey]) {
        tempArr = [CSNotification_Event_DicM objectForKey:eventKey];
    } else {
        tempArr = [NSMutableDictionary new];
        [CSNotification_Event_DicM setObject:tempArr forKey:eventKey];
    }
    return tempArr;
}

//添加事件观察者
static force_inline void CSNotification_addObserver(_CSNotificationObject *eventObj, NSString *eventKey) {
    if (!eventObj) {
        return;
    }
    NSMutableDictionary *observerDic = CSNotification_getObserverDictionary(eventKey);
    [observerDic setValue:eventObj forKey:eventObj.targetKey];
}

//移除对应事件观察者
static force_inline void CSNotification_removeObserverForEnevt(NSString *eventKey, NSString *targetKey) {
    if (eventKey) {
        NSMutableDictionary *observerDic = CSNotification_getObserverDictionary(eventKey);
        if (targetKey) { //移除对象注册的单个事件
            if ([observerDic.allKeys containsObject:targetKey]) {
                _CSNotificationObject *eventObj = [observerDic objectForKey:targetKey];
                [observerDic removeObjectForKey:targetKey];
                if ([eventObj.eventKeyArr containsObject:eventKey]) {
                    [eventObj.eventKeyArr removeObject:eventKey];
                }
                if (eventObj.eventKeyArr.count == 0) {
                    CSNotification_getObserver(targetKey, YES);
                }
            }
        } else { //移除事件对应的所有对象
            for (_CSNotificationObject *eventObj in observerDic.allValues) {
                if ([eventObj.eventKeyArr containsObject:eventKey]) {
                    [eventObj.eventKeyArr removeObject:eventKey];
                }
                if (eventObj.eventKeyArr.count == 0) {
                    CSNotification_getObserver(targetKey, YES);
                }
            }
            [observerDic removeAllObjects];
            
        }
    }
}

//移除对象注册的所有事件
static force_inline void CSNotification_removeObserver(NSString *targetKey) {
    if (targetKey) {
        _CSNotificationObject *eventObj = CSNotification_getObserver(targetKey, YES);
        NSArray *eventKeyArr = eventObj.eventKeyArr.copy;
        for (NSString *eventKey in eventKeyArr) {
            CSNotification_removeObserverForEnevt(eventKey, targetKey);
        }
    }
}

@implementation CSNotificationHandler

+ (void)initialize {
    CSNotification_Event_DicM = [NSMutableDictionary new];
    CSNotification_Observers_DicM = [NSMutableDictionary new];
    CSNotification_lock = dispatch_semaphore_create(1);
}

+ (void)sendNotificationWithObject:(id)param eventType:(CSNotificationEventType)eventType {
    // 主线程执行
    dispatch_semaphore_wait(CSNotification_lock, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *eventKey = [self p_getBaseKey:eventType];
        NSMutableDictionary *observerDic = CSNotification_getObserverDictionary(eventKey);
        NSMutableArray *tempArr = [NSMutableArray new];
        for (_CSNotificationObject *eventObj in observerDic.allValues) {
            if (eventObj.targetObj && [eventObj.targetObj respondsToSelector:@selector(receiveEvent:param:)]) {
                [eventObj.targetObj receiveEvent:eventType param:param];
            } else {
                [tempArr addObject:eventObj];
            }
        }
        for (_CSNotificationObject *eventObj in tempArr) {
            CSNotification_removeObserver(eventObj.targetKey);
        }
    });
    dispatch_semaphore_signal(CSNotification_lock);
}

+ (void)addEventObserver:(id<CSNotificationEventProtocol>)target eventType:(CSNotificationEventType)eventType {
    if (!target || eventType <= CSNotificationEventNone || eventType >= CSNotificationEventMax) {
        return;
    }
    dispatch_semaphore_wait(CSNotification_lock, DISPATCH_TIME_FOREVER);
    NSString *eventKey = [self p_getBaseKey:eventType];
    NSString *targetKey = [self p_getObserverKey:target];
    // 获取已经保存的中间对象，如果之前没有，创建并保存
    _CSNotificationObject *eventObj = CSNotification_getObserver(targetKey, NO);
    eventObj.targetObj = target;
    eventObj.targetKey = targetKey;
    [eventObj.eventKeyArr addObject:eventKey];
    // 把该中间对象添加到对应的事件观察者数组中
    CSNotification_addObserver(eventObj, eventKey);
    dispatch_semaphore_signal(CSNotification_lock);
}

+ (void)removeEventObserver:(id<CSNotificationEventProtocol>)target eventType:(CSNotificationEventType)eventType {
    //移除对象注册的单个事件（有事件，又有对象）
    //移除事件对应的所有对象（有事件，没有对象）
    //移除对象注册的所有事件（没有事件，只有对象）
    dispatch_semaphore_wait(CSNotification_lock, DISPATCH_TIME_FOREVER);
    if ((eventType > CSNotificationEventNone && eventType < CSNotificationEventMax)) {
        NSString *eventKey = [self p_getBaseKey:eventType];
        NSString *targetKey = nil;
        if (target) {
            targetKey = [self p_getObserverKey:target];
        }
        CSNotification_removeObserverForEnevt(eventKey, targetKey);
    } else if (target) {
        NSString *targetKey = [self p_getObserverKey:target];
        CSNotification_removeObserver(targetKey);
    }
    dispatch_semaphore_signal(CSNotification_lock);
}

+ (NSString *)p_getBaseKey:(CSNotificationEventType)eventType {
    NSString *key = [NSString stringWithFormat:@"EventDistribution_EventKey_%zd", eventType];
    return key;
}

+ (NSString *)p_getObserverKey:(id)target {
    NSString *observerKey = [NSString stringWithFormat:@"EventDistribution_ObserverKey_%@_%zd", NSStringFromClass([target class]), [target hash]];
    return observerKey;
}

@end
