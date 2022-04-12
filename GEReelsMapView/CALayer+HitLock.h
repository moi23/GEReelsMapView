//
//  CALayer+HitLock.h
//  SVGKitTest
//
//  Created by Marcilio Junior on 3/24/16.
//  Copyright © 2016 HE:labs. All rights reserved.
//

@import QuartzCore;

@interface CALayer (HitLock)

@property (nonatomic, getter=isHitTestLocked) BOOL hitTestLocked;

@end
