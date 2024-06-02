#!/usr/bin/env python3

from cffi import FFI
import importlib.resources as pkg_resources
from typing import List

def roc_fn():
    """
    Decorator to convert a Python function into a ROC function.
    """
    roc = ROC()
    def decorator(fn):
        def wrapper(*args, **kwargs):
            str_args = [fn.__name__] + [str(arg) for arg in args]
            c_args = roc.c_args(string_list= str_args)
            result = roc.call_roc(c_args)
            return result
        return wrapper
    return decorator

class ROC:
    def __init__(self):
        self.ffi: FFI = FFI()
        self.ffi.cdef("""
            typedef struct {
                char **args; // Pointer to an array of C strings
                uint32_t num; // Number of arguments
            } CArgs;
            int call_roc(CArgs *c_args);
        """)

        # Loading the shared library
        lib_path = pkg_resources.files("lib").joinpath("libhost.so")
        self.roc = self.ffi.dlopen(str(lib_path))
    
    def c_args(self, string_list: List[str]) -> object:
        # Prepare the arguments
        args = [
            self.ffi.new("char[]", arg.encode()) \
            for arg in string_list] \
            + [self.ffi.NULL]

        # Create an instance of CArgs
        c_args = self.ffi.new(
            "CArgs *"
            , {"args": self.ffi.new("char *[]", args)
            , "num": len(string_list)}
        )
        
        return c_args

    def call_roc(self, c_args: object) -> int:
        return self.roc.call_roc(c_args)
