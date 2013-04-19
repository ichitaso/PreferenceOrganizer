//
//  PreferenceOrganizer.mm
//  PreferenceOrganizer
//
//  Created by Qusic on 4/19/13.
//  Copyright (c) 2013 Qusic. All rights reserved.
//

// CaptainHook by Ryan Petrich
// see https://github.com/rpetrich/CaptainHook/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import "CaptainHook/CaptainHook.h"

// Objective-C runtime hooking using CaptainHook:
//   1. declare class using CHDeclareClass()
//   2. load class using CHLoadClass() or CHLoadLateClass() in CHConstructor
//   3. hook method using CHOptimizedMethod()
//   4. register hook using CHHook() in CHConstructor
//   5. (optionally) call old method using CHSuper()

static NSMutableArray *CydiaSpecifiers;
static NSMutableArray *AppStoreSpecifiers;

@interface UIImage (Private)
+(UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface CydiaSpecifiersController : PSListController
@end
@implementation CydiaSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { _specifiers =  CydiaSpecifiers; }
    return _specifiers;
}
@end

@interface AppStoreSpecifiersController : PSListController
@end
@implementation AppStoreSpecifiersController
- (NSArray *)specifiers
{
    if (_specifiers == nil) { _specifiers =  AppStoreSpecifiers; }
    return _specifiers;
}
@end

CHDeclareClass(PrefsListController)
CHOptimizedMethod(0, self, NSMutableArray *, PrefsListController, specifiers)
{
    NSMutableArray *specifiers = CHSuper(0, PrefsListController, specifiers);
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *savedSpecifiers = [NSMutableDictionary dictionary];
        NSInteger group = -1;
        for (PSSpecifier *s in specifiers) {
            if (s.cellType == 0) {
                group++;
                if (group >= 6) {
                    [savedSpecifiers setObject:[NSMutableArray array]forKey:[NSNumber numberWithInteger:group]];
                }
            }
            if (group >= 6) {
                [[savedSpecifiers objectForKey:[NSNumber numberWithInteger:group]]addObject:s];
            }
        }
        if (![[[savedSpecifiers objectForKey:[NSNumber numberWithInteger:6]][1] identifier]isEqualToString:@"DEVELOPER_SETTINGS"]) {
            CydiaSpecifiers = [savedSpecifiers objectForKey:[NSNumber numberWithInteger:6]];
        }
        if (![[[savedSpecifiers objectForKey:[NSNumber numberWithInteger:7]][1] identifier]isEqualToString:@"DEVELOPER_SETTINGS"]) {
            AppStoreSpecifiers = [savedSpecifiers objectForKey:[NSNumber numberWithInteger:7]];
        } else {
            AppStoreSpecifiers = [savedSpecifiers objectForKey:[NSNumber numberWithInteger:8]];
        }
        
        [specifiers addObject:[PSSpecifier groupSpecifierWithName:nil]];
        if (CydiaSpecifiers.count > 0) {
            [specifiers removeObjectsInArray:CydiaSpecifiers];
            [CydiaSpecifiers removeObjectAtIndex:0];
            PSSpecifier *cydiaSpecifier = [PSSpecifier preferenceSpecifierNamed:@"Cydia" target:self set:NULL get:NULL
                                                                         detail:[CydiaSpecifiersController class]
                                                                           cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [cydiaSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.saurik.Cydia"
                                                                                   format:0 scale:[UIScreen mainScreen].scale]
                                 forKey:@"iconImage"];
            [specifiers addObject:cydiaSpecifier];
        }
        if (AppStoreSpecifiers.count > 0) {
            [specifiers removeObjectsInArray:AppStoreSpecifiers];
            [AppStoreSpecifiers removeObjectAtIndex:0];
            PSSpecifier *appstoreSpecifier = [PSSpecifier preferenceSpecifierNamed:@"App Store" target:self set:NULL get:NULL
                                                                            detail:[AppStoreSpecifiersController class]
                                                                              cell:[PSTableCell cellTypeFromString:@"PSLinkCell"] edit:Nil];
            [appstoreSpecifier setProperty:[UIImage _applicationIconImageForBundleIdentifier:@"com.apple.AppStore"
                                                                                      format:0 scale:[UIScreen mainScreen].scale]
                                    forKey:@"iconImage"];
            [specifiers addObject:appstoreSpecifier];
        }
    });
    return specifiers;
}

CHConstructor
{
	@autoreleasepool {
        CHLoadLateClass(PrefsListController);
        CHHook(0, PrefsListController, specifiers);
    }
}
