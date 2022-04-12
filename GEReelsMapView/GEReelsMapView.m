//
//  GEReelsMapView.m
//  SVGKitTest
//
//  Created by Marcilio Junior on 3/22/16.
//  Copyright © 2016 HE:labs. All rights reserved.
//

@import QuartzCore;
#import <BlocksKit/BlocksKit.h>
#import <SVGKit/SVGKit.h>
#import "GEReelsMapView.h"
#import "CALayer+HitLock.h"
#import "UIView+Named.h"
#import "GEReelsMapConstants.h"

typedef NS_ENUM(NSInteger,  LabelAlignment) {
    LabelAlignmentTop,
    LabelAlignmentCenter,
    LabelAlignmentBottom,
};

static NSInteger const kTemporaryParkingSlotInitialCode = 500;

@interface GEReelsMapView () <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
    CGFloat dx;
    CGFloat dy;
    CGFloat angle;
    CGFloat initialAngle;
}

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) SVGKImageView *layeredImageView;
@property (nonatomic, strong) SVGKImage *currentSVGImage;

@property (nonatomic, strong) CALayer *tappedLayer;
@property (nonatomic, strong) UIView *spotView;
@property (nonatomic, strong) UIView *balsaView;
@property (nonatomic, strong) UIView *selectedTemporaryShape;

@property (nonatomic, strong) NSArray<SVGRectElement *> *parkingSpots;
@property (nonatomic, strong) NSMutableArray<CATextLayer *> *reelsLabels;
@property (nonatomic, strong) NSMutableArray<CATextLayer *> *reelsAdditionalLabels;
@property (nonatomic, strong) NSMutableArray<NSString *> *spotsWithParkedReel;
@property (nonatomic, strong) NSMutableArray<NSString *> *markedParkingSlots;
@property (nonatomic, strong) NSArray<CAShapeLayer *> *parkingSlotsLayers;
@property (nonatomic, strong) NSMutableArray<CALayer *> *regionNameLayers;
@property (nonatomic, strong) NSMutableArray<UIView *> *temporaryParkingSlotsPlotted;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation GEReelsMapView

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [self setupView];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self setupView];
    }
    
    return self;
}

- (void)dealloc
{
    [self destroyMapView];
}

- (void)destroyMapView
{
    while (self.subviews.count) {
        UIView *v = self.subviews.lastObject;
        [v removeFromSuperview];
        v = nil;
    }
    self.reelsLabels = nil;
    self.reelsAdditionalLabels = nil;
}

#pragma mark - Public Methods

- (void)createViewOnMapOfType:(GETemporaryViewType)type withIdentifier:(NSString * _Nullable)identifier parkingSlotIdentifier:(NSString * _Nullable)parkingSlotIdentifier
{
    BOOL canCreateNewViewOnMap = (type == GETemporaryViewTypeBalsa && ![self isBalsaCreated]) ||
                                 (type == GETemporaryViewTypeParkingSlot && ![self isNewParkingSlotCreated]);
    
    if (canCreateNewViewOnMap) {
        CGRect visibleRect = [self.scrollView convertRect:self.scrollView.bounds
                                                   toView:self.contentView];
        
        if (CGRectGetHeight(self.contentView.frame) < CGRectGetHeight(self.scrollView.bounds)) {
            visibleRect.size.height = self.contentView.bounds.size.height;
        }
        CGPoint centerPointOfVisibleRect = CGPointMake(visibleRect.origin.x + (visibleRect.size.width / 2),
                                                       visibleRect.origin.y + visibleRect.size.height / 2);
        
        CGSize containerViewSize = CGSizeMake(type == GETemporaryViewTypeParkingSlot ? 60 : 54, type == GETemporaryViewTypeParkingSlot ? 60 : 26);
        
        UIView *temporaryViewContainerView           = [[UIView alloc] initWithFrame:CGRectMake(0, 0, containerViewSize.width, containerViewSize.height)];
        temporaryViewContainerView.backgroundColor   = [UIColor clearColor];
        temporaryViewContainerView.center            = centerPointOfVisibleRect;
        temporaryViewContainerView.name              = [NSString stringWithFormat:@"container_%@", type == GETemporaryViewTypeParkingSlot ? parkingSlotIdentifier : @"region"];
        
        if (type == GETemporaryViewTypeParkingSlot) {
            [self deselectTappedLayer];
            
            self.spotView                                = [[UIView alloc] initWithFrame:self.parkingSlotFrame];
            self.spotView.center                         = CGPointMake(30, 30);
            self.spotView.backgroundColor                = self.selectedParkingSlotColor;
            self.spotView.layer.allowsEdgeAntialiasing   = YES;
            self.spotView.layer.borderColor              = [UIColor blackColor].CGColor;
            self.spotView.layer.borderWidth              = 0.4f;
            
            [temporaryViewContainerView addSubview:self.spotView];
            
            [self selectParkingSlotWithId:parkingSlotIdentifier regionName:nil];
        }
        else
        {
            self.balsaView                                = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 54, 26)];
            self.balsaView.backgroundColor                = [UIColor colorWithRed:1.000 green:1.000 blue:0.878 alpha:1.000];
            self.balsaView.layer.allowsEdgeAntialiasing   = YES;
            self.balsaView.layer.borderColor              = [UIColor colorWithRed:0.812 green:0.824 blue:0.427 alpha:1.000].CGColor;
            self.balsaView.layer.borderWidth              = 0.4f;
            self.balsaView.name                           = identifier;
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
            button.frame = CGRectMake(43, 15, 10, 10);
            button.tintColor = [UIColor colorWithRed:0.078 green:0.576 blue:0.847 alpha:1.000];
            [button addTarget:self action:@selector(infoButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];
            [self.balsaView addSubview:button];
            
            UIView *temporaryParkingSlotView                        = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 40, 15)];
            temporaryParkingSlotView.backgroundColor                = [UIColor whiteColor];
            temporaryParkingSlotView.layer.allowsEdgeAntialiasing   = YES;
            temporaryParkingSlotView.layer.borderColor              = [UIColor blackColor].CGColor;
            temporaryParkingSlotView.layer.borderWidth              = 0.4f;
            temporaryParkingSlotView.tag                            = parkingSlotIdentifier.integerValue;
            
            UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(parkingSlotInsideBalsaDidTapGestureRecognizer:)];
            [self.balsaView addGestureRecognizer:tapGesture];
                        
            [self.balsaView addSubview:temporaryParkingSlotView];
            [temporaryViewContainerView addSubview:self.balsaView];
        }
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(newShapeDidPanWithGestureRecognizer:)];
        panRecognizer.delegate                  = self;
        panRecognizer.minimumNumberOfTouches    = 1;
        panRecognizer.maximumNumberOfTouches    = 1;
        panRecognizer.cancelsTouchesInView      = YES;
        [temporaryViewContainerView addGestureRecognizer:panRecognizer];
        
        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panRecognizer];

        [self.contentView addSubview:temporaryViewContainerView];
        [self.contentView bringSubviewToFront:temporaryViewContainerView];
    }
}

- (void)addTemporaryParkingSlotToPoint:(CGPoint)point withAngle:(CGFloat)givenAngle identifier:(NSString *)identifier
{
    BOOL isSelected = self.preselectedParkingSlot.integerValue == identifier.integerValue;
    BOOL hasParkedReel = [self.spotsWithParkedReel bk_any:^BOOL(NSString *obj) { return [obj isEqualToString:identifier]; }];
    
    UIColor *backgroundColor = [UIColor whiteColor];
    if (hasParkedReel) {
        backgroundColor = self.filledSlotColor;
    }
    else if (isSelected) {
        backgroundColor = self.selectedParkingSlotColor;
    }
    
    NSLog(@"parkingSlot size: %f, %f", self.parkingSlotFrame.size.width, self.parkingSlotFrame.size.height);
    
    //UIView *temporaryParkingSlotView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8.6, 13.8)];
    UIView *temporaryParkingSlotView = [[UIView alloc] initWithFrame:self.parkingSlotFrame];
    temporaryParkingSlotView.center                         = CGPointMake(point.x + 30, point.y + 30);
    temporaryParkingSlotView.backgroundColor                = backgroundColor;
    temporaryParkingSlotView.layer.allowsEdgeAntialiasing   = YES;
    temporaryParkingSlotView.layer.borderColor              = isSelected ? self.selectedParkingSlotBorderColor.CGColor : [UIColor blackColor].CGColor;
    temporaryParkingSlotView.layer.borderWidth              = 0.4f;
    temporaryParkingSlotView.tag                            = identifier.integerValue;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(temporaryParkingSlotDidTapGestureRecognizer:)];
    [temporaryParkingSlotView addGestureRecognizer:tapGesture];
    
    CGFloat givenAngleInDegrees = ((givenAngle) / 180.0 * M_PI);
    
    CGAffineTransform t = CGAffineTransformRotate(temporaryParkingSlotView.transform, givenAngleInDegrees);
    CATextLayer *idTextLayer = [self drawText:identifier
                                      inLayer:temporaryParkingSlotView.layer
                                withTransform:t
                                   inPosition:LabelAlignmentCenter];
    
    temporaryParkingSlotView.transform = CGAffineTransformRotate(temporaryParkingSlotView.transform, givenAngleInDegrees);
    
    [self.temporaryParkingSlotsPlotted addObject:temporaryParkingSlotView];
    [self.reelsLabels addObject:idTextLayer];
    [self.contentView addSubview:temporaryParkingSlotView];
    
    if (isSelected) {
        [self selectParkingSlotWithId:identifier regionName:nil];
    }
}

- (void)addTemporaryRegionToPoint:(CGPoint)point withAngle:(CGFloat)givenAngle regionIdentifier:(NSString *)identifier parkingSlotIdentifier:(NSString *)psIdentifier
{
    UIView *temporaryRegion                      = [[UIView alloc] initWithFrame:CGRectMake(point.x, point.y, 54, 26)];    
    temporaryRegion.backgroundColor              = [UIColor colorWithRed:1.000 green:1.000 blue:0.878 alpha:1.000];
    temporaryRegion.layer.allowsEdgeAntialiasing = YES;
    temporaryRegion.layer.borderColor            = [UIColor colorWithRed:0.812 green:0.824 blue:0.427 alpha:1.000].CGColor;
    temporaryRegion.layer.borderWidth            = 0.4f;
    temporaryRegion.name                         = identifier;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    button.frame = CGRectMake(43, 15, 10, 10);
    button.tintColor = [UIColor colorWithRed:0.078 green:0.576 blue:0.847 alpha:1.000];
    [button addTarget:self action:@selector(infoButtonDidTap:) forControlEvents:UIControlEventTouchUpInside];
    [temporaryRegion addSubview:button];
    
    UIView *temporaryParkingSlotView                        = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 40, 15)];
    temporaryParkingSlotView.backgroundColor                = [UIColor whiteColor];
    temporaryParkingSlotView.layer.allowsEdgeAntialiasing   = YES;
    temporaryParkingSlotView.layer.borderColor              = [UIColor blackColor].CGColor;
    temporaryParkingSlotView.layer.borderWidth              = 0.4f;
    temporaryParkingSlotView.tag                            = psIdentifier.integerValue;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(parkingSlotInsideBalsaDidTapGestureRecognizer:)];
    [temporaryRegion addGestureRecognizer:tapGesture];
    
    CGFloat givenAngleInDegrees = ((givenAngle) / 180.0 * M_PI);
    
    CGAffineTransform t = CGAffineTransformRotate(temporaryRegion.transform, givenAngleInDegrees);
    CATextLayer *idTextLayer = [self drawText:psIdentifier
                                      inLayer:temporaryParkingSlotView.layer
                                withTransform:t
                                   inPosition:LabelAlignmentCenter];
    
    temporaryRegion.transform = CGAffineTransformRotate(temporaryParkingSlotView.transform, givenAngleInDegrees);
    
    [self.temporaryParkingSlotsPlotted addObject:temporaryParkingSlotView];
    [self.reelsLabels addObject:idTextLayer];
    [temporaryRegion addSubview:temporaryParkingSlotView];
    
    [self.contentView addSubview:temporaryRegion];
}


- (void)parkingSlotInsideBalsaDidTapGestureRecognizer:(UITapGestureRecognizer *)recognizer
{
    [self deselectTappedLayer];
    
    if (self.allowParkingSlotSelection) {
        UIView *temporaryParkingSlotView = recognizer.view.subviews.lastObject;
        
        self.selectedTemporaryShape = temporaryParkingSlotView;
        temporaryParkingSlotView.backgroundColor = self.selectedParkingSlotColor;
        temporaryParkingSlotView.layer.borderColor = self.selectedParkingSlotBorderColor.CGColor;
        
        self.selectedParkingSpotCode = @(temporaryParkingSlotView.tag).stringValue;

        if (self.parkingSlotDidSelect) {
            self.parkingSlotDidSelect(self.selectedParkingSpotCode, temporaryParkingSlotView.superview.name);
        }
    }
}


- (void)updateRotationOfViewType:(GETemporaryViewType)type withAngle:(CGFloat)givenAngle
{
    UIView *view;
    if (type == GETemporaryViewTypeParkingSlot) {
        view = self.spotView ? self.spotView : self.selectedTemporaryShape;
    }
    else {
        view = self.balsaView;
    }
    
    CGFloat currentAngle = atan2(view.transform.b, view.transform.a);
    CGFloat givenAngleInDegrees = ((givenAngle) / 180.0 * M_PI);
    angle = givenAngleInDegrees;
    initialAngle = angle;
    
    view.layer.anchorPoint = CGPointMake(0.5, 0.5);
    view.transform = CGAffineTransformRotate(view.transform, givenAngleInDegrees - currentAngle);
    
    if (type == GETemporaryViewTypeParkingSlot) {
        self.temporaryParkingSlotCurrentAngle = givenAngle;
    }
    else {
        self.balsaCurrentAngle = givenAngle;
    }
}

- (void)zoomInAreaWithIdentifier:(NSString *)identifier
{
    [self updateOpacityOfAllLayersWithValue:0.3 excludingLayersWithName:@[identifier]];

    CALayer *layer = [self.currentSVGImage.CALayerTree.sublayers bk_match:^BOOL(CALayer *obj) { return [obj.name isEqualToString:identifier]; }];
    
    [self.scrollView zoomToRect:layer.frame animated:YES];
}

- (BOOL)isNewParkingSlotCreated
{
    return self.spotView != nil;
}

- (BOOL)isBalsaCreated
{
    return self.balsaView != nil;
}

- (NSString *)getRegionForSelectTemporaryParkingSlot
{
    CGPoint centerPoint = [self spotViewContainerPointInSVG];
    centerPoint.x += 30;
    centerPoint.y += 30;
    
    NSArray *phatomRegions = [self.currentSVGImage.CALayerTree.sublayers bk_select:^BOOL(CALayer *obj) {
        //return ![obj.name isEqualToString:GEAreaNewCastleMap];
        return [obj.name isEqualToString:GEAreaFantasma1] || [obj.name isEqualToString:GEAreaFantasma2] || [obj.name isEqualToString:GEAreaYard] || [obj.name isEqualToString:GEAreaQuay];
    }];
    
    CALayer *selectedRegionForTemporaryParkingSlot = [phatomRegions bk_match:^BOOL(CALayer *obj) {
        return CGRectContainsPoint(obj.frame, centerPoint);
    }];
    
    NSLog(selectedRegionForTemporaryParkingSlot.name);
        
    return selectedRegionForTemporaryParkingSlot.name;
}

#pragma mark - Private Properties

- (NSArray<NSString *> *)allReelsLayerIdentifiers
{
    // Every region on map should be in this array
    return @[GEAreaMuroMarine, GEAreaMuroFabrica, GEAreaRecuoFabrica, GEAreaAlmoxarifado, GEAreaRuaMarine, GEAreaLadoRampa, GEAreaRampa, GEAreaLadoFabrica, GEAreaPackaging, GEAreaHidroteste, GEAreaConcreto, GEAreaMontagemLadoB, GEAreaMontagem, GEAreaExpansao, GEAreaCorredorMaua, GEAreaFundoDaLok, GEAreaLadoDoTrilhoMaua, GEAreaRimDriveLadoMaua, GEAreaCorredorBaia, GEAreaRimDriveDaLok, GEAreaSalaDaPetrobras, GEAreaAtrasDaCarcass, GEAreaCarcass, GEAreaLadoDoTrilhoBaia, GEAreaRimDriveDaArmExt, GEAreaFantasma1, GEAreaFantasma2, GEAreaBalsa, GEAreaBaseLogistica, GEAreaYard, GEAreaQuay, GEAreaPCRiver, GEAreaPCRoad, GEAreaRiverSide,GEAreaRoadSide, GEAreaHydro, GEAreaMacLaren, GEAreaBaseLog, GEAreaUm, GEAreaDois, GEAreaTres, GEAreaQuatro, GEAreaCinco, GEAreaSeis, GEAreaHidrotesteBL, GEAreaDesparafinacao, GEAreaCais,GEAreaLoadOut, GEAreaRuaBaseLog];

}
- (NSMutableArray<CATextLayer *> *)reelsAdditionalLabels
{
    if (!_reelsAdditionalLabels) {
        _reelsAdditionalLabels = [NSMutableArray array];
    }
    
    return _reelsAdditionalLabels;
}

- (NSMutableArray<CATextLayer *> *)reelsLabels
{
    if (!_reelsLabels) {
        _reelsLabels = [NSMutableArray array];
    }
    
    return _reelsLabels;
}

- (NSArray<CAShapeLayer *> *)parkingSlotsLayers
{
    if (!_parkingSlotsLayers) {
        _parkingSlotsLayers = [self.parkingSpots bk_map:^CAShapeLayer *(SVGRectElement *obj) {
            NSLog(@"parking slot obj: %@", obj);
            NSLog(@"layer: %@", [self layerForRectElement:obj]);
            return [self layerForRectElement:obj];
        }];
    }
    
    return _parkingSlotsLayers;
}

- (NSMutableArray<CALayer *> *)regionNameLayers
{
    if (!_regionNameLayers) {
        _regionNameLayers = [NSMutableArray array];
        
        [self.currentSVGImage.CALayerTree.sublayers bk_each:^(CALayer *obj) {
            NSArray *titleLayers = [obj.sublayers bk_select:^BOOL(CALayer *obj) {
                return [obj.name hasPrefix:@"t_"];
            }];
            
            [_regionNameLayers addObjectsFromArray:titleLayers];
        }];        
    }
    
    return _regionNameLayers;
}

- (NSArray<SVGRectElement *> *)parkingSpots
{
    if (_parkingSpots == nil && self.currentSVGImage != nil) {
        _parkingSpots = [NSMutableArray array];
        
        for (NSString *layerId in self.allReelsLayerIdentifiers) {
            NSArray *realsForArea = [[self.currentSVGImage.DOMTree getElementById:layerId].childNodes.internalArray bk_select:^BOOL(SVGRectElement *obj) {
                return [obj isKindOfClass:SVGRectElement.class] && ![obj.identifier isEqualToString:@""] && obj.identifier;
            }];
            
            NSLog(@"LAYER ID: %@ - PARKING SLOTS: %@", layerId, realsForArea);
            
            _parkingSpots = [_parkingSpots arrayByAddingObjectsFromArray:realsForArea];
        }
    }
    
    return _parkingSpots;
}

- (CGPoint)temporaryParkingSlotCurrentPosition
{
    return [self spotViewContainerPointInSVG];
}

- (CGPoint)balsaCurrentPosition
{
    return [self balsaViewPointInSVG];
}

#pragma mark - Private Methods

- (void)setupView
{
    [self setup];    
}

- (void)setup
{
    self.allowParkingSlotSelection       = YES;
    self.enableZoomChanges               = YES;
    
    self.selectedParkingSlotColor       = [UIColor colorWithRed:0.000 green:0.571 blue:0.860 alpha:1.000];
    self.selectedParkingSlotBorderColor = [UIColor colorWithRed:0.000 green:0.137 blue:0.374 alpha:1.000];
    self.filledSlotColor                = [UIColor whiteColor];
    
    self.scrollView                 = [[UIScrollView alloc] init];
    self.scrollView.delegate        = self;
    self.scrollView.clipsToBounds   = YES;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.scrollView addSubview:self.contentView];
    [self addSubview:self.scrollView];
    
    dx           = 0;
    dy           = 0;
    angle        = 0;
    initialAngle = 0;
    
    self.backgroundColor             = [UIColor clearColor];
    self.scrollView.backgroundColor  = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.activityView                   = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activityView.hidesWhenStopped  = YES;
    self.activityView.color             = [UIColor blackColor];
    [self.activityView startAnimating];
    
    [self addSubview:self.activityView];
    
    self.markedParkingSlots           = [NSMutableArray array];
    self.spotsWithParkedReel          = [NSMutableArray array];
    self.temporaryParkingSlotsPlotted = [NSMutableArray array];
    self.parkingSlotFrame = CGRectMake(0, 0, 8.6, 13.8);
}

- (void)loadSVGFromFile
{
    __block __weak typeof(self) weakSelf = self;
    
    SVGKSourceLocalFile *source = [SVGKSourceLocalFile internalSourceAnywhereInBundle:weakSelf.bundle
                                                                            usingName:weakSelf.mapFilename];
        
    [SVGKImage imageWithSource:source onCompletion:^(SVGKImage *loadedImage, SVGKParseResult *parseResult) {
        
        __typeof__(self) strongSelf = weakSelf;
        
        strongSelf.currentSVGImage             = loadedImage;
        strongSelf.layeredImageView            = [[SVGKLayeredImageView alloc] initWithSVGKImage:strongSelf.currentSVGImage];
        strongSelf.layeredImageView.frame      = CGRectMake(0, 0, strongSelf.currentSVGImage.size.width, strongSelf.currentSVGImage.size.height);
        strongSelf.layeredImageView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [strongSelf addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:strongSelf action:@selector(viewDidTapWithGestureRecognizer:)]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [strongSelf.contentView addSubview:strongSelf.layeredImageView];
            [strongSelf renderReelsInfo];
            
            if (strongSelf.enableZoomChanges) {
                [strongSelf toggleAdditionalForCurrentZoom:strongSelf.scrollView.zoomScale];
                [strongSelf toggleParkingSlotsForCurrentZoom:strongSelf.scrollView.zoomScale];
                [strongSelf toggleRegionNameForCurrentZoom:strongSelf.scrollView.zoomScale];
            }
            [strongSelf toggleIdentifiersForCurrentZoom:strongSelf.scrollView.zoomScale];
            
            if (strongSelf.preselectedParkingSlot) {
                strongSelf.selectedParkingSpotCode = strongSelf.preselectedParkingSlot;
                
                if (strongSelf.preselectedParkingSlot.integerValue < kTemporaryParkingSlotInitialCode) {
                    SVGRectElement *psElement = [strongSelf.parkingSpots bk_match:^BOOL(SVGRectElement *obj) {
                        return [obj.identifier isEqualToString:strongSelf.preselectedParkingSlot];
                    }];
                    
                    strongSelf.tappedLayer = [strongSelf layerForRectElement:psElement];
                    
                    [strongSelf fillRectElement:psElement
                                      withColor:strongSelf.selectedParkingSlotColor
                                    borderColor:strongSelf.selectedParkingSlotBorderColor];
                }
            }
            
            [strongSelf.activityView stopAnimating];
        });
    
        if (strongSelf.finishedLoadingMap) {
            strongSelf.finishedLoadingMap();
        }
        
    }];    
}

- (void)updateOpacityOfAllLayersWithValue:(CGFloat)opacity
{
    [self updateOpacityOfAllLayersWithValue:opacity
                    excludingLayersWithName:nil];
}

- (void)updateOpacityOfAllLayersWithValue:(CGFloat)opacity
                  excludingLayersWithName:(nullable NSArray<NSString *> *)excludedNames
{    
    for (NSString *layerId in self.allReelsLayerIdentifiers) {
        CALayer *layer = [self.currentSVGImage.CALayerTree.sublayers bk_match:^BOOL(CALayer *obj) {
            return [obj.name isEqualToString:layerId];
        }];
        
        if (![excludedNames containsObject:layer.name]) {
            layer.hitTestLocked = YES;
            layer.opacity = opacity;
        }
        else {
            layer.hitTestLocked = NO;
            layer.opacity = 1.0f;
        }
    }
}

- (void)selectParkingSlotWithId:(NSString *)parkingSlotId regionName:(NSString *)regionName
{
    self.selectedParkingSpotCode = parkingSlotId;
    if (self.parkingSlotDidSelect) {
        self.parkingSlotDidSelect(self.selectedParkingSpotCode, regionName);
    }
}

- (void)removeNewSpotLayer
{
    [[[self.contentView subviews] bk_select:^BOOL(UIView *obj) {
        return [obj.name hasPrefix:@"container_"] && ![obj.name hasSuffix:@"region"];
    }] bk_each:^(UIView *obj) {
        [obj removeFromSuperview];
    }];
    
    self.spotView = nil;

    if (self.temporaryParkingSlotRemoved) {
        self.temporaryParkingSlotRemoved();
    }
}

- (void)infoButtonDidTap:(UIButton *)sender
{
    if (self.balsaInfoDidTap) {
        self.balsaInfoDidTap(sender.superview.name);
    }
}

#pragma mark - Lifecycle

- (void)updateConstraints
{
    [super updateConstraints];
    
    if (self.layeredImageView) {
        id views = @{@"scrollView": self.scrollView,
                     @"contentView": self.contentView,
                     @"imageView": self.layeredImageView};
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scrollView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollView]|" options:0 metrics:nil views:views]];

        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contentView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contentView]|" options:0 metrics:nil views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:views]];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.scrollView setContentSize:self.currentSVGImage.size];
    
    CGFloat screenToDocumentSizeRatio   = self.scrollView.frame.size.width / self.currentSVGImage.size.width;
    CGFloat minimumZoomScale            = MIN(self.scrollView.bounds.size.width / self.currentSVGImage.size.width, self.scrollView.bounds.size.height / self.currentSVGImage.size.height);
    
    self.scrollView.minimumZoomScale        = minimumZoomScale;
    self.scrollView.maximumZoomScale        = MAX(5, screenToDocumentSizeRatio);
    self.scrollView.zoomScale               = minimumZoomScale;
    self.scrollView.contentOffset           = CGPointZero;
    self.scrollView.contentInset            = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets   = UIEdgeInsetsZero;
    
    self.activityView.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

#pragma mark - Gesture Recognizer Handlers

- (void)viewDidTapWithGestureRecognizer:(UITapGestureRecognizer *)recognizer
{
    [self deselectTappedLayer];
    
    CGPoint point           = [recognizer locationInView:self.contentView];
    CGPoint convertedPoint  = [self.contentView convertPoint:point toView:self.scrollView];

    CALayer *hitLayer = [self.contentView.layer hitTest:convertedPoint];
    if ([hitLayer isKindOfClass:CATextLayer.class]) {
        hitLayer = hitLayer.superlayer;
    }
    
    if (!hitLayer.superlayer.isHitTestLocked && self.allowParkingSlotSelection) {
        if ([self isSpotLayer:hitLayer]) {
            self.tappedLayer = hitLayer;
            [self fillLayer:hitLayer
                  withColor:self.selectedParkingSlotColor
                borderColor:self.selectedParkingSlotBorderColor];

            if ([self isNewParkingSlotCreated]) {
                [self removeNewSpotLayer];
            }
        }
    }
}

- (void)temporaryParkingSlotDidTapGestureRecognizer:(UITapGestureRecognizer *)recognizer
{
    [self deselectTappedLayer];
    
    if (self.allowParkingSlotSelection) {
        UIView *temporaryParkingSlotView = recognizer.view;
        
        self.selectedTemporaryShape = temporaryParkingSlotView;
        temporaryParkingSlotView.backgroundColor = self.selectedParkingSlotColor;
        temporaryParkingSlotView.layer.borderColor = self.selectedParkingSlotBorderColor.CGColor;
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(newShapeDidPanWithGestureRecognizer:)];
        panRecognizer.delegate                  = self;
        panRecognizer.minimumNumberOfTouches    = 1;
        panRecognizer.maximumNumberOfTouches    = 1;
        panRecognizer.cancelsTouchesInView      = YES;
        [temporaryParkingSlotView addGestureRecognizer:panRecognizer];
        
        [self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:panRecognizer];
        
        self.selectedParkingSpotCode = @(temporaryParkingSlotView.tag).stringValue;
        
        if (self.parkingSlotDidSelect) {
            self.parkingSlotDidSelect(self.selectedParkingSpotCode, nil);
        }
    }
}

- (void)newShapeDidPanWithGestureRecognizer:(UIPanGestureRecognizer *)recognizer
{
    BOOL canPan = ([recognizer.view.name isEqualToString:@"container_region"] && !self.lockPanGestureForBalsa) ||
                  ([recognizer.view.name hasPrefix:@"container_"] && ![recognizer.view.name hasSuffix:@"region"] && !self.lockPanGestureForNewParkingSlot);
    
    if (canPan) {
        CGPoint translation = [recognizer translationInView:recognizer.view.superview];
        
        [self adjustAnchorPointForGestureRecognizer:recognizer];
        [self updateTransformOfView:recognizer.view withOffset:translation];
        
        // when tag is greather 0 means that's panning an existing temporary parking slot
        if (recognizer.view.tag > 0) {
            recognizer.view.transform = CGAffineTransformRotate(recognizer.view.transform, angle);
        }
    }
}

#pragma mark - UIGestureRecgonizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer.view != otherGestureRecognizer.view) {
        return NO;
    }
    
    if (![gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && ![otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Gesture Helpers

- (void)updateTransformOfView:(UIView *)view withOffset:(CGPoint)offset
{
    view.transform = CGAffineTransformMakeTranslation(offset.x + dx, offset.y + dy);
}

- (void)adjustAnchorPointForGestureRecognizer:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        dx = gesture.view.transform.tx;
        dy = gesture.view.transform.ty;
    }
}

- (CGPoint)spotViewContainerPointInSVG
{
    UIView *viewToEvaluate = nil;
    UIView *visibleRect = nil;
    
    if ([self isNewParkingSlotCreated]) {
        viewToEvaluate = self.spotView.superview;
        visibleRect = viewToEvaluate.superview;
    }
    else {
        UIView *dummyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        CGPoint center = CGPointMake(CGRectGetMidX(self.selectedTemporaryShape.frame),
                                     CGRectGetMidY(self.selectedTemporaryShape.frame));
        dummyView.center = center;
        viewToEvaluate = dummyView;
        visibleRect = self.selectedTemporaryShape.superview;
    }
    
    CGPoint containerPointInSVG = [self.contentView convertPoint:viewToEvaluate.frame.origin fromView:visibleRect];
    
    return containerPointInSVG;
}

- (CGPoint)balsaViewPointInSVG
{
    UIView *viewToEvaluate = self.balsaView.superview;
    UIView *visibleRect = viewToEvaluate.superview;
    
    CGPoint containerPointInSVG = [self.contentView convertPoint:viewToEvaluate.frame.origin fromView:visibleRect];
    
    return containerPointInSVG;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat currentZoom = scrollView.zoomScale;
    
    [self toggleIdentifiersForCurrentZoom:currentZoom];
    if (self.enableZoomChanges) {
        [self toggleAdditionalForCurrentZoom:currentZoom];
        [self toggleParkingSlotsForCurrentZoom:currentZoom];
        [self toggleRegionNameForCurrentZoom:currentZoom];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.contentView;
}

#pragma mark - Selection Helpers

- (BOOL)isSpotLayer:(CALayer *)layer
{
    return layer!= NULL && [self.allReelsLayerIdentifiers containsObject:layer.superlayer.name] && layer.name.length > 0;
}

- (void)fillAllReels
{
    [self.parkingSpots bk_each:^(SVGRectElement *obj) {
        [self fillRectElement:obj withColor:self.filledSlotColor];
    }];
}

- (void)unmarkParkingSlotWithId:(NSString *)parkingSlotId
{
    if (parkingSlotId) {
        [self.markedParkingSlots removeObject:parkingSlotId];
        
        if (parkingSlotId.integerValue > kTemporaryParkingSlotInitialCode) {
            UIView *temporaryParkingSlotView = [[self.temporaryParkingSlotsPlotted bk_select:^BOOL(UIView *obj) {
                return obj.tag == parkingSlotId.integerValue;
            }] firstObject];
            
            temporaryParkingSlotView.backgroundColor = [UIColor whiteColor];
        }
        else {
            SVGRectElement *element = [self.parkingSpots bk_match:^BOOL(SVGRectElement *obj) { return [obj.identifier isEqualToString:parkingSlotId]; }];
            if (element) {
                CALayer *hitLayer        = [self layerForRectElement:element];
                CAShapeLayer *shapeLayer = (CAShapeLayer *)hitLayer;
                
                if ([hitLayer isKindOfClass:CATextLayer.class]) {
                    shapeLayer = hitLayer.superlayer;
                }
                
                // check if hitLayer was succeeded
                if (![shapeLayer.name isEqualToString:parkingSlotId]) {
                    shapeLayer = [shapeLayer.superlayer.sublayers bk_match:^BOOL(CALayer *obj) { return [obj.name isEqualToString:parkingSlotId]; }];
                }
                
                shapeLayer.fillColor = [UIColor whiteColor].CGColor;
            }
        }
    }
}

- (void)markParkingSlotWithId:(NSString *)parkingSlotId andColor:(UIColor *)color
{
    if (parkingSlotId) {
        [self.markedParkingSlots addObject:parkingSlotId];
        
        if (parkingSlotId.integerValue > kTemporaryParkingSlotInitialCode) {
            UIView *temporaryParkingSlotView = [[self.temporaryParkingSlotsPlotted bk_select:^BOOL(UIView *obj) {
                return obj.tag == parkingSlotId.integerValue;
            }] firstObject];
            
            temporaryParkingSlotView.backgroundColor = color;
        }
        else {
            SVGRectElement *element = [self.parkingSpots bk_match:^BOOL(SVGRectElement *obj) { return [obj.identifier isEqualToString:parkingSlotId]; }];
            if (element) {
                CALayer *hitLayer        = [self layerForRectElement:element];
                CAShapeLayer *shapeLayer = (CAShapeLayer *)hitLayer;
                
                if ([hitLayer isKindOfClass:CATextLayer.class]) {
                    shapeLayer = hitLayer.superlayer;
                }
                
                // check if hitLayer was succeeded
                if (![shapeLayer.name isEqualToString:parkingSlotId]) {
                    shapeLayer = [shapeLayer.superlayer.sublayers bk_match:^BOOL(CALayer *obj) { return [obj.name isEqualToString:parkingSlotId]; }];
                }
                
                shapeLayer.fillColor = color.CGColor;
            }
        }
    }
}

- (void)selectParkingSpotWithId:(NSString *)parkingSlotId
{
    [self.spotsWithParkedReel addObject:parkingSlotId];
    
    if (parkingSlotId.integerValue > kTemporaryParkingSlotInitialCode) {
        UIView *temporaryParkingSlotView = [[self.temporaryParkingSlotsPlotted bk_select:^BOOL(UIView *obj) {
            return obj.tag == parkingSlotId.integerValue;
        }] firstObject];
        
        temporaryParkingSlotView.backgroundColor = self.filledSlotColor;
    }
    else {
        SVGRectElement *psElement = [self.parkingSpots bk_match:^BOOL(SVGRectElement *obj) {
            return [obj.identifier isEqualToString:parkingSlotId];
        }];
        
        [self fillRectElement:psElement withColor:self.filledSlotColor];
    }
}
- (void)selectParkingSpotWithId:(NSString *)parkingSlotId withReelsId:(NSString *)reelsId
{
    [self selectParkingSpotWithId:parkingSlotId];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.string == %@",[NSString stringWithFormat:@"\n%@\n",parkingSlotId]];
    NSArray<CATextLayer *>* filtered = [self.reelsLabels filteredArrayUsingPredicate:predicate];
    if (filtered != NULL && [filtered count] > 0) {
        NSString* text = [NSString stringWithFormat:@"\n%@\n%@    ", parkingSlotId, reelsId];
        CATextLayer* c = filtered[0];
        CATextLayer* t = [self drawText:c.string inLayer:c.superlayer withTransform:c.superlayer.affineTransform inPosition:LabelAlignmentCenter];
        
        float size = 0.3 * self.parkingSlotFrame.size.width;
        
        filtered[0].fontSize = 8.f;
        while (filtered[0].fontSize > size) {
                filtered[0].fontSize -= 0.1f;
        }
        
        CGSize sizeForText = [text sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:filtered[0].fontSize + .5f]}];
        
        filtered[0].anchorPoint = CGPointMake(.6f, .35f);
        filtered[0].string = text;
    }
}

- (void)fillElementWithIdentifier:(NSString *)identifier withColor:(UIColor *)color
{
    SVGRectElement *element = [self.parkingSpots bk_match:^BOOL(SVGRectElement *obj) { return [obj.identifier isEqualToString:identifier]; }];
    
    [self fillRectElement:element withColor:color];
}

- (void)fillRectElement:(SVGRectElement *)element withColor:(UIColor *)color
{
    [self fillRectElement:element withColor:color borderColor:[UIColor blackColor]];
}

- (void)fillRectElement:(SVGRectElement *)element withColor:(UIColor *)color borderColor:(UIColor *)borderColor
{
    CALayer *hitLayer = [self layerForRectElement:element];

    [self fillLayer:hitLayer
          withColor:color
        borderColor:borderColor];
}

- (void)fillLayer:(CALayer *)layer withColor:(UIColor *)color borderColor:(UIColor *)borderColor
{
    if ([layer isKindOfClass:CAShapeLayer.class]) {
        CAShapeLayer *shapeLayer = (CAShapeLayer *)layer;
        shapeLayer.fillColor = color.CGColor;
        shapeLayer.strokeColor = borderColor.CGColor;        

        NSString *regionName = shapeLayer.superlayer.name;
        [self selectParkingSlotWithId:shapeLayer.name regionName:regionName];
    }
}

- (CALayer *)layerForRectElement:(SVGRectElement *)element
{
    CGRect originalRect     = CGRectMake(element.x.value, element.y.value, element.width.value, element.height.value);
    CGRect transformedRect  = CGRectApplyAffineTransform(originalRect, element.transform);
    CGPoint centerPoint     = CGPointMake(transformedRect.origin.x + transformedRect.size.width / 2, transformedRect.origin.y + transformedRect.size.height / 2);
    
    CGPoint convertedPoint  = [self.contentView convertPoint:centerPoint toView:self.scrollView];
    
    CALayer *layer = [self.contentView.layer hitTest:convertedPoint];
    
    if (layer == nil) {
        return self.contentView.layer;
    }
    
    return layer;
}

- (void)deselectTappedLayer
{
    UIGestureRecognizer *gesture = self.selectedTemporaryShape.gestureRecognizers.lastObject;
    [self.selectedTemporaryShape removeGestureRecognizer:gesture];
    
    self.selectedTemporaryShape.backgroundColor     = [UIColor whiteColor];
    self.selectedTemporaryShape.layer.borderColor   = [UIColor blackColor].CGColor;
    self.selectedTemporaryShape                     = nil;
    
    if (![self.markedParkingSlots containsObject:self.tappedLayer.name]) {
        if ([self.spotsWithParkedReel containsObject:self.tappedLayer.name]) {
            [self fillLayer:self.tappedLayer
                  withColor:self.filledSlotColor
                borderColor:[UIColor blackColor]];
        }
        else {
            [self fillLayer:self.tappedLayer
                  withColor:[UIColor whiteColor]
                borderColor:[UIColor blackColor]];
        }
    }
    
    self.tappedLayer             = nil;
    self.selectedParkingSpotCode = nil;
}

#pragma mark - Text drawing

- (void)renderReelsInfo
{
    [self.parkingSpots bk_each:^(SVGRectElement *obj) {
        CGRect originalRect     = CGRectMake(obj.x.value, obj.y.value, obj.width.value, obj.height.value);
        CGRect transformedRect  = CGRectApplyAffineTransform(originalRect, obj.transform);
        CGPoint centerPoint     = CGPointMake(transformedRect.origin.x + transformedRect.size.width / 2,
                                              transformedRect.origin.y + transformedRect.size.height / 2);
        
        CALayer *reelLayer = [self.contentView.layer hitTest:centerPoint];
       
        if ([self isSpotLayer:reelLayer]) {
            NSString *textToDraw = self.mappedParkingSlotNames[obj.identifier] ?: obj.identifier;
            
            CATextLayer *idTextLayer = [self drawText:textToDraw
                                              inLayer:reelLayer
                                        withTransform:obj.transform
                                           inPosition:LabelAlignmentCenter];
            
            [self.reelsLabels addObject:idTextLayer];
        }
        
        if ([self hasAddtionalDataForId:obj.identifier]) {
            CATextLayer *vacancy = [self drawText:@"Bobina vazia"
                                          inLayer:reelLayer
                                    withTransform:obj.transform
                                       inPosition:LabelAlignmentBottom];
            
            [self.reelsAdditionalLabels addObject:vacancy];
        }
    }];
}

- (BOOL)hasAddtionalDataForId:(NSString *)identifier
{
    return NO;
}

- (CATextLayer *)drawText:(NSString *)text inLayer:(CALayer *)layer withTransform:(CGAffineTransform)affineTransform inPosition:(LabelAlignment)position
{
    CGFloat angleTransformationInRadians, rotation;
    angleTransformationInRadians = atan2f(affineTransform.b, affineTransform.a);
    rotation                     = angleTransformationInRadians + (M_PI / 2);
    if (rotation > 2) {
        rotation -= M_PI;
    }
    
    CATextLayer *textLayer = [self labelWithText:text fontSize:5.f frame:layer.frame rotation:rotation position:position];
    [layer addSublayer:textLayer];
    return textLayer;
    
    
}

- (CATextLayer *)labelWithText:(NSString *)text fontSize:(CGFloat)fontSize frame:(CGRect)targetFrame rotation:(CGFloat)radians position:(LabelAlignment)position
{
    CGFloat cX, cY, x, y, padding;
    
    switch (position) {
        case LabelAlignmentBottom:
            text = [NSString stringWithFormat:@"\n\n%@", text];
            break;
        case LabelAlignmentTop:
            text = [NSString stringWithFormat:@"%@\n\n", text];
            break;
        default:
            text = [NSString stringWithFormat:@"\n%@\n", text];
            break;
    }
    
    padding = targetFrame.size.width * .15f;
    CGSize sizeForText = [text  sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize]}];
    
    while (sizeForText.width + padding > targetFrame.size.width) {
        fontSize -= .1f;
        sizeForText = [text sizeWithAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:fontSize]}];
    }
    
    
    
    CGRect textFrame = CGRectZero;
    textFrame.size = sizeForText;
    cX           = (targetFrame.size.width / 2.f);
    cY           = (targetFrame.size.height / 2.f);
    x            = cX - (sizeForText.width / 2.f);
    y            = cY - (sizeForText.height / 2.f);
    
    textFrame.origin = CGPointMake(x, y);
    
    textFrame.size.height -= .5f;
    textFrame.size.width += 3.f;
    
    CGFloat anchor              = .5f;
    CATextLayer *textLayer      = [[CATextLayer alloc] init];
    textLayer.font              = (__bridge CFTypeRef _Nullable)(@"Helvetica-Bold");
    textLayer.fontSize          = fontSize;
    textLayer.frame             = textFrame;
    textLayer.string            = text;
    textLayer.alignmentMode     = kCAAlignmentCenter;
    textLayer.foregroundColor   = [UIColor blackColor].CGColor;
    textLayer.contentsScale     = [UIScreen mainScreen].scale * 4;
    textLayer.anchorPoint       = CGPointMake(.6f, .45f);
    textLayer.affineTransform   = CGAffineTransformMakeRotation(radians);
    textLayer.hidden =  YES;
    return textLayer;
}

- (void)toggleAdditionalForCurrentZoom:(CGFloat)currentZoom
{
    BOOL showLayers = (currentZoom >= 3.0f);
    if ([self.reelsAdditionalLabels firstObject].isHidden == !showLayers)
        return;
    
    for (CATextLayer *layer in self.reelsAdditionalLabels)
        layer.hidden = !showLayers;
}


- (void)toggleIdentifiersForCurrentZoom:(CGFloat)currentZoom
{
    BOOL showLayers = (currentZoom >= 1.2f);
    if ([self.reelsLabels firstObject].isHidden == !showLayers)
        return;
    
    for (CATextLayer *layer in self.reelsLabels)
        layer.hidden = !showLayers;
}

- (void)toggleParkingSlotsForCurrentZoom:(CGFloat)currentZoom
{
    BOOL showLayers = (currentZoom >= 1.f);
    if (self.parkingSlotsLayers.firstObject.isHidden == !showLayers) {
        return;
    }
    
    for (CAShapeLayer *layer in self.parkingSlotsLayers) {
        if ([layer isKindOfClass:CAShapeLayer.class]) {
            layer.hidden = !showLayers;
        }
    }
    
    for (UIView *view in self.temporaryParkingSlotsPlotted) {
        view.hidden = !showLayers;
    }
}

- (void)toggleRegionNameForCurrentZoom:(CGFloat)currentZoom
{
    BOOL showLayers = currentZoom < 1.f;
    if (self.regionNameLayers.firstObject.isHidden == !showLayers) {
        return;
    }
    
    for (CALayer *layer in self.regionNameLayers) {
        layer.hidden = !showLayers;
    }
}

@end
