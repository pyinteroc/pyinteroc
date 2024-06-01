from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

ffi.cdef("""
    typedef struct {
        char **args; // Pointer to an array of C strings
        uint32_t num; // Number of arguments
    } CArgs;
    int call_roc(CArgs *c_args);
""")


# Loading the shared library
lib_path = pkg_resources.files("lib")\
    .joinpath("libhost.so")

### Calling the shared library function
roc = ffi.dlopen(str(lib_path))

# Prepare the arguments
args = [ffi.new("char[]", b"STR1"), ffi.new("char[]", b"Second argument"), ffi.NULL]

# Create an instance of CArgs
c_args = ffi.new("CArgs *", {"args": ffi.new("char *[]", args), "num": 2})
