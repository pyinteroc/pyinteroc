from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

ffi.cdef("""
    typedef struct {
        const char* fn_name;
        int32_t num;
    } PyArgC;
    
    int call_roc(PyArgC* arg);
""")


# Loading the shared library
lib_path = pkg_resources.files("lib")\
    .joinpath("libhost.so")

### Calling the shared library function
roc = ffi.dlopen(str(lib_path))
py_arg = ffi.new(
    "PyArgC *"
    , {
        'fn_name': ffi.new("char[]", b"function_name")
        , 'num': 10
    })
