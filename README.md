# Haxe Interface Handlers

This module lets you use HaXe closures easily with native Java APIs.  Example:

```haxe
import com.boltmade.InterfaceHandlers.toHandler
import java.lang.Runnable;

class SomeClass {
  function something() {
    someJavaMethodTakes(toHandler(function(){
      trace("ran!);
    }, Runnable.run));
  }
}
```
