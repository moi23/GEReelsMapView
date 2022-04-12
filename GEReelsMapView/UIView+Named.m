//
//  UIView+Named.m
//  Pods
//
//  Created by Marcilio Junior on 6/23/16.
//
//

#import "UIView+Named.h"
#import <objc/runtime.h>

static void * const kNameStorageKey = (void*)&kNameStorageKey;

@implementation UIView (Named)

- (NSString *)name {
    NSString *property = objc_getAssociatedObject(self, &kNameStorageKey);
    return property;
}

- (void)setName:(NSString *)name {
    objc_setAssociatedObject(self, &kNameStorageKey, name, OBJC_ASSOCIATION_RETAIN);
}

@end
