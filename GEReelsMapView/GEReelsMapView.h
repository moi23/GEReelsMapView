//
//  GEReelsMapView.h
//  SVGKitTest
//
//  Created by Marcilio Junior on 3/22/16.
//  Copyright © 2016 HE:labs. All rights reserved.
//

@import UIKit;

typedef enum: NSUInteger {
    GETemporaryViewTypeParkingSlot,
    GETemporaryViewTypeBalsa
} GETemporaryViewType;

@interface GEReelsMapView : UIView

#pragma mark - Properties

/**
 *  Called when map loading finishes.
 */
@property (nonatomic, copy, nullable) void(^finishedLoadingMap)();

/**
 *  Called when a parking slot is selected.
 */
@property (nonatomic, copy, nullable) void(^parkingSlotDidSelect)(NSString * __nonnull parkingSlotCode, NSString * __nullable regionName);

@property (nonatomic, copy, nullable) void(^balsaInfoDidTap)(NSString * __nonnull balsaCode);

/**
 *  Called when a temporary parking slot is removed from map.
 */
@property (nonatomic, copy, nullable) void(^temporaryParkingSlotRemoved)();

/**
 *  SVG Map file name.
 */
@property (nonatomic, strong, nonnull) NSString *mapFilename;

/**
 *  Bundle that containts SVG File.
 */
@property (nonatomic, strong, nullable) NSBundle *bundle;

/**
 *  Current parking slot code selected.
 */
@property (nonatomic, strong, nullable) NSString *selectedParkingSpotCode;

/**
 *  Point of current temporary parking slot selected.
 */
@property (nonatomic) CGPoint temporaryParkingSlotCurrentPosition;

@property (nonatomic) CGPoint balsaCurrentPosition;

/**
 *  Rotation angle of current temporary parking slot selected.
 */
@property (nonatomic) CGFloat temporaryParkingSlotCurrentAngle;

@property (nonatomic) CGFloat balsaCurrentAngle;

/**
 *  Determines if a temporary parking slot was created.
 */
@property (nonatomic, readonly, getter=isNewParkingSlotCreated) BOOL parkingSlotCreated;

/**
 *  Enable/Disable pan gesture for temporary parking slots.
 */
@property (nonatomic) BOOL lockPanGestureForNewParkingSlot;

@property (nonatomic) BOOL lockPanGestureForBalsa;

/**
 *  Determines if a parking slot can be selected.
 */
@property (nonatomic) BOOL allowParkingSlotSelection;

/**
 *  Determines if the layers of map will appear or disappear based on zoom changes.
 */
@property (nonatomic) BOOL enableZoomChanges;

/**
 *  Color of selected parking slot.
 */
@property (nonatomic, strong, nonnull) UIColor *selectedParkingSlotColor;

/**
 *  Color of selected parking slot.
 */
@property (nonatomic) CGRect parkingSlotFrame;

/**
 *  Border color of selected parking slot.
 */
@property (nonatomic, strong, nonnull) UIColor *selectedParkingSlotBorderColor;

/**
 *  Color of parking slots with parked reels.
 */
@property (nonatomic, strong, nonnull) UIColor *filledSlotColor;

/**
 *  Code of a parking slot that should be selected when map finishes its load on screen.
 */
@property (nonatomic, strong, nullable) NSString *preselectedParkingSlot;

/**
 *  Dictionary responsible to change the name of a parking slot that's appear on map.
 */
@property (nonatomic, strong, nullable) NSDictionary *mappedParkingSlotNames;

#pragma mark - Methods

/**
 *  Loads the SVG file and shows it in the screen.
 */
- (void)loadSVGFromFile;

- (void)setupView;

- (void)createViewOnMapOfType:(GETemporaryViewType)type
               withIdentifier:(NSString * _Nullable)identifier
        parkingSlotIdentifier:(NSString * _Nullable)parkingSlotIdentifier;

/**
 *  Add a temporary parking slot in a given point with a custom angle and an identifier at map.
 *
 *  @param point      Position of the created parking slot in map.
 *  @param givenAngle Rotation angle of created parking slot.
 *  @param identifier Label presented in parking slot.
 */
- (void)addTemporaryParkingSlotToPoint:(CGPoint)point
                             withAngle:(CGFloat)givenAngle
                            identifier:(nonnull NSString *)identifier;

- (void)addTemporaryRegionToPoint:(CGPoint)point
                        withAngle:(CGFloat)givenAngle
                 regionIdentifier:(nonnull NSString *)identifier
            parkingSlotIdentifier:(nonnull NSString *)psIdentifier;

- (void)updateRotationOfViewType:(GETemporaryViewType)type withAngle:(CGFloat)givenAngle;

/**
 *  Selects a parking slot based on its identifier.
 *
 *  @param parkingSpotId Identifier of parking slot that should be selected.
 */
- (void)selectParkingSpotWithId:(nonnull NSString *)parkingSpotId;

/**
*  Selects a parking slot based on its identifier.
*
*  @param parkingSpotId Identifier of parking slot that should be selected.
*  @param reelsId Identifier of reels in spot.
*/
- (void)selectParkingSpotWithId:(nonnull NSString *)parkingSlotId withReelsId:(nonnull NSString *)reelsId;

/**
 *  Marks that's a parking slot have a reel parked.
 *
 *  @param parkingSpotId Parking slot identifier.
 *  @param color         Background color of the parking slot view.
 */
- (void)markParkingSlotWithId:(nonnull NSString *)parkingSpotId
                     andColor:(nonnull UIColor *)color;

/**
 *  Marks that's a parking slot doesn't have a reel parked.
 *
 *  @param parkingSlotId Parking slot identifier.
 */
- (void)unmarkParkingSlotWithId:(nonnull NSString *)parkingSlotId;

/**
 *  Zooms map in a given region.
 *
 *  @param identifier Region identifier.
 */
- (void)zoomInAreaWithIdentifier:(nonnull NSString *)identifier;

/**
 *  Updates the opacity of all regions in the map.
 *
 *  @param opacity Given opacity value.
 */
- (void)updateOpacityOfAllLayersWithValue:(CGFloat)opacity;

/**
 *  Updates the opacity of all regions in the map. Except the ones that are in `excludedNames` parameter.
 *
 *  @param opacity       Opacity value
 *  @param excludedNames Regions that should not have opacity change.
 */
- (void)updateOpacityOfAllLayersWithValue:(CGFloat)opacity
                  excludingLayersWithName:(nullable NSArray<NSString *> *)excludedNames;

/**
 *  Gets the region that the created parking slot is contained in.
 *
 *  @return Region identifier.
 */
- (nullable NSString *)getRegionForSelectTemporaryParkingSlot;

@end
