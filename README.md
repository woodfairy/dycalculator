# dycalculator
PoC dylib hijacking with the stock macOS calculator app

## Useful commands

Compiling the dylib  
```
gcc -framework AppKit -framework Foundation -o CalculatorInject.dylib -dynamiclib CalculatorInject.m
```

Injecting the dylib  
```
DYLD_INSERT_LIBRARIES=/path/to/CalculatorInject.dylib /System/Applications/Calculator.app/Contents/MacOS/Calculator
```


## How to do this yourself

#### 1. Setting up the dylib

First, you have to set up the code for your dylib.  
Create a definition called CalculatorInjectOverrides (or whatever you want) by declaring an interface:
```objective-c
#include <Foundation/Foundation.h>

@interface CalculatorInjectOverrides : NSObject
+(void)load;
-(void)newApplicationDidFinishLaunching:(void *)arg2;
@end
```

As you can see, CalculatorInjectOverrides has 2 instance methods.
The first one (load) is the constructor of the dylib and gets called when it is injected into another process.  
That's where most of the magic happens. You'll swap out the implementation of whatever method you want to hijack with the implementation of the second instance method of CalculatorInjectOverrides (newApplicationDidFinishLaunching).


#### 2. Get the original method and its implementation
Let's retrieve the original method in the constructor (load):
```objective-c
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
}
```
First, we get the original class using NSClassFromString, and passing ```@"CalculatorController``` as argument, as this is the class we want to hook.  
Then, we can obtain the instance method using class_getInstanceMethod which expects the original class as first, and a selector as second parameter.  
In this case, as we want to hook ```-(void)applicationDidFinishLaunching:(void *)arg2```, we take ```@selector(applicationDidFinishLaunching:)```as selector.  
To retrieve the implementation itself from the original method, we can use method_getImplementation which expects the original method as parameter.  

#### 3. Get your new (substitute) method and swap out the implementations
Now we can swap out the implementation of the original method with our custom implementation.  
This can be done by adding the following lines to your constructor:  
```objective-c
// get the new (substitute) method
Method substituteApplicationDidFinishLaunchingMethod = class_getInstanceMethod(NSClassFromString(@"CalculatorInjectOverrides"), @selector(newApplicationDidFinishLaunching:));
// change the implementation of the original method and replace it by our substitute
method_exchangeImplementations(originalApplicationDidFinishLaunchingMethod, substituteApplicationDidFinishLaunchingMethod);
```

You basically do the same you did for the orignal method, you first retrieve the new substitute method using class_getInstanceMethod.
In the second step, you exchange the implementations using method_exchangeImplementation, which expects the (original) implementation as first, and the new (substitute) method as second argument.  

#### 4. Implement your new method
Now it's time to write our custom code which will be executed instead of ```-(void)applicationDidFinishLaunching:(void *)arg2```.
Just implement ```-(void)newApplicationDidFinishLaunching:(void *)arg2``` of ```CalculatorInjectOverrides```.  
```objective-c
-(void)newApplicationDidFinishLaunching:(void *)arg2 
{
    NSLog(@"Hooking CalculatorController_applicationDidFinishLaunching");

    // run the original method, you can also skip this
    sOriginalApplicationDidFinishLaunching(self, @selector(applicationDidFinishLaunching:), arg2);
    
    // create NSAlert for PoC 
    NSAlert *alert = [NSAlert alertWithMessageText:@"dylib hijacking succesful!" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Code succesfully injected using DYLD_INSERT_LIBRARIES."];
    [alert runModal];
    return;
}
```
First, we just log that we are hooking the original method, so we now, that our substitute is invoked succesfully.  
Then, we invoke the original method in order to keep its behavior (but in general, you don't have to!). Further information on this: https://developer.apple.com/documentation/objectivec/objective-c_runtime/imp  
After running the original method, we can simply execute our own, custom code and do whatever we want. For this basic proof of concept, we just create an NSAlert modal and show it.  

That's it, you now have succesfully hijacked an instance method using DYLD_INSERT_LIBRARIES!
