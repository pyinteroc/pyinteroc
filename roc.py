from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

# Assuming you know the function signatures you want to call
ffi.cdef("""
    int main();
""")

# Load the shared library
lib_path = pkg_resources.files("lib")\
    .joinpath("libhost.so")
roc_lib = ffi.dlopen(str(lib_path))

# Now you can call functions from the library, e.g., `lib.add(2, 3)`
result = roc_lib.main()
# print(result)