from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

ffi.cdef("""
    int main();
    int call_roc(int);
""")

# Loading the shared library
lib_path = pkg_resources.files("lib")\
    .joinpath("libhost.so")

### Calling the shared library function
roc = ffi.dlopen(str(lib_path))

# result = roc.main()