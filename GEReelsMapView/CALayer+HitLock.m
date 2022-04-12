//
//  CALayer+HitLock.m
//  SVGKitTest
//
//  Created by Marcilio Junior on 3/24/16.
//  Copyright © 2016 HE:labs. All rights reserved.
//

#import "CALayer+HitLock.h"
#import <objc/runtime.h>

static void * const kHitTestLockedStorageKey = (void*)&kHitTestLockedStorageKey;

@implementation CALayer (HitLock)

- (BOOL)isHitTestLocked {
    NSNumber *boolProperty = objc_getAssociatedObject(self, &kHitTestLockedStorageKey);
    return boolProperty.boolValue;
}

- (void)setHitTestLocked:(BOOL)isHitTestLocked {
    objc_setAssociatedObject(self, &kHitTestLockedStorageKey, [NSNumber numberWithBool:isHitTestLocked], OBJC_ASSOCIATION_RETAIN);
}

@end
