#!/usr/bin/env python3

import pytest
from cffi import FFI

from roc import roc, c_args


def test_roc(capfd):
    
    result = roc.call_roc(c_args)
    out, err = capfd.readouterr()
    expected_output = "OK: STR1"
    # Assuming the output is printed with a newline at the end, we strip it before comparing
    assert out.strip() == expected_output

    assert result == 1