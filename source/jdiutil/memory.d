module jdiutil.memory;

import std.stdio;

// https://wiki.dlang.org/Memory_Management#Explicit_Class_Instance_Allocation
// https://forum.dlang.org/post/pqykojxbmjaiwzxcdxnh@forum.dlang.org
// I recommend using libc's malloc and free instead of GC.malloc and GC.free.
// Reason: you avoid increasing the GC's heap size.
// Note that you only need to use GC.addRange if the objects you allocate themselves point to other objects.
 
T heapAlloc(T, bool notifyGC, Args...) (Args args) {
    import std.conv : emplace;
    import core.stdc.stdlib : malloc;
    import core.memory : GC;
    
    // get class size of class instance in bytes
    auto size = __traits(classInstanceSize, T);
    
    // allocate memory for the object
    auto memory = malloc(size)[0..size];
    if(!memory)
    {
        import core.exception : onOutOfMemoryError;
        onOutOfMemoryError();
    }                    
    
    // writeln("Memory allocated");

    // notify garbage collector that it should scan this memory
    static if (notifyGC) {
      GC.addRange(memory.ptr, size);
    }
    
    // call T's constructor and emplace instance on
    // newly allocated memory
    return emplace!(T, Args)(memory, args);                                    
}

T heapAlloc(T, Args...) (Args args) {
  return heapAlloc!(T, false, Args)(args);
}
 
void heapFree(T, bool notifyGC)(T obj) {
    import core.stdc.stdlib : free;
    import core.memory : GC;
    
    // calls obj's destructor
    destroy(obj); 

    // garbage collector should no longer scan this memory
    static if (notifyGC) {
      GC.removeRange(cast(void*)obj);
    }
    
    // free memory occupied by object
    free(cast(void*)obj);
    
    // writeln("Memory deallocated");
}

void heapFree(T)(T obj) {
  heapFree!(T, false)(obj);
}


unittest {
  class TestClass {
    int x;
    
    this(int x) 
    {
        writeln("TestClass's constructor called");
        this.x = x;
    }
    
    ~this() 
    {
        writeln("TestClass's destructor called");
    }
  }

  void main() {
    // allocate new instance of TestClass on the heap
    auto test = heapAlloc!TestClass(42);
    scope(exit)
    {
        heapFree(test);    
    }
    
    writefln("test.x = %s", test.x);
  }

  main();

}
