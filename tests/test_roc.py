#!/usr/bin/env python3

import pytest
from cffi import FFI

from roc import ROC, roc_fn

def test_c_args_creation():
    roc = ROC()
    test_args = ["STR1", "ARG1"]
    c_args = roc.c_args(test_args)
    assert c_args.num == 2

def test_call_roc():
    roc = ROC()
    test_args = ["STR2", "arg1"]
    c_args = roc.c_args(test_args)
    result = roc.call_roc(c_args)
    
    assert result == 2

def test_roc_fn_decorator():
    roc = ROC()
    
    @roc_fn()
    def sum_in_roc(a: int, b: int, c: int) -> int:
        raise NotImplementedError  ### This should never reach here

    assert sum_in_roc(1, 2, 3) == 6
    assert sum_in_roc(1, 2, 3, 4, 89) == 99
    assert sum_in_roc(1, 2, 3, 98, 150) == 254