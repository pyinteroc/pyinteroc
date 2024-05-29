from cffi import FFI
import importlib.resources as pkg_resources

ffi = FFI()

ffi.cdef("""
    typedef struct {
        uint8_t fn_num;
        int32_t num;
    } PyArg;
    
    int main();
    int call_roc(PyArg arg);
""")


# Loading the shared library
lib_path = pkg_resources.files("lib")\
    .joinpath("libhost.so")

### Calling the shared library function
roc = ffi.dlopen(str(lib_path))
py_arg = ffi.new("PyArg *", {'fn_num': 5, 'num': 10})