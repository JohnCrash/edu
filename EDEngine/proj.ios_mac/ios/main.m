#import <UIKit/UIKit.h>
#include "parsparam.h"

int main(int argc, char *argv[]) {
    ParseCommand( argc,argv );
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"AppController");
    [pool release];
    return retVal;
}
