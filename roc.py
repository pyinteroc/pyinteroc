from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

# Assuming you know the function signatures you want to call
ffi.cdef("""
    int add(int, int);
""")

# Load the shared library
with pkg_resources.path("pyinteroc.lib", "libhost.so") as lib_path:
    lib = ffi.dlopen(str(lib_path))

# Now you can call functions from the library, e.g., `lib.add(2, 3)`
result = lib.add(2, 3)
print(result)