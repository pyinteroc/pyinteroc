#!/usr/bin/env python3

import pytest
from cffi import FFI

from roc import ROC

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