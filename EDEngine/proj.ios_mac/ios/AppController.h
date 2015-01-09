#import <UIKit/UIKit.h>
#import "staticlib.h"

@class RootViewController_v3;

@interface AppController_v3 : NSObject <UIApplicationDelegate> {
    UIWindow *window;
}

@property(nonatomic, readonly) RootViewController_v3* viewController;

@end

