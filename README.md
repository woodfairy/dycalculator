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

### 1. 
