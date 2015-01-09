#import <UIKit/UIKit.h>
#include "parsparam.h"
#include "staticlib.h"
UsingMySpace;


int main(int argc, char *argv[]) {
    ParseCommand( argc,argv );
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"AppController_v3");
    [pool release];
    return retVal;
}
