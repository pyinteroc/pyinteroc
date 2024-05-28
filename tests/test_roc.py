import pytest

from roc import roc

def test_roc(capfd):
    roc.call_roc(10)
    out, err = capfd.readouterr()
    expected_output = "1,2,Fizz,4,Buzz,Fizz,7,8,Fizz,Buzz"
    # Assuming the output is printed with a newline at the end, we strip it before comparing
    assert out.strip() == expected_output