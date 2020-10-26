#import "CalculatorInjectOverrides.h"
 
#include <stdio.h>
#include <objc/runtime.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

typedef void (*original_applicationDidFinishLaunching_IMP)(void*, SEL, void*);
static original_applicationDidFinishLaunching_IMP sOriginalApplicationDidFinishLaunching;
 
@implementation CalculatorInjectOverrides
 
 // this is the constructor
+(void)load
{
    // get the original class CalculatorController
    Class originalClass = NSClassFromString(@"CalculatorController");

    // get the original instance method
    Method originalApplicationDidFinishLaunchingMethod = class_getInstanceMethod(originalClass, @selector(applicationDidFinishLaunching:));
    // get the implementation of the instance method
    sOriginalApplicationDidFinishLaunching = method_getImplementation(originalApplicationDidFinishLaunchingMethod);
    
    // get the new (substitute) method
    Method substituteApplicationDidFinishLaunchingMethod = class_getInstanceMethod(NSClassFromString(@"CalculatorInjectOverrides"), @selector(newApplicationDidFinishLaunching:));
    // change the implementation of the original method and replace it by our substitute
    method_exchangeImplementations(originalApplicationDidFinishLaunchingMethod, substituteApplicationDidFinishLaunchingMethod);
}

-(void)newApplicationDidFinishLaunching:(void *)arg2 
{
    NSLog(@"Hooking CalculatorController_applicationDidFinishLaunching");

    // create NSAlert for PoC 
    NSAlert *alert = [NSAlert alertWithMessageText:@"dylib hijacking succesful!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Code succesfully injected using DYLD_INSERT_LIBRARIES."];
    [alert runModal];

    // run the original method, you can also skip this
    sOriginalApplicationDidFinishLaunching(self, @selector(applicationDidFinishLaunching:), arg2);
    return;
}


@end